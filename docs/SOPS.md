# SOPS (Secrets OPerationS) マニュアル

このドキュメントでは、dotfilesリポジトリにおけるSOPSを使用したシークレット管理について説明します。

## 概要

SOPS (Secrets OPerationS) は、設定ファイル内の機密情報を暗号化するためのツールです。このプロジェクトでは、以下の目的でSOPSを使用しています：

- APIキーやトークンなどの機密情報を安全に管理
- Gitリポジトリに暗号化された形でシークレットを保存
- Nixの設定と統合して、必要な時に自動的に復号化

### 使用している暗号化方式

このプロジェクトでは、age暗号化を使用しています。ageは現代的で安全な暗号化ツールで、シンプルで使いやすいのが特徴です。

## セットアップ

### 1. 新しいホストでのage鍵の生成

新しいマシンでシークレットを使用するには、まずage鍵を生成する必要があります：

```bash
# age鍵を保存するディレクトリを作成
mkdir -p ~/.config/sops/age

# age鍵を生成
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
```

生成された公開鍵（`age1...`で始まる文字列）は、`.sops.yaml`ファイルに追加する必要があります。

### 2. 既存のage鍵の復元

既存のマシンから鍵を移行する場合：

```bash
# 元のマシンから鍵をコピー
cp /path/to/old/keys.txt ~/.config/sops/age/keys.txt

# 適切な権限を設定
chmod 600 ~/.config/sops/age/keys.txt
```

### 3. .sops.yamlへの鍵の追加

新しいホストの公開鍵を`.sops.yaml`に追加します：

```yaml
keys:
  - &admin age1r9r7z5crn6v77ye6psxvf24mdtmxgnng8xuvdryhckpjpmlyhdyqh8j2pc
  - &sc age1hd03r99ut6kj64y9kxnekggxkzyzav985uzxes35v9e5cfjtp4fs6gelkf
  - &mac age16hjw8qjvc0aakun7e4j9kfpzl787vqcvsfaqyr4u488vlyema5lsu95evr
  - &new_host age1新しい公開鍵...  # 新しく追加

creation_rules:
  - path_regex: secrets/(.*)?[.](yaml|json|env|ini)$
    key_groups:
      - age:
          - *admin
          - *sc
          - *mac
          - *new_host  # ここにも追加
```

## 設定ファイル

### .sops.yaml

`.sops.yaml`は、SOPSの動作を制御する設定ファイルです。

#### 構造

```yaml
keys:
  - &admin age1r9r7z5crn6v77ye6psxvf24mdtmxgnng8xuvdryhckpjpmlyhdyqh8j2pc
  - &sc age1hd03r99ut6kj64y9kxnekggxkzyzav985uzxes35v9e5cfjtp4fs6gelkf
  - &mac age16hjw8qjvc0aakun7e4j9kfpzl787vqcvsfaqyr4u488vlyema5lsu95evr

creation_rules:
  - path_regex: secrets/(.*)?[.](yaml|json|env|ini)$
    key_groups:
      - age:
          - *admin
          - *sc
          - *mac
```

#### 設定項目の説明

- **keys**: 暗号化に使用する公開鍵のリスト。YAMLアンカー（`&`）を使用して後で参照
- **creation_rules**: ファイルパスに基づいて暗号化ルールを定義
  - **path_regex**: 暗号化対象のファイルパスを正規表現で指定
  - **key_groups**: 暗号化に使用する鍵のグループ。すべての鍵で復号化可能

### secrets/default.yaml

実際の暗号化されたシークレットを保存するファイルです。SOPSによって暗号化され、以下のような構造になっています：

```yaml
test: ENC[AES256_GCM,data:暗号化されたデータ...]
brave-api-key: ENC[AES256_GCM,data:暗号化されたデータ...]
github-token: ENC[AES256_GCM,data:暗号化されたデータ...]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
        - recipient: age1r9r7z5crn6v77ye6psxvf24mdtmxgnng8xuvdryhckpjpmlyhdyqh8j2pc
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            暗号化されたキーマテリアル...
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2024-05-14T13:40:17Z"
    mac: ENC[AES256_GCM,data:MAC情報...]
    pgp: []
    unencrypted_suffix: _unencrypted
    version: 3.8.1
```

### Nix設定での定義

Home Managerの設定（`home-manager/default.nix`）でSOPSを設定：

```nix
sops = {
  # デフォルトのシークレットファイル
  defaultSopsFile = ../secrets/default.yaml;
  
  # age鍵の場所
  age = {
    keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  
  # 使用するシークレットの定義
  secrets.test = { };
  # 他のシークレットも同様に定義
};
```

## シークレット管理

### 新しいシークレットの追加

1. **シークレットファイルを編集**：
   ```bash
   sops secrets/default.yaml
   ```
   
   エディタが開いたら、新しいシークレットを追加：
   ```yaml
   test: テスト用の値
   brave-api-key: 実際のAPIキー
   github-token: 実際のGitHubトークン
   new-secret: 新しいシークレットの値  # 追加
   ```

