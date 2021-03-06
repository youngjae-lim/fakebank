# Create DB on AWS RDS

- Go to AWS RDS service and enable postgres service.

- You also need to edit the security group so that you can access database from anywhere. We never want to do that in a production, but here it is ok to allow the public access since we are trying things out.

  - Follow the link under `VPC security groups` for your database and edit the `source` field to `0.0.0.0/0`.

- Once the service is available, you will need an auto-generated `master password` and `endpoint`.

  - Use these two values to access the database from your local machine using any postgres database client.
  - Also update `Makefile`:
    - Duplicate `migrateup` command and rename it to `migrateup_to_aws`.
    - Replace the password and endpoint with those from AWS.
    - Then run the `migrateup_to_aws` command in your local terminal to run migrations in the AWS postgres.

> Note that `migrateup_to_aws` command is for a temporary purpose to test the AWS postgres connection and migration, so it will be deleted later mainly because it exposes a postgres password.
