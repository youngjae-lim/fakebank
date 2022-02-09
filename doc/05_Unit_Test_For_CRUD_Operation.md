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
- `account_test.go`
- `entry_test.go`
- `transfer_test.go`

Add `test` command to `Makefile`:

```Makefile
test:
  go test -v -cover ./...
```
