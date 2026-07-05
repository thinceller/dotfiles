import type { Plugin } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";
import { writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Mnemos: セッション終了ごとに vault へセッションログを自動記録する。
// 実処理は共用 worker (vault-session-log-worker, PATH 上。実体は
// home-manager/programs/claude-code/scripts/vault-session-log-worker.sh) が担う。
// デバウンス・サイズゲート・多重起動ロック・冪等な上書き更新は worker 側の責務。
// ここは client.session.messages を JSON に書き出して worker を起動するだけの薄い入口。
const AGENT = "OpenCode";

const runWorker = (sessionID: string, transcriptPath: string, final: boolean) => {
  const args = [AGENT, sessionID, transcriptPath, ...(final ? ["--final"] : [])];
  const child = spawn("vault-session-log-worker", args, {
    stdio: "ignore",
    detached: true,
  });
  child.on("error", () => {});
  child.unref();
};

export const VaultSessionLog: Plugin = async ({ client }) => {
  // server.instance.disposed には sessionID が乗らないため、
  // session.idle で見たセッションを覚えておいて dispose 時にまとめて処理する。
  const seenSessions = new Set<string>();

  const dumpTranscript = async (sessionID: string): Promise<string | null> => {
    const result = await client.session.messages({ path: { id: sessionID } });
    if (!result.data) return null;
    const path = join(tmpdir(), `opencode-session-${sessionID}.json`);
    await writeFile(path, JSON.stringify(result.data));
    return path;
  };

  return {
    event: async ({ event }) => {
      try {
        if (event.type === "session.idle") {
          const { sessionID } = event.properties;
          seenSessions.add(sessionID);
          const transcriptPath = await dumpTranscript(sessionID);
          if (transcriptPath) runWorker(sessionID, transcriptPath, false);
        } else if (event.type === "server.instance.disposed") {
          for (const sessionID of seenSessions) {
            const transcriptPath = await dumpTranscript(sessionID);
            if (transcriptPath) runWorker(sessionID, transcriptPath, true);
          }
        }
      } catch (err) {
        // OpenCode 本体を止めないよう握りつぶす。
        console.error("[vault-session-log]", err);
      }
    },
  };
};
