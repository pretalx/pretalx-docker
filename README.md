# pretalx-docker

This repository contains a docker-compose setup for a
[pretalx](https://github.com/pretalx/pretalx) installation based on docker.

**⚠️ Please note that this repository is provided by the pretalx community, and not supported by the pretalx team. ⚠️**

**⚠️ The files in this repository may not support the current pretalx version, or may be undocumented, not secure, and/or
outdated. Please make sure you read the files before executing them, and check the
[issues](https://github.com/pretalx/pretalx-docker/issues) for further information. ⚠️**

## Installation with docker-compose

### For testing

* Run ``docker-compose up -d``. After a few minutes the setup should be accessible at http://localhost/orga
* Set up a user and an organizer by running ``docker exec -it pretalx pretalx init``.

### For production

* Edit ``conf/pretalx.cfg`` and fill in your own values (→ [configuration
  documentation](https://docs.pretalx.org/en/latest/administrator/configure.html))
* Edit ``docker-compose.yml`` and change the line to ``ports: - "127.0.0.1:8346:80"`` (if you use nginx). **Change the
  database password.**
* If you don't want to use docker volumes, create directories for the persistent data and make them read-writeable for
  the userid 999 and the groupid 999. Change ``pretalx-redis``, ``pretalx-database``, ``pretalx-data`` and ``pretalx-public`` to the corresponding
  directories you've chosen.
* Configure a reverse-proxy for better security and to handle TLS. Pretalx listens on port 80 in the ``pretalxdocker``
  network. You can find a few words on an nginx configuration at
  ``reverse-proxy-examples/nginx``
* Make sure you serve all requests for the `/static/` and `/media/` paths (when `debug=false`). See [installation](https://docs.pretalx.org/administrator/installation/#step-7-ssl) for more information
* Optional: Some of the Gunicorn parameters can be adjusted via environment variables:
  * To adjust the number of [Gunicorn workers](https://docs.gunicorn.org/en/stable/settings.html#workers), provide
  the container with `GUNICORN_WORKERS` environment variable.
  * `GUNICORN_MAX_REQUESTS` and `GUNICORN_MAX_REQUESTS_JITTER` to configure the requests a worker instance will process before restarting.
  * `GUNICORN_FORWARDED_ALLOW_IPS` lets you specify which IPs to trust (i.e. which reverse proxies' `X-Forwarded-*` headers can be used to infer connection security).
  * `GUNICORN_BIND_ADDR` can be used to change the interface and port that Gunicorn will listen on. Default: `0.0.0.0:80`

  Here's how to set an environment variable [in
  `docker-compose.yml`](https://docs.docker.com/compose/environment-variables/set-environment-variables/)
  or when using [`docker run` command](https://docs.docker.com/engine/reference/run/#env-environment-variables).
* Run ``docker-compose up -d ``. After a few minutes the setup should be accessible under http://yourdomain.com/orga
* Set up a user and an organizer by running ``docker exec -ti pretalx pretalx init``.
* Set up a cronjob for periodic tasks like this ``15,45 * * * * docker exec pretalx-app pretalx runperiodic``

## Installation with Ansible

(Please note that we also provide a ansible role for use without docker
[here](https://github.com/pretalx/ansible-pretalx/)).

## Installation with Docker

Another docker based pretalx installation: 
https://github.com/allmende/pretalx-docker
