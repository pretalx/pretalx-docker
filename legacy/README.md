# Legacy docker-compose support

This example demonstrates a setup that is compatible with the legacy version of Docker Compose.

It assumes:

- availability of the image specified by `PRETALX_IMAGE` and `PRETALX_TAG`

It contains changes that accommodate for a specific environment:

- removes SELinux settings
- uses host-mounted volumes
- uses only a single Compose manifest to launch without multiple `-f` flags
- adds a separate `.env.pretalx` environment file, due to unsupported YAML interpolation syntax
- deactivates running the automatic migrations container and turns its function into a manual step, due to unsupported `service_completed_successfully`
- adapts the healthcheck interpolation syntax by escaping `$` escape signs

Please use the example as a basis for your own modifications.

## Preparation

Run these commands from the root of the repository.

Copy the example files in place:

```sh
cp legacy/docker-compose.yml.example docker-compose.yml
cp legacy/docker-compose.env.example .env
cp legacy/docker-compose.env.pretalx.example .env.pretalx
```

Remove the now redundant original configuration:

```sh
rm compose.yml
```

## Environment

This legacy Docker Compose setup for running the Pretalx system brings two configuration files for adapting the environment.

- `.env`, used for Docker Compose, the Traefik Reverse Proxy and the database credentials.
- `.env.pretalx`, used for all application-specific configuration options. Refer to the original documentation for details.

### .env

- Modify the `VOLUME`s as needed.
- Use a valid and available `IMAGE`/`TAG` combination.
- Set the `FQDN`.
- Specify the database credentials.

### .env.pretalx

- Adapt the `SITE_URL` to match the `FQDN` and the expected scheme.
- Set a preferred `LANGUAGE_CODE`.
- Choose the expected `TIME_ZONE`.
- Choose a `LOGGING_EMAIL`.
- Configure `MAIL` settings.

## Volumes

Create the directories which will be used as host-mounted volumes.

```sh
grep VOLUME .env | cut -d"=" -f2 | xargs -I% sh -c 'set -x; if [ ! -d "%" ]; then echo "Create: %"; mkdir -p "%"; else echo "Exists: %"; fi'
```

Apply the expected permissions:

```sh
grep -e 'DATA' -e 'PUBLIC' .env | cut -d"=" -f2 | xargs -L1 chown 999:999
```

Rootful Docker cannot perform subuid/-gid mapping.

## Build

This setup is prepared to perform a custom build with a selection of plugins, which are defined in the [`context/plugins/Dockerfile`](./context/plugins/Dockerfile).

In case you wish to perform such a custom build, prepare the application image:

```sh
cp legacy/docker-compose.build.yml.example build.yml
docker-compose -f docker-compose.yml -f build.yml build app
```

## First run

Before running the application, check your `.env` and `.env.pretalx` files again. For example, you may want to replace the `pretalx/pretalx` image with `pretalx/pretalx-extended`, if you wanted to use one with plugins. When the files look good, prepare your Container engine with pulling the used images:

```sh
docker-compose pull
```

Skip this step for custom builds.

Due to missing exit code evaluation of service dependencies in the legacy Docker Compose, we need a more manual approach to applying state to the containers, as with the non-legacy setup.

Begin with initialising the databases:

```sh
docker-compose up -d postgres redis
```

Run the database migrations and implied build of static assets manually:

```sh
docker-compose run --rm app migrate
```

This is needed, since missing static assets will lead to errors when starting the other application containers.

You are now ready to start the rest of the whole application.

## Run

This will take a moment, due to the dependencies between containers and the latency of the healthchecks intervals.

```sh
docker-compose up -d
```

Then prepare your initial user and the initial conference organiser:

```sh
docker-compose exec app python -m pretalx init
```

You can now login at `$PRETALX_SITE_URL/orga/`.

One useful initial step is to navitagte to `$PRETALX_SITE_URL/orga/me` after login and to provide a username, which was omitted during the `init` step.

## Validate

Validate your configuration on `$PRETALX_SITE_URL/orga/admin`.

Try to invite other members to your organiser and send yourself a password reset email to test email deliverability.

Otherwise use the Django built-in:

```sh
docker-compose exec app python -m pretalx sendtestemail
```

Congratulations, you have setup a fully working Pretalx instance!
