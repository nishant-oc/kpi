# coding: utf-8
import time

from django.conf import settings
from django.http import HttpResponse

from kpi.models import Asset



def service_health(request):
    """
    Return a HTTP 200 if some very basic runtime tests of the application
    pass. Otherwise, return HTTP 500
    """

    any_failure = False

    t0 = time.time()
    mongo_message = None
    try:
        settings.MONGO_DB.instances.find_one(max_time_ms=settings.MONGO_TIMEOUT_MS)
    except Exception:
        pass
    else:
        mongo_message = 'OK'
    mongo_time = time.time() - t0

    t0 = time.time()
    try:
        Asset.objects.order_by().first()
    except Exception as e:
        postgres_message = repr(e)
        any_failure = True
    else:
        postgres_message = 'OK'
    postgres_time = time.time() - t0

    output = (
        '{} KPI\r\n\r\n'
        'Postgres: {} in {:.3} seconds\r\n'
    ).format(
        'FAIL' if any_failure else 'OK',
        postgres_message, postgres_time,
    )

    if mongo_message is not None:
        output += 'Mongo: {} in {:.3} seconds\r\n'.format(mongo_message, mongo_time)

    return HttpResponse(
        output, status=(500 if any_failure else 200), content_type='text/plain'
    )
