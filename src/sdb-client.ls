ews.sdb-client = (opt = {}) ->
  @ <<< do
    _evthdr: {}
    # sharedb connection object. survives disconnection,
    # so docs (and their pendingOps / inflightOp) are kept across reconnect.
    _connection: null
    # current scoped socket facade for sharedb. disposable; renewed per reconnect.
    _sws: null
    _ws: opt.ws
  # unfortunately `close` event is not reliable, so we track ews offline event.
  @_ws.on \offline, ~> @_on-broken!
  # if we can ensure @_ws is ews, we can omit this.
  @_ws.addEventListener \close, ~> @_on-broken!
  @

ews.sdb-client.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @_evthdr.[][n].push cb
  fire: (n, ...v) -> for cb in (@_evthdr[n] or []) => cb.apply @, v

  # a socket declared dead must never speak to sharedb again.
  # we don't touch @_connection here - docs must survive disconnection.
  _on-broken: ->
    if !@_sws => return
    @_release-sws!
    @fire \close

  _release-sws: ->
    if !@_sws => return
    # a disposed ews is unsupervised and detached from every raw ws it ever
    # installed listeners on - late events from an old session can no longer
    # reach sharedb through it.
    @_sws.dispose!
    @_sws = null

  _bind: ->
    if @_sws => return   # current socket still alive; nothing to do.
    @_sws = new ews ws: @_ws, scope: \sharedb
    if !@_connection =>
      @_connection = new sharedb.Connection @_sws
      # sharedb.Connection won't throw errors but send error here.
      # so we should always handle sdb errors.
      @_connection.on \error, (err) ~> @fire \error, {err}
    else
      # sharedb's sanctioned reconnect path: same Connection, fresh socket.
      # sets connection state directly (no invalid-transition throw), then
      # handshakes / resubscribes / flushes pendingOps automatically.
      @_connection.bindToSocket @_sws

  connect: ->
    Promise.resolve!
      .then ~> if @_ws.status! != 2 => @_ws.connect! else null
      .then ~> @_bind!

  ensure: -> @connect!

  get-snapshot: ({id, version, collection}) -> new Promise (res, rej) ~>
    @_connection.fetchSnapshot(
      (if collection? => collection else \doc),
      id,
      (if version? => version else null),
      (e, s) -> if e => rej(e) else res(s)
    )

  get: ({id, watch, create, collection}) ->
    <~ @ensure!then _
    p = new Promise (res, rej) ~>
      doc = @_connection.get (if collection? => collection else \doc), id
      (e) <~ doc.fetch _
      if e => return rej e
      doc.subscribe (ops, source) -> res doc
      doc.on \error, (err) ~> @fire \error, {doc, err}
      if watch? => doc.on 'op batch', (ops, source) -> watch ops, source
      if !doc.type => doc.create ((if create => create! else null) or {})
    p.catch (e) ~>
      if e.code == \wrapped-lderror => e = new Error! <<< JSON.parse(e.message)
      Promise.reject e

  disconnect: -> @_ws.disconnect!
  cancel: -> @_ws.cancel!
  status: -> @_ws.status!

if module? => module.exports = ews.sdb-client
else if window? => window.ews.sdb-client = ews.sdb-client
