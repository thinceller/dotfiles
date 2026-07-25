# oberon リモートエージェントコーディング環境 実装プラン

> **Status**: 未実装 (2026-07-26 設計完了)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iPhone (Moshi) / iPad Pro (Termius, Moshi) から Tailscale 経由で oberon に SSH/mosh 接続し、herdr 上で claude / opencode セッションを起動してリモートエージェントコーディングできるようにする。

**Architecture:**

- **接続レイヤー**: 既存の Tailscale SSH (有効化済み) をそのまま使う。スマホ側は Tailscale アプリ + Moshi/Termius から MagicDNS 名 `oberon` へ接続。モバイル回線の切断・ローミング対策として mosh を追加し、UDP 60000–61000 は `trustedInterfaces = [ "tailscale0" ]` で tailnet 内にのみ開放する (グローバルには開けない)。切断耐性は二段構え: 経路断は mosh、クライアント終了は herdr の `resume_agents_on_restore`
- **環境レイヤー**: oberon に home-manager (NixOS module) を導入。既存 home-manager 構成から portable なモジュール (bat/bottom/delta/direnv/fzf/gh/htop/hunk/jq/lazygit/lsd/ripgrep) はそのまま import し、darwin 依存が濃いモジュール (fish/git/claude-code/opencode) はサーバー版 (`server.nix`) を用意する。fish と claude-code は共通部分を抽出して darwin 版と共有する
- **リポジトリ**: gh + ghq で GitHub から clone。Mac と同じ `herdr-launch` (ghq + fzf) フローを再現
- **認証**: claude / opencode / gh は初回 SSH セッションで手動ログイン (OAuth トークンは生きた state なので sops 管理しない)
- **リソース**: 2GB RAM + 既存 4GiB swapfile に zram を追加。運用は同時 1〜2 エージェントまで

**Tech Stack:** NixOS (nixpkgs-stable 25.11), home-manager (master input を流用、release check off), Tailscale SSH, mosh, herdr, claude-code-bin (edgepkgs), opencode, gh/ghq

## Global Constraints

