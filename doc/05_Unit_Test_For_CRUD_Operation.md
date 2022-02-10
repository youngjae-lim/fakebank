# Unit Test For CRUD Operation

## Preliminary setup

We need Go postgres driver to complete the test. Let's go get a package for the postgres driver:

```shell
go get github.com/lib/pq
```

To help our testing process, let's add another package:

```shell
go get github.com/stretchr/testify
```

Let's create a `util` package to generate some random data that can help testing as well:

```go
// random.go

package util

import (
	"math/rand"
	"strings"
	"time"
)

const alphabet = "abcdefghijklnmopqrstuvwxyz"

func init() {
	rand.Seed(time.Now().UnixNano())
}

// RandomInt generates a random integer between min and max
func RandomInt(min, max int64) int64 {
	return min + rand.Int63n(max-min+1)
}

// RandomString generates a random string of length n
func RandomString(n int) string {
	var sb strings.Builder
	k := len(alphabet)

	for i := 0; i < n; i++ {
		c := alphabet[rand.Intn(k)]
		sb.WriteByte(c)
	}

	return sb.String()
}

// RandomOwner generates a random owner name
func RandomOwner() string {
	return RandomString(6)
}

// RandomMoney generates a random amount of money between 0 and 1000
func RandomMoney() int64 {
	return RandomInt(0, 1000)
}

// RandomCurrency generates a random currecy code
func RandomCurrency() string {
	currencies := []string{"EUR", "USD", "CAD"}
	n := len(currencies)
	return currencies[rand.Intn(n)]
}
```

## Create Test files

Create the following two go files in `db/sqlc` directory:

- `setup_test.go`

  ```go
  package db

  import (
    "database/sql"
    "log"
    "os"
    "testing"

    _ "github.com/lib/pq"
  )

  const (
    dbDriver = "postgres"
    dbSource = "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable"
  )

  var testQueries *Queries

  func TestMain(m *testing.M) {
    conn, err := sql.Open(dbDriver, dbSource)
    if err != nil {
      log.Fatal("cannot connect to db:", err)
    }

    testQueries = New(conn)

    os.Exit(m.Run())
  }
  ```

- `account_test.go`

  ```go
  package db

  import (
    "context"
    "database/sql"
    "testing"
    "time"

    "github.com/stretchr/testify/require"
    "github.com/youngjae-lim/fakebank/util"
  )

  func createRandomAccount(t *testing.T) Account {
    arg := CreateAccountParams{
      Owner:    util.RandomOwner(),
      Balance:  util.RandomMoney(),
      Currency: util.RandomCurrency(),
    }

    account, err := testQueries.CreateAccount(context.Background(), arg)
    require.NoError(t, err)
    require.NotEmpty(t, account)

    require.Equal(t, arg.Owner, account.Owner)
    require.Equal(t, arg.Balance, account.Balance)
    require.Equal(t, arg.Currency, account.Currency)

    require.NotZero(t, account.ID)
    require.NotZero(t, account.CreatedAt)

    return account
  }

  func TestCreateAccount(t *testing.T) {
    createRandomAccount(t)
  }

  func TestGetAccount(t *testing.T) {
    account1 := createRandomAccount(t)
    account2, err := testQueries.GetAccount(context.Background(), account1.ID)
    require.NoError(t, err)
    require.NotEmpty(t, account2)

    require.Equal(t, account1.ID, account2.ID)
    require.Equal(t, account1.Owner, account2.Owner)
    require.Equal(t, account1.Balance, account2.Balance)
    require.Equal(t, account1.Currency, account2.Currency)
    require.WithinDuration(t, account1.CreatedAt, account2.CreatedAt, time.Second)
  }

  func TestUpdateAccount(t *testing.T) {
    account1 := createRandomAccount(t)

    arg := UpdateAccountParams{
      ID:      account1.ID,
      Balance: util.RandomMoney(),
    }

    account2, err := testQueries.UpdateAccount(context.Background(), arg)
    require.NoError(t, err)
    require.NotEmpty(t, account2)

    require.Equal(t, account1.ID, account2.ID)
    require.Equal(t, account1.Owner, account2.Owner)
    require.Equal(t, arg.Balance, account2.Balance)
    require.Equal(t, account1.Currency, account2.Currency)
    require.WithinDuration(t, account1.CreatedAt, account2.CreatedAt, time.Second)
  }

  func TestDeleteAccount(t *testing.T) {
    account1 := createRandomAccount(t)
    err := testQueries.DeleteAccount(context.Background(), account1.ID)
    require.NoError(t, err)

    account2, err := testQueries.GetAccount(context.Background(), account1.ID)
    require.Error(t, err)
    require.EqualError(t, err, sql.ErrNoRows.Error())
    require.Empty(t, account2)
  }

  func TestListAccounts(t *testing.T) {
    for i := 0; i < 10; i++ {
      createRandomAccount(t)
    }

    arg := ListAccountsParams{
      Limit:  5,
      Offset: 5,
    }

    accounts, err := testQueries.ListAccounts(context.Background(), arg)
    require.NoError(t, err)
    require.Len(t, accounts, 5)

    for _, account := range accounts {
      require.NotEmpty(t, account)
    }
  }
  ```

