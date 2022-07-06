# @plotdb/ews

elastic websocket.


## Usage

Constructor options:

 - `ws`: websocket object to use. auto-greated if omitted and `url` is derivable.
 - `scheme`: scheme of the URL to use. ignored if `url` or `ws` is provided. default `ws` if omitted
 - `domain`: domain of the URL to use. ignored if `url` or `ws` is provided. `window.location.host` is used if omitted
 - `path`: path of the URL to use. ignored if `url` or `ws` is provided. default `` if omitted.
 - `url`: url for websocket connection.
   - ignored if `ws` is provided.
   - derived from `scheme`, `domain` and `path` above if both `ws` and `url` are omitted
 - `scope`: scope of this socket. default ``


API (ews):

 - `pipe(scope)`: return a scoped `ews` object piped from this ews object.
 - `ws()`: return the real websocket object used.
 - `ensure()`: ensure connection. return Promise, resolves when connected
 - `disconnect()`: disconnect websocket from server.
   - return Promise when disconnected.
 - `connect(opt)`: reconnect websocket if disconnected. return a Promise which is resolved when connected.
   - options:
     - `retry`: automatically retry if set to true. default true.
     - `delay`: delay ( in millisecond) before first connection attmpt. default 0
     - `now`: reset current reconnection attempts and start a new attempt immediately
 - `cancel()`: cancel connection. return Promise, resolves when connection canceled.
   - reject lderror 1026 if no connection to cancel.
 - `status()`: get connection status. return a integer with following possible values:
   - `0`: not connected
   - `1`: connecting
   - `2`: connected


API (from original WebSocket):

 - `send`
 - `close`
 - `addEventListener`
 - `dispatchEvent`
 - `removeEventListener`
 - `on`: (TBD) used by websocket-json-stream


## Sharedb

Sharedb is bundled in this repo, in following files:

 - `dist/sharedb.min.js`: standalone sharedb bundle, expose `sharedb` object.
 - `dist/sdb-client.min.js`: client side sharedb wrapper
 - `dist/sdb-server.min.js`: server side sharedb wrapper


### sdb-client

prepare a `ews` object:

      ws = new ews({url: ...});

create a sdb-client everytime the ews object (re)connected:

      ws.on("open", function() {
        sdb = new ews.sdb-client({ws: ws});
        sdb.connect().then( ... );
      });

Additionally, following events are available in sdb-client:

 - `close`: socket is closed.
 - `error`: fired when receiving `error` events from sharedb `Doc`


### sdb-server

use `http` and `ws` module to create a WebSocket server ( use `express` as example ):

    sdbServer = require("@plotdb/ews/sdb-server")
    app = express();
    server = http.createServer(express());
    wss = new ws.Server({ server: server });
    ret = sdb-server({io: {postgres configuration ...} , wss})
    wss.on("connection", function(ws, req) {
      /* you can still use the created ws object */
      var myws = new ews({ws});
      ...
    });


### Metadata

If `metadata(opt)` function is provided, it will be called when `commit` hook is triggered with an object including following parameters:

 - `m`: the metadata object from sharedb op.
 - `type`: either `readSnapshots` or `submit`.
 - `collection`: target collection.
 - `id`: target doc id. This will be null if there are multiple doc ids - in this case, check `snapshots` instead.
 - `req`: the express request object.
 - `session`: shorthand for `req.session` from `express-session`.
 - `user`: shorthand for `session.user` from `passport`.

edit the `m` field directly to inject necessary metadata. For example, add user id:

    metadata = ({m, user, session, collection, id, snaptshos}) -> m.user = (if user? => user.key else 0)


### Access Control

If `access` is function provided, it will be called in following hooks:

 - `readSnapshots`
 - `submit`

`access(opt)` is called with an object containing following paramters:

 - `type`: either `readSnapshots` or `submit`.
 - `collection`: target collection.
 - `id`: target doc id. This will be null if there are multiple doc ids - in this case, check `snapshots` instead.
 - `snapshots`: array of snapshots. Only provided when called by `readSnapshots` hook.
 - `req`: the express request object.
 - `session`: shorthand for `req.session` from `express-session`.
 - `user`: shorthand for `session.user` from `passport`.

`access(opt)` should return a Promise which only resolve when access is granted. By default the returned promise reject a lderror id 1012 error when access is denied.

Here is an example to prevent new document creation: 

    access = ({snapshots}) ->
      if snapshots and !(snapshots.0.id) =>
        return lderror.reject 1012
      return Promise.resolve!

Please note that ShareDB logs rejected errors (by recognizing its `stack` attribute) and wrap errors in `{code, message}` format. Consider rejecting a plain lderror object as above example, `@plotdb/ews` will wrap/parse your lderror objects for you so you can receive a correct lderror object in frontend.



## License

MIT
