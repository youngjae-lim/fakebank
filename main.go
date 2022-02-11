package main

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
	"github.com/youngjae-lim/fakebank/api"
	db "github.com/youngjae-lim/fakebank/db/sqlc"
	"github.com/youngjae-lim/fakebank/util"
)

func main() {
	config, err := util.LoadConfig(".")
	if err != nil {
		log.Fatal("cannot load config:", err)
	}

	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}

	store := db.NewStore(conn)
	server := api.NewServer(store)

	err = server.Start(config.SERVER_ADDRESS)
	if err != nil {
		log.Fatal("cannot start server:", err)
	}
}
