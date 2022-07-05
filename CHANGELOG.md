# Change Logs

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
