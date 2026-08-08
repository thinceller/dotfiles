# settings.json / CLAUDE.md を symlink でなく通常ファイルとしてコピー配備する。
# 理由: nix store への symlink は mtime=1970 のため Claude Code の retention cleanup に
# 「期限切れ」として削除される (cleanupPeriodDays=9999 でも、stat が symlink を辿るため
# 消える)。また read-only symlink では Claude 側からの設定書き込みが全て失敗する。
# コピー化で両方解消し、実行時に Claude が書いた変更 (drift) は activation 時に
# *.drift へ退避して claude-config-drift で確認できるようにする。
{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  # upstream モジュールのバージョン差異吸収:
  # master は home.file のキーが "${configDir}/settings.json" (絶対パス)、
  # release-25.11 は ".claude/settings.json" (相対パス)
  hasConfigDir = options.programs.claude-code ? configDir;
  settingsKey =
    if hasConfigDir then
      "${config.programs.claude-code.configDir}/settings.json"
    else
      ".claude/settings.json";
  memoryKey =
    if hasConfigDir then "${config.programs.claude-code.configDir}/CLAUDE.md" else ".claude/CLAUDE.md";
  # enable=false はリンク配備だけを止め、home.file.<name>.source の定義
  # (モジュールが jsonFormat.generate 等で組み立てた store path) はそのまま
  # 読める、という home-manager の評価順序に依存している。
  settingsSource = config.home.file.${settingsKey}.source;
  memorySource = config.home.file.${memoryKey}.source;

  claudeConfigDrift = pkgs.writeShellScriptBin "claude-config-drift" ''
    set -euo pipefail

    jq="${pkgs.jq}/bin/jq"
    diff="${pkgs.diffutils}/bin/diff"

    checkJson() {
      local name="$1" baseline="$2" current="$3" out
      if [ ! -f "$current" ]; then
        echo "$name: 配備されていません ($current)"
        return
      fi
      if [ ! -f "$baseline" ]; then
        echo "$name: baseline なし (未 rebuild)"
        return
      fi
      if out=$("$diff" -u --label nix-deployed --label current \
        <("$jq" -S . "$baseline") <("$jq" -S . "$current")); then
        echo "$name: drift なし"
      else
        echo "$name: drift あり"
        echo "$out"
      fi
    }

    checkText() {
      local name="$1" baseline="$2" current="$3" out
      if [ ! -f "$current" ]; then
        echo "$name: 配備されていません ($current)"
        return
      fi
      if [ ! -f "$baseline" ]; then
        echo "$name: baseline なし (未 rebuild)"
        return
      fi
      if out=$("$diff" -u --label nix-deployed --label current "$baseline" "$current"); then
        echo "$name: drift なし"
      else
        echo "$name: drift あり"
        echo "$out"
      fi
    }

    checkJson "settings.json" "$HOME/.claude/.nix-deployed-settings.json" "$HOME/.claude/settings.json"
    checkText "CLAUDE.md" "$HOME/.claude/.nix-deployed-CLAUDE.md" "$HOME/.claude/CLAUDE.md"

    for drift in "$HOME/.claude/settings.json.drift" "$HOME/.claude/CLAUDE.md.drift"; do
      if [ -f "$drift" ]; then
        echo "前回 rebuild 時に退避された drift があります: $drift"
      fi
    done

    exit 0
  '';
in
{
  # モジュールが生成する symlink 配備だけを無効化する (source の生成・内容はそのまま利用する)
  home.file.${settingsKey}.enable = false;
  home.file.${memoryKey}.enable = false;

  home.packages = [ claudeConfigDrift ];

  # linkGeneration の後: 旧世代の symlink 掃除が終わってからコピーを置く
  home.activation.claudeCodeDeployCopies = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    claudeDeploy() {
      local src="$1" dest="$2" baseline="$3" drift="$4"
      if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        # 通常ファイルが baseline (前回配備した内容) と異なる = Claude が実行時に書いた変更
        if { [ ! -f "$baseline" ] || ! cmp -s "$dest" "$baseline"; } && ! cmp -s "$dest" "$src"; then
          run cp -f "$dest" "$drift"
          warnEcho "claude-code: $dest に実行時変更があったため $drift に退避しました (claude-config-drift で確認)"
        fi
      fi
      run mkdir -p "$(dirname "$dest")"
      run rm -f "$dest"
      run install -m 600 "$src" "$dest"
      run install -m 600 "$src" "$baseline"
    }
    claudeDeploy "${settingsSource}" "$HOME/.claude/settings.json" "$HOME/.claude/.nix-deployed-settings.json" "$HOME/.claude/settings.json.drift"
    claudeDeploy "${memorySource}" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/.nix-deployed-CLAUDE.md" "$HOME/.claude/CLAUDE.md.drift"
  '';
}
