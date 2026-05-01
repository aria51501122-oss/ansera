# NOTICE

This product includes software developed by third parties.
See below for attribution and license information.

---

# Ansera - サードパーティソフトウェア・ライセンス

> 最終更新: 2026-04-30 (v33)

Ansera は以下のオープンソースソフトウェアおよびAIモデルを利用しています。
すべてのコンポーネントは商用利用可能なライセンスで提供されています。

## ⚠️ 重要: n8n Attribution

This package includes n8n (https://n8n.io/), an open-source workflow 
automation tool, used under the Sustainable Use License 
(https://docs.n8n.io/sustainable-use-license/).

n8n is a fair-code licensed workflow automation tool. The Sustainable 
Use License permits internal business use, including the model employed 
by Ansera (free distribution + paid setup support).

For commercial use cases beyond what the SUL permits, please contact 
n8n directly at help@n8n.io.

---

## 含まれるコンポーネント一覧

### ワークフローエンジン
| 名称 | バージョン | ライセンス | URL |
|---|---|---|---|
| n8n | 1.88.0 | Sustainable Use License | https://n8n.io/ |

### LLM実行環境・モデル
| 名称 | バージョン | ライセンス | URL |
|---|---|---|---|
| Ollama | latest | MIT | https://github.com/ollama/ollama |
| Qwen3-8B | 8B | Apache 2.0 | https://huggingface.co/Qwen/Qwen3-8B |
| BGE-M3 | latest | MIT | https://huggingface.co/BAAI/bge-m3 |

### データベース
| 名称 | バージョン | ライセンス | URL |
|---|---|---|---|
| PostgreSQL | 17 | PostgreSQL License | https://www.postgresql.org/ |
| pgvector | 0.8.2 | PostgreSQL License | https://github.com/pgvector/pgvector |
| PGroonga | 4.0.6 | PostgreSQL License | https://pgroonga.github.io/ |

### コンテナ基盤
| 名称 | ライセンス | 備考 |
|---|---|---|
| Docker Engine | Apache 2.0 | コア部分 |
| Docker Desktop | Docker Subscription Service Agreement | 顧客責任で別途同意必要 |

### UI
| 名称 | バージョン | ライセンス | URL |
|---|---|---|---|
| Tailwind CSS | 3.4.0 | MIT | https://tailwindcss.com/ |
| marked.js | latest | MIT | https://github.com/markedjs/marked |

---

## ライセンス全文へのリンク

各ライセンスの詳細は以下を参照してください:

- **Sustainable Use License (n8n)**: https://docs.n8n.io/sustainable-use-license/
- **MIT License**: https://opensource.org/licenses/MIT
- **Apache License 2.0**: https://www.apache.org/licenses/LICENSE-2.0
- **PostgreSQL License**: https://www.postgresql.org/about/licence/
- **Docker Subscription Service Agreement**: https://www.docker.com/legal/docker-subscription-service-agreement/

---

## Docker Desktop に関する注意事項

Docker Desktop は Docker, Inc. が提供する独自ライセンスのソフトウェアです。
以下の条件を満たす組織での利用は無料です:

- 従業員数 250人未満
- かつ年間売上 \$10M (約15億円) 未満

上記を超える組織での商用利用には Docker Pro/Team/Business 契約が必要です。
詳細は https://www.docker.com/pricing/ をご確認ください。

このライセンスは Docker, Inc. と Docker Desktop 利用者の間で発生する
契約であり、Ansera プロジェクトはこの契約に関与しません。

---

## 商用利用について

Ansera のビジネスモデル（パッケージ無料配布 + 有償セットアップ支援）は、
2026年4月にn8n社（Freddie AI）に直接確認し、SULの「fully permitted」範囲内
であることが書面で確認されています。

将来的にビジネスモデルを以下のように拡張する場合は、事前に
help@n8n.io に連絡し、commercial agreement について相談する予定です:

- 継続的な月額保守サポートの提供
- カスタムワークフロー開発の有償提供
- パッケージ自体の有償販売
- 高度な n8n 機能の利用（Git管理、Custom nodes、Multiple environments）
