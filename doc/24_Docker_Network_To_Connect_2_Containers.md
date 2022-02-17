# Docker Network To Connect Two Standalone Containers

Let's run the docker image that we've built previously:

```shell
$ docker run --name fakebank -p 8080:8080 -e GIN_MODE=release fakebank:latest
```

Inspect docker container:
This will show you two separate containers running with its own id address. Therefore, the enviornment variable pointing a localhost for postgres db
is scoped to our app, not to the postgres running in the separate container. So our app fails to connect to the database. We can see the two containers are running on different ip address by running `docker inspect` command:

```shell
$ docker container inspect fakebank
$ docker container inspect postgres14
```

```shell
# List docker networks
$ docker network ls

# Create bank-network
$ docker network create bank-network

# Connect postgres14 container to bank-network
$ docker network connect bank-network postgres14

# Run fakebank container
$ docker run --name fakebank \\
             --network bank-network \\
             -p 8080:8080 \\
             -e GIN_MODE=release \\
             -e DB_SOURCE="postgresql://postgres:password@postgres14:5432/fake_bank?sslmode=disable" \\
             fakebank:latest

# Check bank-network to see two containes running in the same network
$ docker network inspect bank-network

[
    {
        "Name": "bank-network",
        "Id": "c9afb57910186be531d159045e0b1130eb98eadfc68c52a6ec81712977bf95e2",
        "Created": "2022-02-17T22:12:30.881264262Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.25.0.0/16",
                    "Gateway": "172.25.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "4bddc1d5f98c80b09783bb3ce1c85016916c519c6ef8f83abf32a0d7724b0db5": {
                "Name": "fakebank",
                "EndpointID": "9f3af6b98e796f2d865947af71b9adf1e7edebf87ea49a383e042d83319fa11a",
                "MacAddress": "02:42:ac:19:00:03",
                "IPv4Address": "172.25.0.3/16",
                "IPv6Address": ""
            },
            "f6b582fd161e046084729904570dc6b9142b1ad57e17c859acfc9ccb8835af52": {
                "Name": "postgres14",
                "EndpointID": "2292173d05f5f5b84a9bcc3fb370977084fa779b7e34aa40e0933c5211db552f",
                "MacAddress": "02:42:ac:19:00:02",
                "IPv4Address": "172.25.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```
