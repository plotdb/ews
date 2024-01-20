require! <[sharedb @plotdb/sharedb-postgres sharedb-pg-mdb ws http websocket-json-stream]>
ews = require "./index"

# according to `lib/agent.js`, sharedb send Error to frontend as objects in `{code, message}` format:
#  - https://github.com/share/sharedb/blob/master/lib/agent.js#L288 (`getReplyErrorObject` function)
# where allowed error code (as string) can be found here:
#  - https://github.com/share/sharedb/blob/master/lib/error.js#L15
# however, this blocks our custom error object.
# thus, we use a custom error code `wrapped-lderror` and stringify lderror in `message` field,
# so we can decode it in frontend.
lderror-wrapper = (e) ->
  if !e => e = {name: \lderror, id: 1012}
  if e.name != \lderror => e
  else {code: "wrapped-lderror", message: JSON.stringify(e{id,name,message})}

sdb-server = (opt) ->
  # session: express-session middelware.
  # e.g., in @servebase, it can be retrieved by `backend.session.middleware!`
  {app, io, session, access, milestone-db, wss, metadata} = opt

  server = null
  mdb = if (milestone-db and milestone-db.enabled) =>
    new sharedb-pg-mdb {io-pg: io, interval: milestone-db.interval or 250}
  else null

  # ShareDB Backend
  backend = new sharedb { db: sharedb-postgres(io), milestoneDb: mdb }

  # Connection object for ShareDB Server
  connect = backend.connect!

  # HTTP -> server -> on('upgrade') -> ( processing ... ) if not authorized: socket.destroy!
  # -> emit wss.on('connection') -> ...
  # wss: WebSocket Server - only create a new wss if wss is not provided ( no external wss )
  if !wss =>
    # HTTP Server - if we create server here, we should server.listen instead of app.listen
    server = http.create-server app
    wss = new ws.Server do
      server: server
      # noServer: true
      # key data: info.req.session / info.req.session.passport.user
      # we used verifyClient to populate session data into request,
      # but this is discouraged by lpinca ( https://github.com/websockets/ws/issues/377#issuecomment-462152231 )
      # so we don't do it now. instead, use http server upgrade event.
      # verifyClient: (info, done) -> session(info.req, {}, -> done({result: true}))

  # 1. HTTP upgrade to WebSocket
  # when http server get a header "Upgrade: Websocket" this will be triggered
  # lpinca suggests to use this to prepare additional data for each connection.
  # session data kept in req object.
  #server.on \upgrade, (req, socket, head) ->
  #  p = if session? => new Promise((res, rej) -> session(req, {}, (-> res!))) else Promise.resolve!
  #  p.then -> wss.handleUpgrade req, socket, head, (ws) -> wss.emit \connection, ws, req

  # 2. If not rejected, WebSocket Server got connection
  # manually init session data to request object and inject into wjs.
  # wjs will then be used in sharedb as agent.stream.
  wss.on \connection, (ws, req) ->
    p = if session? => new Promise((res, rej) -> session(req, {}, (-> res!))) else Promise.resolve!
    sws = new ews ws: ws, scope: \sharedb
    p.then ->
      # if we need session or user object from passport ...
      # session = req.session
      # user = session and session.passport and session.passport.user
      backend.listen (wjs = websocket-json-stream(sws)), req
    .catch (e) ->
      console.log "[sdb-server] wss on connection error: ", e.message, e
    ws.on \close, ->

  # 3. Backend handle sharedb connect.
  #    Can decide whether to allow connection at all here.
  #    Here we inject custom data into agent from session.
  backend.use \connect, ({agent, req, stream}, cb) ->
    if !req or !stream.ws => return cb!
    session = req.session
    user = (session and session.passport and session.passport.user) or {}
    agent.custom <<< {req, session, user}
    cb!

  # 4.a Backend handle metadata request
  if metadata? =>
    backend.use \commit, ({collection, agent, snapshot, op, id}, cb) ->
      if !agent.stream.ws => return cb!
      {req, session, user} = agent.custom
      metadata({m: op.m} <<< agent.custom)
      cb!

  # 4.b Backend handle readSnapshot request
  #     Decide if an user can get access to certain doc.
  if access? =>
    backend.use \readSnapshots, ({agent, collection, snapshots}, cb) ->
      # no websocket - it's server stream
      if !agent.stream.ws => return cb!
      id = if snapshots.length > 1 => null else snapshots.0.id
      access({id, collection, snapshots, type: \readSnapshots} <<< agent.custom)
        .then -> cb!
        .catch (e) -> cb lderror-wrapper e
    backend.use \submit, ({collection, agent, op, id}, cb) ->
      if !agent.stream.ws => return cb!
      access({id, collection, op, type: \submit} <<< agent.custom)
        .then -> cb!
        .catch (e) -> cb lderror-wrapper e

  ret = { server, sdb: backend, connect, wss }

module.exports = sdb-server
