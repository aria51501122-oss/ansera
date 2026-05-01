# Ansera

ローカル PC 上で動作する RAG（Retrieval-Augmented Generation）システム。
PDF を投入し、ハイブリッド検索（ベクトル + 全文）で日本語の質問に回答します。

## 特徴
- 完全ローカル動作（外部 API 呼び出しなし、機密文書も安全）
- 日本語特化（pgroonga + MeCab トークナイザ）
- ハイブリッド検索（pgvector + pgroonga、重み 0.7 / 0.3）
- GUI は単一 HTML ファイル（インストール不要）

## 構成
- PostgreSQL 17 + pgvector + pgroonga
- Ollama（qwen3:8b 生成 + bge-m3 埋め込み）
- n8n（ワークフロー実行基盤）
- 単一 HTML UI（Tailwind CDN + vanilla JS）

## 動作環境

### 必須要件

- Windows 10 64bit (バージョン1903以降) または Windows 11
- 管理者権限
- Docker Desktop（最新版）
- RAM: 16GB 以上
- 空き容量: 20GB 以上（SSD 推奨）
- NVIDIA GPU: VRAM 8GB 以上（GTX 1070 / RTX 3060 等）
- ネット接続: 初回セットアップ時のみ（モデルDL約8GB）

### 推奨要件

- RAM: 32GB
- 空き容量: 30GB（成長余地）
- VRAM: 12GB 以上（RTX 3060 12GB / RTX 4070 等）

### 動作不可環境

- AMD GPU（CUDA 必須）
- Intel 内蔵 GPU
- macOS（M1/M2/M3 は別途相談）
- Linux
- Windows 32bit
- スマートフォン / タブレット

GPU は NVIDIA（CUDA 対応）のみサポートしています。OS は Windows 10/11 のみ動作確認済みです。

## セットアップ手順

### 1. リポジトリ取得

```
git clone <TODO: リポジトリ URL>
cd <repo>
```

### 2. setup.bat 実行

`setup.bat` を**右クリック → 管理者として実行**。

自動で以下を行います。

1. 前提確認（Docker / GPU / 空き容量）
2. Docker サービス起動
3. PostgreSQL / n8n / Ollama の起動待機
4. AI モデルのダウンロード（qwen3:8b 約 5GB、bge-m3 約 1.2GB）
5. **n8n 初期設定の手動操作**（下記）
6. n8n ワークフローの自動インポート + 自動有効化

### 3. n8n 初期設定の手動操作

`setup.bat` がモデル DL 後に一時停止し、ブラウザでの初期設定を促します。以下の手順で進めてください。

1. ブラウザで `http://localhost:5678` を開く
2. アカウントを作成（名前 / メール / パスワード）
3. 左メニュー **Settings → Credentials → Add Credential** をクリック
4. 「PostgreSQL」を検索して選択
5. 以下の値を入力

| 項目 | 値 |
|---|---|
| Credential名 | Postgres account |
| Host | postgres |
| Port | 5432 |
| Database | ansera |
| User | ansera |
| Password | ansera |

6. **Save** をクリック
7. `setup.bat` のウィンドウに戻り Enter キーを押す

その後、ワークフローのインポートと自動有効化が走ります。

### 4. UI 起動

`ui\index.html` をダブルクリックでブラウザに開きます。

## 使い方

### PDF をアップロード
1. UI 左上の「+ ファイル追加」から PDF を選択
2. 自動で分割・埋め込み生成され、検索対象になります

### 質問する
1. 入力欄に日本語で質問
2. モード選択：
   - **strict**：投入文書のみから回答（出典必須）
   - **study**：文書 + AI 知識を併用
3. 必要に応じて参照ファイルを絞り込み

### ファイル削除
ファイル一覧の × ボタンから削除可能（DB からも削除されます）。

## API仕様

UI を介さず HTTP で直接叩けます。すべての API は認証ヘッダー `X-API-Key: rag-local-dev-key-2025` が必要です。

### POST `/webhook/rag-chat`（質問応答）

```
POST http://localhost:5678/webhook/rag-chat
X-API-Key: rag-local-dev-key-2025
Content-Type: application/json

{
  "question": "ここに質問文",
  "mode": "strict",
  "sources": ["sample.pdf"]
}
```

- `mode`: `"strict"` または `"study"`
- `sources`: 参照を絞る場合のファイル名配列（省略可）
- レスポンス：

```
{
  "answer": "回答テキスト",
  "sources": ["sample.pdf"],
  "meta": {
    "chunks_used": 5,
    "chunks_total": 120,
    "estimated_tokens": 1234
  }
}
```

### POST `/webhook/rag-pdf`（PDF 登録）

```
POST http://localhost:5678/webhook/rag-pdf
X-API-Key: rag-local-dev-key-2025
Content-Type: multipart/form-data

file=@your.pdf
```

- フィールド名は `file`
- 自動で分割・埋め込み生成され、DB に登録されます

### POST `/webhook/rag-delete`（PDF 削除）

```
POST http://localhost:5678/webhook/rag-delete
X-API-Key: rag-local-dev-key-2025
Content-Type: application/json

{
  "source": "sample.pdf"
}
```

- 指定ファイル名のチャンクを DB から削除します

## FAQ

