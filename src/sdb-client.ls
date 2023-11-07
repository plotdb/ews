ews.sdb-client = (opt = {}) ->
  @ <<< do
    _evthdr: {}
    _connection: null # sharedb connection object
    _ws: opt.ws
  # unfortunately `close` event is not reliable, so we track ews offline event.
  @_ws.on \offline, ~>
    if !(@_connection and @_sws) => return
    @ <<< _connection: null, _sws: null
    @fire \close
  # if we can ensure @_ws is ews, we can omit this.
  @_ws.addEventListener \close, ~>
    if !(@_connection and @_sws) => return
    @ <<< _connection: null, _sws: null
    @fire \close
  @

ews.sdb-client.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @_evthdr.[][n].push cb
  fire: (n, ...v) -> for cb in (@_evthdr[n] or []) => cb.apply @, v

  get-snapshot: ({id, version, collection}) -> new Promise (res, rej) ~>
    @_connection.fetchSnapshot(
      (if collection? => collection else \doc),
      id,
      (if version? => version else null),
      (e, s) -> if e => rej(e) else res(s)
    )

  get: ({id, watch, create, collection}) ->
    <~ (if !@_connection => @connect! else Promise.resolve!).then _
    p = new Promise (res, rej) ~>
      doc = @_connection.get (if collection? => collection else \doc), id
      (e) <~ doc.fetch _
      if e => return rej e
      doc.subscribe (ops, source) -> res doc
      doc.on \error, (err) ~> @fire \error, {doc, err}
      if watch? => doc.on \op, (ops, source) -> watch ops, source
      if !doc.type => doc.create ((if create => create! else null) or {})
    p.catch (e) ~>
      if e.code == \wrapped-lderror => e = new Error! <<< JSON.parse(e.message)
      Promise.reject e

  connect: ->
    if @_connection => return Promise.resolve!
    if @_ws.status! != 2 => @_ws.connect!
    # Should we wait until @_ws is connected? Probably don't have to.
    Promise.resolve!
      .then ~>
        @_sws = new ews ws: @_ws, scope: \sharedb
        @_connection = new sharedb.Connection @_sws

  disconnect: -> @_ws.disconnect!
  cancel: -> @_ws.cancel!
  status: -> @_ws.status!
  ensure: -> @_ws.ensure!

if module? => module.exports = ews.sdb-client
else if window? => window.ews.sdb-client = ews.sdb-client
