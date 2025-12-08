# LiteLLM Proxy for Local Models - Complete Setup

You now have everything set up to run a Dockerized LiteLLM proxy for LM Studio and Ollama on your MacBook Pro!

## What Was Created

### Configuration Files
1. **`docker-compose.local-models.yml`** - Docker Compose configuration that:
   - Builds and runs LiteLLM proxy in a container
   - Uses `host.docker.internal` to reach your Mac's LM Studio and Ollama
   - Exposes proxy at `http://localhost:4000`

2. **`config.local-models.yaml`** - LiteLLM proxy configuration that:
   - Defines model routes for Ollama models (llama2, llama3, mistral, neural-chat)
   - Defines model routes for LM Studio
   - Includes catch-all patterns for any model

3. **`.env.local.example`** - Environment variable template (optional)

### Helper Scripts & Examples
4. **`start-local-proxy.sh`** - Convenient startup script with commands:
   - `./start-local-proxy.sh start` - Start proxy with logs
   - `./start-local-proxy.sh status` - Check if running
   - `./start-local-proxy.sh test` - Test connectivity
   - And more...

5. **`examples_local_models.py`** - Python script with example usage:
   - Chat completions with Ollama and LM Studio
   - Streaming responses
   - Multi-turn conversations
   - Model listing and health checks

### Documentation
6. **`SETUP_LOCAL_MODELS.md`** - Comprehensive setup guide covering:
   - Prerequisites installation (LM Studio, Ollama, Docker)
   - Step-by-step setup instructions
   - Usage examples in Python, curl, and Node.js
   - Advanced configuration options
   - Architecture overview

7. **`TROUBLESHOOTING_LOCAL_MODELS.md`** - Solutions for:
   - Docker connectivity issues
   - Port conflicts
   - Missing models
   - Performance issues
   - Complete diagnostic checklist

8. **`QUICK_REFERENCE.md`** - One-page reference with:
   - Common commands
   - API endpoints
   - Port mappings
   - Quick fixes for common issues

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                 Your MacBook Pro                     │
│                                                      │
│  ┌─────────────────┐      ┌──────────────────────┐ │
│  │   LM Studio     │      │      Ollama          │ │
│  │ localhost:1234  │      │  localhost:11434     │ │
│  └────────┬────────┘      └───────────┬──────────┘ │
│           │                           │            │
│           └───────────┬───────────────┘            │
│                       │                            │
│          Docker Container (Bridge Network)        │
│          ┌────────────▼───────────────┐           │
│          │   LiteLLM Proxy            │           │
│          │  Port 4000                 │           │
│          │  - Unified API             │           │
│          │  - Load balancing          │           │
│          │  - Rate limiting           │           │
│          └────────────┬───────────────┘           │
│                       │                            │
└───────────────────────┼────────────────────────────┘
                        │
                        ▼
         Your Applications
         (Python, Node.js, cURL, etc.)
```

## Quick Start (5 Minutes)

### 1. Prerequisites
- LM Studio installed and running with a model loaded
- Ollama installed with models pulled: `ollama pull llama2 mistral`
- Docker Desktop for Mac running

### 2. Start the Proxy
```bash
cd /path/to/litellm

# Start proxy with logs visible
./start-local-proxy.sh start

# In another terminal, verify it's working
./start-local-proxy.sh test
```

### 3. Use It
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000",
    api_key="sk-1234"
)

response = client.chat.completions.create(
    model="ollama-llama2",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

## Key Concepts

### `host.docker.internal`
- Special DNS name that Docker containers use to reach the host (Mac)
- Automatically configured in `docker-compose.local-models.yml`
- Allows container at port 4000 to reach LM Studio at 1234 and Ollama at 11434

### Model Names
- In proxy config: `ollama-llama2`, `lm-studio-default`
- In API calls: Use the names defined in `config.local-models.yaml`
- View available models: `curl http://localhost:4000/models`

### API Compatibility
- Full OpenAI API compatibility (drop-in replacement)
- Works with any OpenAI SDK client
- Supports streaming, embeddings, and more

## Next Steps

1. **Read the detailed setup guide:**
   ```bash
   cat SETUP_LOCAL_MODELS.md
   ```

2. **Start the proxy:**
   ```bash
   ./start-local-proxy.sh start
   ```