- oberon は `nixpkgs-stable` (nixos-25.11) を使う。unstable にしない
- oberon の deploy は on-server clone (`/home/thinceller/.dotfiles`) + **tmux 内**で `sudo nixos-rebuild switch` (memory: `feedback_oberon_deploy_methods`)。`nixos-rebuild test` は使用禁止 (credentials 永続消失 Issue #161072)
- 新規ファイルは `nix build` / `nix eval` 前に `git add` する (Flakes は git 管理下のファイルしか見えない)
- Mac 側 (kohei-m4-mac-mini / SC-N-843) の挙動を変えない。リファクタ後に darwin 両ホストのビルドが通ることを確認する
- firewall のグローバル開放はしない (mosh UDP も tailscale0 のみ)
- sshd の 127.0.0.1 バインド / cloudflared / network 設定には触れない

## 実装前の確認事項

1. `programs.mosh.openFirewall` オプションが nixos-25.11 に存在するか (`nix eval` で判明する。無ければ `programs.mosh.enable` のみにして、firewall は trustedInterfaces 任せで問題ない — mosh module のグローバル開放を打ち消す形になるが tailnet 経由なら実害なし。むしろ openFirewall が default true の場合は明示 false が必須)
2. `gh-prism` / `hunk` の homeManagerModules が x86_64-linux で評価できるか (Task 9 の eval で判明)
3. HM master module + nixpkgs-stable pkgs の組み合わせで `programs.claude-code` / `programs.opencode` が評価できるか (同上)

---

### Task 1: NixOS 側 — mosh / zram / fish login shell / tailscale0 trusted

**Files:**
- Modify: `hosts/oberon/configuration.nix`
- Modify: `hosts/oberon/tailscale.nix`
- Modify: `hosts/oberon/users.nix`

**Interfaces:**
- Produces: oberon システムに mosh-server / zram / fish login shell。以降の Task の前提

- [ ] **Step 1: configuration.nix に mosh / zram / fish を追加**

`hosts/oberon/configuration.nix` の `swapDevices` の後に追加:

```nix
  # zram: 2GB RAM でエージェント (claude/opencode) を回すための圧縮スワップ。
  # 既存の /swapfile (4GiB, ディスク) より優先度が高く、先に zram が使われる。
  zramSwap.enable = true;

  # mosh: スマホ (Moshi アプリ) からの接続でモバイル回線の切断・ローミングを
  # 吸収する。UDP 60000-61000 のグローバル開放はせず、tailscale0 を
  # trustedInterfaces に入れることで tailnet 内からのみ到達可能にする
  # (tailscale.nix 参照)。
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # herdr / home-manager のユーザー環境は fish 前提 (herdr config の
  # default_shell = "fish")。login shell 登録のため system 側でも有効化する。
  programs.fish.enable = true;
```

- [ ] **Step 2: tailscale.nix に trustedInterfaces を追加**

`hosts/oberon/tailscale.nix` の `services.tailscale = { ... };` ブロックの後に追加:

```nix
  # tailnet 内からの通信 (mosh の UDP 60000-61000 等) を無条件で許可する。
  # 到達できるのは tailnet に参加した自分のデバイスのみなので、
  # グローバル firewall は閉じたまま個別ポート開放が不要になる。
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
```

- [ ] **Step 3: users.nix で login shell を fish に変更**

`hosts/oberon/users.nix` の `users.users.${userConfig.username}.hashedPasswordFile = ...;` の直後に追加 (`pkgs` を引数に追加すること):

```nix
  # Tailscale SSH / mosh でログインした時のシェル。herdr・home-manager の
  # fish 設定 (abbr / prompt / completion) をそのまま使えるようにする。
  users.users.${userConfig.username}.shell = pkgs.fish;
```

ファイル先頭の引数を `{ config, userConfig, ... }:` から `{ config, pkgs, userConfig, ... }:` に変更。

- [ ] **Step 4: eval 検証**

```bash
git add -A
nix eval --raw .#nixosConfigurations.oberon.config.system.build.toplevel.drvPath
```

Expected: drvPath が出力される (エラーなし)。`programs.mosh.openFirewall` が存在しない場合はここでエラーになるので、その時は `openFirewall = false;` 行を削除して mosh module のソースを確認する。

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(oberon): mosh + zram + fish login shell を追加"
```

---

### Task 2: fish 設定の共通部分抽出 (darwin / server 共有)

**Files:**
- Create: `home-manager/programs/fish/common.nix`
- Modify: `home-manager/programs/fish/default.nix`
- Create: `home-manager/programs/fish/server.nix`

**Interfaces:**
- Consumes: `sources` (nvfetcher: fish-ghq, hydro), `userConfig.dotfilesDir`, `userConfig.homeDir`
- Produces: `fish/common.nix` (portable な abbr / plugin / prompt)。darwin は `default.nix`、oberon は `server.nix` を import する

- [ ] **Step 1: common.nix を作成 (portable 部分)**

`home-manager/programs/fish/common.nix`:

```nix
# fish の portable 設定 (darwin / linux 共通)。
# darwin 専用 (homebrew PATH, op/wt completion, sops env, cage 系) は
# default.nix、サーバー追加分は server.nix に置く。
{
  sources,
  userConfig,
  ...
}:
let
  inherit (userConfig) homeDir dotfilesDir;
in
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      gs = "git status --short --branch";
      gcim = {
        setCursor = true;
        expansion = "git commit -m '%'";
      };
      gcf = "git commit --fixup";
      gri = "git rebase -i";
      gsw = {
        setCursor = true;
        expansion = "git switch -c '%'";
      };
      gca = "git commit --amend --no-edit";
      gd = "git diff --no-index";
      null = {
        position = "anywhere";
        expansion = ">/dev/null 2>&1";
      };
      fbr = "git branch --list | fzf --preview \"git log --pretty=format:'%h %cd %s' --date=format:'%Y-%m-%d %H:%M' {}\" | xargs git switch";
      dc = "docker compose";
    };
    plugins = [
      {
        name = sources.fish-ghq.pname;
        src = sources.fish-ghq.src;
      }
      {
        name = sources.hydro.pname;
        src = sources.hydro.src;
      }
    ];
    interactiveShellInit = ''
      if test -f "${dotfilesDir}/env.fish"
        source "${dotfilesDir}/env.fish"
      end

      fish_add_path ${homeDir}/.local/bin
      herdr completion fish | source

      # hydro prompt (tokyonight palette)
      set -g hydro_color_pwd 7dcfff
      set -g hydro_color_git bb9af7
      set -g hydro_color_prompt 7aa2f7
      set -g hydro_color_error f7768e
      set -g hydro_color_duration e0af68
      set -g hydro_multiline true

      # starship の add_newline 相当: prompt の前に空行を挟む
      if not functions -q _hydro_original_prompt
        functions -c fish_prompt _hydro_original_prompt
        function fish_prompt
          echo
          _hydro_original_prompt
        end
      end

      # nvim の :terminal から起動された fish では direnv state が継承されるが
      # fish_add_path / mise activate に PATH を上書きされる。reload で復元する。
      if set -q NVIM; and set -q DIRENV_DIR
        direnv reload 2>/dev/null
      end
    '';
  };
}
```

- [ ] **Step 2: default.nix を darwin 専用部分だけに縮小**

`home-manager/programs/fish/default.nix` 全体を置き換え:

```nix
# darwin 専用の fish 設定。portable 部分は common.nix にある。
{
  config,
  ...
}:
{
  imports = [ ./common.nix ];

  programs.fish = {
    functions = {
      scc = {
        body = ''
          set git_root (git rev-parse --show-toplevel 2>/dev/null)
          if test $status -eq 0
            cd $git_root
            # sandbox-exec が /bin/ps をブロックするため ccstatusline の
            # ターミナル幅検出が失敗する。COLUMNS を明示的に渡して回避。
            set -x COLUMNS (tput cols)
            cage claude --dangerously-skip-permissions $argv
          else
            echo "Not in a git repository"
            return 1
          end
        '';
        description = "Move to git root and run claude via cage sandbox";
      };
    };
    shellAbbrs = {
      ccc = "cage claude";
    };
    interactiveShellInit = ''
      fish_add_path /opt/homebrew/bin
      fish_add_path /Applications/Obsidian.app/Contents/MacOS
      fish_add_path /Applications/Ghostty.app/Contents/MacOS
      wt config shell init fish | source
      op completion fish | source
      export TEST=$(cat ${config.sops.secrets.test.path})
      export DISCORD_BOT_TOKEN=$(cat ${config.sops.secrets.discord-bot-token.path})
    '';
  };
}
```

注意: `interactiveShellInit` は複数モジュールで定義すると改行結合される (順序は module import 順に依存するが、上記の内容はどの順序でも壊れない)。`pkgs` / `sources` / `userConfig` の引数は不要になったので外す。

- [ ] **Step 3: server.nix を作成**

`home-manager/programs/fish/server.nix`:

```nix
# oberon (サーバー) 用の fish 設定。common.nix だけで完結する。
{ ... }:
{
  imports = [ ./common.nix ];
}
```

- [ ] **Step 4: darwin ビルドで regression がないことを確認**

```bash
git add -A
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
```

Expected: ビルド成功。

- [ ] **Step 5: Commit**

```bash
git commit -m "refactor(fish): portable 設定を common.nix に抽出し server.nix を追加"
```

---

### Task 3: claude-code 共有部品の抽出 (package / herdr hooks)

**Files:**
- Create: `home-manager/programs/claude-code/package.nix`
- Create: `home-manager/programs/claude-code/herdr-hooks.nix`
- Modify: `home-manager/programs/claude-code/default.nix`

**Interfaces:**
- Produces:
  - `package.nix`: `{ pkgs }: <derivation>` — libexec wrapper 化した claude-code-bin
  - `herdr-hooks.nix`: `{ pkgs }: { hooks = <attrset>; toolMetadataScript = <path>; }` — herdr integration hook 群
- Consumes (later): Task 6 の `server.nix` が両方を import する

- [ ] **Step 1: package.nix を作成**

`home-manager/programs/claude-code/package.nix` (default.nix の `claudeCodePackage` let 束縛をそのまま移動):

```nix
# Override edgepkgs' wrapProgram to place the binary in libexec/ instead of
# renaming it to .claude-wrapped. This preserves the process name as "claude"
# (via p_comm), which tools like tcmux rely on for session detection.
{ pkgs }:
pkgs.edge.claude-code-bin.overrideAttrs (_old: {
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    install -m755 $src $out/libexec/claude

    makeBinaryWrapper $out/libexec/claude $out/bin/claude \
      --inherit-argv0 \
      --set DISABLE_AUTOUPDATER 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --prefix PATH : ${
        pkgs.lib.makeBinPath (
          with pkgs;
          [
            procps
            ripgrep
          ]
        )
      }

    runHook postInstall
  '';
})
```

- [ ] **Step 2: herdr-hooks.nix を作成**

`home-manager/programs/claude-code/herdr-hooks.nix` (default.nix の `herdrAgentStateScript` / `herdrToolMetadataScript` / `herdrClaudeHook(s)` を移動):

```nix
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
```

- [ ] **Step 3: default.nix を新部品を使う形に書き換え**

`home-manager/programs/claude-code/default.nix` の let 句を変更:

- `herdrAgentStateScript` / `herdrToolMetadataScript` / `herdrClaudeHook` / `herdrClaudeHooks` / `claudeCodePackage` の定義を削除
- 代わりに追加:

```nix
  claudeCodePackage = import ./package.nix { inherit pkgs; };
  herdrIntegration = import ./herdr-hooks.nix { inherit pkgs; };
  herdrClaudeHooks = herdrIntegration.hooks;
