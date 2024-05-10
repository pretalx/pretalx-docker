# pretalx-docker

This repository contains a Container image and a Docker Compose setup for a
[pretalx](https://github.com/pretalx/pretalx) installation.

> **Please note that the repository is provided by the pretalx community and not officially supported.**

## Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Build](#build)
  - [CI](#ci)
  - [Setting up the build environment](#setting-up-the-build-environment)
  - [Local building of the Container image and the Compose manifest](#local-building-of-the-container-image-and-the-compose-manifest)
  - [Live deployment](#live-deployment)
  - [Local live-like deployment](#local-live-like-deployment)
  - [With plugins](#with-plugins)
- [Run](#run)
  - [Locally](#locally)
  - [Live](#live)
  - [Management commands](#management-commands)
- [Initialisation](#initialisation)
- [Recycle](#recycle)
- [Legacy](#legacy)
- [Authors](#authors)
- [License](#license)
- [Copyright](#copyright)

## Installation

This repository follows the Pretalx installation instructions as closely as possible.

- [Installation — pretalx documentation](https://docs.pretalx.org/administrator/installation/)

## Configuration

The repository implements the dot env pattern to configure all application containers through environmental variables.

The setup prepares all environmental variables supported by Pretalx:

- [Configuration — pretalx documentation](https://docs.pretalx.org/administrator/configure/)

Copy the example and modify it according to your setup:

```sh
cp .env.example .env
```

You will likely want to provide email settings to a live environment.

Additional variables were introduced to configure the web proxy, the containers, the image build and the database:

- `FQDN`, fully-qualified domain name, used for the `Host` matcher in the `traefik` configuration and for the `plugins` images
- `POSTGRES_DB`, Postgres database name
- `POSTGRES_USER`, Postgres user name
- `POSTGRES_PASSWORD`, Postgres user password
- `PRETALX_LOG_LEVEL`, Gunicorn and Celery log level
- `PRETALX_IMAGE`, Pretalx Container image name
- `PRETALX_TAG`, Pretalx Container image tag

The following variables are available to configure the Gunicorn web process:

- `GUNICORN_WORKERS`
- `GUNICORN_MAX_REQUESTS`
- `GUNICORN_MAX_REQUESTS_JITTER`
- `GUNICORN_FORWARDED_ALLOW_IPS`
- `GUNICORN_BIND_ADDR`

Please refer to [`context/default/entrypoint.sh`](./context/default/entrypoint.sh) and [the Gunicorn settings documentation](https://docs.gunicorn.org/en/stable/settings.html) about their usage.

## Build

This repository is used for building Container images from the source manifests present here.

> It does not cover the use case of building a Pretalx development environment.
>
> It is left for the curious reader to propose this with [development containers](https://containers.dev/) directly to the `pretalx/pretalx` repository.

### CI

We provide CI manifests to build and push container images to Docker Hub (`docker.io`) and to the GitHub Container Registry (`ghcr.io`).

Find them in [`.github/workflows/`](.github/workflows/).

- `build-and-push.yml`, a generic build and push workflow that is called by other workflows and releases artifacts into Docker Hub and the GitHub Container Registry.
- `build.default.yml`, builds the `default` context into a `pretalx` image.
- `build.plugins.yml`, builds the `plugins` context into a `pretalx-extended` image.

The artifacts can be retrieved from:

- [pretalx/pretalx Tags | Docker Hub](https://hub.docker.com/r/pretalx/pretalx/tags)
- [pretalx/pretalx-extended Tags | Docker Hub](https://hub.docker.com/r/pretalx/pretalx-extended/tags)
- [pretalx versions · pretalx · GHCR](https://github.com/pretalx/pretalx-docker/pkgs/container/pretalx/versions)
- [pretalx-extended versions · pretalx · GHCR](https://github.com/pretalx/pretalx-docker/pkgs/container/pretalx-extended/versions)

### Setting up the build environment

For educational purposes we implement this with Docker Compose on a Rootless Podman context on a SELinux-enabled Linux host, using the Docker CLI with a context on the local socket of the Podman systemd user unit.

- [Using Podman and Docker Compose | Enable Sysadmin](https://www.redhat.com/sysadmin/podman-docker-compose)

```sh
$ systemctl --user start podman.service podman.socket
$ docker context create podman --docker 'host=tcp:///run/user/1000/podman/podman.sock'
$ docker context use podman
$ docker context ls
NAME       DESCRIPTION                               DOCKER ENDPOINT                            ERROR
default    Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
podman *                                             unix:///run/user/1000/podman/podman.sock
```

If your system does not have SELinux enabled or you wish to use this only with the regular Docker and Compose tooling, remove the SELinux-specific configuration:

```sh
sed '/selinux/d' -i compose.yml
```

To speed up builds and to build for the local platform only, you can disable BuildX with:

```sh
export DOCKER_BUILDKIT=0
```

We are making good use of [YAML Fragments in the Compose files](https://docs.docker.com/compose/compose-file/10-fragments/).

> Feel free to adapt these examples to your liking. E.g. you may need to copy and paste the adaptations into the single manifest, e.g. to run without `-f` modifiers, or have the main file called `docker-compose.yml` for the ancient version of `docker-compose`.

### Local building of the Container image and the Compose manifest

These were the commands frequently used to develop this Compose manifest:

```sh
docker build --load -t library/pretalx/pretalx:latest context/default
```

The previous command is equivalent to:

```sh
docker compose -f compose.yml -f compose/build.yml build app
```

This will build the image with the name `${PRETALX_IMAGE}:${PRETALX_TAG}`, as specified by the inferred `image:` directive.

If you have chosen not to disable BuildX, you can preview its configuration derieved from the Compose manifests:

```sh
docker buildx bake -f compose.yml -f compose/build.yml --print
```

### Live deployment

This assumes the presence of the image at the expected location in Docker Hub and a fully configured `traefik` instance connected to the `web` network.

```sh
docker compose -f compose.yml -f compose/traefik.yml config
```

### Local live-like deployment

If you were running a local `traefik` instance on a local `web` network, maybe even with a Smallstep CA for provisioning ACME certificates for your `.internal` network, you could add the network and necessary labels with:

```sh
docker compose -f compose.yml -f compose/local.yml -f compose/traefik.yml config
```

### With plugins

There is a need to accommodate for the presence of Pretalx plugins in this configuration.

This is achieved by creating overlay OCI file system layers and building a custom container image based on the default build context.

```sh
docker compose -f compose.yml -f compose/local.yml -f compose/plugins.yml config
```

Or in a live environment:

```sh
docker compose -f compose.yml -f compose/traefik.yml -f compose/plugins.yml config
```

All Compose commands in place of `config` apply from here.

If you had successfully built your local Pretalx image, you could build an image with the plugins with:

```sh
bash -c 'source .env; docker build --build-arg PRETALX_IMAGE=${PRETALX_IMAGE} --build-arg PRETALX_TAG=${PRETALX_TAG} -t pretalx-${FQDN} context/plugins'
```

The previous command is equivalent to:

```sh
docker compose -f compose.yml -f compose/build.yml -f compose/plugins.yml build app
```

This does not work with BuildX, which for this step must be disabled as shown above, due to known regressions.

<details><summary>Reference</summary>

- [Docker build "FROM" Fails to search local images · Issue #795 · docker/buildx](https://github.com/docker/buildx/issues/795)

</details>

Yet you can use it to review the build context:

```sh
docker buildx bake -f compose.yml -f compose/build.yml -f compose/plugins.yml --print
```

## Run

You may want to watch your Podman for the health of the containers from another shell:

```sh
watch -n 0.5 podman ps
```

### Locally

When you are done with building and preloading the images into your container engine's image store, you can start the composition with:

```sh
docker compose -f compose.yml -f compose/local.yml -f compose/plugins.yml up -d
```

- *Continue* to **Initialisation** below.

### Live

To run this in a live environment, it is not needed to build the images locally. They will be provided by Docker Hub.

```sh
docker compose -f compose.yml -f compose/traefik.yml -f compose/plugins.yml up -d
```

- *Continue* to **Initialisation** below.

> See [#59](https://github.com/pretalx/pretalx-docker/issues/59) for a known regression with pulling Pretalx images with Podman from Docker Hub.
>
> A default blend of plugins can be provided in another image for distribution and could be built automatically here @pretalx or in other third-party repositories.
>
> This would allow to provide an alternative Compose overlay that does not need to build the images with plugins, but reuses some which are already published.

### Management commands

The [entrypoint](./context/default/entrypoint.sh) provides convenience commands to run the Container with different processes from the same image in the same environment.

- `migrate` launches the database migrations and initiates a `rebuild`.
- `rebuild` regenerates static Django assets in `$PRETALX_FILESYSTEM_STATIC`, but only once. Can be `--force`d.
- `gunicorn` launches the Gunicorn Python web server to serve Pretalx.
  Can be configured with the `GUNICORN_*` environmental variables mentioned above.
- `celery` launches the Celery task worker.
- `cron` launches the Cron daemon to schedule the commands in the [`context/default/crontab`](./context/default/crontab).

All other commands are passed down to Pretalx.

- [Management commands — pretalx documentation](https://docs.pretalx.org/administrator/commands/)

They can be executed from within a running `app` container with `python` calling the `pretalx` module and passing the name of the task as an argument, in this example `showmigrations`:

```sh
docker compose exec app python -m pretalx showmigrations
```

This command does not need to have the `-f compose.{build.,local.,plugins.,traefik.}yml` arguments for defining overlays present, as it only modifies runtime state of an already existing container.

## Initialisation

You can start configuring your instance, when your `web` container shows as `healthy` in `podman ps`.

Invoke the initialisation command:

```sh
docker compose exec app python -m pretalx init
```

You will see this configuration summary and the initialisation wizard:

```console
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ┏━━━━━━━━━━┓  pretalx v2024.1.0                                                 ┃
┃ ┃  ┌─·──╮  ┃  Settings:                                                         ┃
┃ ┃  │  O │  ┃  Database:  pretalx (postgresql)                                   ┃
┃ ┃  │ ┌──╯  ┃  Logging:   /data/logs                                             ┃
┃ ┃  └─┘     ┃  Root dir:  /pretalx/.local/lib/python3.12/site-packages/pretalx   ┃
┃ ┗━━━┯━┯━━━━┛  Python:    /usr/local/bin/python                                  ┃
┃     ╰─╯       Plugins:   pretalx_pages, pretalx_public_voting, prtx_faq         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Welcome to pretalx! This is my initialization command, please use it only once.
You can abort this command at any time using C-c, and it will save no data.

Let's get you a user with the right to create new events and access every event on this pretalx instance.
E-mail:
```

After finishing the questionnaire, you can login at [`http://localhost:8080/orga/`](http://localhost:8080/orga/).

> One of your first steps may very well be to disable telemetry and update notifications, when wanting to maintain versions from the "outside" perspective of tagged Container images.

As you can see, we are not using a settings file. This is not needed, due to following the dot env pattern for [12factor.net](https://12factor.net) container-native applications. An example for `pretalx.cfg` and how to add it to the containers is available in `compose/local.yml` and in the `config/` subdirectory, in case needed.

## Recycle

There are few lifecycle commands, which can help you reduce local resource usage. They are:

```sh
docker compose down --remove-orphans
docker images | grep '<none>' | awk '{ print $3 }' | xargs docker rmi
```

You can now start building images and creating containers from scratch.

To delete eventual state, you can run either of these commands:

```sh
docker compose down --volumes
docker volume rm $(docker volume ls -q | grep pretalx)
```

Remove `.env` when you need to reset the whole setup completely.

```sh
docker compose down -v --remove-orphans
rm .env
```

## Legacy

The repository contains an example configuration for supporting the legacy version of Docker Compose.
Due to the different feature set, an independent manifest is used.

Please refer to [`legacy/`](./legacy/) to learn more.

## Authors

- Bastian Hodapp
- Bruno Morisson
- Daniel Goodman
- Hadrien
- Ian Foster
- Johan Van de Wauw
- Jon Richter
- Jonathan Günz
- Luca
- Lukas
- Marcus Müller
- Matt Yaraskavitch
- MaxR
- Michal Stanke
- Simeon Keske
- Simon
- Simon Hötten
- Timon Erhart
- Tobias Kunze
- geleeroyale
- jascha ehrenreich
- kuhball
- plaste
- realitygaps

## License

CC0

## Copyright

© 2018—2024 Pretalx Community
