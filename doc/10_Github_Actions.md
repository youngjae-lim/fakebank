# Github Actions

## Workflow

- An automated procedure
- Made up of 1+ jobs
- Triggered by events, scheduled, or manually
- Add `.yml` file to repository

## Runner

- A server to run the jobs
- Run 1 job at a time
- Github hosted or self hosted

## Job

- A set of steps that execute on the same Runner
- Normal jobs run in parallel
- Dependent jobs run serially

## Step

- An individual task
- Run serially within a job
- Contain 1+ actions

## Action

- A standalone command
- Run serially within a step
- Can be reused

Now that we understand what Github Actions, let's create one for our own project:

Create `./github/workflows/` directory and create ci.yml file:

```yml
name: ci-test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: password
          POSTGRES_DB: fake_bank
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - name: Set up Go
        uses: actions/setup-go@v2
        with:
          go-version: 1.17
        id: go

      - name: Check out code into the Go module directory
        uses: actions/checkout@v2

      - name: Install golang-migrate
        run: |
          curl -L https://github.com/golang-migrate/migrate/releases/download/v4.15.1/migrate.linux-amd64.tar.gz | tar xvz
          sudo mv migrate /usr/bin/
          which migrate

      - name: Run migrations
        run: make migrateup

      - name: Test
        run: make test
```
