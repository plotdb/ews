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
 - `revive`: auto-reconnect if true. default true.


API (ews):

 - `pipe(scope)`: return a scoped `ews` object piped from this ews object.
 - `connect(url, revive)`: (re)connect if necessary.
   - `url`: reconnect to this url. optinal
   - `revive`: auto-reconnect if true. use `revive` in constructor option (default true) if omitted. default true
 - `ws()`: return the real websocket object used.
 - `disconnect(revive)`:
   - `revive`: auto-reconnect if true. overwrite `revive` in constructor option. default false.

API (from original WebSocket):

 - `send`
 - `close`
 - `addEventListener`
 - `dispatchEvent`
 - `removeEventListener`


## License

MIT
