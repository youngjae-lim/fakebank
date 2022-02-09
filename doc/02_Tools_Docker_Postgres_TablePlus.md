# Docker

## Lecture Objective

In this lecture, we will be utilizing 3 tools:

1. Docker
2. Postgres
3. Beekeeper Studio

## Pull an image

```shell
# Pull docker postgre images from docker hub
$ docker pull postgres:14-alpine

# List all images
$ docker images
```

## Start a container

```shell
$ docker run --name postgres14 \\
             -p 5432:5432 \\
             -e POSTGRES_USER=postgres \\
             -e POSTGRES_PASSWORD=password \\
             -d postgres:14-alpine

# List running containers
$ docker ps

# To stop the container
$ docker stop postgres14

# List all running and stopped containers
$ docker ps -a
```

## Run command inside a container

```shell
$ docker exec -it postgres14 psql -U postgres
```

## View container logs

```shell
$ docker logs postgres14
```

## Beekeeper Studio

- Download TablePlus
- Connect to the postgres database running on the docker container
- Open up the sql that we've exported as sql using dbdiagram.io
- Run the query; you will see all 3 table are generated in the postgres database