2. **Nixでシークレットを定義**：
   
   使用したいモジュール（例：`home-manager/default.nix`）で定義：
   ```nix
   sops.secrets.new-secret = { };
   ```

3. **シークレットを使用**：
   
   設定ファイルやスクリプトでシークレットのパスを参照：
   ```nix
   # 例：環境変数として使用
   programs.fish.shellInit = ''
     export NEW_SECRET=$(cat ${config.sops.secrets.new-secret.path})
   '';
   ```

### 既存のシークレットの編集

```bash
# SOPSエディタでファイルを開く
sops secrets/default.yaml

# 値を編集して保存
```

### シークレットの削除

1. シークレットファイルから削除：
   ```bash
   sops secrets/default.yaml
   # 不要なエントリを削除
   ```

2. Nix設定からも削除：
   ```nix
   # sops.secrets.削除したシークレット = { }; を削除
   ```

### シークレットの回転（ローテーション）

すべての鍵でシークレットを再暗号化：

```bash
sops -r secrets/default.yaml
```

これは、鍵を追加/削除した後に実行する必要があります。

## Nixとの統合

### sops-nixの仕組み

1. **flake.nix**での入力定義：
   ```nix
   inputs = {
     sops-nix = {
       url = "github:Mic92/sops-nix";
       inputs.nixpkgs.follows = "nixpkgs";
     };
   };
   ```

2. **Home Managerへの統合**：
   ```nix
   home-manager.sharedModules = [
     sops-nix.homeManagerModules.sops
   ];
   ```

3. **実行時の動作**：
   - ビルド時にシークレットは暗号化されたまま
   - システム起動時に自動的に復号化
   - `/run/user/$(id -u)/secrets/`以下に復号化されたファイルが配置

### 実際の使用例

#### MCP Servers（Claude用）
`home-manager/mcp-servers/default.nix`：
```nix
sops.secrets.brave-api-key = { };
sops.secrets.github-token = { };

mcpServers = {
  brave-search = {
    command = "npx";
    args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
    env = {
      BRAVE_API_KEY = readFile config.sops.secrets.brave-api-key.path;
    };
  };
  github = {
    command = "npx";
    args = [ "-y" "@modelcontextprotocol/server-github" ];
    env = {
      GITHUB_PERSONAL_ACCESS_TOKEN = readFile config.sops.secrets.github-token.path;
    };
  };
};
```

#### Fish Shell
`home-manager/programs/fish/default.nix`：
```nix
programs.fish.shellInit = ''
  export TEST=$(cat ${config.sops.secrets.test.path})
'';
```

### パーミッションとオーナーシップ

必要に応じてシークレットファイルの権限を設定：

```nix
sops.secrets.my-secret = {
  mode = "0400";  # 読み取り専用
  owner = config.users.users.myuser.name;
  group = config.users.users.myuser.group;
};
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. "could not decrypt with any of the keys" エラー

**原因**: age秘密鍵がない、または公開鍵が`.sops.yaml`に登録されていない

**解決方法**:
- age鍵が正しい場所にあるか確認：`ls ~/.config/sops/age/keys.txt`
- 公開鍵が`.sops.yaml`に含まれているか確認
- すべての鍵で再暗号化：`sops -r secrets/default.yaml`

#### 2. "failed to get sops file" エラー

**原因**: SOPSファイルのパスが間違っている

**解決方法**:
- `defaultSopsFile`のパスが正しいか確認
- 相対パスは`home-manager/default.nix`からの相対パス

#### 3. シークレットが空の値になる

**原因**: シークレットの定義が不足している

**解決方法**:
- Nix設定で`sops.secrets.シークレット名 = { };`が定義されているか確認
- `darwin-rebuild switch`を実行して設定を適用

#### 4. エディタが開かない

**原因**: `$EDITOR`環境変数が設定されていない

**解決方法**:
```bash
export EDITOR=vim  # または好みのエディタ
sops secrets/default.yaml
```

### デバッグ方法

1. **復号化されたファイルの確認**：
   ```bash
   # 実行時のシークレットパスを確認
   ls -la /run/user/$(id -u)/secrets/
   ```

2. **SOPSのデバッグ出力**：
   ```bash
   SOPS_LOG_LEVEL=debug sops secrets/default.yaml
   ```

3. **age鍵の確認**：
   ```bash
   # 公開鍵を表示
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

### セキュリティのベストプラクティス

1. **秘密鍵の保護**:
   - `~/.config/sops/age/keys.txt`は600の権限で保護
   - 秘密鍵をGitにコミットしない

2. **最小権限の原則**:
   - 必要なシークレットのみを定義
   - 適切なファイル権限を設定

3. **定期的な回転**:
   - シークレットは定期的に更新
   - 不要になった鍵は`.sops.yaml`から削除

4. **バックアップ**:
   - age秘密鍵は安全な場所にバックアップ
   - 複数の管理者鍵を設定してリスクを分散