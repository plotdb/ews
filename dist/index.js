(function(){
  var ews, ref$;
  ews = function(o){
    o == null && (o = {});
    this._src = o.src;
    this.scheme = o.scheme;
    this.domain = o.domain;
    this.path = o.path;
    this._url = o.url
      ? o.url
      : !o.ws ? (this.scheme || 'ws') + "://" + (this.domain || window.location.host) + (this.path || '') : null;
    this._ws = o.ws
      ? o.ws
      : this.url ? new WebSocket(this.url) : null;
    if (this._ws && !this._url) {
      this._url = this._ws.url;
    }
    this._scope = o.scope;
    return this;
  };
  ews.prototype = (ref$ = Object.create(Object.prototype), ref$.addEventListener = function(t, cb, o){
    return this._ws.addEventListener(t, cb, o);
  }, ref$.dispatchEvent = function(evt){
    return this._ws.dispatchEvent(evt);
  }, ref$.removeEventListener = function(t, cb, o){
    return this._ws.removeEventListener(t, cb, o);
  }, ref$.close = function(c, r){
    return this._ws.close(c, r);
  }, ref$.send = function(d){
    return this._ws.send((this._scope || '') + "|" + d);
  }, ref$);
  Object.defineProperties(ews.prototype, {
    bufferedAmount: {
      get: function(){
        return this._ws.bufferedAmount;
      }
    },
    binaryType: {
      get: function(){
        return this._ws.binaryType;
      }
    },
    protocol: {
      get: function(){
        return this._ws.protocol;
      }
    },
    readyState: {
      get: function(){
        return this._ws.readyState;
      }
    },
    url: {
      get: function(){
        return this._ws.url;
      }
    }
  });
  ref$ = ews.prototype;
  ref$.ws = function(){
    return this._ws;
  };
  ref$.pipe = function(s){
    s == null && (s = '');
    return new ews({
      ws: this._ws,
      scope: this._scope + "/" + s,
      src: this
    });
  };
  ref$.connect = function(url, revive){};
  ref$.disconnect = function(revive){};
}).call(this);
