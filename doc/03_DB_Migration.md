# DB Migration

## Objectives

- Know how to run commands inside a running container
- Know how to migrate to database using golang-migrate
- Know how to use Makefile to run commands that we frequently use

## Install golang-migrate

```shell
$ brew install golang-migrate
```

### Generate Up & Down Migration Files

#### [migrate CLI](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)

- Create a project direcotry: fakebank
- Create /db/migration/ directory under the proejct root
- Create migration files for initiating schema

  ```shell
  $ migrate create -ext sql -dir db/migration -seq init_schema
  ```

- Two up & down migration files will be generated in /db/migration directory
  - Copy and paste the previsouly generated sql file to up migration file.
  - Edit the down migration file as follows:

#### Up migration file

```sql
CREATE TABLE "accounts" (
  "id" bigserial PRIMARY KEY,
  "owner" varchar NOT NULL,
  "balance" bigint NOT NULL,
  "currency" varchar NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "entries" (
  "id" bigserial PRIMARY KEY,
  "account_id" bigint NOT NULL,
  "amount" bigint NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "transfers" (
  "id" bigserial PRIMARY KEY,
  "from_account_id" bigint NOT NULL,
  "to_account_id" bigint NOT NULL,
  "amount" bigint NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

ALTER TABLE "entries" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("id");

ALTER TABLE "transfers" ADD FOREIGN KEY ("from_account_id") REFERENCES "accounts" ("id");

ALTER TABLE "transfers" ADD FOREIGN KEY ("to_account_id") REFERENCES "accounts" ("id");

CREATE INDEX ON "accounts" ("owner");

CREATE INDEX ON "entries" ("account_id");

CREATE INDEX ON "transfers" ("from_account_id");

CREATE INDEX ON "transfers" ("to_account_id");

CREATE INDEX ON "transfers" ("from_account_id", "to_account_id");

COMMENT ON COLUMN "entries"."amount" IS 'can be negative or postivite';

COMMENT ON COLUMN "transfers"."amount" IS 'must be positive';

```

#### Down miagration file

- ```sql
  DROP TABLE IF EXISTS entries;
  DROP TABLE IF EXISTS transfers;
  DROP TABLE IF EXISTS accounts;
  ```

### How to run migration files in the Docker

```shell
$ docker exec -it postgres14 /bin/sh
/ # createdb --username=postgres --owner=postgres fake_bank
/ # su - postgres
3f282909b3fe:~$ psql fake_bank
fake_bank-# \q
3f282909b3fe:~$ dropdb fake_bank
3f282909b3fe:~$ exit
/ # exit
```

Now you can run the same commands without going through the shell:

```shell
# Create fake_bank database
$ docker exec -it postgres14 createdb --username=postgres --owner=postgres fake_bank

# Drop fake_bank database
$ docker exec --user postgres -it postgres14 dropdb fake_bank
```

Once database is setup, we are now ready to run our first migration to the database to create tables:

```shell
# Migrate up
$ migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose up

# Migrate down
$ migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose down
```

You can go to Beekeeper to check if tables are generated and dropped properly.

### Create a Makefile

Let's make `Makfile` to run all the commands we've previsouly ran:

```Makefile
postgres:
	docker run --name postgres14 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -d postgres:14-alpine

createdb:
	docker exec -it postgres14 createdb --username=postgres --owner=postgres fake_bank

dropdb:
	docker exec --user postgres -it postgres14 dropdb fake_bank

migrateup:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose down

.PHONY: postgres createdb dropdb migrateup migratedown
```
