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

2. A few gotchas:

> Wile you create a cluster, please make sure you select at least `t3.small` instance type for the node group being created. If you select `t3.micro` that has maximum number of pods, 4, then we won't have ability to increase desired capacity to deploy your docker image. So for now choosing `t3.small` would be enough for our demo. For more detail, please read [here](https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt) and [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI).

> Node Group Scaling Configuration:

- Minimum size: 0 nodes
- Maximum size: 2 nodes
- Desired size: 1 nodes