```

- `hooks = herdrClaudeHooks // { ... }` 内の `herdrToolMetadataScript` 参照を `herdrIntegration.toolMetadataScript` に置換 (1 箇所、PreToolUse の matcher "*" エントリ)

- [ ] **Step 4: darwin ビルド検証**

```bash
git add -A
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
```

Expected: ビルド成功。settings.json の内容は変わらないので regression なし。

- [ ] **Step 5: Commit**

```bash
git commit -m "refactor(claude-code): package と herdr hooks を server 共有用に抽出"
```

---

### Task 4: git / claude-code / opencode のサーバー版モジュール

**Files:**
- Create: `home-manager/programs/git/server.nix`
- Create: `home-manager/programs/claude-code/server.nix`
- Create: `home-manager/programs/opencode/server.nix`

**Interfaces:**
- Consumes: Task 3 の `package.nix` / `herdr-hooks.nix`
- Produces: oberon の `home.nix` (Task 5) が import する 3 モジュール

- [ ] **Step 1: git/server.nix を作成**

darwin 版から 1Password 署名 / sops (Cloudflare Access) / wt / forgejo 関連を除いた portable subset。commit 署名はサーバーでは行わない (1Password agent が無い):

```nix
# oberon (サーバー) 用の git 設定。darwin 版 (default.nix) から
# 1Password SSH 署名 / Cloudflare Access include / wt を除いたもの。
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      alias = {
        pushf = "push --force-with-lease --force-if-includes";
      };
      user = {
        email = "thinceller@gmail.com";
        name = "thinceller";
      };
      core = {
        editor = "vim";
      };
      ghq = {
        # dotfiles (~/.dotfiles) も ghq list に載せるため root を複数指定する。
        # ghq 1.9.4 では git config の解決順 (last wins) で最後のエントリが
        # primary root (ghq get の clone 先) になるため ~/src を末尾に置く。
        root = [
          "~/.dotfiles"
          "~/src"
        ];
      };
      rebase = {
        autostash = true;
        autosquash = true;
      };
      pull = {
        rebase = true;
      };
      merge = {
        ff = false;
      };
      init = {
        defaultBranch = "main";
      };
    };
    ignores = [
      ".claude/worktrees"
    ];
  };
}
```

