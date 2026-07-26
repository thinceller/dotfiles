# herdr integration (Claude Code): `herdr integration install claude` が
# 書き出す hook 群と等価。上流 (ogulcancelik/herdr,
# src/integration/assets/claude/herdr-agent-state.sh) を vendor しており、
# HERDR_INTEGRATION_VERSION=7。上流で version が bump されたらファイルごと更新する。
{ pkgs }:
let
  herdrAgentStateScript = pkgs.writeShellScript "claude-herdr-agent-state" (
    builtins.readFile ./hooks/herdr-agent-state.sh
  );

  # herdr sidebar に直近使用した tool 名 + 短い要約を表示するための PreToolUse hook。
  # configs/.config/herdr/config.toml の rows_by_agent.claude 4 行目 ($tool) と対応する。
  herdrToolMetadataScript = pkgs.writeShellScript "claude-herdr-tool-metadata" (
    builtins.readFile ./hooks/herdr-tool-metadata.sh
  );

  # `herdr integration install claude` が settings.json に登録する hook 群
  # (src/integration/targets.rs::install_claude と一致)。
  herdrClaudeHook = arg: {
    matcher = "*";
    hooks = [
      {
        type = "command";
        command = "${herdrAgentStateScript} ${arg}";
        timeout = 10;
      }
    ];
  };
in
{
  hooks = {
    SessionStart = [ (herdrClaudeHook "session") ];
    Stop = [ (herdrClaudeHook "idle") ];
    SubagentStop = [ (herdrClaudeHook "working") ];
    SessionEnd = [ (herdrClaudeHook "release") ];
    UserPromptSubmit = [ (herdrClaudeHook "working") ];
    PreToolUse = [ (herdrClaudeHook "working") ];
    PostToolUse = [ (herdrClaudeHook "working") ];
  };
  toolMetadataScript = herdrToolMetadataScript;
}
