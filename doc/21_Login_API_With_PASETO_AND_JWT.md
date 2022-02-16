# Login API With PASETO AND JWT

## Login User API

1. HTTP Request: POST /users/login

- username
- password

2. HTTP Response: 200 OK with Access Token

## Add 2 New Env Variables

`TOKEN_SYMMETRIC_KEY=12345678901234567890123456789012`
`ACCESS_TOKEN_DURATION=15m`

Update `config.go` in util package to load the new env variables.

Add `loginUser` handler to `user.go`
Add `/users/login` route to `server.go`

