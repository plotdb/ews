(function(){
  ews.sdbClient = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    import$(this, {
      _evthdr: {},
      _connection: null,
      _sws: null,
      _ws: opt.ws
    });
    this._ws.on('offline', function(){
      return this$._onBroken();
    });
    this._ws.addEventListener('close', function(){
      return this$._onBroken();
    });
    return this;
  };
  ews.sdbClient.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var this$ = this;
      return (Array.isArray(n)
        ? n
        : [n]).map(function(n){
        var ref$;
        return ((ref$ = this$._evthdr)[n] || (ref$[n] = [])).push(cb);
      });
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this._evthdr[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    _onBroken: function(){
      if (!this._sws) {
        return;
      }
      this._releaseSws();
      return this.fire('close');
    },
    _releaseSws: function(){
      if (!this._sws) {
        return;
      }
      this._sws.dispose();
      return this._sws = null;
    },
    _bind: function(){
      var this$ = this;
      if (this._sws) {
        return;
      }
      this._sws = new ews({
        ws: this._ws,
        scope: 'sharedb'
      });
      if (!this._connection) {
        this._connection = new sharedb.Connection(this._sws);
        return this._connection.on('error', function(err){
          return this$.fire('error', {
            err: err
          });
        });
      } else {
        return this._connection.bindToSocket(this._sws);
      }
    },
    connect: function(){
      var this$ = this;
      return Promise.resolve().then(function(){
        if (this$._ws.status() !== 2) {
          return this$._ws.connect();
        } else {
          return null;
        }
      }).then(function(){
        return this$._bind();
      });
    },
    ensure: function(){
      return this.connect();
    },
    getSnapshot: function(arg$){
      var id, version, collection, this$ = this;
      id = arg$.id, version = arg$.version, collection = arg$.collection;
      return new Promise(function(res, rej){
        return this$._connection.fetchSnapshot(collection != null ? collection : 'doc', id, version != null ? version : null, function(e, s){
          if (e) {
            return rej(e);
          } else {
            return res(s);
          }
        });
      });
    },
    get: function(arg$){
      var id, watch, create, collection, this$ = this;
      id = arg$.id, watch = arg$.watch, create = arg$.create, collection = arg$.collection;
      return this.ensure().then(function(){
        var p;
        p = new Promise(function(res, rej){
          var doc;
          doc = this$._connection.get(collection != null ? collection : 'doc', id);
          return doc.fetch(function(e){
            if (e) {
              return rej(e);
            }
            doc.subscribe(function(ops, source){
              return res(doc);
            });
            doc.on('error', function(err){
              return this$.fire('error', {
                doc: doc,
                err: err
              });
            });
            if (watch != null) {
              doc.on('op batch', function(ops, source){
                return watch(ops, source);
              });
            }
            if (!doc.type) {
              return doc.create((create ? create() : null) || {});
            }
          });
        });
        return p['catch'](function(e){
          if (e.code === 'wrapped-lderror') {
            e = import$(new Error(), JSON.parse(e.message));
          }
          return Promise.reject(e);
        });
      });
    },
    disconnect: function(){
      return this._ws.disconnect();
    },
    cancel: function(){
      return this._ws.cancel();
    },
    status: function(){
      return this._ws.status();
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = ews.sdbClient;
  } else if (typeof window != 'undefined' && window !== null) {
    window.ews.sdbClient = ews.sdbClient;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