- [ ] **Step 2: claude-code/server.nix を作成**

darwin 版から sandbox (Seatbelt 前提) / cage / Mnemos / obsidian / codex plugin を除いた構成。herdr integration と statusline は維持:

```nix
# oberon (サーバー) 用の Claude Code 設定。darwin 版 (default.nix) から
# macOS sandbox (Seatbelt) / cage / Mnemos (vault) / codex plugin を除き、
# herdr integration と statusline を維持したもの。
{
  pkgs,
  config,
  ...
}:
let
  statuslineScript = pkgs.writeShellScript "claude-statusline" (
    builtins.readFile ./statusline-command.sh
  );
  claudeCodePackage = import ./package.nix { inherit pkgs; };
  herdrIntegration = import ./herdr-hooks.nix { inherit pkgs; };
in
{
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      theme = "dark";
      autoCompactEnabled = false;
      alwaysThinkingEnabled = true;
      language = "japanese";
      autoMemoryEnabled = true;
      cleanupPeriodDays = 9999;

      model = "opus";
      skipAutoPermissionPrompt = true;
      useAutoModeDuringPlan = true;
      tui = "fullscreen";

      permissions = {
        allow = [
          "WebFetch"
          "WebSearch"
          "Bash(ls:*)"
          "Bash(grep:*)"
        ];
        ask = [
          "Bash(rm:*)"
          "Bash(git merge:*)"
          "Bash(git rebase:*)"
          "Bash(git push:*)"
        ];
        deny = [
          "Read(~/.ssh/**)"
          "Read(.env*)"
          "Bash(sudo:*)"
          "Bash(git commit --no-gpg-sign:*)"
          "Edit(~/.ssh/**)"
          "Edit(.env*)"
        ];
        defaultMode = "auto";
      };

      env = {
        BASH_DEFAULT_TIMEOUT_MS = "60000";
        BASH_MAX_TIMEOUT_MS = "180000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        DISABLE_AUTOUPDATER = "1";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_NEW_INIT = "1";
      };

      hooks = herdrIntegration.hooks // {
        PreToolUse = herdrIntegration.hooks.PreToolUse ++ [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = herdrIntegration.toolMetadataScript;
                timeout = 10;
              }
            ];
          }
        ];
      };

      statusLine = {
        type = "command";
        command = statuslineScript;
      };

      extraKnownMarketplaces = {
        "thinceller-claude-plugins" = {
          source = {
            source = "github";
            repo = "thinceller/claude-plugins";
          };
        };
        "superpowers-dev" = {
          source = {
            source = "github";
            repo = "obra/superpowers";
          };
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-dev" = true;
        "git-toolkit@thinceller-claude-plugins" = true;
      };
    };

    context = ./user-memory.md;

    skills = {
      herdr = ./skills/herdr;
      hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
    };
  };
}
```

