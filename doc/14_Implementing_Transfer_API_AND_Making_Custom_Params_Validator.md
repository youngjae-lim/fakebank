# Implementing Transfer api

Create `transfer.go` in `/api`:

```go
// transfer.go

package api

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	db "github.com/youngjae-lim/fakebank/db/sqlc"
)

type transferRequest struct {
	FromAccountID int64  `json:"from_account_id" binding:"required,min=1"`
	ToAccountID   int64  `json:"to_account_id" binding:"required,min=1"`
	Amount        int64  `json:"amount" binding:"required,gt=0"`
	Currency      string `json:"currency" binding:"required,oneof=USD EUR CAD"`
}

func (server *Server) createTransfer(ctx *gin.Context) {
	var req transferRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	if !server.validAccount(ctx, req.FromAccountID, req.Currency) {
		return
	}

	if !server.validAccount(ctx, req.ToAccountID, req.Currency) {
		return
	}

	arg := db.TransferTxParams{
		FromAccountID: req.FromAccountID,
		ToAccountID:   req.ToAccountID,
		Amount:        req.Amount,
	}

	result, err := server.store.TransferTx(ctx, arg)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, result)
}

func (server *Server) validAccount(ctx *gin.Context, accountID int64, currency string) bool {
	account, err := server.store.GetAccount(ctx, accountID)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, errorResponse(err))
			return false
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return false
	}

	if account.Currency != currency {
		err := fmt.Errorf("account [%d] currency mismatch: %s vs %s", account.ID, account.Currency, currency)
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return false
	}

	return true
}
```

# Making Custom Params Validator

Create `validator.go` in `/api`:

```go
// validator.go

package api

import (
	"github.com/go-playground/validator/v10"
	"github.com/youngjae-lim/fakebank/util"
)

var validCurrency validator.Func = func(fieldLevel validator.FieldLevel) bool {
	if currency, ok := fieldLevel.Field().Interface().(string); ok {
		// check currency is supported
		return util.IsSupportedCurrency(currency)
	}
	return false
}
```

Create `currency.go` in `/util`:

```go
// currency.go

package util

// Constants for all supported currencies
const (
	USD = "USD"
	EUR = "EUR"
	CAD = "CAD"
)

func IsSupportedCurrency(currency string) bool {
	switch currency {
	case USD, EUR, CAD:
		return true
	}
	return false
}
```

Register the custom validator with `Gin`:

Open up `server.go` and update it as follows:

```go
// server.go

package api

import (
	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"
	db "github.com/youngjae-lim/fakebank/db/sqlc"
)

// Server serves HTTP requests for our banking service
type Server struct {
	store  db.Store
	router *gin.Engine
}

// NewServer creates a new HTTP server and sets up routing
func NewServer(store db.Store) *Server {
	server := &Server{
		store: store,
	}
	router := gin.Default()

	// Add custom validator
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		v.RegisterValidation("currency", validCurrency)
	}

	router.POST("/accounts", server.createAccount)
	router.GET("/accounts/:id", server.getAccount)
	router.GET("/accounts", server.listAccount)

	router.POST("/transfers", server.createTransfer)

	server.router = router
	return server
}

// Start runs the HTTP server on a specific address
func (server *Server) Start(address string) error {
	return server.router.Run(address)
}

func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
```

Go back to dbidagrm.io to add `users` table:

Add users table as you see below and make `owner` column in the `accounts` table referece to `username` in `users` table. Because now a single user can have multiple accounts with a distinctive currency, we also need to add a unique composite index on `(owner, currency)` in `accounts` table. Once everthing looks good, export it as postgreSQL.

```sql
Table users as U {
  username varchar [pk]
  hashed_password varchar [not null]
  full_name varchar [not null]
  email varchar [unique, not null]
  password_changed_at timestamptz [not null, default: '0001-01-01 00:00:00Z']
  created_at timestamptz [not null, default: `now()`]
}

Table accounts as A {
  id bigserial [pk]
  owner varchar [ref: > U.username, not null]
  balance bigint [not null]
  currency varchar [not null]
  created_at timestamptz [not null, default: `now()`]

  Indexes {
    owner
    (owner, currency) [unique]
  }
}

Table entries {
  id bigserial [pk]
  account_id bigint [ref: > A.id, not null]
  amount bigint [not null, note: 'can be negative or postivite']
  created_at timestamptz [not null, default: `now()`]

  Indexes {
    account_id
  }
}

Table transfers {
  id bigserial [pk]
  from_account_id bigint [ref: > A.id, not null]
  to_account_id bigint [ref: > A.id, not null]
  amount bigint [not null, note: 'must be positive']
  created_at timestamptz [not null, default: `now()`]

  Indexes {
    from_account_id
    to_account_id
    (from_account_id, to_account_id)
  }
}
```

With the exported postgreSQL, we will add new migration files to create a users table with newly added contraints.

To create a new set of up and down migration file, please run the following:

```shell
$ migrate create -ext sql -dir db/migration -seq add_users
```

Then edit the up and down migration file like this:

Up migrgation file:

```sql
CREATE TABLE "users" (
  "username" varchar PRIMARY KEY,
  "hashed_password" varchar NOT NULL,
  "full_name" varchar NOT NULL,
  "email" varchar UNIQUE NOT NULL,
  "password_changed_at" timestamptz NOT NULL DEFAULT '0001-01-01 00:00:00Z',
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

ALTER TABLE "accounts" ADD FOREIGN KEY ("owner") REFERENCES "users" ("username");

ALTER TABLE "accounts" ADD CONSTRAINT "owner_currency_key" UNIQUE ("owner", "currency");

```

Down migration file:

```sql

ALTER TABLE IF EXISTS "accounts" DROP CONSTRAINT IF EXISTS "owner_currency_key";

ALTER TABLE IF EXISTS "accounts" DROP CONSTRAINT IF EXISTS "accounts_owner_fkey";

DROP TABLE IF EXISTS "users";
```

Let's clean up all the tables and contraints from fake_bank database and rerun all migrations:

```shell
$ make migrationdown
$ make migrationup
```

Note that I added two new commands `migrateup1` and `migratedown1` in the `Makefile` to be able to run the most recent migration up and down:

```Makefile
postgres:
	docker run --name postgres14 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -d postgres:14-alpine

createdb:
	docker exec -it postgres14 createdb --username=postgres --owner=postgres fake_bank

dropdb:
	docker exec --user postgres -it postgres14 dropdb fake_bank

migrateup:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose up

# migrate up the most current one
migrateup1:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose up 1

migratedown:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose down

# migrate down the most latest one
migratedown1:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose down 1

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/youngjae-lim/fakebank/db/sqlc Store

.PHONY: postgres createdb dropdb migrateup migrateup1 migratedown migratedown1 sqlc test server mock
```
