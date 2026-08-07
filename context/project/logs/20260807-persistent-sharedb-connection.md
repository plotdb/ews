# 持久化 sharedb 連線與 dispose 機制 ( v0.2.0 - v0.2.2 )

起因: 下游採用 sharedb 做即時同步的表單應用回報, websocket 瞬斷時
使用者剛輸入、尚未同步的資料會在重連後被 server 資料蓋掉而消失。
追查後確認資料遺失的根源不在應用層, 而是 `sdb-client` 在斷線時主動
銷毀 sharedb `Connection` 與 doc, 使 sharedb 內建的 `pendingOps` /
`inflightOp` 重送機制完全沒有發揮的機會。


## 核心認知

 - 斷線無法即時得知。TCP `send()` 成功只代表資料進了 kernel buffer,
   半開連線 ( 對端已死但本地不知 ) 可以持續存在十幾秒, 直到 ping /
   watchdog 逾時才被宣告。因此正確設計不是「更快偵測」, 而是
   ack + 重送 + 冪等 ( sharedb 的 `inflightOp` / `pendingOps` /
   `(src, seq)` 去重正是這三件套 )。
 - ews 本身就是 sharedb 生態期待的 reconnecting-socket 門面:
   門面物件永久存活, 底下 raw ws 可拋棄式更換, listener 由 `_evthdr`
   保存並於重連時重掛。基礎設施原本就支援持久連線, 是上層自己拆掉的。


## 變更內容

### v0.2.0

 - `sdb-client`: offline / close 時不再清除 `_connection`。
   斷線時僅廢棄 scoped socket ( `_sws` ), Connection 與其名下所有
   doc ( 含 pending / inflight ops ) 跨斷線存活。
 - `sdb-client`: 重連時建立新的 scoped socket 並以 `bindToSocket`
   重綁 — sharedb 官方的重連路徑。之後 sharedb 自行 resubscribe
   ( 依 doc version 補漏掉的 ops ) 並重送未確認的 ops
   ( server 依 `(src, seq)` 去重, 半開時代送出但沒 ack 的 op 不會重複套用 )。
 - `dispose()`: 廢棄一個 ews ( 通常是 scoped 子 ews ) — 從 root 的
   `_svl` 除名 + 拆掉曾裝在任何 raw ws 上的 handler。
   被宣告死亡的 socket 從此不能再對 consumer 說話, 解掉兩類亡靈事件:
   `_handleSubscribe` 收到孤兒回覆 crash ( sharedb 對 `inflightSubscribe`
   為 null 沒有防禦 ), 以及遲到的 open / close 打亂 Connection 狀態機。
 - `_iws`: 各 ews 自行記錄「曾把 listener 裝在哪些 raw ws 上」。
   必要性: root 的 close-handler 會在 fire `offline` 之前先把受監管
   子 ews 的 `_ws` 清成 null, 所以 dispose 時不能依賴 `_ws`。
   同時修剪 readyState 3 的死 ws 以免擋住 GC。

### v0.2.2

 - `dispose()` 拆手前先補送一個合成 close ( `code: 4000`,
   `reason: 'disposed'` ) 給尚未收到 close 的 listener。
   原因: 手動宣告死亡是同步的, raw ws 真實 close 事件是非同步的
   ( 半開時甚至可能永遠不來 ); v0.2.0 的 dispose 拆得太乾淨,
   sharedb 永遠看不到 close, Connection state 卡在 `connected`,
   下次 `bindToSocket` 內部的 `_setState('connecting')` ( 有狀態機驗證,
   並非直接賦值 ) 便拋出 `ERR_CONNECTION_STATE_TRANSITION_INVALID`。
   sharedb 的 close 處理是冪等的 ( 同狀態 early return ), 重複收到無害。


## 使用面注意

 - `sdb-client` 建一次即可, 斷線後呼叫 `ensure()`; 「每次重連重新
   `get()` 同一個 doc」在持久連線下是反模式 ( 重複 subscribe,
   會觸發孤兒回覆 crash )。搭配 `@plotdb/datahub` >= 0.7.0 已正確處理。
 - 測試半開連線的方法:
   - console 猴子補丁: `WebSocket.prototype.send` 靜音, 最方便;
   - `kill -STOP <server-pid>`: kernel 仍回 TCP ACK 但應用層無回應;
   - pf: `echo "block drop quick proto tcp from any to any port <port>" | sudo pfctl -ef -`。


## 發佈

npm `@plotdb/ews` 0.2.2, github release 同步。相關 commit:
`bec96b9` ( v0.2.0 ), `c7128c4` ( v0.2.2 )。