- [ ] **Step 3: opencode/server.nix を作成**

darwin 版から vault (references / Mnemos / enquire) / tmux-agent-sidebar を除き、herdr integration plugin を維持:

```nix
# oberon (サーバー) 用の OpenCode 設定。darwin 版 (default.nix) から
# vault (references / Mnemos) / tmux-agent-sidebar を除いたもの。
{
  pkgs,
  config,
  ...
}:
{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    extraPackages = with pkgs; [
      git
      gh
      ripgrep
    ];

    settings = {
      model = "opencode-go/glm-5.2";
      small_model = "opencode-go/minimax-m3";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
      ];

      compaction = {
        auto = false;
        prune = false;
      };

      permission = {
        bash = {
          "*" = "ask";
          "ls*" = "allow";
          "grep*" = "allow";
          "git status*" = "allow";
          "git diff*" = "allow";
          "git log*" = "allow";
          "rm*" = "ask";
          "git merge*" = "ask";
          "git rebase*" = "ask";
          "git push*" = "ask";
          "sudo*" = "deny";
        };
        webfetch = "allow";
        websearch = "allow";
        read = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "~/.ssh/**" = "deny";
        };
        edit = {
          "*" = "allow";
          "*.env*" = "deny";
          "~/.ssh/**" = "deny";
        };
        external_directory = "ask";
      };

      watcher = {
        ignore = [
          "node_modules/**"
          ".git/**"
          "dist/**"
          "build/**"
        ];
      };
    };

    tui = {
      theme = "tokyonight";
      mouse = true;
      attention = {
        enabled = false;
      };
    };

    context = ./AGENTS.md;

    skills = {
      hunk-review = "${config.programs.hunk.package}/skills/hunk-review";
    };
  };

  # herdr integration (opencode 側): `herdr integration install opencode` が
  # 書き出す ~/.config/opencode/plugins/herdr-agent-state.js と等価。
  xdg.configFile."opencode/plugins/herdr-agent-state.js" = {
    source = ./plugins/herdr-agent-state.js;
  };
}
```

