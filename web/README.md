# EWS Dev Server

A local dev server for testing ews with ShareDB over WebSocket.

## Prerequisites

Requires a running PostgreSQL instance for sharedb, with the following default config (see `web/server.ls`):

- host: `localhost`
- port: `5432` (override with `DB_PORT` env var)
- database: `postgres`
- user: `postgres`
- password: `postgres`

Override host with `DB_HOST` env var.

### Schema

Run `web/sharedb.sql` to create the required tables (`ops`, `snapshots`, `milestonesnapshots`):

```sh
psql -h localhost -p 5432 -U postgres -d postgres -f web/sharedb.sql
```

## Running

```sh
npm start
```

Then open `http://localhost:5100`.
