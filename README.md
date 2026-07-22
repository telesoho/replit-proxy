# Replit Proxy

Replit Proxy は FastAPI ベースのプロキシサービスです。Replit アプリから外部 API へアクセスするトラフィックをプロキシ層に集約し、ログの集中管理と統一的な制御を可能にします。

## 機能概要

- `api/eagle-pms` 関連リクエストの統一プロキシ
- ヘルスチェックエンドポイント `GET /health`
- リクエストログの記録（送信元 IP、メソッド、パス、ステータスコード、処理時間）
- アプリケーションレベルの `httpx.AsyncClient` による接続再利用とタイムアウト制御

## 動作環境

- Python 3.10+
- [uv](https://github.com/astral-sh/uv)
- （任意）Windows サービスとしてインストールする場合は [NSSM](https://nssm.cc/download)
- （任意）Linux サービスとしてインストールする場合は `systemd`

## インストール手順

### 1) リポジトリのクローンと移動

```bash
git clone <your-repo-url>
cd replit-proxy
```

### 2) 依存関係のインストール

```bash
uv sync
```

### 3) サービスの起動

#### 共通方法（推奨）

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8080
```

#### スクリプトによる起動

- Linux/macOS:
  ```bash
  ./scripts/run.sh
  ```
- Windows:
  ```bat
  scripts\run.bat
  ```

### 4) 起動確認

```bash
curl http://127.0.0.1:8080/health
```

レスポンス例:

```json
{"status":"ok","service":"replit-proxy"}
```

## アンインストール手順

デプロイ方法に応じて、該当する手順を選択してください。

### A. ローカル実行のみ（システムサービス未インストール）

1. 実行中のプロセスを停止（ターミナルで `Ctrl + C`）
2. （任意）仮想環境とキャッシュを削除:

```bash
rm -rf .venv .ruff_cache
```

Windows では該当ディレクトリを手動で削除してください。

### B. Linux/macOS（systemd サービス）のアンインストール

#### ユーザーレベルサービス（デフォルト）

```bash
./scripts/remove-service.sh
```

#### システムレベルサービス（`--system` でインストールした場合）

```bash
./scripts/remove-service.sh --system
```

未インストールで先にサービスをセットアップする場合:

```bash
./scripts/install-service.sh
# または
./scripts/install-service.sh --system
```

### C. Windows（NSSM サービス）のアンインストール

```bat
scripts\remove-service.bat
```

未インストールで先にサービスをセットアップする場合:

```bat
scripts\install-service.bat
```

## ファイル構成

```text
replit-proxy/
├─ main.py                     # FastAPI エントリポイント、プロキシルートとログミドルウェア
├─ config.py                   # サービス設定（ポート、上流 URL、タイムアウトなど）
├─ keyvox.py                   # KeyVox/eagle-pms HMAC 署名呼び出しのサンプルクライアント
├─ pyproject.toml              # プロジェクトメタデータと依存関係定義
├─ uv.lock                     # 依存関係ロックファイル
├─ scripts/
│  ├─ run.sh                   # Linux/macOS 起動スクリプト
│  ├─ run.bat                  # Windows 起動スクリプト
│  ├─ install-service.sh       # Linux/macOS systemd サービスインストールスクリプト
│  ├─ remove-service.sh        # Linux/macOS systemd サービスアンインストールスクリプト
│  ├─ install-service.bat      # Windows NSSM サービスインストールスクリプト
│  ├─ remove-service.bat       # Windows NSSM サービスアンインストールスクリプト
│  ├─ replit-proxy.service     # systemd ユニットテンプレート
│  └─ service.bat              # Windows サービス補助スクリプト
├─ .gitignore                  # Git 除外ルール
└─ README.md                   # プロジェクト説明ドキュメント
```

## よく使う開発コマンド

```bash
# 起動（開発モード、自動リロード）
uv run uvicorn main:app --host 0.0.0.0 --port 8080 --reload

# テスト実行
uv run pytest

# コードチェックとフォーマット
uv run ruff check .
uv run ruff format .
```

## プロキシ API の例

- Replit アプリからのプロキシリクエスト先:
  `http://<proxy-host>:8080/api/eagle-pms/...`
- サービスが転送する上流先:
  `https://eco.blockchainlock.io/api/eagle-pms/...`