- [ ] **Step 4: git add + fmt**

```bash
git add -A
nix fmt
```

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(home-manager): git / claude-code / opencode のサーバー版モジュールを追加"
```

---

### Task 5: oberon 用 home.nix とサーバーパッケージ

**Files:**
- Create: `hosts/oberon/home.nix`

**Interfaces:**
- Consumes: Task 2〜4 の server モジュール群、`userConfig` (Task 6 で拡張)、`sources`
- Produces: `hosts/oberon/default.nix` (Task 6) が `home-manager.users.thinceller` に渡すモジュール

- [ ] **Step 1: hosts/oberon/home.nix を作成**

```nix
# oberon の home-manager 構成。Mac の hosts/*/home.nix と違い、
# darwin 依存モジュール (fish/git/claude-code/opencode) はサーバー版を import し、
# GUI / sops / vault 関連は含めない。
{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  inherit (userConfig) dotfilesDir;
  rootDir = /. + dotfilesDir + /configs;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ../../home-manager/programs/bat
    ../../home-manager/programs/bottom
    ../../home-manager/programs/claude-code/server.nix
    ../../home-manager/programs/delta
    ../../home-manager/programs/direnv
    ../../home-manager/programs/fish/server.nix
    ../../home-manager/programs/fzf
    ../../home-manager/programs/gh
    ../../home-manager/programs/git/server.nix
    ../../home-manager/programs/htop
    ../../home-manager/programs/hunk
    ../../home-manager/programs/jq
    ../../home-manager/programs/lazygit
    ../../home-manager/programs/lsd
    ../../home-manager/programs/opencode/server.nix
    ../../home-manager/programs/ripgrep
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDir;

  # oberon は glibc locale を en_US.UTF-8 しか生成していない
  # (nixos/modules/common.nix の defaultLocale 参照)。ja_JP を設定すると
  # locale エラーになるので en_US に固定する。
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
  };

  # HM input は master (nixpkgs unstable 追従) だが oberon の pkgs は
  # nixpkgs-stable。programs.claude-code / opencode の最新オプションを
  # Mac と揃えるために master を使うので、バージョン不一致警告を止める。
  home.enableNixpkgsReleaseCheck = false;

  home.packages = with pkgs; [
    ghq
    herdr
    # herdr-launch の editor タブが nvim を起動する。Mac の neovim module
    # (nvfetcher plugin 群) は重いので、まずは素の neovim を置く。
    neovim
  ];

  # herdr 設定 + プロジェクトランチャー (Mac と同じファイルを共有)。
  # out-of-store symlink の実体は on-server clone (/home/thinceller/.dotfiles)。
  home.file.".local/bin/herdr-launch" = {
    source = symlink /${rootDir}/bin/herdr-launch;
  };
  # 単一ファイル symlink にする理由: herdr は ~/.config/herdr/ 配下に
  # ログやローカル override を書くため (home-manager/files.nix と同じ)。
  xdg.configFile."herdr/config.toml" = {
    source = symlink /${rootDir}/.config/herdr/config.toml;
  };

  home.stateVersion = "25.11";
}
```

- [ ] **Step 2: Commit (eval は Task 6 で配線後に行う)**

```bash
git add -A
git commit -m "feat(oberon): home-manager 構成 (home.nix) を追加"
```

---

### Task 6: hosts/oberon/default.nix に home-manager を配線

**Files:**
- Modify: `hosts/oberon/default.nix`

**Interfaces:**
- Consumes: flake inputs `home-manager` / `gh-prism` / `hunk` / `herdr`、Task 5 の `home.nix`
- Produces: `nixosConfigurations.oberon` に HM が統合された状態

- [ ] **Step 1: default.nix を書き換え**

`hosts/oberon/default.nix` 全体を以下に置き換え:

```nix
{ inputs }:
let
  inherit (inputs)
    self
    sops-nix
    disko
    edgepkgs
    hermes-agent
    nix-index-database
    home-manager
    gh-prism
    hunk
    herdr
    ;
  # oberon は cache 安定性のため NixOS stable channel を使う (unstable ではない)。
  nixpkgs = inputs.nixpkgs-stable;
  system = "x86_64-linux";
  userConfig = rec {
    username = "thinceller";
    hostname = "oberon";
    homeDir = "/home/${username}";
    dotfilesDir = homeDir + "/.dotfiles";
    isPersonal = false;
    inherit system;
  };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
      (_final: _prev: {
        herdr = herdr.packages.${system}.default;
      })
    ];
  };

  # Load the generated sources by nvfetcher (fish plugins 等で使用)
  sources = pkgs.callPackage ../../_sources/generated.nix { };