3. **Test it works:**
   ```bash
   python3 examples_local_models.py
   ```

4. **Integrate with your applications:**
   - Replace OpenAI base URL with `http://localhost:4000`
   - Use model names from `config.local-models.yaml`

5. **Customize configuration:**
   - Edit `config.local-models.yaml` to:
     - Add more model routes
     - Configure rate limiting
     - Enable authentication
     - Add model aliases

## Troubleshooting

**Models not showing?**
```bash
# Check config is mounted
docker exec litellm-proxy cat /app/config.yaml
```

**Connection refused?**
```bash
# Verify services running
curl http://localhost:1234/v1/models  # LM Studio
curl http://localhost:11434/api/tags  # Ollama
```

**Slow responses?**
- Use smaller models (7B parameters)
- Reduce `max_tokens`
- Check Activity Monitor for resource usage

See `TROUBLESHOOTING_LOCAL_MODELS.md` for complete guide.

## Common Commands

```bash
# Start/stop/restart
./start-local-proxy.sh start              # Foreground with logs
./start-local-proxy.sh start-daemon       # Background
./start-local-proxy.sh stop
./start-local-proxy.sh restart

# Monitor
./start-local-proxy.sh logs               # View logs
./start-local-proxy.sh status             # Check status
./start-local-proxy.sh test               # Test connectivity

# Direct docker-compose
docker-compose -f docker-compose.local-models.yml up -d
docker-compose -f docker-compose.local-models.yml logs -f
docker-compose -f docker-compose.local-models.yml down
```

## API Endpoints

```
GET    /models                          # List available models
GET    /health/liveliness               # Health check

POST   /chat/completions                # Chat API
POST   /completions                     # Completion API
POST   /embeddings                      # Embedding API

GET    /model_info                      # Model information
```

## Advanced Features

### Enable Authentication
Edit `config.local-models.yaml`:
```yaml
router_settings:
  key_management_system: "mock"
  master_key: "sk-your-master-key"
```

### Configure Rate Limiting
```yaml
model_list:
  - model_name: ollama-llama2
    litellm_params:
      model: ollama/llama2
      api_base: http://host.docker.internal:11434
      rpm: 60  # Requests per minute limit
      timeout: 300  # Timeout in seconds
```

### Add Load Balancing
```yaml
model_list:
  - model_name: fast-model
    litellm_params:
      model: ollama/mistral
      api_base: http://host.docker.internal:11434
      weight: 100  # 100% of requests
```

## Files Reference

| File | Purpose |
|------|---------|
| `docker-compose.local-models.yml` | Docker configuration |
| `config.local-models.yaml` | Proxy model configuration |
| `start-local-proxy.sh` | Startup helper script |
| `examples_local_models.py` | Python example usage |
| `SETUP_LOCAL_MODELS.md` | Detailed setup guide |
| `TROUBLESHOOTING_LOCAL_MODELS.md` | Troubleshooting guide |
| `QUICK_REFERENCE.md` | One-page reference |
| `.env.local.example` | Environment variables template |

## Resources

- **LiteLLM Documentation:** https://docs.litellm.ai/
- **LiteLLM Proxy Docs:** https://docs.litellm.ai/docs/simple_proxy
- **LM Studio:** https://lmstudio.ai/
- **Ollama:** https://ollama.ai/
- **OpenAI Python SDK:** https://github.com/openai/openai-python

## Support

If you run into issues:

1. Check `TROUBLESHOOTING_LOCAL_MODELS.md`
2. Run diagnostic: `./start-local-proxy.sh check`
3. Review logs: `./start-local-proxy.sh logs`
4. Check that all three services are running:
   - LM Studio: Running on Mac
   - Ollama: Running on Mac
   - LiteLLM Proxy: Running in Docker

## Summary

You now have:
- ✅ A Dockerized LiteLLM proxy ready to run
- ✅ Configuration for LM Studio and Ollama
- ✅ Helper scripts to manage the proxy
- ✅ Python examples to test it
- ✅ Complete documentation
- ✅ Troubleshooting guide

**Ready to get started?**
```bash
./start-local-proxy.sh start
```

Then in another terminal:
```bash
./start-local-proxy.sh test
```

That's it! You now have a unified API gateway for your local LLMs.
