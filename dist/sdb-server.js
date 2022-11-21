(function(){
  var sharedb, sharedbPostgres, sharedbPgMdb, ws, http, websocketJsonStream, ews, lderrorWrapper, sdbServer;
  sharedb = require('sharedb');
  sharedbPostgres = require('@plotdb/sharedb-postgres');
  sharedbPgMdb = require('sharedb-pg-mdb');
  ws = require('ws');
  http = require('http');
  websocketJsonStream = require('websocket-json-stream');
  ews = require("./index");
  lderrorWrapper = function(e){
    if (!e) {
      e = {
        name: 'lderror',
        id: 1012
      };
    }
    if (e.name !== 'lderror') {
      return e;
    } else {
      return {
        code: "wrapped-lderror",
        message: JSON.stringify({
          id: e.id,
          name: e.name,
          message: e.message
        })
      };
    }
  };
  sdbServer = function(opt){
    var app, io, session, access, milestoneDb, wss, metadata, server, mdb, backend, connect, ret;
    app = opt.app, io = opt.io, session = opt.session, access = opt.access, milestoneDb = opt.milestoneDb, wss = opt.wss, metadata = opt.metadata;
    server = null;
    mdb = milestoneDb && milestoneDb.enabled ? new sharedbPgMdb({
      ioPg: io,
      interval: milestoneDb.interval || 250
    }) : null;
    backend = new sharedb({
      db: sharedbPostgres(io),
      milestoneDb: mdb
    });
    connect = backend.connect();
    if (!wss) {
      server = http.createServer(app);
      wss = new ws.Server({
        server: server
      });
    }
    wss.on('connection', function(ws, req){
      var p, sws;
      p = session != null
        ? new Promise(function(res, rej){
          return session(req, {}, function(){
            return res();
          });
        })
        : Promise.resolve();
      sws = new ews({
        ws: ws,
        scope: 'sharedb'
      });
      p.then(function(){
        var wjs;
        return backend.listen(wjs = websocketJsonStream(sws), req);
      })['catch'](function(e){
        return console.log("[sdb-server] wss on connection error: ", e.message, e);
      });
      return ws.on('close', function(){});
    });
    backend.use('connect', function(arg$, cb){
      var agent, req, stream, session, user, ref$;
      agent = arg$.agent, req = arg$.req, stream = arg$.stream;
      if (!req || !stream.ws) {
        return cb();
      }
      session = req.session;
      user = (session && session.passport && session.passport.user) || {};
      ref$ = agent.custom;
      ref$.req = req;
      ref$.session = session;
      ref$.user = user;
      return cb();
    });
    if (metadata != null) {
      backend.use('commit', function(arg$, cb){
        var collection, agent, snapshot, op, id, ref$, req, session, user;
        collection = arg$.collection, agent = arg$.agent, snapshot = arg$.snapshot, op = arg$.op, id = arg$.id;
        if (!agent.stream.ws) {
          return cb();
        }
        ref$ = agent.custom, req = ref$.req, session = ref$.session, user = ref$.user;
        metadata(import$({
          m: op.m
        }, agent.custom));
        return cb();
      });
    }
    if (access != null) {
      backend.use('readSnapshots', function(arg$, cb){
        var agent, collection, snapshots, id;
        agent = arg$.agent, collection = arg$.collection, snapshots = arg$.snapshots;
        if (!agent.stream.ws) {
          return cb();
        }
        id = snapshots.length > 1
          ? null
          : snapshots[0].id;
        return access(import$({
          id: id,
          collection: collection,
          snapshots: snapshots,
          type: 'readSnapshots'
        }, agent.custom)).then(function(){
          return cb();
        })['catch'](function(e){
          return cb(lderrorWrapper(e));
        });
      });
      backend.use('submit', function(arg$, cb){
        var collection, agent, op, id;
        collection = arg$.collection, agent = arg$.agent, op = arg$.op, id = arg$.id;
        if (!agent.stream.ws) {
          return cb();
        }
        return access(import$({
          id: id,
          collection: collection,
          op: op,
          type: 'submit'
        }, agent.custom)).then(function(){
          return cb();
        })['catch'](function(e){
          return cb(lderrorWrapper(e));
        });
      });
    }
    return ret = {
      server: server,
      sdb: backend,
      connect: connect,
      wss: wss
    };
  };
  module.exports = sdbServer;
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