in
nixpkgs.lib.nixosSystem {
  inherit pkgs;
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    sops-nix.nixosModules.sops
    disko.nixosModules.disko
    hermes-agent.nixosModules.default
    nix-index-database.nixosModules.nix-index
    ./disko.nix
    ./configuration.nix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        gh-prism.homeManagerModules.default
        hunk.homeManagerModules.default
      ];
      home-manager.extraSpecialArgs = {
        inherit userConfig sources;
      };
      home-manager.users."${userConfig.username}" = import ./home.nix;
    }
  ];
}
```

- [ ] **Step 2: eval 検証 (Mac から)**

```bash
git add -A
nix eval --raw .#nixosConfigurations.oberon.config.system.build.toplevel.drvPath
```

Expected: drvPath が出力される。ここで「実装前の確認事項」2・3 (gh-prism / hunk / claude-code / opencode module の x86_64-linux + stable pkgs での評価) が検証される。エラーが出た場合:
- `gh-prism` / `hunk` module 起因 → 該当 sharedModule と gh module の `programs.gh-prism.enable` / hunk import を oberon から外して素の package 参照に切り替える
- HM module のオプション不一致 → エラーメッセージのオプション名を確認して server.nix 側を修正

- [ ] **Step 3: darwin regression 確認 + fmt**

```bash
nix fmt
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
nix build .#darwinConfigurations.SC-N-843.system --no-link
```

Expected: すべて成功。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(oberon): home-manager を NixOS module として統合"
```

---

### Task 7: コード改善 (simplify)

- [ ] **Step 1: simplify skill を実行**

対象: Task 1〜6 で変更した nix ファイル。重複の残り・不要な引数・過剰な条件分岐を確認して修正。

- [ ] **Step 2: 修正があれば再検証 + commit**

```bash
nix eval --raw .#nixosConfigurations.oberon.config.system.build.toplevel.drvPath
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
git add -A && git commit -m "refactor: simplify レビューの修正を適用"
```

---

### Task 8: oberon へのデプロイ

**前提**: master に merge 済み (または oberon 上で作業ブランチを checkout)。

- [ ] **Step 1: 変更を push し、oberon 上で pull**

