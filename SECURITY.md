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

## 📚 ライセンス

詳細は LICENSES.md 参照。
全コンポーネントが商用利用可能。
