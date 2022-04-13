err = (e) -> new Error! <<< {name: \lderror, id: e}

ews = (o = {}) ->
  @_src = o.src
  @ <<< {_scheme: o.scheme, _domain: o.domain, _path: o.path}

  if o.url and !o.ws =>
    @_url = o.url
    if (r = /^(\S+):\/\/([^\s\/]+)\/(.+)$/.exec(@_url)) =>
      @ <<< {_scheme: r.0, _domain: r.1, _path: r.2}

  @_scheme = if @_scheme => @_scheme
  else if (window? and window.location.protocol) => window.location.protocol.replace(':', '')
  else \wss
  if @_scheme.startsWith \https => @_scheme = \wss
  else if @_scheme.startsWith \http => @_scheme = \ws

  @_domain = @_domain or if window? => window.location.host else null
  @_path = if !@_path => \/ else if @_path[0] != \/ => "/#{@_path}" else @_path

  if o.ws => @_ws = if o.ws instanceof ews => o.ws.ws! else o.ws
  if !(@_ws or @_url) => @_url = "#{@_scheme}://#{@_domain}#{@_path}"
  if !@_ws and @_url => @_origin = true
  @_scope = o.scope or ''
  @_evthdr = {}
  @_hdr = new WeakMap!
  @ <<<
    # connect controller
    _ctrl:
      count: 0
      pending: []
      hdr: null
      canceller: null
      disconnector: null
    # status. 0: disconnected. 1: connecting. 2: connected.
    _s: 0
  @

# essential websocket APIs
ews.prototype = Object.create(Object.prototype) <<<

  # we may add event listener before ws is created.
  # additionally, we may reconnect.
  # thus we keep all event listeners,
  # and `_installEventListeners` every time a new ws is created.
  addEventListener: (t, cb, o, fromon) ->
    if !(t in <[message open close error]>) => return
    @_evthdr.[][t].push {cb, o, fromon}
    @_installEventListener t, cb, o, fromon

  _installEventListener: (t, cb, o, fromon) ->
    if !@_ws => return
    if t != \message => return @_ws.addEventListener t, cb, (o or {})
    ((scope, fromon) ~>
      @_ws.addEventListener t, (hdr = (e) ~>
        if !e.data.startsWith("#{@_scope}|") => return
        data = e.data.substring(@_scope.length + 1)
        if fromon => return cb data
        evt = new MessageEvent \message, do
          data: data
          origin: e.origin
          ports: e.ports
          source: e.source
        cb evt
      ), (o or {})
      @_hdr.set cb, hdr
    )(@_scope, fromon)

  _installEventListeners: ->
    for t, list of @_evthdr => 
      for {cb, o, fromon} in list => @_installEventListener t, cb, o, fromon

  # TODO: wrap / unwrap scope?
  dispatchEvent: (evt) ->
    @_ws.dispatchEvent evt

  removeEventListener: (t, cb, o) ->
    @_evthdr[][t] = @_evthdr[t].filter -> it.h != cb
    if !@_ws => return
    if t != \message => return @_ws.removeEventListener t, cb, o
    @_ws.removeEventListener t, @_hdr.get(cb), o

  close: (c, r) -> @_ws.close c, r
  # format message in "scope|data". accept string only for now
  send: (d) -> @_ws.send "#{@_scope}|#d"

# essential websocket properties
Object.defineProperties ews.prototype, {
  bufferedAmount: get: -> if !@_ws => 0 else @_ws.bufferedAmount
  binaryType: get: -> if !@_ws => \blob else @_ws.binaryType
  protocol: get: -> if !@_ws => @_scheme else @_ws.protocol
  readyState: get: -> if !@_ws => 3 else @_ws.readyState
  url: get: -> if !@_ws => @_url else @_ws.url
  onmessage: set: (cb) -> @addEventListener \message, (evt) -> cb evt
  onopen: set: (cb) -> @addEventListener \open, cb
  onerror: set: (cb) -> @addEventListener \error, cb
  onclose: set: (cb) -> @addEventListener \close, cb
}


# extended websocket APIs
ews.prototype <<<
  on: (n, cb) ->
    if n in <[message open error close]> => return @addEventListener n, cb, null, true
    (if Array.isArray(n) => n else [n]).map (n) ~> @_evthdr.[][n].push cb
  fire: (n, ...v) ->
    if n in <[message open close error]> => throw new Error("fire should not be used to fire native events")
    for cb in (@_evthdr[n] or []) => cb.apply @, v
  ws: -> @_ws
  pipe: (s = '') -> new ews({ws: @_ws, scope: "#{@_scope}/#s", src: @})

  # resolves if connected. otherwise rejects.
  _connect: (opt = {}) -> new Promise (res, rej) ~>
    if @_ws => return rej(err 1011)
    if !@_url => return rej(err 1026)
    @_ws = new WebSocket @_url

    @_ws.addEventListener \close, ~>
      @_ws = null
      # Promise is resolved if ever connected so we don't reject.
      # Besides, `close` is fired only if ever connected.
      # if not yet connected, we are still connecting so we shouldn't fire close event.
      # additionally _s should be 1 and controlled by caller,
      # so we shouldn't touch it here.
      if @_s != 2 => return rej(err 0)
      # otherwise, it's a normal close event. we reset status and fire close event.
      @_status 0
      #@fire \close
      if @_ctrl.disconnector => @_ctrl.disconnector.res!
    @_ws.addEventListener \open, ~>
      if !@_ctrl.canceller => return res!
      @_ctrl.canceller.res!
      return rej(err 0)

    # must put after above listeners,
    # otherwise user listener cant get correct status information
    @_installEventListeners!

  connect: (opt = {}) ->
    cc = @_ctrl
    if @_s == 2 => return Promise.reject(err 1011)
    (res, rej) <~ new Promise _
    cc.pending.push {res, rej}
    if @_s == 1 => return
    @_status 1
    retry = !(opt.retry?) or !opt.retry
    cc.count = 0
    _ = ~>
      delay = Math.round(Math.pow(cc.count++, 1.4) * 500) + (opt.delay or 0)
      cc.hdr = setTimeout (~>
        cc.hdr = null
        console.log "reconnect ( #delay ms )"
        @_connect!
          .then ~>
            @_status 2
            cc.[]pending.splice 0 .map -> it.res!
          .catch ->
            if it and it.id and it.id == 1011 => return
            if retry and !cc.canceller => return _!
            cc.canceller = null
            cc.[]pending.splice 0 .map -> it.rej!
      ), delay
    _!

  disconnect: ->
    if @_s == 0 => return Promise.resolve!
    if @_s == 1 => return @cancel!
    ret = new Promise (res, rej) ~> @_ctrl.disconnector = {res, rej}
    # let _connect takes care of deinit tasks
    @_ws.close!
    ret

  cancel: ->
    cc = @_ctrl
    if @_s != 1 => return Promise.reject(err 1026)
    if cc.hdr =>
      clearTimeout cc.hdr
      cc.hdr = null
      @_status 0
      return Promise.resolve!
    # it's only possible to reach here if timer is fired yet _connect is ongoing.
    new Promise (res, rej) -> cc.canceller = {res, rej}

  _status: (s) ->
    os = @_s
    @_s = s
    if s != os => @fire \status, s

  status: -> return @_s
  ensure: -> if @_s == 2 => Promise.resolve! else @connect!


if module? => module.exports = ews
else if window? => window.ews = ews
