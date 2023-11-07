# Change Logs

## v0.0.16

 - due to untrustable `close` event, we move close event handler to a standalone function, and call it from both close and offline event.


## v0.0.15

 - fire `offline` event when offline event received from window.
 - upgrade dependencies


## v0.0.14

 - support `ping` function, which send `ping` message to server every 60s by default if page is visible
 - fix bug: `status()` should query status from `_src` if this is a scoped ws.


## v0.0.13

 - pass `op` parameter from middleware `submit` action to access function for fine-grained access control


## v0.0.12

 - fix bug: ws refresh causes ews losing event handlers.


## v0.0.11

 - fix bug: pipe create new ews which depends on source ws, however source ws may update, may not ready yet,
   lead to unusable piped ews. additional tracing from root ews is added to update the whole ews pipe tree.
 - upgrade dependencies


## v0.0.10

 - wrap lderror in sharedb error format so we can't decode it back to a lderror object in client side.


## v0.0.9

 - remove `id` from `access` function in readSnapshots for multi-snapsthos scenario
 - support `submit` hook for access checking
 - support metadata injection with `metadata` called with `commit` hook.
 - refind document for `access` and `metadata` parameters.


## v0.0.8

 - support immediately reconnect option


## v0.0.7

 - fire `close` event in sharedb client when socket closed
 - document events in sharedb client


## v0.0.6

 - fix bug: disconnect handler doesn't correctly clean up internal variables


## v0.0.5

 - again add missing dependency `ws` for server side usage


## v0.0.4

 - add missing dependencies for server side usage


## v0.0.3

 - internal event listeners should be run before user event listeners
 - fix bug: `_scheme` incorrect set
 - fix bug: `_ws` should be cleared when socket closes.


## v0.0.2

 - addEventListener with default `{}` option if option is null.
   - without this, `ws` version > 8 may fail due to incorrectly initialization of option.
 - provide more information in error log

 
## v0.0.1

 - init release
