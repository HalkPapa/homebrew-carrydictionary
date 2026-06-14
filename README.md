# homebrew-carrydictionary

[CarryDictionary](https://github.com/HalkPapa/CarryDictionary) の配布リポジトリ
（Homebrew tap 兼 Scoop bucket）。

CarryDictionary 本体のソースは **非公開** です。ここには **formula / Scoop マニフェスト
とビルド済みバイナリ（GitHub Releases）だけ** が置かれ、ソースコードは含みません。

配布物:

| ツール | 内容 |
|---|---|
| `cd-mcp` | CarryDictionary の MCP サーバ（`cd_mcp`）。ローカル辞書を任意の MCP/AI クライアントに公開する CLI。 |

プラットフォーム状況: **macOS arm64 = 公式**、macOS x86_64 / Linux / Windows = **ベータ**。

## インストール

### macOS / Linux（Homebrew）

```bash
brew tap halkpapa/carrydictionary
brew trust halkpapa/carrydictionary   # Homebrew 6.0+ は外部 tap の信頼が必要
brew install cd-mcp
```

> `brew trust` は Homebrew 6.0 から導入された、外部 tap の formula を読み込む前の
> 信頼ステップです（5.x では不要）。対話実行ならインストール時に確認が出ることもあります。

### Windows（Scoop・ベータ）

```powershell
scoop bucket add carrydictionary https://github.com/HalkPapa/homebrew-carrydictionary
scoop install cd-mcp
```

いずれも `cd_mcp` が PATH に入ります。MCP クライアント登録は `command` に `cd_mcp`、
`env.CD_DB_PATH` にDBパスを設定（`brew info cd-mcp` / マニフェストの notes 参照）。

## アップデート

```bash
brew update && brew upgrade cd-mcp     # macOS / Linux
scoop update cd-mcp                     # Windows
```

---

## リリース手順（メンテナ向け）

### 自動（推奨・GitHub Actions）

本体（非公開）リポジトリでタグを打つと、`.github/workflows/release.yml` が
mac/linux/windows でビルド → この repo の Release に成果物を添付 → `Formula/cd-mcp.rb`
と `bucket/cd-mcp.json` の version/url/sha を更新してコミットします。

```bash
# CarryDictionary 本体リポジトリで
git tag cd_mcp-v<version>
git push origin cd_mcp-v<version>
```

事前に本体リポジトリへシークレット **`TAP_REPO_TOKEN`**（この repo への
`contents: write` 権限を持つ PAT）を登録しておくこと。

### 手動（CIを使わない場合）

1. 各OSでビルド・パッケージ:
   - macOS / Linux: `./apps/cd_mcp/scripts/package_release.sh`
   - Windows(PowerShell): `apps\cd_mcp\scripts\package_release.ps1`
2. この repo に Release を作成し成果物を添付:
   ```bash
   gh release create cd_mcp-v<version> dist/* --repo HalkPapa/homebrew-carrydictionary \
     --title "cd_mcp v<version>" --notes "..."
   ```
   タグは `cd_mcp-v<version>`、アセット名は `cd_mcp-<version>-<os>-<arch>.(tar.gz|zip)` に固定。
3. version/url/sha を反映:
   ```bash
   python3 apps/cd_mcp/scripts/update_tap.py --version <version> --dist dist \
     --formula Formula/cd-mcp.rb --scoop bucket/cd-mcp.json
   ```
   （未ビルドのプラットフォームは触られず、placeholder のまま残る）
4. 確認: `brew update && brew upgrade cd-mcp`、`brew test cd-mcp`、`brew audit --strict cd-mcp`。

> なぜ `dart compile exe` ではないか: cd_mcp は sqlite3 のネイティブ build hook を使うため
> `dart compile exe` 非対応。`dart build cli`（preview）が共有ライブラリ同梱の再配置可能な
> バンドルを生成するので、それを tarball/zip 化して配布している。
