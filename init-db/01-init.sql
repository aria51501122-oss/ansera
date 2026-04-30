CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgroonga;

CREATE TABLE IF NOT EXISTS documents (
  id BIGSERIAL PRIMARY KEY,
  content TEXT,
  source TEXT,
  embedding vector(1024),
  content_tsv tsvector
);

CREATE INDEX IF NOT EXISTS idx_documents_content_pgroonga
  ON documents USING pgroonga (content) WITH (tokenizer='TokenMecab');

CREATE OR REPLACE FUNCTION documents_tsv_trigger()
RETURNS trigger LANGUAGE plpgsql AS
$$
BEGIN
  NEW.content_tsv := to_tsvector('simple', NEW.content);
  RETURN NEW;
END;
$$
;

DROP TRIGGER IF EXISTS trg_documents_tsv ON documents;
CREATE TRIGGER trg_documents_tsv
  BEFORE INSERT OR UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION documents_tsv_trigger();

CREATE OR REPLACE FUNCTION match_documents_hybrid(
  query_embedding vector,
  query_text text,
  match_count integer DEFAULT 10,
  source_filter text[] DEFAULT NULL
)
RETURNS TABLE(id bigint, content text, source text, similarity double precision)
LANGUAGE plpgsql AS
$$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.content,
    d.source,
    (0.7 * (1 - (d.embedding <=> query_embedding)) +
     0.3 * CASE
       WHEN d.content &@~ query_text THEN 1.0
       ELSE 0.0
     END
    )::float AS similarity
  FROM documents d
  WHERE (source_filter IS NULL OR d.source = ANY(source_filter))
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$
;

CREATE TABLE IF NOT EXISTS access_logs (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMPTZ DEFAULT now(),
  endpoint TEXT NOT NULL,
  question TEXT,
  source_filter TEXT,
  mode TEXT,
  chunks_used INTEGER,
  estimated_tokens INTEGER,
  response_status TEXT,
  client_ip TEXT,
  processing_time_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp
  ON access_logs (timestamp DESC);
