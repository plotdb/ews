ews = (o = {}) ->
  @_src = o.src
  @ <<< o{scheme, domain, path}
  @_url = if o.url => o.url
  else if (!o.ws) => "#{@scheme or \ws}://#{@domain or window.location.host}#{@path or ''}"
  else null
  @_ws = if o.ws => o.ws else if @url => new WebSocket(@url) else null
  if @_ws and !@_url => @_url = @_ws.url
  @_scope = o.scope
  @

# essential websocket APIs
ews.prototype = Object.create(Object.prototype) <<<
  addEventListener: (t, cb, o) -> @_ws.addEventListener t, cb, o
  dispatchEvent: (evt) -> @_ws.dispatchEvent evt
  removeEventListener: (t, cb, o) -> @_ws.removeEventListener t, cb, o
  close: (c, r) -> @_ws.close c, r
  # format message in "scope|data". accept string only for now
  send: (d) -> @_ws.send "#{@_scope or ''}|#d"

# essential websocket properties
Object.defineProperties ews.prototype, {
  bufferedAmount: get: -> @_ws.bufferedAmount
  binaryType: get: -> @_ws.binaryType
  protocol: get: -> @_ws.protocol
  readyState: get: -> @_ws.readyState
  url: get: -> @_ws.url
}

# extended websocket APIs
ews.prototype <<<
  ws: -> @_ws
  pipe: (s = '') -> new ews({ws: @_ws, scope: "#{@_scope}/#s", src: @})
  connect: (url, revive) ->
  disconnect: (revive) ->
