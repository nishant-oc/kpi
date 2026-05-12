#!/bin/bash
set -e

source /etc/profile

echo 'KPI initializing…'

cd "${KPI_SRC_DIR}"

if [[ -z $DATABASE_URL ]]; then
    echo "DATABASE_URL must be configured to run this server"
    echo "example: 'DATABASE_URL=postgres://hostname:5432/dbname'"
    exit 1
fi

wait_for_postgres() {
    local host port retries=60 wait=2
    host=$(python3 -c "import os,urllib.parse; u=urllib.parse.urlparse(os.environ['DATABASE_URL']); print(u.hostname)")
    port=$(python3 -c "import os,urllib.parse; u=urllib.parse.urlparse(os.environ['DATABASE_URL']); print(u.port or 5432)")
    echo "Waiting for PostgreSQL at ${host}:${port}…"
    until pg_isready -h "${host}" -p "${port}" -q; do
        retries=$(( retries - 1 ))
        if [[ ${retries} -le 0 ]]; then
            echo "PostgreSQL at ${host}:${port} did not become ready in time. Aborting."
            exit 1
        fi
        echo "PostgreSQL not ready — retrying in ${wait}s… (${retries} attempts left)"
        sleep "${wait}"
        wait=$(( wait < 30 ? wait * 2 : 30 ))
    done
    echo "PostgreSQL is ready."
}

KPI_WEB_SERVER="${KPI_WEB_SERVER:-uWSGI}"
if [[ "${KPI_WEB_SERVER,,}" == 'uwsgi' ]]; then
    if ! diff -q "${KPI_SRC_DIR}/dependencies/pip/requirements.txt" "${TMP_DIR}/pip_dependencies.txt"
    then
        echo "Syncing production pip dependencies…"
        pip-sync dependencies/pip/requirements.txt 1>/dev/null
        cp "dependencies/pip/requirements.txt" "${TMP_DIR}/pip_dependencies.txt"
    fi
else
    if ! diff -q "${KPI_SRC_DIR}/dependencies/pip/dev_requirements.txt" "${TMP_DIR}/pip_dependencies.txt"
    then
        echo "Syncing development pip dependencies…"
        pip-sync dependencies/pip/dev_requirements.txt 1>/dev/null
        cp "dependencies/pip/dev_requirements.txt" "${TMP_DIR}/pip_dependencies.txt"
    fi
fi

wait_for_postgres

# ---------------------------------------------------------------------------
# Fix inconsistent migration history from original Docker PG9.5 DB.
#
# RULES (learned from migration testing):
# - Insert into django_migrations = migration already applied in old DB
#   (table/column exists) but record was missing — safe to mark as done
# - DO NOT insert = column/table genuinely missing — must run for real
# - fake migrate = table/column exists but Django would try to create again
#
# Migrations that run for real (columns/tables missing from old DB):
#   kpi.0038 — data_sharing column missing
#   kpi.0041 — advanced_features column missing
#   kpi.0044 — searchable_fields column missing
#   kpi.0047 — date_deployed column missing
#   kpi.0048 — removes kpi_onetimeauthenticationkey (already gone, fake it)
#
# Migrations that are faked (tables/columns already exist):
#   kpi.0039, 0040, 0042, 0043, 0045, 0046, 0048, 0049, 0050
#   bossoidc2.0002_auto, 0002_keycloak_subdomain, 0003_keycloak_usertype
#   oauth2_provider.0002 through 0006
#   subsequences.0001, 0002
# ---------------------------------------------------------------------------
echo 'Fixing inconsistent migration history from original Docker DB...'
gosu "${UWSGI_USER}" python manage.py shell -c "
from django.db import connection

