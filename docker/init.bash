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

# Handle Python dependencies BEFORE attempting any `manage.py` commands
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
# Fake migrations for schema compatibility when migrating from Docker PG9.5
# to RDS. These migrations try to create tables/columns that already exist
# in the restored database. We fake them to mark as applied without running.
# The || true ensures the script continues even if already faked/applied.
# NOTE: We only fake migrations UP TO a specific point — not forward.
#       Using app-level --fake fakes ALL migrations which causes rollbacks.
#       Always specify the exact migration name to avoid rolling back.
# ---------------------------------------------------------------------------
echo 'Running fake migrations for existing schema compatibility...'

# bossoidc2 — table and columns already exist from restored DB
gosu "${UWSGI_USER}" python manage.py migrate bossoidc2 0002_auto_20201110_2129 --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate bossoidc2 0002_keycloak_subdomain --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate bossoidc2 0003_keycloak_usertype --fake --noinput || true

# kpi — columns already exist from restored DB
gosu "${UWSGI_USER}" python manage.py migrate kpi 0038_add_data_sharing_to_asset --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0041_asset_advanced_features --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0042_snapshots_uuids --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0043_asset_tracks_addl_columns --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0044_standardize_searchable_fields --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0045_project_view_export_task --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0046_project_view_assets_indexes --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0049_add_pending_delete_to_asset --fake --noinput || true
gosu "${UWSGI_USER}" python manage.py migrate kpi 0050_add_indexes_to_import_and_export_tasks --fake --noinput || true

# oauth2_provider — partially applied in old DB
gosu "${UWSGI_USER}" python manage.py migrate oauth2_provider --fake --noinput || true

echo 'Running migrations...'
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

chown -R "${UWSGI_USER}:${UWSGI_GROUP}" "${KPI_MEDIA_DIR}"

echo 'KPI initialization completed.'

exec /usr/bin/runsvdir "${SERVICES_DIR}"
