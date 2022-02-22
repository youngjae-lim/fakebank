# Set up Ingress In K8s Clusters

[Read](https://kubernetes.io/docs/concepts/services-networking/ingress/)

![Ingress](/doc/images/Ingress_Service_Diagram.png)

## Preliminary Configuration

Open up `service.yml` and change `type` under `spec` from `LoadBalancer` to `ClusterIP`. The reason for doing this is once we want to use Ingress, we don't want to expose external ips to outside the cluster.

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
  type: ClusterIP
```

Then apply the change to `kubectl`:

```shell
$ kubectl apply -f eks/service.yml
```

Once it is applied, please make sure to open up `k9s` console and check if `external ip` is no longer available on the fakebank-api-service.

## Create `ingress.yml`

Create `ingress.yml` in `/eks` directory of our project root:

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fakebank-ingress
spec:
  rules:
    - host: 'api.fake-bank.org'
      http:
        paths:
          - pathType: Prefix
            path: '/'
            backend:
              service:
                name: fakebank-api-service
                port:
                  number: 80
```

Let's deploy `ingress.yml`:

```shell
$ kubectl apply -f eks/ingress.yml
```

## Ingress address

In `k9s` console, search `ingress` service to verify it by typing `:ingress`. Please pay attention to `Address` column that is still empty. This means that ingress service won't work yet because there is no address attached to it. In other words, only creating an Ingress resource has no effect, we must have an `Ingress controller` ([Read](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)) to satisfy an Ingress.

## Install NGINX Ingress Controller

There are many types of Ingress controller out there, but we will use `NGINX Ingress Controller` for our service:

[Intallation Guide for AWS](https://kubernetes.github.io/ingress-nginx/deploy/#aws)

```shell
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/aws/deploy.yaml
```

To verify the installation, please open up `k9s` console and search for `pods`. You should be able to see `ingress-nginx` namespace from the list. Now search for `ingress` again, you will be able to see an Address attached to fakebank-api-service.

All we have to do now is copy and paste the address to the value field on `api.fake-bank.org` A-record in AWS Route 53.

### Test

Run nslookup to see if it is working:

```shell
$ nslookup api.fake-bank.org
```

Go to Postman and try to log in as the created user.

## Ingress class

Last but not least, if you look at the ingress service from `k9s`, there is missing value on `Class` column. Because Ingresses can be implemented by different controllers, often with different configuration, each Ingress should specify a class which is a reference to an IngressClass resource that contains additional configuration including the name of the controller that should implement the class. [Read](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/aws/deploy.yaml)

Let's add extra configuration to `ingress.yml` for Ingress class:

```yml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fakebank-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: 'api.fake-bank.org'
      http:
        paths:
          - pathType: Prefix
            path: '/'
            backend:
              service:
                name: fakebank-api-service
                port:
                  number: 80
```

Then redeploy the ingress:

```shell
$ kubectl apply -f eks/ingress.yml
```

Go to `k9s` console and search for ingress service. You should be able to see `nginx` under the `CLASS` column for fakebank-ingress.
