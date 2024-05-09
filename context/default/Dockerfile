FROM python:3.10-bookworm

RUN apt update && \
    apt install -y \
                cron \
                git \
                gettext \
                libmariadb-dev \
                libpq-dev \
                locales \
                libmemcached-dev \
                build-essential \
                locales \
                nodejs \
                npm \
                --no-install-recommends && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL=C.UTF-8

# Add unprivileged user with home directory /pretalx
RUN groupadd -g 999 pretalx && \
    useradd -r -u 999 -g pretalx -d /pretalx -ms /bin/bash pretalx

# Add directories for volumes
RUN mkdir -p /data /public && \
    chown -R 999:999 /data /public

# Provide and enable crontab
COPY --chown=0 --chmod=644 crontab /etc/crontab
RUN crontab /etc/crontab

# Switch to unprivileged user
USER pretalx
WORKDIR /pretalx

# Provide PIP with a correct path to install binaries
RUN mkdir -p /pretalx/.local/bin
ENV PATH="/pretalx/.local/bin:${PATH}"

# Install build and runtime dependencies
RUN pip3 install -U pip \
                    setuptools \
                    wheel \
                    typing \
                    pylibmc \
                    gunicorn
# Install Pretalx with Postgres and Redis database adapters
RUN pip3 install -U pretalx[postgres,redis]

COPY --chown=999 --chmod=755 entrypoint.sh /pretalx/entrypoint.sh

# Shared resources used
VOLUME ["/data", "/public"]
# Shared resources provided
EXPOSE 8080

ENTRYPOINT ["/pretalx/entrypoint.sh"]
