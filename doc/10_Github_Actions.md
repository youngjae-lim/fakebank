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
