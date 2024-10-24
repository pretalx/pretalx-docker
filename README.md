# pretalx-docker

This repository contains a Container image and a Docker Compose setup for a
[pretalx](https://github.com/pretalx/pretalx) installation.

> **Please note that the repository is provided by the pretalx community and not officially supported.**

## Contents

- [Components](#components)
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

## Components

The repository holds the a collection of usable components.

- Dockerfiles to build container images
- Compose manifests to show how to use the containers
- CI manifests to automatically build the images

<details><summary>Files and directories explained</summary>

### Directories

You can list the directories in this repository with:

```sh
$ tree -d -L 3 -a -I '.git'
```

- `.github/`, GitHub-specific contents
  - `workflows/`, GitHub Actions workflows
- `bin/`, maintenance and life-cycle scripts
- `compose/`, Compose overlays, to be used as additional `-f` flags
  - `build/`, overlays for locally building the images
    - `source/`, overlays for source builds
    - `standalone/`, overlays for building standalone images
- `config/`, runtime configuration files
- `context/`, Container image build contexts
  - `base/`, the pretalx base image with its system dependencies
  - `cron/`, an image variant with cron
  - `default/`, the Pretalx stock image
  - `extended/`, an extended Pretalx image variant with plugins
  - `source/`, contexts to build Pretalx images from source
    - `extended.cron/`, an extended Pretalx image with plugins and cron
    - `standalone`, a standalone Pretalx image with supervisor; builds from local or remote sources
    - `standalone.extended.cron/`, a standalone Pretalx image with cron, supervisor and plugins
  - `standalone/`, contexts to build standalone Pretalx images
    - `default/`, a standalone Pretalx image with supervisor
    - `extended/`, an extended standalone Pretalx image with supervisor and plugins
    - `extended.cron`, an extended standalone Pretalx image with supervisor, cron and plugins
- `legacy/`, support for the legacy Python version of `docker-compose`

### Files

The application stack is defined by a Compose manifest and an environment file, which are extended by overlay Compose manifests.

An additional environment is provided for conducting image builds with Compose.

- `.env.build.example`, example environment to build images
- `.env.example`, example environment
- `compose.yml`, Compose manifest

#### .github/

GitHub-specific configuration files.

- `dependabot.yml`, configuration to automatically update dependencies

##### .github/workflows/

GitHub Actions workflows to build the images in CI.

- `build-and-push.yml`, parametrised build workflow to be called by other workflows
- `build.default.yml`, build workflow that builds the `default` context
- `build.plugins.yml`, build workflow that builds the `plugins` context

#### bin/

Scripts to perfom bulk operations on the repository.

- `clean`, removes generated data, including built images and an eventual clone of pretalx for the local source overlay
- `build`, builds the `pretalx/base:3.12-bookworm`, `pretalx/pretalx:2024.3.0`, `pretalx/pretalx-extended:2024.3.0` and `pretalx/pretalx-extended:2024.3.0-cron` images
- `build.source`, builds the `pretalx/base:3.12-bookworm`, `pretalx/pretalx-extended:main-source-remote-cron`, `pretalx/standalone:main-source-{local,remote}` and `pretalx/standalone-extended:main-source-remote-cron` images
- `build.standalone`, builds the `pretalx/pretalx:2024.3.0`, `pretalx/standalone:2024.3.0` and `pretalx/standalone-extended:2024.3.0{,-cron}` images

#### compose/

Compose overlays for running locally and/or behind a Traefik reverse proxy.

- `local.yml`, overlay to add a local listening port for the `web` container
- `traefik.yml`, overlay to add the Traefik-specific external `web` network and associated configuration labels

##### compose/build/

Compose overlays to exemplify the build of certain image variants.

- `base.yml`, builds the `base` context, used for the `pretalx/base` image
- `default.yml`, builds the image from the `default` context, used for the `pretalx/pretalx` image
- `extended.yml`, builds the image from the `extended` context, based on `default`, used for the `pretalx/pretalx-extended` image
- `extended.cron.yml`, builds the image from the `cron` context, based on `extended`, used for the `pretalx/pretalx-extended` image, tagged `-cron`

###### compose/source/

Compose overlays to build the pretalx application from its source code.

- `extended.cron.remote.yml`, builds an extended image from the latest, remotely pulled git source, with cron and plugins
- `standalone.local.yml`, builds a standalone image from locally available sources
- `standalone.remote.yml`, builds a standalone image from a remote git source
- `standalone.extended.cron.remote.yml`, extends the previous image with cron and plugins

###### compose/standalone/

- `default.yml`, a standalone image, equivalent with the `pretalx/standalone` image from CI
- `extended.yml`, a standalone image extended with plugins
- `extended.cron.yml`, a standalone image extended with cron and plugins

#### config/

Configuration manifests of run-time components.

- `nginx.conf`, configuration for Nginx that serves static assets and otherwise proxies to the application container
- `pretalx.cfg.example`, depreciated, example of a configuration file to be used optionally, e.g. with the `local` overlay

#### context/

The Docker build contexts that define the various images supported by this repository.

##### context/base/

- `Dockerfile.debian`, Debian-based container image manifest for Pretalx, used for the `pretalx/base` image
- `entrypoint.sh`, script to be evaluated at runtime when the container starts; prepared for all variants; expects an argument

##### context/cron/

- `crontab`, configuration to run periodic tasks; adapted for use inside a container
- `Dockerfile.debian`, Debian-based container image manifest for Pretalx, includes cron

##### context/default/

- `Dockerfile.debian`, Debian-based container image manifest for Pretalx, used for the `pretalx/pretalx` image

##### context/extended/

- `Dockerfile.debian`, Debian-based container image manifest for Pretalx, includes plugins

##### context/source/

The source contexts are used to build pretalx from locally or remotely available source code.

###### context/source/extended.cron/

- `crontab`, configuration to run periodic tasks; adapted for use inside a container
- `Dockerfile.debian.remote`, Debian-based container image manifest for Pretalx

###### context/source/standalone/

- `Dockerfile.debian.local`, Debian-based container image manifest for Pretalx; continuation of the old `pretalx/standalone` image
- `Dockerfile.debian.remote`, Debian-based container image manifest for Pretalx; extended with supervisor; used for the `pretalx/standalone` image
- `supervisord.conf`, configuration to run multiple unprivileged processes in the same container

###### context/source/standalone.extended.cron/

- `crontab`, configuration to run periodic tasks; adapted to be run via the supervisor
- `Dockerfile.debian.remote`, Debian-based container image manifest for Pretalx, extended with cron and plugins
- `supervisord.conf`, configuration to run multiple privileged and unprivileged processes in the same container; adapted for use with cron

##### context/standalone/

The standalone context is provided for compatibility with the `pretalx/standalone` image created with the `pretalx-docker` repository before 05.2024. These containers run both processes of the main Gunicorn process and the Celery task worker. This is useful for testing, but they cannot be scaled independently in a real-world scenario, why migration to the newer `pretalx/pretalx` image with running both processes in separate containers is recommended.

This depreciates the old standalone container, which was tightly coupled with source code in a git submodule, which has been depreciated. A new version that offers a migration path with a decoupled git repository is available in `context/source/standalone/Dockerfile.debian.local`.

###### context/standalone/default/

- `Dockerfile.debian`, Debian-based container image manifest for Pretalx
- `supervisord.conf`, configuration to run multiple unprivileged processes in the same container

###### context/standalone/extended/

- `Dockerfile.debian`, Debian-based container image manifest for Pretalx, extended with plugins

###### context/standalone/extended.cron/

- `crontab`, configuration to run periodic tasks; adapted to be run via the supervisor
- `Dockerfile.debian`, container image manifest that adds plugins to Pretalx, extended with cron and plugins
- `supervisord.conf`, configuration to run multiple privileged and unprivileged processes in the same container; adapted for use with cron

#### legacy/

- `docker-compose.build.yml.example`, overlay example to build an `pretalx-extended` image from the `extended` context
- `docker-compose.env.example`, Compose, Traefik and Postgres environment example
- `docker-compose.env.pretalx.example`, Pretalx environment example
- `docker-compose.yml.example`, Docker Compose manifest example

Please read on thorugh the following sections to find out how they interact with each other.

</details>

## Installation

This repository follows the Pretalx installation instructions as closely as possible.

- [Installation — pretalx documentation](https://docs.pretalx.org/administrator/installation/)

## Configuration

The repository implements the dot env pattern to configure all application containers through environmental variables.

Copy the example and modify it according to your setup:

```sh
cp .env.example .env
```

The Pretalx image and version to pull or build are indicated at the top:

- `PRETALX_IMAGE`, Pretalx Container image name
- `PRETALX_TAG`, Pretalx Container image tag

### Run-time variables

The setup uses all environmental variables used by Pretalx:

- [Configuration — pretalx documentation](https://docs.pretalx.org/administrator/configure/)

You will likely want to uncomment and provide email settings to a live environment.

These variables configure the web proxy, the application processes and the database:

- `FQDN`, fully-qualified domain name, used for the `Host` matcher in the `traefik` configuration and for the `plugins` images
- `POSTGRES_DB`, Postgres database name
- `POSTGRES_USER`, Postgres user name
- `POSTGRES_PASSWORD`, Postgres user password
- `PRETALX_LOG_LEVEL`, Gunicorn and Celery log level

The following variables are available to configure the Gunicorn web process:

- `GUNICORN_WORKERS`
- `GUNICORN_MAX_REQUESTS`
- `GUNICORN_MAX_REQUESTS_JITTER`
- `GUNICORN_FORWARDED_ALLOW_IPS`
- `GUNICORN_BIND_ADDR`

Please refer to [`context/default/entrypoint.sh`](./context/base/entrypoint.sh) and [the Gunicorn settings documentation](https://docs.gunicorn.org/en/stable/settings.html) about their usage.

## Building

This repository is used for developing Container images from the source manifests present in the `context/` directory.

> It does not cover the use case of building a Pretalx development environment.
>
> It is left for the curious reader to propose this with [development containers](https://containers.dev/) directly to the `pretalx/pretalx` repository.

### CI

We provide CI manifests to build and push container images to Docker Hub (`docker.io`) and to the GitHub Container Registry (`ghcr.io`).

Find them in [`.github/workflows/`](.github/workflows/).

- `build-and-push.yml`, a generic build and push workflow that is called by other workflows and releases artifacts into Docker Hub and the GitHub Container Registry.
- `build.default.yml`, builds the `default` context into a `pretalx` image.
- `build.plugins.yml`, builds the `plugins` context into a `pretalx-extended` image.

The artifacts are published to:

- [pretalx/pretalx Tags | Docker Hub](https://hub.docker.com/r/pretalx/pretalx/tags)
- [pretalx/pretalx-extended Tags | Docker Hub](https://hub.docker.com/r/pretalx/pretalx-extended/tags)
- [pretalx versions · pretalx · GHCR](https://github.com/pretalx/pretalx-docker/pkgs/container/pretalx/versions)
- [pretalx-extended versions · pretalx · GHCR](https://github.com/pretalx/pretalx-docker/pkgs/container/pretalx-extended/versions)

### Prerequisites

This setup was implemented with Docker Compose on a Rootless Podman context on a SELinux-enabled Linux host, using the Docker CLI with a context on the local socket of the Podman systemd user unit for educational purposes.

It also works with rootful or rootless Docker and rootful Podman respectively.

<details><summary><i>Optional:</i> Using Rootless Podman with Docker Compose via a Docker Context</summary>

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

</details>

<details><summary><i>Optional:</i> Removing the SELinux compatibility, if not needed</summary>

If your system does not have SELinux enabled or you wish to use this only with the rootful tooling, remove the SELinux-specific configuration:

```sh
sed '/selinux/d' -i compose.yml
```

</details>

<details><summary><i>Optional:</i> Work around BuildKit issues with caching and newer Docker features</summary>

The Docker Buildx BuildKit configuration does not allow to reuse cached image layers in subsequent build steps.

- [Docker build "FROM" Fails to search local images · Issue #795 · docker/buildx](https://github.com/docker/buildx/issues/795)

#### Using Docker, Buildx and Compose to build all images locally (using cache)

To use this repository with Docker, Docker Compose and Docker Buildx, we need to switch back from BuildKit in a container to the default docker builder.

```sh
docker context use default
docker buildx ls
docker buildx use default
```

We can now locally conduct layered image builds with Docker, Compose through Buildx.

#### Using rootless Podman, Buildx and Compose to build all images locally (using cache)

To use this repository with rootless Podman, Docker Compose and Docker Buildx, we need to disable BuildKit entirely

```sh
docker context use podman
export DOCKER_BUILDKIT=0
```

</details>

We are making good use of [YAML Fragments in the Compose files](https://docs.docker.com/compose/compose-file/10-fragments/). Be sure to learn what they do, which will aid you in reading the manifests.

> Feel free to adapt these examples to your liking. E.g. you may need to copy and paste the adaptations into the single manifest, e.g. to run without `-f` modifiers, or have the main file called `docker-compose.yml` for the ancient version of `docker-compose`. See the *legacy* section for this use case.

### Build-time variables

To start building the images locally, copy the build environment example:

```sh
cp .env.build.example .env.build
```

The variables present in `.env.build` should not be modified and can be considered as sane defaults.

The values are (hopefully) mostly self-explaining. Those you may want to experiment with changing are:

- `PRETALX_VERSION`, the Pretalx version to install into the image
- `BASE_IMAGE`, the base image to build from
- `BASE_TAG`, the base image tag to build from
- `PRETALX_BASE_IMAGE`, the name of the pretalx base image to build
- `PRETALX_BASE_TAG`, the tag of the pretalx base image to build
- `PRETALX_IMAGE`, the name of the pretalx image to build
- `PRETALX_TAG`, the tag of the pretalx image to build

### Local building of the Container images with using the Compose manifests

Use the `build*` scripts in the `bin/` repository to conduct local builds, which package the most common use cases.

```sh
bin/build
bin/build.standalone
bin/build.source
```

The commands below help to develop and debug the Compose manifests and are provided as a reference:

```sh
docker compose --env-file .env -f compose.yml --env-file .env.build -f compose/build/default.yml build app
```

This will build the image with the name `${PRETALX_IMAGE}:${PRETALX_TAG}`, as specified by the inferred `image:` directive.

### Building different combinations of overlays

There is a need to accommodate for the presence of Pretalx plugins together with the application.

This is achieved by creating overlay OCI file system layers and building a custom container image based on the default build context.

```sh
docker compose --env-file .env -f compose.yml -f compose/local.yml --env-file .env.build -f compose/build/extended.yml config
```

Or in a live environment:

```sh
docker compose --env-file .env -f compose.yml -f compose/traefik.yml --env-file .env.build -f compose/build/extended.yml config
```

All Compose commands in place of `config` apply from here.

If you had successfully built your local Pretalx image, you could build an image extended with plugins with:

```sh
docker compose -f compose.yml --env-file .env.build -f compose/build/extended.yml build app
```

## Running

During development, you may want to watch your container scheduler for the health of the containers from another shell:

```sh
watch -n 0.5 docker ps
```

### Locally

When you are done with building and preloading the images into your container engine's image store, you can start the composition with:

```sh
docker compose --env-file .env -f compose.yml -f compose/local.yml --env-file .env.build -f compose/build/extended.yml up -d
```

> - *Continue* to **Initialisation** below.

---

### Local live-like environment

If you were running a local `traefik` instance on a local `web` network, maybe even with a Smallstep CA for provisioning ACME certificates for your `.internal` network, you could add the network and necessary labels with:

```sh
docker compose -f compose.yml -f compose/local.yml -f compose/traefik.yml config
```

### Live

To run this in a live environment, it is not needed to build the images locally. They will be provided by the container registry.

This further assumes the presence of a fully configured `traefik` instance connected to the `web` network.

Review the configuration you are about to launch:

```sh
docker compose --env-file .env -f compose.yml -f compose/traefik.yml --env-file .env.build -f compose/build/extended.cron.yml config
```

Launch a selected configuration:

```sh
docker compose --env-file .env -f compose.yml -f compose/traefik.yml --env-file .env.build -f compose/build/extended.cron.yml up -d
```

> - *Continue* to **Initialisation** below.

---

### Management commands

The [entrypoint](./context/default/entrypoint.sh) provides convenience commands to run the Container with different processes from the same image in the same environment.

- `migrate` launches the database migrations and initiates a `rebuild`.
- `rebuild` regenerates static Django assets in `$PRETALX_FILESYSTEM_STATIC`, but only once. Can be `--force`d.
- `gunicorn` launches the Gunicorn Python web server to serve Pretalx.
  Can be configured with the `GUNICORN_*` environmental variables mentioned above.
- `celery` launches the Celery task worker.
- `cron` launches the Cron daemon to schedule the commands in the [`context/default/crontab`](./context/default/crontab).
- `supervisor` launches the Supervisor daemon to run multiple long-running processes in the same container.

All other commands are passed down to Pretalx.

- [Management commands — pretalx documentation](https://docs.pretalx.org/administrator/commands/)

They can be executed from within a running `app` container with `python` calling the `pretalx` module and passing the name of the task as an argument, in this example `showmigrations`:

```sh
docker compose exec app python -m pretalx showmigrations
```

This command does not need to have the `-f compose.{local,traefik,build/default,build/extended}.yml` arguments for defining overlays present, as it only modifies runtime state of an already existing container.

## Initialisation

You can start configuring your instance, when your `web` container shows as `healthy` in `docker ps`.

Invoke the initialisation command:

```sh
docker compose exec app python -m pretalx init
```

You will see this configuration summary and the initialisation wizard:

```console
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ┏━━━━━━━━━━┓  pretalx v2024.3.0                                                 ┃
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

As you can see, we are not using a settings file. This is not needed, due to following the dot env pattern for [12factor.net](https://12factor.net) container-native applications. An example for `pretalx.cfg` and how to add it to the containers is available in `compose/local.yml` and in the `config/` subdirectory, in case needed.

> *Please note:* Users of the `standalone` images need to manually run the database migrations, before the application can be initialised. Follow these steps instead:
>
> ```sh
> docker compose run --rm app migrate
> docker compose run --rm -it app init
> ```

## Upgrading

In case the images used in this composition are updated in the container registry, you can update your installation with few interventions:

1. Change the `PRETALX_TAG` to the newer version in the `.env` file
2. Pull new images with `docker compose pull`
3. Recreate existing containers with `docker compose up -d`

> *Note:* Users of the standalone image also need to run `docker compose run --rm app migrate` between the steps 2. and 3.

## Migrating from the old `pretalx/standalone` container image/build …

The repository has seen a major refactor in May 2024. While it depreciates some of the original developments, it continues their work and seeks compatibility with the development patterns that were present. While there are many ways in which the components of the repository can be combined and adjusted, we would like to give some hints on common migration paths.

More detailed instructions will be added here, when we find them.

### … to the `pretalx/pretalx` image

The `pretalx/pretalx` image does not bundle the supervisor, why you have to run two independent containers for the application server (Gunicorn) and the task worker (Celery). Please read `compose.yml` carefully on how to set this up.

A more concise example may be given in the `legacy/` folder.

Configuration values from `pretalx.cfg` have been converted into environment variables in `.env`. For future-compatibility, you are advised to perform the migration. It is still possible to mount a configuration file at `/pretalx/.pretalx.cfg`. Please refer to `local.yml` and `standalone.extended.cron.remote.yml` for examples.

### … to the updated `pretalx/standalone` image

As theory has it, you should be able to pull newly-tagged `pretalx/standalone` images and use them as a drop in replacement. Please leave us an issue, if that is not the case.

### … to a custom source build based on the new `pretalx/standalone` image

Please feel free to explore the range of examples that are given in the `build/` contexts to evaluate how you can reproduce the previous local source builds. `context/source/standalone/Dockerfile.debian.local` tries to be as close as possible to the previous setup that was using a git submodule to build images from.

While this pattern has been depreciated for regular image builds, the previous way has been continued and tested with the others. Please report back any issue that you may encounter.

## Recycle

There are few life-cycle commands, which can help you reduce local resource usage. They are:

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

To also clean your working directory, you can run:

```sh
bin/clean
```

To also clean your container engine's build cache, also run:

```sh
docker buildx prune -a
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
