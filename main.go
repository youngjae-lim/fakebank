package main

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
	"github.com/youngjae-lim/fakebank/api"
	db "github.com/youngjae-lim/fakebank/db/sqlc"
)

// TODO: Refactor all env variables into .env
const (
	dbDriver      = "postgres"
	dbSource      = "postgresql://postgres:password@localhost:5432/fake_bank?sslmode=disable"
	serverAddress = "0.0.0.0:8080"
)

func main() {
	conn, err := sql.Open(dbDriver, dbSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}

	store := db.NewStore(conn)
	server := api.NewServer(store)

	err = server.Start(serverAddress)
	if err != nil {
		log.Fatal("cannot start server:", err)
	}
}
