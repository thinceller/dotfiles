import { spawn } from "node:child_process";
import { writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Mnemos: セッションが一定時間 idle のままになったら vault へセッションログを自動記録する。
// 実処理は共用 worker (vault-session-log-worker, PATH 上。実体は
// home-manager/programs/claude-code/scripts/vault-session-log-worker.sh) が担う。
// サイズゲート・多重起動ロック・冪等な上書き更新は worker 側の責務。
// ここは ctx.session.context を JSON に書き出して worker を起動するだけの薄い入口。
// @opencode/plugin を import せず plain object で定義する (ローカル plugin から解決できる保証がないため)。
//
// v1 は TUI 終了 (server.instance.disposed) で --final 記録していたが、v2 の plugin は常駐
// background service 上で動き unload がほぼ起きない。代わりに IDLE_MS 続いた idle を
// セッションの区切りとみなして --final で記録する (worker の debounce を経由すると
// 最初の記録以降の作業が残らないため)。
const AGENT = "OpenCode";
const IDLE_MS = 10 * 60 * 1000;

const runWorker = (sessionID: string, transcriptPath: string) => {
  const child = spawn("vault-session-log-worker", [AGENT, sessionID, transcriptPath, "--final"], {
    stdio: "ignore",
    detached: true,
  });
  child.on("error", () => {});
  child.unref();
};

export default {
  id: "thinceller.vault-session-log",
  setup(ctx: any) {
    const controller = new AbortController();
    const timers = new Map<string, ReturnType<typeof setTimeout>>();

    const record = async (sessionID: string) => {
      timers.delete(sessionID);
      try {
        const messages = await ctx.session.context({ sessionID });
        const path = join(tmpdir(), `opencode-session-${sessionID}.json`);
        await writeFile(path, JSON.stringify(messages));
        runWorker(sessionID, path);
      } catch (err) {
        // OpenCode 本体を止めないよう握りつぶす。
        console.error("[vault-session-log]", err);
      }
    };

    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type !== "session.status") continue;
        // plugin は location ごとに読み込まれるが event は全 location 分届くので、自分の分だけ扱う。
        if (event.location && event.location.directory !== ctx.location.directory) continue;
        const { sessionID, status } = event.data;
        clearTimeout(timers.get(sessionID));
        timers.delete(sessionID);
        if (status?.type === "idle") timers.set(sessionID, setTimeout(() => void record(sessionID), IDLE_MS));
      }
    })().catch(() => {});

    return () => {
      controller.abort();
      for (const timer of timers.values()) clearTimeout(timer);
    };
  },
};
