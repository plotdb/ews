<-(->it.apply {}) _
channels = {}
messages = {}

@active = -> @doc and @ws and (@ws.status! == 2)
@init = ->
  @data = {}
  @ws = ws = new ews url: "ws://localhost:5100"
  ws.on \close, ~> @ <<< doc: null
  ws.on \status, -> console.log "status: ", it
  ws.on \status, (s) ~>
    if s != 2 => return
    channels.A = ws.pipe("A")
    channels.B = ws.pipe("B")
    channels.A.send "pipe A initialized"
    channels.B.send "pipe B initialized"
    channels.A.addEventListener \message, (evt) ~>
      messages.[]A.push evt.data; if @view => @view.render!
    channels.B.addEventListener \message, (evt) ~>
      messages.[]B.push evt.data; if @view => @view.render!

  @view = view = new ldview do
    root: document.body
    action:
      input:
        textarea: ({node}) ~>
          if !@active! => return
          cur = {data: node.value}
          @doc.submitOp json0.diff(@data, cur)
      click:
        disconnect: ~> @disconnect!
        reconnect: ~> @connect!
    handler:
      textarea: ({node}) ~> node.value = (@data or {}).data or ''
      channel:
        list: -> <[A B]>
        key: -> it
        view:
          action: click:
            send: ({ctx, views}) ~>
              console.log \there, @active!
              if !@active! => return
              console.log \here
              msg = views.0.get('message').value or 'n/a'
              channels[ctx].send msg
          handler:
            name: ({ctx}) -> "Channel #ctx"
            message:
              list: ({ctx}) -> messages[ctx]
              text: ({data}) -> data
  Promise.resolve!

@disconnect = -> @ws.disconnect!
@connect = ->
  @ws.connect!
    .then ~>
      console.log "connecting sdb..."
      @sdb = new ews.sdb-client ws: @ws
      @sdb.connect!
    .then ~>
      console.log "get sdb doc..."
      @sdb.get {
        id: \test
        watch: ~>
          console.log 'watch', it
          @view.render!
        create: -> {}
      }
    .then (doc) ~>
      @doc = doc
      @data = doc.data or {}
      @view.render!

@init!
  .then ~> @connect!