- `entry_test.go`

  ```go
  package db

  import (
    "context"
    "testing"
    "time"

    "github.com/stretchr/testify/require"
    "github.com/youngjae-lim/fakebank/util"
  )

  func createRandomEntry(t *testing.T, account Account) Entry {

    arg := CreateEntryParams{
      AccountID: account.ID,
      Amount:    util.RandomMoney(),
    }

    entry, err := testQueries.CreateEntry(context.Background(), arg)
    require.NoError(t, err)
    require.NotEmpty(t, entry)

    require.Equal(t, arg.AccountID, entry.AccountID)
    require.Equal(t, arg.Amount, entry.Amount)

    require.NotZero(t, entry.ID)
    require.NotZero(t, entry.CreatedAt)

    return entry
  }

  func TestCreateEntry(t *testing.T) {
    account := createRandomAccount(t)
    createRandomEntry(t, account)
  }

  func TestGetEntry(t *testing.T) {
    account1 := createRandomAccount(t)
    entry1 := createRandomEntry(t, account1)
    entry2, err := testQueries.GetEntry(context.Background(), entry1.ID)
    require.NoError(t, err)
    require.NotEmpty(t, entry2)

    require.Equal(t, entry1.ID, entry2.ID)
    require.Equal(t, entry1.AccountID, entry2.AccountID)
    require.Equal(t, entry1.Amount, entry2.Amount)
    require.WithinDuration(t, entry1.CreatedAt, entry2.CreatedAt, time.Second)
  }

  func TestListEntries(t *testing.T) {
    account := createRandomAccount(t)
    for i := 0; i < 10; i++ {
      createRandomEntry(t, account)
    }

    arg := ListEntriesParams{
      AccountID: account.ID,
      Limit:     5,
      Offset:    5,
    }

    entries, err := testQueries.ListEntries(context.Background(), arg)
    require.NoError(t, err)
    require.Len(t, entries, 5)

    for _, entry := range entries {
      require.NotEmpty(t, entry)
      require.Equal(t, arg.AccountID, entry.AccountID)
    }
  }
  ```

- `transfer_test.go`

  ```go
  package db

  import (
    "context"
    "testing"
    "time"

    "github.com/stretchr/testify/require"
    "github.com/youngjae-lim/fakebank/util"
  )

  func createRandomTransfer(t *testing.T, fromAccount, toAccount Account) Transfer {

    arg := CreateTransferParams{
      FromAccountID: fromAccount.ID,
      ToAccountID:   toAccount.ID,
      Amount:        util.RandomMoney(),
    }

    transfer, err := testQueries.CreateTransfer(context.Background(), arg)
    require.NoError(t, err)
    require.NotEmpty(t, transfer)

    require.Equal(t, arg.FromAccountID, transfer.FromAccountID)
    require.Equal(t, arg.ToAccountID, transfer.ToAccountID)
    require.Equal(t, arg.Amount, transfer.Amount)

    require.NotZero(t, transfer.ID)
    require.NotZero(t, transfer.CreatedAt)

    return transfer
  }

  func TestCreateTransfer(t *testing.T) {
    account1 := createRandomAccount(t)
    account2 := createRandomAccount(t)
    createRandomTransfer(t, account1, account2)
  }

  func TestGetTransfer(t *testing.T) {
    account1 := createRandomAccount(t)
    account2 := createRandomAccount(t)

    transfer1 := createRandomTransfer(t, account1, account2)
    transfer2, err := testQueries.GetTransfer(context.Background(), transfer1.ID)
    require.NoError(t, err)
    require.NotEmpty(t, transfer2)

    require.Equal(t, transfer1.ID, transfer2.ID)
    require.Equal(t, transfer1.FromAccountID, transfer2.FromAccountID)
    require.Equal(t, transfer1.ToAccountID, transfer2.ToAccountID)
    require.Equal(t, transfer1.Amount, transfer2.Amount)
    require.WithinDuration(t, transfer1.CreatedAt, transfer2.CreatedAt, time.Second)
  }

  func TestListTransfers(t *testing.T) {
    account1 := createRandomAccount(t)
    account2 := createRandomAccount(t)
    for i := 0; i < 5; i++ {
      createRandomTransfer(t, account1, account2)
      createRandomTransfer(t, account2, account1)
    }

    arg := ListTransfersParams{
      FromAccountID: account1.ID,
      ToAccountID:   account1.ID,
      Limit:         5,
      Offset:        5,
    }

    transfers, err := testQueries.ListTransfers(context.Background(), arg)
    require.NoError(t, err)
    require.Len(t, transfers, 5)

    for _, transfer := range transfers {
      require.NotEmpty(t, transfer)
      require.True(t, transfer.FromAccountID == account1.ID || transfer.ToAccountID == account1.ID)
    }
  }
  ```

  Add `test` command to `Makefile`:

```Makefile
test:
  go test -v -cover ./...
```
