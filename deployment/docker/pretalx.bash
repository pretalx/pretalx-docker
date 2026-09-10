#!/bin/bash
cd /pretalx/src || exit 1
export PRETALX_DATA_DIR="${PRETALX_DATA_DIR:-/data}"
export HOME=/pretalx

PRETALX_FILESYSTEM_LOGS="${PRETALX_FILESYSTEM_LOGS:-/data/logs}"
PRETALX_FILESYSTEM_MEDIA="${PRETALX_FILESYSTEM_MEDIA:-/data/media}"
PRETALX_FILESYSTEM_STATIC="${PRETALX_FILESYSTEM_STATIC:-/pretalx/src/static.dist}"

GUNICORN_WORKERS="${GUNICORN_WORKERS:-${WEB_CONCURRENCY:-$((2 * $(nproc)))}}"
GUNICORN_MAX_REQUESTS="${GUNICORN_MAX_REQUESTS:-1200}"
GUNICORN_MAX_REQUESTS_JITTER="${GUNICORN_MAX_REQUESTS_JITTER:-50}"
GUNICORN_FORWARDED_ALLOW_IPS="${GUNICORN_FORWARDED_ALLOW_IPS:-127.0.0.1}"
GUNICORN_BIND_ADDR="${GUNICORN_BIND_ADDR:-0.0.0.0:80}"

AUTOMIGRATE="${AUTOMIGRATE:-yes}"
AUTOREBUILD="${AUTOREBUILD:-yes}"

REDIS_BUNDLED="${REDIS_BUNDLED:-no}"

# Point pretalx at the Redis bundled in this image. Environment variables are
# the last config layer pretalx reads, so these take precedence over any
# [redis]/[celery] settings in pretalx.cfg. REDIS_AUTOSTART is what
# supervisord.conf reads to decide whether to run its redis program.
if [ "$REDIS_BUNDLED" = "yes" ]; then
    export REDIS_AUTOSTART=true
    export PRETALX_REDIS="${PRETALX_REDIS:-redis://127.0.0.1:6379/0}"
    export PRETALX_REDIS_SESSIONS="${PRETALX_REDIS_SESSIONS:-True}"
    export PRETALX_CELERY_BACKEND="${PRETALX_CELERY_BACKEND:-redis://127.0.0.1:6379/1}"
    export PRETALX_CELERY_BROKER="${PRETALX_CELERY_BROKER:-redis://127.0.0.1:6379/2}"
else
    export REDIS_AUTOSTART=false
fi

if [ "$PRETALX_FILESYSTEM_LOGS" != "/data/logs" ]; then
    export PRETALX_FILESYSTEM_LOGS
fi
if [ "$PRETALX_FILESYSTEM_MEDIA" != "/data/media" ]; then
    export PRETALX_FILESYSTEM_MEDIA
fi
if [ "$PRETALX_FILESYSTEM_STATIC" != "/pretalx/src/static.dist" ]; then
    export PRETALX_FILESYSTEM_STATIC
fi

if [ ! -d "$PRETALX_FILESYSTEM_LOGS" ]; then
    mkdir "$PRETALX_FILESYSTEM_LOGS";
fi
if [ ! -d "$PRETALX_FILESYSTEM_MEDIA" ]; then
    mkdir "$PRETALX_FILESYSTEM_MEDIA";
fi
if [ "$PRETALX_FILESYSTEM_STATIC" != "/pretalx/src/static.dist" ] &&
   [ ! -d "$PRETALX_FILESYSTEM_STATIC" ] &&
   [ "$AUTOREBUILD" = "yes" ]; then
    mkdir -p "$PRETALX_FILESYSTEM_STATIC"
    flock --nonblock /pretalx/.lockfile python3 -m pretalx rebuild
fi

if [ "$1" == "redis" ]; then
    mkdir -p "$PRETALX_DATA_DIR/redis"
    # Bind to loopback only: this Redis serves the processes in this container
    # and runs without authentication.
    # shellcheck disable=SC2086
    exec redis-server --bind 127.0.0.1 --port 6379 \
        --dir "$PRETALX_DATA_DIR/redis" $REDIS_ARGS
fi

# "all" runs nothing itself: Redis, the web worker and the task worker are all
# supervisord programs, and the migrations happen in the web worker below.
if [ "$1" == "all" ]; then
    exec /usr/bin/supervisord -n -c /etc/supervisord.conf
fi

# pretalx runs Django system checks that reach for the cache and the celery
# broker, so everything below needs Redis to be up. supervisord runs it as a
# program of its own, but starts all of them in parallel, so wait for it.
if [ "$REDIS_BUNDLED" = "yes" ]; then
    for attempt in $(seq 1 120); do
        redis-cli -h 127.0.0.1 -p 6379 ping >/dev/null 2>&1 && break
        if [ "$attempt" = 120 ]; then
            echo "Timed out waiting for the bundled Redis" >&2
            exit 1
        fi
        sleep 0.5
    done
fi

if [ "$1" == "cron" ]; then
    exec python3 -m pretalx runperiodic
fi

# Only the web worker migrates, so that the two workers supervisord starts in
# parallel cannot run migrations against each other. The task worker only
# needs the broker to start up, and picks up tasks once the web worker is
# serving anyway.
if [ "$AUTOMIGRATE" = "yes" ] && [ "$1" != "taskworker" ]; then
    python3 -m pretalx migrate --noinput
fi

if [ "$1" == "webworker" ]; then
    exec gunicorn pretalx.wsgi \
        --name pretalx \
        --workers "${GUNICORN_WORKERS}" \
        --max-requests "${GUNICORN_MAX_REQUESTS}" \
        --max-requests-jitter "${GUNICORN_MAX_REQUESTS_JITTER}" \
        --forwarded-allow-ips "${GUNICORN_FORWARDED_ALLOW_IPS}" \
        --log-level=info \
        --bind="${GUNICORN_BIND_ADDR}"
fi

if [ "$1" == "taskworker" ]; then
    exec celery -A pretalx.celery_app worker -l info
fi

if [ "$1" == "shell" ]; then
    exec python3 -m pretalx shell
fi

exec python3 -m pretalx "$@"
