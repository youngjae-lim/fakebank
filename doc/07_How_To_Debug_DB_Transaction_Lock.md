# How To Debug A DB Transaction Lock

Before we jump into DB lock, let't finish what's left in the previous lecture. In the last lecture, we were able to transfer money from one account to another:

- [ ] Create a tranfer record in the `transfer` table
- [ ] Create a from entry record and a to entry record in the `entries` table
- [ ] Update each account

To make functionality of updating the account for both a sender and a receiver, we will take a lookt at TTD approach in this lecture.

## TTD(Test-Driven Development)

Update `account.sql`:

Add the follwoing:

```sql
-- name: GetAccountForUpdate :one
SELECT * FROM accounts
WHERE id = $1 LIMIT 1
FOR UPDATE;
```

With `FOR UPDATE` added to SELECT statement, the query will be waiting for the other transaction to commit or rollback before it continues.

[Postgres Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring)

Then run `make sqlc` to regenerate Go codes. Open up `account.sql.go` to see the newly generated code:

```go
const getAccountForUpdate = `-- name: GetAccountForUpdate :one
SELECT id, owner, balance, currency, created_at FROM accounts
WHERE id = $1 LIMIT 1
FOR UPDATE
`

func (q *Queries) GetAccountForUpdate(ctx context.Context, id int64) (Account, error) {
	row := q.db.QueryRowContext(ctx, getAccountForUpdate, id)
	var i Account
	err := row.Scan(
		&i.ID,
		&i.Owner,
		&i.Balance,
		&i.Currency,
		&i.CreatedAt,
	)
	return i, err
}
```

To test a specific function in Go:

```shell
go test -v -run TestTransferTx
```
