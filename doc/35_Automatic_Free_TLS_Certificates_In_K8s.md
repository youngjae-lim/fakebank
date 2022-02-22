# Automatic and Free TLS Certificates in k8s

## 1. Install cert-manager

> `cert-manager` adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the porcess of obtaining, renewing and using those certificates.

[cert-manager](https://cert-manager.io/)

### Default static Install

```shell
$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
```

### Verify the installation

Back to `k9s` console, search for namespace by typing `:ns`. You should be able to find `cert-manager` active on the list of namespaces. There will be three running pods in `cert-manger` namespace:

- `cert-manager`
- `cert-manager-cainjector`
- `cert-manager-webhook`

You can also manually verify:

```shell
$ kubectl get pods --namespace cert-manager
```

![verify-cert-manager](/doc/images/verify_cert_manager.png)

## 2. Issuer Configuration

[Read](https://cert-manager.io/docs/configuration/)

Now that we've installed `cert-manager` and applied it to kubectl properly, let's configure an issuer which you can then use to issue certificates.

We will use `ACME` issuer type because that is what `Let's Encrypt` uses.

Create `issuer.yml` in `/eks` directory of the project root:

```yml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: youngjaelim.webdev@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-account-private-key
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
      - http01:
          ingress:
            class: nginx
```

Let's apply the `issuer.yml` to kubectl:

```shell
$ kubectl apply -f eks/issuer.yml
```

## 3. Attach the issuer to Ingress

Back to `k9s` console, search for `clusterissuer`. You should be able to find `letsencrypt` with the status `The ACME account was registered with the ACME server`.

You can also search for `secrets` in `k9s` console to find out `letsencrypt-account-private-key` that we've just configured in `issuer.yml` file. However, if you search for `certificate`, you won't see any certificates created mainly because we haven't attached the issuer to Ingress yet.

Let's update `issuer.yml`:

- `annotations` under `metadata`
- 'tls' section under `spec`

```yml
# ingress.yml
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
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
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
  tls:
    - hosts:
        - api.fake-bank.org
      secretName: fakebank-api-cert
```

Let's redeploy `ingress.yml` through kubectl:

```shell
$ kubectl apply -f eks/ingress.yml
```

Back to `k9s` and search for `ingress` and hit `d` to describe `fakebank-api-ingress`. You should be able to see TL enabled and the letsencrypt certificate created successfully. If you search for `certificate`, you will also see `fakebank-api-cert` created under `default` namespace. You can also find created, expired, renewal times by describing(hitting `d`) the certificate.

Also search for `certificaterequests` to see if the certificate request is approved or not.

Now if you make HTTP or HTTPS POST request for logging in a user on Postman, you should be able to get `200 OK` response.
