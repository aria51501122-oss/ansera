# Ansera セキュリティポリシー

> 最終更新: 2026-04-30 (v33)

## 🎯 基本方針

Anseraは「データ流出ゼロ」を最優先に設計されています。

- 完全ローカル動作: すべての処理がお客様のPC内で完結
- 外部送信ゼロ: お客様のデータは一切外部に送信されません
- 顧客ごとに独立: 各お客様の環境は完全に独立
- オープンソース: 全コードが公開され、第三者検証可能

## 🔒 セキュリティ対策

### 1. 完全ローカル処理
PDF・質問・回答・ログすべてお客様のPC内のみ。外部送信なし。

### 2. 認証情報の自動ランダム化
setup.bat 実行時に以下を顧客ごとにランダム生成：
- PostgreSQL パスワード（32文字）
- n8n 暗号化キー（32文字）
- Webhook API キー（32文字）

### 3. ネットワーク分離
全サービスが localhost (127.0.0.1) のみにバインド。
外部からアクセス不可。

### 4. SQLインジェクション対策
n8n標準のパラメータバインディング使用。

### 5. Webhook認証必須
全APIエンドポイントで X-API-Key ヘッダー必須。

### 6. Dockerコンテナの分離
- privileged モード未使用
- ホストファイルシステムへの広範なマウントなし
- Docker socket マウントなし

### 7. 完全オフライン動作
全コンポーネントが外部CDN非依存。
ネットワーク切断状態でも動作。

## ⚠️ お客様へのお願い

### 推奨
- 週1回のバックアップ
- .env ファイルの安全な保管
- Docker Desktop / OS の定期更新

### 禁止
- ポートの外部公開
- 認証情報の共有
- 不審なPDFのアップロード

## 📞 セキュリティ問題の報告

連絡先: [営業前に記入]

## 📋 ログポリシー

### 保存される情報

Ansera は `access_logs` テーブルに以下を記録します:

- `timestamp`: アクセス日時
- `endpoint`: 呼び出された API（rag-chat / rag-pdf / rag-delete）
- `question`: 質問内容（全文）
- `source_filter`: 検索対象フィルタ
- `mode`: 検索モード
- `chunks_used`: 使用チャンク数
- `estimated_tokens`: 推定トークン数
- `response_status`: HTTP ステータス
- `client_ip`: クライアント IP
- `processing_time_ms`: 処理時間

### データ保管場所

全てのログは PostgreSQL コンテナ内に保存され、外部サーバへの送信は一切行いません。

### ログ閲覧

```
docker exec -it ansera-db psql -U ansera -d ansera -c "SELECT * FROM access_logs ORDER BY timestamp DESC LIMIT 100;"
```

### ログ削除（推奨運用）

30 日以上前のログを削除する SQL の例:

```sql
DELETE FROM access_logs WHERE timestamp < NOW() - INTERVAL '30 days';
```

保持期間は顧客の運用ポリシーに従って設定してください。

### データ流出ゼロの根拠

- 全ログはローカル PostgreSQL 内に閉じている
- n8n テレメトリ無効化済み（v33 以降）
- 外部 API 呼び出しは LLM ルートに存在しない

## 🗂 PDF / バイナリデータ管理

### n8n 内部仕様（理解しておくべきこと）

Webhook 経由でアップロードされた PDF は、n8n の内部仕様により以下に一時保管されます:

- 保管場所: コンテナ内 `/home/node/.n8n/binaryData/`（Docker ボリューム `n8n_data`）
- 紐付け: 各 execution 記録（n8n 内部 SQLite）に関連付け
- 削除タイミング: 紐付く execution が prune されたとき

外部送信は一切ありません（ボリューム内に閉じている）が、機密 PDF が長期間滞留する可能性があるため、Ansera では以下の自動 prune 設定を `docker-compose.yml` に組み込み済みです（v33 以降）:

```
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=336      # 14 日 (時間単位)
EXECUTIONS_DATA_PRUNE_MAX_COUNT=10000
```

**14 日以上経過した execution と、紐付くバイナリデータ（PDF）は自動削除**されます。

### 手動 purge（即時削除したい場合）

#### 方法 1: バイナリデータのみ即時削除

```
docker exec --user node ansera-n8n sh -c "rm -rf /home/node/.n8n/binaryData/*"
```

> 注: n8n を停止せずに実行しても問題ありませんが、進行中の execution は失敗する可能性があります。

#### 方法 2: execution 履歴ごと削除

```
docker exec --user node ansera-n8n sh -c "rm -f /home/node/.n8n/database.sqlite-shm /home/node/.n8n/database.sqlite-wal" 
docker compose restart n8n
```

> 注: 履歴・実行ログがすべてリセットされます。WF 定義は残ります。

### 保持期間の調整

社内ポリシーに合わせて `EXECUTIONS_DATA_MAX_AGE` を変更できます:

| 用途 | 推奨値 (時間) |
|---|---|
| 高機密用途（即日削除） | 24 |
| 標準（v33 デフォルト） | 336 (= 14 日) |
| デバッグ重視 | 720 (= 30 日) |

`docker-compose.yml` を編集後、`docker compose up -d` で反映されます。

## 📚 ライセンス

詳細は LICENSES.md 参照。
全コンポーネントが商用利用可能。
