# Authentication Middleware

Create `middleware.go` in `/api` directory:

```go
// middleware.go

```

Add `middleware_test.go`:

```go
// middleware_test.go

```

# Authorization Rules

- `API Create account` --> Rule: A logged-in user can only create an account for him/herself
- `API Get account` --> Rule: A logged-in user can only get accounts that he/she owns
- `API List accounts` --> Rule: A logged-in user can only list accounts that belong to him/her
- `API Transfer money` --> Rule: A logged-in user can only send money from his/her own account

Update `account.sql` in `/db/query` directory:

We need to add WHERE condition to ListAccount query to be able to select accounts that belong to an owner only.

```sql
-- name: CreateAccount :one
INSERT INTO accounts (
  owner,
  balance,
  currency
) VALUES (
  $1, $2, $3
)
RETURNING *;

-- name: GetAccount :one
SELECT * FROM accounts
WHERE id = $1 LIMIT 1;

-- name: GetAccountForUpdate :one
SELECT * FROM accounts
WHERE id = $1 LIMIT 1
FOR NO KEY UPDATE;

-- name: ListAccounts :many
SELECT * FROM accounts
WHERE owner = $1
ORDER BY id LIMIT $2 OFFSET $3;

-- name: UpdateAccount :one
UPDATE accounts SET balance = $2
WHERE id = $1
RETURNING *;

-- name: AddAccountBalance :one
UPDATE accounts SET balance = balance + sqlc.arg(amount)
WHERE id = sqlc.arg(id)
RETURNING *;

-- name: DeleteAccount :exec
DELETE FROM accounts WHERE id = $1;

```
