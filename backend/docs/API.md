# API reference

## Authentication and rate limiting

Set `RAG_API_KEY` to require the `X-API-Key` header on HTTP endpoints:

```powershell
$env:RAG_API_KEY = "local-demo-secret"
```

Optionally set `RAG_RATE_LIMIT_PER_MINUTE` to limit requests per client IP.
Both controls are disabled by default for local development.

## `GET /health`

Returns service status, corpus size, active model, and code version.

## `POST /session/{session_id}/chunk`

Request:

```json
{"text":"What are the foreign currency reimbursement rules?"}
```

The response contains `decision`, `answer`, `citations`, `version`, and
`telemetry`. The controller decisions are `WAIT`, `RETRIEVE`, and
`NO_RETRIEVE`.

## `GET /session/{session_id}/events`

Returns structured events such as controller decisions, subqueries, search
latency, LLM usage, draft acceptance/rejection, delta retrieval, and citation
validation.

## `POST /session/{session_id}/audio`

Multipart request with a `file` field. The Gnani Prisma REST adapter sends clips
up to 30 seconds to Gnani (set `GNANI_API_KEY` in the backend `.env`) and forwards the returned transcript as a segment. Each
segment contains `timestamp_s`, `text`, and the normal chunk response. The
backend returns `503` when `GNANI_API_KEY` is missing and `422` when Gnani
rejects or cannot process the request.

## Corpus management

`POST /corpus/upload` accepts one `.pdf`, `.md`, `.txt`, or `.json` file,
rebuilds the processed corpus, and hot-reloads retrieval. `POST /corpus/rebuild`
rebuilds from `RAG_RAW_DIR` (default `data/raw`). Both routes require the same
`X-API-Key` when `RAG_API_KEY` is configured.

## WebSocket

Connect to `ws://127.0.0.1:8000/ws/session/{session_id}` and send the same JSON
payload as the HTTP endpoint. Each message receives the same response shape.
