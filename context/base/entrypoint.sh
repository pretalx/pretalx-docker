#!/usr/bin/env bash

export PRETALX_DATA_DIR="${PRETALX_DATA_DIR:-/data}"

PRETALX_FILESYSTEM_LOGS="${PRETALX_FILESYSTEM_LOGS:-/data/logs}"
PRETALX_FILESYSTEM_MEDIA="${PRETALX_FILESYSTEM_MEDIA:-/data/media}"
PRETALX_FILESYSTEM_STATIC="${PRETALX_FILESYSTEM_STATIC:-/data/static}"

GUNICORN_WORKERS="${GUNICORN_WORKERS:-${WEB_CONCURRENCY:-4}}"
GUNICORN_MAX_REQUESTS="${GUNICORN_MAX_REQUESTS:-1200}"
GUNICORN_MAX_REQUESTS_JITTER="${GUNICORN_MAX_REQUESTS_JITTER:-50}"
GUNICORN_FORWARDED_ALLOW_IPS="${GUNICORN_FORWARDED_ALLOW_IPS:-127.0.0.1}"
GUNICORN_BIND_ADDR="${GUNICORN_BIND_ADDR:-0.0.0.0:8080}"

if [ "$PRETALX_FILESYSTEM_LOGS" != "/data/logs" ]; then
    export PRETALX_FILESYSTEM_LOGS
fi
if [ "$PRETALX_FILESYSTEM_MEDIA" != "/data/media" ]; then
    export PRETALX_FILESYSTEM_MEDIA
fi
if [ "$PRETALX_FILESYSTEM_STATIC" != "/data/static" ]; then
    export PRETALX_FILESYSTEM_STATIC
fi

if [ ! -d "$PRETALX_FILESYSTEM_LOGS" ]; then
    mkdir -p "$PRETALX_FILESYSTEM_LOGS";
fi
if [ ! -d "$PRETALX_FILESYSTEM_MEDIA" ]; then
    mkdir -p "$PRETALX_FILESYSTEM_MEDIA";
fi
if [ ! -d "$PRETALX_FILESYSTEM_STATIC" ]; then
    mkdir -p "$PRETALX_FILESYSTEM_STATIC"
fi

case "${1}" in
    # maintenance commands
    migrate)
        python3 -m pretalx migrate --noinput
        ${0} rebuild
        ;;
    rebuild)
        if [ ! -f "$PRETALX_FILESYSTEM_STATIC"/.built ] || [ "${2}" == "--force" ]; then
            echo "Running one-time build of static assets."
            python3 -m pretalx rebuild
            touch "$PRETALX_FILESYSTEM_STATIC/.built"
        fi
        ;;
    upgrade)
        ${0} rebuild
        python3 -m pretalx regenerate_css
        ;;

    # default web and task workers
    gunicorn)
        exec gunicorn pretalx.wsgi \
            --name pretalx \
            --workers "${GUNICORN_WORKERS}" \
            --max-requests "${GUNICORN_MAX_REQUESTS}" \
            --max-requests-jitter "${GUNICORN_MAX_REQUESTS_JITTER}" \
            --forwarded-allow-ips "${GUNICORN_FORWARDED_ALLOW_IPS}" \
            --log-level=${PRETALX_LOG_LEVEL} \
            --bind="${GUNICORN_BIND_ADDR}"
        ;;
    celery)
        exec celery -A pretalx.celery_app worker -l ${PRETALX_LOG_LEVEL}
        ;;

    # for use with the cron base image
    cron)
        exec cron -f -L 15
        ;;
    # for use with the standalone image variant
    supervisor)
        ${0} migrate
        exec sudo -E /usr/bin/supervisord -n -c /etc/supervisord.conf
        ;;
    *)
        python3 -m pretalx "$@"
esac