# These migrations are recorded as applied in django_migrations to fix
# dependency chain issues. Their tables/columns already exist in the DB.
missing_migrations = [
    # kpi — these exist in DB but records were missing causing chain errors
    ('kpi', '0039_add_support_paired_data_to_asset_file'),
    ('kpi', '0040_synchronous_export'),
    ('kpi', '0042_snapshots_uuids'),
    ('kpi', '0043_asset_tracks_addl_columns'),
    ('kpi', '0045_project_view_export_task'),
    ('kpi', '0046_project_view_assets_indexes'),
    ('kpi', '0048_remove_onetimeauthenticationkey'),
    ('kpi', '0049_add_pending_delete_to_asset'),
    ('kpi', '0050_add_indexes_to_import_and_export_tasks'),
    # bossoidc2 — table and columns already exist from restored DB
    ('bossoidc2', '0002_auto_20201110_2129'),
    ('bossoidc2', '0002_keycloak_subdomain'),
    ('bossoidc2', '0003_keycloak_usertype'),
    # oauth2_provider — partially applied in old DB
    ('oauth2_provider', '0002_auto_20190406_1805'),
    ('oauth2_provider', '0003_auto_20201211_1314'),
    ('oauth2_provider', '0004_auto_20200902_2022'),
    ('oauth2_provider', '0005_auto_20211222_2352'),
    ('oauth2_provider', '0006_alter_application_client_secret'),
    # subsequences — table already exists from restored DB
    ('subsequences', '0001_initial'),
    ('subsequences', '0002_non_nullable_unique_together_asset_and_submission_uuid'),
]

cursor = connection.cursor()
for app, name in missing_migrations:
    cursor.execute(
        '''INSERT INTO django_migrations (app, name, applied)
           SELECT %s, %s, NOW()
           WHERE NOT EXISTS (
               SELECT 1 FROM django_migrations
               WHERE app=%s AND name=%s
           )''',
        [app, name, app, name]
    )
    print(f'Ensured {app}.{name} exists in django_migrations')
print('Migration history fix complete.')
" || true

echo 'Running all remaining migrations...'
gosu "${UWSGI_USER}" python manage.py migrate --noinput

echo 'Creating superuser…'
gosu "${UWSGI_USER}" python manage.py create_kobo_superuser

if [[ ! -d "${KPI_SRC_DIR}/staticfiles" ]] || ! python "${KPI_SRC_DIR}/docker/check_kpi_prefix_outdated.py"; then
    if [[ "${FRONTEND_DEV_MODE}" == "host" ]]; then
        echo "Dev mode is activated and \`npm\` should be run from host."
        mkdir -p "${KPI_SRC_DIR}/staticfiles"
    else
        echo "Cleaning old build…"
        rm -rf "${KPI_SRC_DIR}/jsapp/fonts" && \
        rm -rf "${KPI_SRC_DIR}/jsapp/compiled"

        echo "Syncing \`npm\` packages…"
        if ( ! check-dependencies ); then
            npm install --legacy-peer-deps --quiet > /dev/null 2>&1
        else
            npm run postinstall > /dev/null 2>&1
        fi

        echo "Rebuilding client code…"
        npm run build

        echo "Building static files from live code…"
        python manage.py collectstatic --noinput
    fi
fi

echo "Copying static files to nginx volume…"
rsync -aq --no-times --delete --chown=www-data "${KPI_SRC_DIR}/staticfiles/" "${NGINX_STATIC_DIR}/" || true

if [[ ! -d "${KPI_SRC_DIR}/locale" ]] || [[ -z "$(ls -A ${KPI_SRC_DIR}/locale)" ]]; then
    echo "Fetching translations…"
    git submodule init && \
    git submodule update --remote && \
    python manage.py compilemessages
fi

rm -rf /etc/profile.d/pydev_debugger.bash.sh
if [[ -d /srv/pydev_orig && -n "${KPI_PATH_FROM_ECLIPSE_TO_PYTHON_PAIRS}" ]]; then
    echo 'Enabling PyDev remote debugging.'
    "${KPI_SRC_DIR}/docker/setup_pydev.bash"
fi

echo 'Cleaning up Celery PIDs…'
rm -rf /tmp/celery*.pid

echo 'Restore permissions on Celery logs folder'
chown -R "${UWSGI_USER}:${UWSGI_GROUP}" "${KPI_LOGS_DIR}"

mkdir -p "${KPI_MEDIA_DIR}"
chown -R "${UWSGI_USER}:${UWSGI_GROUP}" "${KPI_MEDIA_DIR}"

echo 'KPI initialization completed.'

exec /usr/bin/runsvdir "${SERVICES_DIR}"
