# DB Transaction

## What is db transaction?

## Why do we need db transaction?

1. To provide a realiable and consistent unit of work, even in case of system failure
2. To provide isolation between programs that access the database concurrently

To achieve these goals, we need to understand what is ACID property first:

1. `Atomicity(A)`

Either all operations complete successfully or the transaction fails and the db is unchanged.

2. `Consistency(C)`

The db state must be valid after the transaction. All contraints must be satisfied.

3. `Isolation(I)`

Concurrent transactions must not affect each other.

4. `Durablitiy(D)`

Data written by a successful transaction must be recorded in persistent storage.

## How to write db transaction in Go

1. Create `store.go` in `db/sqlc` directory.

- `store.go`

  ```go
  package db

  import (
    "context"
    "database/sql"
    "fmt"
  )

  // Store provides all functions to execute db queries and transactions
  type Store struct {
    *Queries
    db *sql.DB
  }

  // NewStore creates a new Store
  func NewStore(db *sql.DB) *Store {
    return &Store{
      db:      db,
      Queries: New(db),
    }
  }

  // execTx executes a function within a database transaction
  func (store *Store) execTx(ctx context.Context, fn func(*Queries) error) error {
    tx, err := store.db.BeginTx(ctx, nil)
    if err != nil {
      return err
    }

    q := New(tx)
    err = fn(q)
    if err != nil {
      if rbErr := tx.Rollback(); rbErr != nil {
        return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
      }
      return err
    }

    return tx.Commit()
  }

  // TransferTxParams contains the input parameters of the transfer transaction
  type TransferTxParams struct {
    FromAccountID int64 `json:"from_account_id"`
    ToAccountID   int64 `json:"to_account_id"`
    Amount        int64 `json:"amount"`
  }

  // TransferTxResult is the result of the transfer transaction
  type TransferTxResult struct {
    Transfer    Transfer `json:"transfer"`
    FromAccount Account  `json:"from_account"`
    ToAccount   Account  `json:"to_account"`
    FromEntry   Entry    `json:"from_entry"`
    ToEntry     Entry    `json:"to_entry"`
  }

  // TransferTx performs a money transfer from one account to the other
  func (store *Store) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error) {
    var result TransferTxResult

    // Execute transfer transaction
    err := store.execTx(ctx, func(q *Queries) error {
      var err error

      // Create a transfer record
      result.Transfer, err = q.CreateTransfer(ctx, CreateTransferParams{
        FromAccountID: arg.FromAccountID,
        ToAccountID:   arg.ToAccountID,
        Amount:        arg.Amount,
      })
      if err != nil {
        return err
      }

      // Add from account entry
      result.FromEntry, err = q.CreateEntry(ctx, CreateEntryParams{
        AccountID: arg.FromAccountID,
        Amount:    -arg.Amount,
      })
      if err != nil {
        return err
      }

      // Add to account entry
      result.ToEntry, err = q.CreateEntry(ctx, CreateEntryParams{
        AccountID: arg.ToAccountID,
        Amount:    arg.Amount,
      })
      if err != nil {
        return err
      }

      // TODO: Update accounts' balance later
      return nil
    })

    return result, err
  }
  ```

2. Create `store_test.go`

- `store_test.go`

  ```go
  package db

  import (
    "context"
    "testing"

    "github.com/stretchr/testify/require"
  )

  func TestTransferTx(t *testing.T) {
    store := NewStore(testDB)

    account1 := createRandomAccount(t)
    account2 := createRandomAccount(t)

    // Run n concurrent transfer transactions
    n := 5
    amount := int64(10)

    // Create two channels to be able to access errors, results from the goroutines
    errs := make(chan error)
    results := make(chan TransferTxResult)

    for i := 0; i < n; i++ {
      go func() {
        result, err := store.TransferTx(context.Background(), TransferTxParams{
          FromAccountID: account1.ID,
          ToAccountID:   account2.ID,
          Amount:        amount,
        })

        errs <- err
        results <- result
      }()
    }

    // Check results
    for i := 0; i < n; i++ {
      err := <-errs
      require.NoError(t, err)

      result := <-results
      require.NotEmpty(t, result)

      // Check transfer
      transfer := result.Transfer
      require.NotEmpty(t, transfer)
      require.Equal(t, account1.ID, transfer.FromAccountID)
      require.Equal(t, account2.ID, transfer.ToAccountID)
      require.Equal(t, amount, transfer.Amount)
      require.NotZero(t, transfer.ID)
      require.NotZero(t, transfer.CreatedAt)

      // Check if a transfer record is created in the database
      _, err = store.GetTransfer(context.Background(), transfer.ID)
      require.NoError(t, err)

      // Check entries
      fromEntry := result.FromEntry
      require.NotEmpty(t, fromEntry)
      require.Equal(t, account1.ID, fromEntry.AccountID)
      require.Equal(t, -amount, fromEntry.Amount)
      require.NotZero(t, fromEntry.ID)
      require.NotZero(t, fromEntry.CreatedAt)

      _, err = store.GetEntry(context.Background(), fromEntry.ID)
      require.NoError(t, err)

      toEntry := result.ToEntry
      require.NotEmpty(t, toEntry)
      require.Equal(t, account2.ID, toEntry.AccountID)
      require.Equal(t, amount, toEntry.Amount)
      require.NotZero(t, toEntry.ID)
      require.NotZero(t, toEntry.CreatedAt)

      _, err = store.GetEntry(context.Background(), toEntry.ID)
      require.NoError(t, err)

      // TODO: Check accounts' balance later
    }
  }
  ```

### Understand Go Composition vs Inheritance in other OOP languages

### Understand Goroutines

### Understand Channels
