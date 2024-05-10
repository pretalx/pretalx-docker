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
cp compose/docker-compose.yml.example docker-compose.yml
cp compose/docker-compose.env.example .env
cp compose/docker-compose.env.pretalx.example .env.pretalx
```

Remove the now redundant original configuration:

```sh
rm compose.yml
```

Create the directories which will be used as host-mounted volumes.

```sh
grep VOLUME .env | cut -d"=" -f2 | xargs -I% sh -c 'set -x; if [ ! -d "%" ]; then echo "Create: %"; mkdir -p "%"; else echo "Exists: %"; fi'
```

Apply the expected permissions:

```sh
grep -e 'DATA' -e 'PUBLIC' .env | cut -d"=" -f2 | xargs -L1 chown 999:999
```

Rootful Docker cannot perform subuid/-gid mapping.

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

## Build

This setup is using a custom build with selected plugins, which are defined in the [`context/plugins/Dockerfile`](./context/plugins/Dockerfile).

Prepare the application image:

```sh
docker-compose build app
```

## First run

Due to missing exit code evaluation of service dependencies, we need a more cautious approach to applying state to the containers.

Begin with initialising the databases:

```sh
docker-compose up -d postgres redis
```

Run the database migrations and implied build of static assets, if applicable:

```sh
docker-compose run --rm migrations
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

