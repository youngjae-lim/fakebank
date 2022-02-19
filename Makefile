postgres:
	docker run --name postgres14 --network bank-network -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -d postgres:14-alpine

createdb:
	docker exec -it postgres14 createdb --username=postgres --owner=postgres fake_bank

dropdb:
	docker exec --user postgres -it postgres14 dropdb fake_bank

migrateup:
	migrate -path db/migration -database "postgresql://postgres:CeUF1K2JSjarIqmsCHVj@fake-bank.cyxurplypeoa.us-east-2.rds.amazonaws.com:5432/fake_bank" -verbose up

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
