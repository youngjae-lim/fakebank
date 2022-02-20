# Build and Push Docker Image to AWS ECR

We will create a new Github actions to deploy our docker image to AWS ECR.

First, we will go to Github marketplace to find an official Github actions maded by AWS team to login to AWS ECR:

[AWS ECR Login Action for Github Actions](https://github.com/marketplace/actions/amazon-ecr-login-action-for-github-actions)

Create `deploy.yml` in `./github/workflows` direcotory:

```yml

```

## Create a new user in AWS using IAM service

We will create a new user in AWS using IAM service.

## Create a Github Actions Secrets for AWS Credentials

We will also create `Action secrets` for our Github actions for deployment to store `AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY` that are used in our `deploy.yml` Github actions. Those two env variables are from one we've just created in `AWS IAM` as a `github-ci` user.

![Github Secrets for Actions]()
