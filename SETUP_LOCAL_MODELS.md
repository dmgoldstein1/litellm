# LiteLLM Proxy Setup for LM Studio and Ollama on MacBook Pro

This guide explains how to run a Dockerized LiteLLM Proxy that connects to LM Studio and Ollama running locally on your MacBook Pro.

## Overview

You'll have:
- **LM Studio**: Running on your Mac at `localhost:1234` (local model inference)
- **Ollama**: Running on your Mac at `localhost:11434` (local model inference)
- **LiteLLM Proxy**: Running in Docker at `localhost:4000` (unified API gateway)

The Docker container uses `host.docker.internal` to reach services on your Mac host.

## Prerequisites

### 1. Install LM Studio
- Download from: https://lmstudio.ai/
- Install and launch LM Studio
- Download at least one model in the app
- Start the LM Studio server (usually listens on `localhost:1234`)
- You'll see the server status in the app

### 2. Install Ollama
- Download from: https://ollama.ai/
- Install and launch Ollama
- Pull models you want to use:
  ```bash
  ollama pull llama2
  ollama pull llama3
  ollama pull mistral
  ollama pull neural-chat
  ```
- Ollama server runs at `localhost:11434` by default

### 3. Have Docker and Docker Compose installed
- Docker Desktop for Mac: https://www.docker.com/products/docker-desktop/
- Verify: `docker --version && docker-compose --version`

## Setup Steps

### Step 1: Navigate to the LiteLLM repository
```bash
cd /path/to/litellm
```

### Step 2: Configure Your Models

Edit `config.local-models.yaml` and update the model names to match what you have:

**For LM Studio:**
- Find the exact model name in LM Studio's server dropdown
- Common examples: `mistral-7b-instruct`, `neural-chat-7b`, `llama-2-7b-chat`
- Update the `lm-studio-default` and `lm-studio-chat` entries

**For Ollama:**
- The example config includes: `llama2`, `llama3`, `mistral`, `neural-chat`
- You can modify these to match models you've pulled

### Step 3: Start LM Studio and Ollama

**LM Studio:**
1. Open LM Studio
2. Go to the "Local Server" tab
3. Select your model from the dropdown
4. Click "Start Server"
5. Verify it's running at `http://localhost:1234`

**Ollama:**
```bash
# If not already running, start Ollama
# On Mac, this typically auto-starts in the background
# Verify it's running:
curl http://localhost:11434/api/tags
```

### Step 4: Build and Start the LiteLLM Proxy

```bash
# Build the Docker image (first time only)
docker-compose -f docker-compose.local-models.yml build

# Start the proxy in the foreground (to see logs)
docker-compose -f docker-compose.local-models.yml up

# Or start in the background
docker-compose -f docker-compose.local-models.yml up -d

# Check logs at any time
docker-compose -f docker-compose.local-models.yml logs -f litellm
```

### Step 5: Verify the Proxy is Running

```bash
# Check if proxy is healthy
curl http://localhost:4000/health/liveliness

# List available models
curl http://localhost:4000/models
```

## Usage

### Using with Python

```python
from openai import OpenAI

# Create client pointing to LiteLLM proxy
client = OpenAI(
    base_url="http://localhost:4000",
    api_key="sk-1234"  # Any key works (no auth enabled by default)
)

# Use any configured model
response = client.chat.completions.create(
    model="ollama-llama2",  # or "lm-studio-default", etc.
    messages=[
        {"role": "user", "content": "What is the capital of France?"}
    ],
    max_tokens=100,
    temperature=0.7
)

print(response.choices[0].message.content)
```

### Using with curl

```bash
# Chat completions with Ollama model
curl http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama-llama2",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 100
  }'

# Chat completions with LM Studio model
curl http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "lm-studio-chat",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 100
  }'
```

### Using with OpenAI Compatible Libraries

Any library that supports custom OpenAI base URLs will work:

```javascript
// Node.js example
import OpenAI from "openai";

const openai = new OpenAI({
  baseURL: "http://localhost:4000",
  apiKey: "sk-1234",
});

const message = await openai.chat.completions.create({
  model: "ollama-llama3",
  messages: [{ role: "user", content: "Hello!" }],
});

console.log(message);
```

