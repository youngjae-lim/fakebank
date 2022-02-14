Create `user.sql` in `/db/query`:

```sql

```

Run `make sqlc` again to regenate type-safe Go codes.

Take a look at `models.go`, `user.sql.go` files to see if they are updated accordingly.

Create `user_test.go` file in `/db/sqlc`:

```go
// user_test.go

```

Run tests:

```shell
$ cd db/sqlc
$ go test -v -run TestCreateUser
$ go test -v -run TestGetUser
# go test -v .
```

Now that we added a new users table in our model, we need to update mock db as well:

Run `make mock` again.
Run tests again.