```bash
# Mac から (Tailscale 経由)
ssh oberon
# oberon 上で
cd ~/.dotfiles && git pull
```

- [ ] **Step 2: tmux 内で rebuild (SSH 切断対策の既存運用)**

```bash
tmux new -s rebuild
sudo nixos-rebuild switch --flake .#oberon
```

Expected: activation 成功。今回の変更は sshd / network / cloudflared に触れないので SSH 切断リスクは低いが、運用ルール通り tmux 内で実行する。

- [ ] **Step 3: 動作確認 (oberon 上)**

```bash
# 新しい SSH セッションで (login shell が fish になっている)
echo $SHELL            # → /run/current-system/sw/bin/fish 等 fish であること
which herdr claude opencode gh ghq nvim mosh-server
herdr --version
swapon --show          # zram0 が /swapfile より高優先度で載っていること
```

- [ ] **Step 4: 初回認証 (oberon 上、手動)**

```bash
gh auth login          # GitHub (HTTPS + browser code flow)
claude                 # 初回起動で OAuth ログイン (URL をスマホ/Mac のブラウザで開く)
opencode auth login    # opencode-go プロバイダー
```

- [ ] **Step 5: herdr セッション起動確認 (oberon 上)**

```bash
herdr
# prefix (ctrl+j) + ctrl+o → herdr-launch → リポジトリ選択 → open
# agent タブで claude が起動し、sidebar に $model / $ctx が出ること
```

---

### Task 9: スマホ / iPad 側セットアップ (手動)

- [ ] **Step 1: Tailscale アプリ**

iPhone / iPad に Tailscale アプリをインストールし、tailnet アカウントでログイン。VPN プロファイルを有効化。

- [ ] **Step 2: tailnet ACL の ssh ルール確認**

Tailscale admin console → Access Controls。`"ssh"` セクションで自分のデバイス → oberon への SSH が許可されていることを確認。デフォルトの `"action": "check"` はモバイルで都度ブラウザ認証が挟まって煩わしいので、必要なら自分のデバイス限定で `"action": "accept"` に変更:

```jsonc
"ssh": [
  {
    "action": "accept",
    "src": ["autogroup:member"],
    "dst": ["autogroup:self"],
    "users": ["autogroup:nonroot"]
  }
]
```

- [ ] **Step 3: Moshi / Termius の接続設定**

- Host: `oberon` (MagicDNS) または tailnet IP (`tailscale status` で確認)
- User: `thinceller`
- Moshi: mosh 接続を有効化 (SSH bootstrap → UDP 60000-61000)。Tailscale SSH が鍵認証を代替するため SSH 鍵の登録は不要
- Termius: 素の SSH (mosh 非対応)。切断時は再接続して herdr が復元する

- [ ] **Step 4: エンドツーエンド動作確認**

1. iPhone (Moshi) から `oberon` へ mosh 接続 → fish プロンプトが出る
2. `herdr` 起動 → launcher でリポジトリを開き claude セッション開始
3. 機内モード ON/OFF (経路断) → mosh がセッションを維持していること
4. Moshi アプリを完全終了 → 再接続 → `herdr` で agent が復元されること
5. `btm` (herdr popup: prefix+ctrl+t) でメモリを確認し、claude 1 セッション時の残 RAM を把握しておく

---

## 運用メモ

- **同時エージェント数**: 2GB RAM なので claude 1 + opencode 1 が実用上限。重いビルドを伴う作業は避けるか Mac 側で行う
- **フォールバック経路**: Tailscale 障害時は Mac から cloudflared 経由 SSH、最終手段は Sakura パネルの VNC (パスワードは 1Password)
- **設定変更の反映**: herdr config / herdr-launch は out-of-store symlink なので oberon 上で `git pull` するだけで反映 (rebuild 不要)。nix モジュール変更は rebuild が必要
- **将来の拡張候補** (今回はやらない): Claude Code の Linux sandbox (bubblewrap)、ブラウザターミナル (Cloudflare Access browser-rendered SSH)、VPS プラン増強
