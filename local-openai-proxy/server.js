// Simple OpenAI-compatible proxy that validates a local API key and forwards
// requests to a local Ollama server. Useful to expose a consistent API key to
// VS Code or other tools while keeping Ollama itself using its local bearer.

require('dotenv').config();
const express = require('express');
const axios = require('axios');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(morgan('tiny'));
app.use(express.json({ limit: '50mb' }));

const KEYS_FILE = path.join(__dirname, 'keys.txt');
let allowedKeys = [];

if (process.env.PROXY_API_KEYS) {
  allowedKeys = process.env.PROXY_API_KEYS.split(',').map(k => k.trim()).filter(Boolean);
} else if (fs.existsSync(KEYS_FILE)) {
  allowedKeys = fs.readFileSync(KEYS_FILE, 'utf8').split(/\r?\n/).map(l => l.trim()).filter(Boolean);
} else {
  // generate a key and persist it
  const k = 'local-' + Math.random().toString(36).slice(2, 12);
  allowedKeys = [k];
  fs.writeFileSync(KEYS_FILE, k + '\n');
  console.log('\n=== GENERATED API KEY ===');
  console.log('Use this key in your clients: ' + k + '\n');
}

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const FORWARD_BEARER = process.env.OLLAMA_BEARER || 'ollama';

function verifyKey(req) {
  const h = req.headers['authorization'] || '';
  if (!h.toLowerCase().startsWith('bearer ')) return false;
  const key = h.slice(7).trim();
  return allowedKeys.includes(key);
}

app.use('/v1', async (req, res) => {
  if (!verifyKey(req)) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  // Forward to Ollama: keep path under /v1
  const target = OLLAMA_URL + req.originalUrl;

  try {
    const headers = Object.assign({}, req.headers);
    // Replace incoming Authorization with Ollama's internal bearer
    headers['authorization'] = 'Bearer ' + FORWARD_BEARER;
    // remove host to avoid conflicts
    delete headers['host'];

    const axiosRes = await axios({
      url: target,
      method: req.method,
      headers,
      data: req.body,
      responseType: 'stream',
      timeout: 120000
    });

    res.status(axiosRes.status);
    for (const [k, v] of Object.entries(axiosRes.headers)) {
      // avoid duplicate transfer-encoding headers
      if (k.toLowerCase() === 'transfer-encoding') continue;
      res.setHeader(k, v);
    }
    axiosRes.data.pipe(res);
  } catch (err) {
    if (err.response) {
      res.status(err.response.status).json({ error: err.response.data });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});

const PORT = process.env.PORT || 11435;
app.listen(PORT, () => {
  console.log(`Local OpenAI-compatible proxy listening on http://0.0.0.0:${PORT}`);
});
