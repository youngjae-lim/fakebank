# How to deploy a web app to kubernetes on AWS

[Read](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

Create `deployment.yml` in `/eks` directory:

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fakebank-api-deployment
  labels:
    app: fakebank-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fakebank-api
  template:
    metadata:
      labels:
        app: fakebank-api
    spec:
      containers:
        - name: fakebank-api
          image: 168633195351.dkr.ecr.us-east-2.amazonaws.com/fakebank:c7e5ad78f6c2cc1abf46b16fbd5939572b86da51
          ports:
            - containerPort: 80
```

Now run `k9s` to see if any pods and deployments are running on our default system. Use `:ns` and ':deployments' shortcuts to navigate. If this is your first deployment, you won't see any pods and deployments in the list.

Let's apply `deployment.yml` to kubectl:

```shell
$ kubectl apply -f eks/deployment.yml
deployment.apps/fankbank-api-deployment created
```

Now check out `k9s` console to see if our deployment is ready:

- `:deployments` to see the fakebank-api-deployment is ready
  - Hit `enter` to see if pods are ready and running
  - Hit another `enter` to see if containers are ready and running
  - Hit 'l' to see the logs

To access the running container from our local machine, we need to add `kubernetes service`. For more detail, pleaser ready [here](https://kubernetes.io/docs/concepts/services-networking/service/). Basically, service is an abstract way to expos an application running on a set of `Pods` as a network service.

Create `service.yml` file in the `/eks` directory:

```yml
apiVersion: v1
kind: Service
metadata:
  name: fakebank-api-service
spec:
  selector:
    app: fakebank-api
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

Let's apply `service.yml` to kubectl:

```shell
$ kubectl apply -f eks/service.yml
```

Go to `k9s` console and enter `:services` to see if the `fakebank-api-service` is up and running.

Let's test out external-ip given to the service:

> Note that it might take a few minutes to take dns servive ready.

```shell
$ nslookup ac83f816e1ebe4b76a3fa2c18ae10b9f-1114365193.us-east-2.elb.amazonaws.com
```

Go to Postman and try to login with the user id and password that we've generated before. It should work without any issue.

Let's go back to `k9s` console and check the log of container as well. You should see a successful POST request logged in there.

Let's check out resources of node as well:

- `:nodes` to bring up a list of node
- Hit `d` to describe.

~~If it is successful, you can find `fakebank-api-deployment` from the `k9s` GUI. However, you wil see the deployment is still not ready. The reason is that we don't have any nodes to schedule pods yet in AWS EKS. To resolve that, we have to go back to AWS EKS to increase desired capacity of `autoscailing groups` that is currently set to 0.~~

~~To increase the desired capacity, find `fakebank` cluster on AWS EKS and follow `autoscaling group name` from the details tab to see. Once the capacity is increased successfullly, you will be able to find a new node created from `nodes` tab of your fakebank cluster.~~

~~However, when we go back to `k9s` to see if deployment is ready, you will see it is still failing to deploy. The reason is because we selected~~
