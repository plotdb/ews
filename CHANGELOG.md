# Change Logs

## v0.2.3

 - bind the `window offline` listener once instead of once per connection attempt. `_connect` runs again on every retry, so listeners accumulated for the life of the page and every one of them fired on the next offline event.
 - cap the reconnect backoff at 40s. the ladder grows as `count^1.4 * 500`, so a long outage left the next attempt minutes away - past a point it only delays recovery. reached on the 23rd attempt, about six minutes in; below that the ramp is unchanged.


## v0.2.2

 - fix bug: `dispose()` now delivers a final synthetic close event to consumers before detaching handlers. death may be declared while the raw ws is still half-open ( real close event not yet fired ); consumers detached without ever seeing a close kept a stale `connected` state - e.g., sharedb `Connection` then rejected the next `bindToSocket` with `ERR_CONNECTION_STATE_TRANSITION_INVALID` ( "Cannot transition directly from connected to connecting" ), forcing a page reload after reconnect.


## v0.2.1

 - upgrade dependencies
 

## v0.2.0

 - add `dispose()`: permanently detach an ews object - unsupervise from its source and remove all handlers it ever installed on any raw websocket, so a discarded ( e.g. scoped ) ews can never leak stale events to its consumer.
 - track raw websockets we installed listeners on ( `_iws` ), pruning fully-closed ones to avoid blocking GC.
 - sdb-client: sharedb `Connection` now survives disconnection - docs ( along with their pending / inflight ops ) are kept across reconnect. on reconnect a fresh scoped socket is bound via `bindToSocket`; sharedb then resubscribes ( catch-up by doc version ) and resends unacknowledged ops ( deduplicated by src / seq on server ) by itself. no need to recreate sdb-client per reconnect anymore.
 - sdb-client: a socket declared dead is disposed immediately, so late events from a stale session ( half-open socket revived, buffered close, orphan replies ) can no longer reach sharedb. this fixes orphan-reply crashes in `_handleSubscribe` and `ERR_CONNECTION_STATE_TRANSITION_INVALID` during reconnect.
 - NOTE: with a persistent connection, re-`get`ting the same doc on every reconnect becomes an anti-pattern ( duplicate subscription; risk of orphan-reply crashes ). just call `ensure()` and let sharedb resync - or use `@plotdb/datahub` >= 0.7.0, which handles this correctly.


## v0.1.0

 - pass close event info (code, reason, wasClean) as `info` object when firing `offline` event.
 - `disconnect` now accepts an `info` object and forwards it to the `offline` event.
 - pass `{src: "browser-offline"}` as info when offline is triggered by browser's offline event.


## v0.0.20

 - use `op batch` instead of `op` event for batching ops, to prevent conceptual atomic transactions such as object moving from being tear apart into string editing, causing rendering issue.
 - separate sharedb bundle tool from build script to a standalone package.json


## v0.0.19

 - support `interval` option in `ping` api, and `pingInterval` option in ews constructor.
 - change minimal ping interval from 60s to 20s.


## v0.0.18

 - watch for `Connection` errors so caller can handle those errors.


## v0.0.17

 - prevent calling `close` and `send` without `_ws`
 - make `close-handler` work only if event source = `_ws`
 - use `on` instead of `addEventListener` for `offline` event


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
