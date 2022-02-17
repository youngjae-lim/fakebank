# Build Docker Image

Never push any changes to the main branch!!

Create a new branch:

```shell
$ git checkout -b feature/docker
$ git status
$ git add .
$ git commit -m "your commit message"
$ git push origin feature/docker
```

Create a pull request for 'feature/docker' on Github by visiting:

- https://github.com/youngjae-lim/fakebank/pull/new/feature/docker

Then check `Files changed` tab to see all the changes made.

Create `Dockerfile` in the root of the project.

```Dockerfile
FROM golang:1.17:alpine
WORKDIR /app
COPY . .
RUN go build -o main main.go

EXPOSE 8080
CMD ["/app/main"]
```

Build and run a docker container:

```shell
$ docker build -t fakebank:latest .
$ docker images
```

When you build an image for the first time with the initial `Dockerfile`, you will see the image size being almost 500MB. The reason for this is the image has all the go packages to build a final binary file. However, what we want to keep is only the binary file to be able to run an app successfully. So let's trim down the image size by using multi-stage building process:

```Dockerfile
# Build stage
FROM golang:1.17-alpine3.15 AS builder
WORKDIR /app
COPY . .
RUN go build -o main main.go

# Run stage
FROM alpine:3.15
WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["/app/main"]
```

Build the docker image again:

```shell
$ docker build -t fakebank:latest .
$ docker images
REPOSITORY            TAG         IMAGE ID       CREATED          SIZE
fakebank              latest      486f5d929e2b   12 seconds ago   22.4MB
<none>                <none>      e6260f052147   11 minutes ago   507MB

# Remove any unwanted image
$ docker rmi e6260f052147
```
