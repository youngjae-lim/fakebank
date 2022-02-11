postgres:
	docker run --name postgres14 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -d postgres:14-alpine

createdb:
	docker exec -it postgres14 createdb --username=postgres --owner=postgres fake_bank

dropdb:
	docker exec --user postgres -it postgres14 dropdb fake_bank

migrateup:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable" -verbose down

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

.PHONY: postgres createdb dropdb migrateup migratedown sqlc test server
