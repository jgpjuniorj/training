# local-openai-proxy

Small OpenAI-compatible HTTP proxy that validates a local API key and forwards
requests to a local Ollama server (default http://localhost:11434). Useful to
expose a stable API key for VS Code or remote tools while keeping the model
running locally.

Quick start

1. Install dependencies:

```bash
cd /mnt/c/training/local-openai-proxy
npm install
```

2. Start Ollama and a model (see project root instructions). Ollama default:
`http://localhost:11434` and Ollama bearer `ollama`.

3. Start the proxy:

```bash
# foreground
npm start

# or background
nohup npm start >/tmp/local-openai-proxy.log 2>&1 &
tail -f /tmp/local-openai-proxy.log
```

4. The first run generates a key in `keys.txt` (or you can set `PROXY_API_KEYS` in environment).

Usage in VS Code / Continue

- Base URL: `http://localhost:11435/v1`
- API Key: value from `keys.txt` (or `PROXY_API_KEYS`)
- Model: any Ollama model name (e.g. `qwen2.5-coder:7b`)

Example request:

```bash
curl http://localhost:11435/v1/chat/completions \
  -H "Authorization: Bearer <YOUR_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"hello"}]}'
```