## Troubleshooting

### Docker container can't reach LM Studio or Ollama

**Problem:** Connection refused errors in proxy logs

**Solution:** 
- Verify LM Studio and Ollama are actually running and listening
- On Mac, `host.docker.internal` is required (already configured)
- Check Docker Desktop settings allow host communication

```bash
# Test from inside the container
docker-compose -f docker-compose.local-models.yml exec litellm \
  curl http://host.docker.internal:1234/v1/models

docker-compose -f docker-compose.local-models.yml exec litellm \
  curl http://host.docker.internal:11434/api/tags
```

### Models not showing up in `/models` endpoint

**Solution:**
- Verify `config.local-models.yaml` is mounted correctly
- Check the `docker-compose.local-models.yml` has the correct volume path
- Restart the container after config changes:
  ```bash
  docker-compose -f docker-compose.local-models.yml restart litellm
  ```

### Can't connect to proxy from host

**Problem:** `Connection refused` when calling `http://localhost:4000`

**Solution:**
- Verify the port mapping is correct in `docker-compose.local-models.yml`
- Check if another service is using port 4000
- Verify container is running: `docker ps | grep litellm`

### Model inference is slow

**Problem:** Responses take a long time

**Solution:**
- This is expected with local LLMs on consumer hardware
- Larger models are slower (7B < 13B < 70B parameters)
- Reduce `max_tokens` to speed up initial response
- Try a smaller model if available

## Advanced Configuration

### Enable Authentication

Edit `config.local-models.yaml` and uncomment the router_settings section:

```yaml
router_settings:
  key_management_system: "mock"
  master_key: "sk-litellm-master-key"
```

Then require API keys:
```bash
curl http://localhost:4000/chat/completions \
  -H "Authorization: Bearer sk-litellm-master-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "ollama-llama2", "messages": [{"role": "user", "content": "Hi"}]}'
```

### Add Rate Limiting

Add to `router_settings` in `config.local-models.yaml`:

```yaml
router_settings:
  num_retries: 2
  timeout: 60
  enable_logging: true
```

### Monitor Logs

```bash
# Stream logs in real-time
docker-compose -f docker-compose.local-models.yml logs -f

# View specific number of lines
docker-compose -f docker-compose.local-models.yml logs --tail=50
```

## Stopping Services

```bash
# Stop the proxy
docker-compose -f docker-compose.local-models.yml down

# Stop and remove volumes
docker-compose -f docker-compose.local-models.yml down -v

# Stop LM Studio and Ollama
# LM Studio: Quit the app
# Ollama: `brew services stop ollama` or quit the app
```

## Additional Resources

- LiteLLM Docs: https://docs.litellm.ai/
- LM Studio Docs: https://lmstudio.ai/docs/
- Ollama Docs: https://github.com/ollama/ollama
- OpenAI API Reference: https://platform.openai.com/docs/api-reference/chat/create

## Architecture Diagram

```
Your MacBook Pro:
┌─────────────────────────────────────────┐
│  LM Studio (localhost:1234)             │
│  Ollama (localhost:11434)               │
└───────────────┬─────────────────────────┘
                │
                │ host.docker.internal
                ▼
        ┌──────────────────────┐
        │  Docker Container    │
        │  LiteLLM Proxy       │
        │  (localhost:4000)    │
        │  - Unified API       │
        │  - Load balancing    │
        │  - Rate limiting     │
        └──────────────────────┘
                │
                ▼
        Your Applications
        (Python, Node.js, etc.)
```

## Tips for Best Results

1. **Model Selection:**
   - 7B models: Fast, good for testing (Mistral 7B, Llama 2 7B)
   - 13B models: Better quality, moderate speed
   - For MacBook Pro with good specs, 13B models work well

2. **Performance Optimization:**
   - Use smaller models for latency-sensitive tasks
   - Batch requests when possible
   - Adjust `max_tokens` based on your needs

3. **Memory Management:**
   - Close other apps to free up RAM
   - Monitor memory with Activity Monitor
   - If running out of memory, restart LM Studio/Ollama

4. **Keep Models Updated:**
   - Regularly pull latest versions: `ollama pull llama3`
   - LM Studio auto-updates models periodically
