FROM python:3.14-slim-trixie AS builder

# Quiet down pip and npm so build logs stay readable.
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_NO_INPUT=1 \
    PIP_PROGRESS_BAR=off \
    NPM_CONFIG_LOGLEVEL=error \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_PROGRESS=false

RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
        git gettext \
        libmariadb-dev libpq-dev libmemcached-dev build-essential \
        nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=root:root pretalx/pyproject.toml /pretalx/
COPY --chown=root:root pretalx/_build /pretalx/_build
COPY --chown=root:root pretalx/src /pretalx/src

RUN pip3 install --no-cache-dir -U pip setuptools wheel && \
    pip3 install --no-cache-dir -e /pretalx/[postgres,redis] && \
    pip3 install --no-cache-dir pylibmc gunicorn

RUN python3 -m pretalx rebuild && \
    rm -f /pretalx/src/pretalx.cfg /pretalx/src/data/.secret


FROM python:3.14-slim-trixie

RUN DEBIAN_FRONTEND=noninteractive apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
        gettext locales \
        libmariadb3 libmemcached11t64 \
        nodejs npm \
        supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8 && \
    mkdir /etc/pretalx /data /public && \
    groupadd -g 999 pretalxuser && \
    useradd -r -u 999 -g pretalxuser -d /pretalx -ms /bin/bash pretalxuser

ENV LC_ALL=C.UTF-8

COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin/gunicorn /usr/local/bin/celery /usr/local/bin/
COPY --from=builder --chown=pretalxuser:pretalxuser /pretalx /pretalx

COPY --chown=root:root deployment/docker/pretalx.bash /usr/local/bin/pretalx
COPY --chown=root:root deployment/docker/supervisord.conf /etc/supervisord.conf

RUN chmod +x /usr/local/bin/pretalx && \
    chown pretalxuser:pretalxuser /data /public /etc/pretalx

USER pretalxuser

VOLUME ["/etc/pretalx", "/data", "/public"]
EXPOSE 80
ENTRYPOINT ["pretalx"]
CMD ["all"]
