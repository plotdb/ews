# `cancel` 讓 connect 的 promise 永不 settle

進 `cancel` 的路徑只有一條：`window offline` → `disconnect`（`_s == 1`）→ `cancel`。
走哪個分支只看當下 `cc.hdr` 是不是 null：

- **在 backoff 等待中**（`cc.hdr` 有值）：清掉 timer、`_status 0`，但 `cc.pending`
  沒 settle。呼叫端（`@servebase/connector` 的 `open!`）永遠等不到答案，`_running`
  就永久 latch 住。
- **`_connect` 進行中**（`cc.hdr` 是 null）：設 `canceller`。若那次握手其實成功了，
  open handler 只 `rej(err 0)` 而沒清掉 `@_ws` —— 留下一個活著的 socket。下次
  `_connect` 看到它就 `rej(err 1011)`，retry loop 讀成「別人在連」而 `return`，
  一樣不 settle。`_s` 卡在 1 且無 timer，連 offline cover 的「立刻重試」都失效
  （`connect {now: true}` 會從自己的 `_s == 1` 守衛掉下去）。

## 影響

不是無聲 —— cover 在，5 秒後有「重新載入頁面」，`@servebase/connector` 的
`_safeguard` 也會在 23 秒後宣告終局。使用者按 reload 就過得去，所以不急。
代價是 cover 上寫的「嘗試重新連線 ...」是假的：沒有任何東西在重試。

## 打算怎麼改

1. `disconnect` 在 `_s == 1` 時直接 return —— 砍掉進行中的連線買不到任何東西
   （真的斷了那次嘗試自己會失敗），卻會毀掉重試迴圈。這一刀切掉上面兩條的唯一入口。
2. `_connect` 的 open handler 在 cancel 路徑上把 socket 收乾淨（`@_ws = null`、
   `close!`）再 reject。
3. 防禦性：`cancel` 的 hdr 分支與 retry loop 的 1011 分支都補上
   `cc.pending.splice 0 .map -> it.rej!`；順便把 `if it and it.id and it.id == 1011`
   改成 `it?.id == 1011`（原式靠 `err 0` 的 id 為 falsy 才掉進重試分支，是巧合）。

注意 3 會讓 `open!` 在以前會掛住的地方改成 reject，而 connector 的 `reopen` catch
是終局的 —— 有了 1 之後這條路徑不會被 offline 事件走到，但要一起想過。
