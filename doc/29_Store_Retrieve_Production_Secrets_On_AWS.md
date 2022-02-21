# Store and Retrieve Production Secrets On AWS

What we're going to do in this section, we will rebuild our docker image in a way that all environment variable values in `app.env` are replaced with production ones. We will be using `AWS Secrets Manager` service to achieve our goal.

# AWS Secrets Manager

We will be creating the same set of `ENV` variables' keys from `app.env` in AWS Secrets Mananger.

- DB_SOURCE: must be a postgres connection string form AWS RDS
- DB_DRIVER: postgres
- SERVER_ADDRESS: 0.0.0.0:8080
- TOKEN_SYMMETRIC_KEY: Generate 32 characters long string using `openssl`. See below!
- ACCESS_TOKEN_DURATION: 15m

## Generate Token Symmetric Key Using `OpenSSL`

We need to generate a 32 characters long key for one of our environment variables, TOKEN_SYMMETRIC_KEY in `app.env`. The `openssl` cli will help us out to create one.

```shell
openssl rand -hex 64 | head -c 32
```

> Note that there might be '%' character at the end of the string that will end up make 33 characters. If that's the case, pleasa remove '%' and make sure the length of string is exactly 32 characters.

## Sample Code to retrieve the secrets in your application

This is just an example provided by AWS that is not going to be used in our application.

```go
// Use this code snippet in your app.
// If you need more information about configurations or implementing the sample code, visit the AWS docs:
// https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/setting-up.html

import (
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"encoding/base64"
	"fmt"
)

func getSecret() {
	secretName := "fakebank"
	region := "us-east-2"

	//Create a Secrets Manager client
	sess, err := session.NewSession()
	if err != nil {
		// Handle session creation error
		fmt.Println(err.Error())
		return
	}
	svc := secretsmanager.New(sess,
	                          aws.NewConfig().WithRegion(region))
	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(secretName),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	// In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
	// See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html

	result, err := svc.GetSecretValue(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
				case secretsmanager.ErrCodeDecryptionFailure:
				// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
				fmt.Println(secretsmanager.ErrCodeDecryptionFailure, aerr.Error())

				case secretsmanager.ErrCodeInternalServiceError:
				// An error occurred on the server side.
				fmt.Println(secretsmanager.ErrCodeInternalServiceError, aerr.Error())

				case secretsmanager.ErrCodeInvalidParameterException:
				// You provided an invalid value for a parameter.
				fmt.Println(secretsmanager.ErrCodeInvalidParameterException, aerr.Error())

				case secretsmanager.ErrCodeInvalidRequestException:
				// You provided a parameter value that is not valid for the current state of the resource.
				fmt.Println(secretsmanager.ErrCodeInvalidRequestException, aerr.Error())

				case secretsmanager.ErrCodeResourceNotFoundException:
				// We can't find the resource that you asked for.
				fmt.Println(secretsmanager.ErrCodeResourceNotFoundException, aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		return
	}

	// Decrypts secret using the associated KMS key.
	// Depending on whether the secret is a string or binary, one of these fields will be populated.
	var secretString, decodedBinarySecret string
	if result.SecretString != nil {
		secretString = *result.SecretString
	} else {
		decodedBinarySecretBytes := make([]byte, base64.StdEncoding.DecodedLen(len(result.SecretBinary)))
		len, err := base64.StdEncoding.Decode(decodedBinarySecretBytes, result.SecretBinary)
		if err != nil {
			fmt.Println("Base64 Decode Error:", err)
			return
		}
		decodedBinarySecret = string(decodedBinarySecretBytes[:len])
	}

	// Your code goes here.
}
```

## Install AWS Command-Line application

[]()

Let's configure aws:

```shell
$ aws configure
```

Example

Follow the instruction and enter:

- AWS Access Key SecretId: <your_access_key>
- AWS Secret Access Key: <your_secret>
- Default region secretName: us-east-2
- Default output format: json

To find AWS access key and secret, please visit `IAM` service and find the user you've previously added for your app. In our case, it was `github-ci` user.

Run the following commands to verify:

```shell
$ cat ~/.aws/credentials
$ cat ~/.aws/config
```

Now let's use aws command for getting secrets:

```shell
# Show help for get-secret-value command
$ aws secretsmanager get-secret-value help
```

> To be able to successfully run the command, we need to add another permission policy called `SecretsManagerReadWrite` to our AWS user group `deployment` that our `github-ci` user belongs to.

![]()

```shell
# Return JSON format of Secrets that we've stored in AWS Secrets Mananger for fakebank
$ aws secretsmanager get-secret-value --secret-id fakebank

# Print the "SecretString" value in a friendly format
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text
```

Install `jq` cli that is a lightweight and flexible command-line JSON processor.

> Note that `jq` is already included in linux machine, so we don't need to include an installation step in `deploy.yml` workflow.

[jq](https://stedolan.github.io/jq/)

For macos,

```shell
$ brew install jq
```

```shell
# Transform JSON to key, value format like { "key": "foo", "value": "bar"}
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq 'to_entries'

# Extract key and value separately using map()
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq 'to_entries|map(.key)'
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq 'to_entries|map(.value)'

# Extract key and value together linked with = sign
# -r option removes surrouding dobule quotes
# pipiing with |.[] removes surrouding square brackets and commas separating each key-value pairs
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]'

# Pipe the final foramt to app.env file
$ aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > app.env
```

We will be using the final command right before we build a docker image to be deployed to AWS ECR.

> Please make sure that you use a single quotation mark, not a back tick when it is needed. Otherwise, it will not process any command properly.

```yml
# deploy.yml

name: Deploy to production

on:
  push:
    branches: [main]

jobs:
  build:
    name: Build image
    runs-on: ubuntu-latest

    steps:
      - name: Check out code
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-2

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Load AWS secrets and save to app.env
        run: aws secretsmanager get-secret-value --secret-id fakebank --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > app.env

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: fakebank
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

## TEST Docker Image

To test out the docker image pusehd to AWS ECR, we need to log in ECR first. To do that, run the following command:

```shell
# Login to AWS ECR
$ aws ecr get-login-password | docker login --username AWS --password-stdin 168633195351.dkr.ecr.us-east-2.amazonaws.com/fakebank

# Pull a docker image from AWS ECR
$ docker pull 168633195351.dkr.ecr.us-east-2.amazonaws.com/fakebank:f2836c02ef182d6ea9081214d4
b903036983b6e9

# Run a docker container
$ docker run -p 8080:8080 168633195351.dkr.ecr.us-east-2.amazonaws.com/fakebank:f2836c02ef182d6ea9081214d4
b903036983b6e9
```

## Test Using Postman

Once the docker container is successfully running, you can open up Postman and test it out.

Make `POST` request using `http://locahost:8080/users` with the following JSON body:

```json
{
  "username": "johndoe",
  "full_name": "John Doe",
  "email": "johndoe@test.com",
  "password": "whatever"
}
```

Once you get a `200 OK` response, open up your postgres DB client and see if the user is created in `users` table.
