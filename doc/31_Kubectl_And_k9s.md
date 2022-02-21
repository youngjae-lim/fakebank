# Kubectl And k9s

We will be utilizing kubectl and k9s to connect to a kubernetes cluster on AWS EKS in this section.

## Install kubectl

[Install on macOS](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/)

```shell
# Install kubectl
$ brew install kubectl

# Test the installation
$ kubectl version --client
```

## Verify kubectl configuration

To configure kubectl, we have to pull AWS EKS info using AWS cli:

To be able to connect to AWS EKS using AWS cli, you have to give another permission to `deployment` user group that our `github-ci` user belongs to. Go to `AWS IAM` and create an inline policy to deployment group.

```shell
$ aws eks update-kubeconfig --name fakebank --region us-east-2
Added new context arn:aws:eks:us-east-2:168633195351:cluster/fakebank to /Users/youngjaelim/.kube/config
```

> Note that we have to use the same AWS credentials when using aws cli to work with EKS. Because a root user created a fakebank node group on AWS EKS, we have to create the same credentials and use them for our aws cli credentials. [Read](https://aws.amazon.com/premiumsupport/knowledge-center/amazon-eks-cluster-access/)

```shell
# Add a new credential you've set from AWS
$ vi ~/.aws/credentials
```

Once everything is set, you can see the AWS EKS cluster-info by running the following command:

[Read](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#verify-kubectl-configuration)

```shell
$ kubectl cluster-info
```

### How to allow a non-creator of AWS EKS cluster to access to AWS EKS using kubectl

So far, we used our AWS root user credential, but we want our `github-ci` user to be able to work with kubectl. How can we achieve that?

Let's create `aws-auth.yml` file in the `eks` directory in our projet root:

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::168633195351:user/github-ci
      username: github-ci 
      groups: 
        - system:masters
```

Then apply the `aws-auth.yml` to `kubectl`:

> You might see a warning message that can be ignored for now.

```shell
$ kubectl apply -f ekcs/aws-auth.yml
```

Switch to `github-ci` user from root:

```shell
# Swtich from a root user to github-cil user
$ export AWS_PROFILE=github-ci

# Check to see if you pull the AWS EKS cluster info using github-ci user.
$ kubectl cluster-info
```

### Useful, but lengthy kubectl commands

```shell
# Get services running on AWS EKS cluster
$ kubectl get services

# Get running pods
$ kubectl get pods
```

Here comes `k9s` to save us from using those lengthy commands:

Install `k9s` on `macOS`:

```shell
$ brew install k9s
```

Run the `k9s`:

```shell
$ k9s
```

### Some useful short cuts to navigate in `k9s` GUI:

- `:ns`: navigate to namespaces

  - Use `up` or `down` arrow keys to select any namespace.
  - Hit `enter` to go into the selected namespace.
  - Hit `esc` to get out of the selected namespace.

- `:service`: list all services running
- `:pods`: list all pods
- `:cj`: list all cronjobs
- `:nodes`: list all nodes
- `:configmap`: list all configmaps
- `:quit`: escape from the k9s back to terminal
