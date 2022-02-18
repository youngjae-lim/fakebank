# Docker Compose

> If you've previsouly merged a new branch into main and deleted the branch in Github, please checkout main and pull the latest source from Github and delete the branch from your local repository:

```shell
$ git checkout main
$ git pull
$ git branch -d feature/docker
```

## Docker-compose

Create `docker-compose.yml` file:

```yml
version: '3.9'
services:
  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=fake_bank
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - '8080:8080'
    environment:
      - DB_SOURCE=postgresql://postgres:password@postgres:5432/fake_bank?sslmode=disable
    depends_on:
      - postgres
    entrypoint: ['/app/wait-for.sh', 'postgres:5432', '--', '/app/start.sh']
    command: ['/app/main']
```

Read about `entrypoint` on [click](https://docs.docker.com/compose/compose-file/compose-file-v3/#entrypoint)

> Setting entrypoint both overrides any default entrypoint set on the service’s image with the ENTRYPOINT Dockerfile instruction, and clears out any default command on the image - meaning that if there’s a CMD instruction in the Dockerfile, it is ignored.

## Dockerfile

Update `Dockerfile`:

```Dockerfile
# Build stage
FROM golang:1.17-alpine3.15 AS builder
WORKDIR /app
COPY . .
RUN apk add curl
RUN go build -o main main.go
RUN curl -L https://github.com/golang-migrate/migrate/releases/download/v4.15.1/migrate.linux-amd64.tar.gz | tar xvz


# Run stage
FROM alpine:3.15
WORKDIR /app
COPY --from=builder /app/main .
COPY --from=builder /app/migrate .
COPY app.env .
COPY start.sh .
COPY db/migration ./migration

EXPOSE 8080
CMD ["/app/main"]
ENTRYPOINT [ "/app/start.sh" ]
```

Some of the things you have to pay attention to:

> Note that `/app/main` will be passed onto the entry point `/app/start.sh` as a parameter to run the `main` binary file. In other words, when `CMD` is used with `ENTRYPOINT`, it is used as a parameter to be passed onto `ENTRYPOINT`.

> Also note that using `COPY` without `--from=builder` in the run stage is a simply copy and paste from our local host to the docker image.

> The last two command `CMD` and `ENTRYPOINT` will be overwritten by `docker-compose.yml`.

## Start.sh script

Create `start.sh` file and give execution permission:

```shell
$ touch start.sh
$ chmod +x start.sh
```

```sh
#!/bin/sh
# start.sh

set -e

echo "run db migration"
/app/migrate -path /app/migration -database "$DB_SOURCE" -verbose up

echo "start the app"
exec "$@"
```

> Note that $@ means all of the parameters passed to the script.

## wait-for.sh

The postgres service must be ready before we try to run migrations.
Read more on [startup order](https://docs.docker.com/compose/startup-order/)

Download the latest sh-compatible `wait-for` script here: [download](https://github.com/eficode/wait-for)