**Q. GPU がなくても動きますか？**
A. 動きますが、応答に数分かかります。GPU（VRAM 8GB+）を強く推奨します。

**Q. setup.bat を再実行したいです**
A. `setup.bat --force` で WF を再インポートします。

**Q. データはどこに保存されますか？**
A. Docker volume（`pg_data` / `n8n_data` / `ollama_data`）に保存。`docker compose down -v` で全削除されます。

**Q. 外部に通信していませんか？**
A. 初回のモデル DL（Ollama Hub）と PDF 内の外部リンクを除き、推論・検索は完全にローカルで完結します。

**Q. 対応言語は？**
A. 日本語に最適化（pgroonga + MeCab）。英語も動作しますが精度は日本語ほど検証していません。

## トラブルシューティング

- `setup.log` にすべての出力が記録されます。エラー時はこちらを確認してください。
- Docker Desktop が起動していない場合は先に起動してください。
- ポート競合（5432 / 5678 / 11434）が起きる場合は他のプロセスを停止してください。

## 🛠 運用ガイド

### バックアップ（推奨運用）

`scripts\backup.ps1` で PostgreSQL と n8n データを一括バックアップできます。

```powershell
.\scripts\backup.ps1
```

デフォルトでは `backups\` 配下に `ansera-db-<timestamp>.sql` と `ansera-n8n-<timestamp>.tar` が出力されます。出力先を変更する場合は `-Destination` パラメータを使用してください。

```powershell
.\scripts\backup.ps1 -Destination D:\Ansera\Backups
```

> 重要: バックアップは別ドライブまたはクラウドストレージへ転送してください。同一ディスクに置くと災害時に同時消失します。定期実行は Windows タスクスケジューラから登録できます（後述）。

### ワークフローのエクスポート

n8n 画面の誤操作や WF JSON の破損に備え、定期的に WF をエクスポートしておくと安全です。

```bash
docker exec ansera-n8n n8n export:workflow --all --output=/tmp/wf-backup.json
docker cp ansera-n8n:/tmp/wf-backup.json ./wf-backup-YYYYMMDD.json
```

復元手順は `setup.bat --force` で WF 再インポート、または n8n 画面の **Workflows → Import from File** から行えます。

### コンポーネントのバージョン

| コンポーネント | 現在のタグ | 状態 |
|---|---|---|
| n8n | `1.88.0` | ✅ 固定済み |
| PostgreSQL (pgroonga) | `latest-debian-17` | ⚠️ メジャーのみ固定 |
| Ollama | `latest` | ⚠️ 未固定 |
| pgvector | `v0.8.2` | ✅ 固定済み (Dockerfile 内) |

将来的なリリースで `latest` タグを廃止し、全コンポーネントを特定バージョンに固定する予定です。現状はメジャーバージョンの安定運用を優先しており、`docker compose pull` での自動アップデート互換性を確保しています。

## 有料セットアップ支援

導入が難しい方向けに、有料でリモートセットアップ支援を提供しています。

- 環境構築代行
- 動作確認サポート
- 初期チューニング

詳細・お申込みは下記までご連絡ください。

## 連絡先

<!-- TODO: メールアドレス / 連絡フォーム URL を記入 -->

## 🔐 Webhook認証

初回セットアップ時、`setup.bat` が自動生成した `WEBHOOK_API_KEY` を確認するには：

- Mac/Linux: `cat .env`
- Windows: `type .env`

このキーをn8nのcredential作成画面で入力してください。
UIは初回起動時にこのキーを尋ねます。

## 🔐 セキュリティ

Anseraは「データ流出ゼロ」を最優先に設計されています。

### 自動セキュリティ対策
- 認証情報は setup.bat 実行時に顧客ごとにランダム生成
- 全ポートが localhost 限定（外部公開なし）
- 全処理がお客様のPC内で完結

詳細は SECURITY.md を参照してください。

### お客様へのお願い

❌ **やってはいけないこと**:
- ポート 5432, 5678, 11434 の外部公開
- ngrok等のトンネリングツール使用
- .env ファイルの共有

✅ **推奨**:
- 週1回のバックアップ
- .env ファイルの安全な保管
- Docker Desktop の定期更新

### 認証情報の確認方法

setup.bat が自動生成した認証情報は .env ファイルに保存されています：
- Mac/Linux: `cat .env`
- Windows: `type .env`

## 📦 含まれるソフトウェア (Attribution)

This package includes n8n (https://n8n.io/), an open-source workflow 
automation tool, used under the Sustainable Use License 
(https://docs.n8n.io/sustainable-use-license/).

### 日本語訳（参考）

本パッケージには n8n (https://n8n.io/) というオープンソースのワークフロー
自動化ツールが含まれており、Sustainable Use License 
(https://docs.n8n.io/sustainable-use-license/) のもとで利用しています。

その他の含まれるソフトウェアおよびライセンス詳細については `LICENSES.md` を
ご参照ください。

## 🔄 ロールバック手順（v33 セキュリティ強化版）

v33 への更新で問題が発生した場合、`docker_backup_v33` から復元できます：

```bash
docker compose down
cd /Users/blonded/rag-ui/
mv docker docker_failed_v33
mv docker_backup_v33 docker
ls docker/
```

`ls docker/` で `setup.bat` `docker-compose.yml` `n8n-workflows/` 等が表示されれば復元成功です。

