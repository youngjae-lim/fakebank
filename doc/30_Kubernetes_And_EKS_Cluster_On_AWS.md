# Kubernetes and EKS(Elastic Kubernetes Service) Cluster on AWS

## What is Kubernetes?

- An open-source container orchestration engine
- For automating deployment, scaling, and management of containerized applications

## Kubernetes' components

- Worker Node

  - Kublet Agent: make sure containers run inside pods
  - Container Runtimes: Docker, containerd, CRI-O
  - Kube-Proxy: maintain network rules, allow communication with pods

- Master Node
  - API Server
  - etcd
  - Scheduler
  - Controller manager
    - node controller
    - job controller
    - end-pointe controller
    - service account & token controller
  - Cloud controller manager
    - node controller
    - route controller
    - service controller

## AWS EKS

### Create a Role

### Create a EKS Cluster

> Note that creating a EKS cluster may take several minutes.

1. Create a worker node.

- Create a new role using `IAM`:
  - for EKS:
    - AmazonEKSWorkerNodePolicy
    - AmazonEKS_CNI_Policy
  - for ECR:
    - AmazonEC2ContainerRegistryReadOnly
