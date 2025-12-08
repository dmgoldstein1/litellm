# Quick Reference - LiteLLM Proxy for Local Models

## Quick Start (5 minutes)

```bash
# 1. Start LM Studio and Ollama on your Mac
# 2. Navigate to litellm repository
cd /path/to/litellm

# 3. Start the proxy
./start-local-proxy.sh start

# 4. In another terminal, test it
curl http://localhost:4000/models

# 5. Use it in Python
python3 examples_local_models.py
```

## Common Commands

```bash
# Start proxy (see logs)
./start-local-proxy.sh start

# Start proxy (background)
./start-local-proxy.sh start-daemon

# Stop proxy
./start-local-proxy.sh stop

# Restart proxy
./start-local-proxy.sh restart

# View logs
./start-local-proxy.sh logs

# Check status
./start-local-proxy.sh status

# Test connectivity
./start-local-proxy.sh test

# Raw docker-compose commands
docker-compose -f docker-compose.local-models.yml up
docker-compose -f docker-compose.local-models.yml down
docker-compose -f docker-compose.local-models.yml logs -f
```

## Port Mapping

| Service | Host Port | Container Port | URL |
|---------|-----------|-----------------|-----|
| LM Studio | 1234 | 1234 | http://localhost:1234/v1 |
| Ollama | 11434 | 11434 | http://localhost:11434 |
| LiteLLM Proxy | 4000 | 4000 | http://localhost:4000 |

## API Endpoints

```bash
# List available models
curl http://localhost:4000/models

# Chat completions
curl http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama-llama2",
    "messages": [{"role": "user", "content": "hi"}]
  }'

# Health check
curl http://localhost:4000/health/liveliness
```

## Python Examples

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000",
    api_key="sk-1234"
)

# Simple chat
response = client.chat.completions.create(
    model="ollama-llama2",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)

# Streaming
with client.chat.completions.create(
    model="ollama-llama2",
    messages=[{"role": "user", "content": "Tell a story"}],
    stream=True
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

## Model Name Format

```
Model Name in Proxy        Service       What You See
─────────────────────────────────────────────────────
ollama-llama2              Ollama        ollama/llama2
ollama-llama3              Ollama        ollama/llama3
ollama-mistral             Ollama        ollama/mistral
ollama-*                   Ollama        Any Ollama model

lm-studio-default          LM Studio     lm_studio/default-model
lm-studio-chat             LM Studio     lm_studio/default-model
lm-studio-*                LM Studio     Any LM Studio model
```

## Configuration File Structure

```yaml
# config.local-models.yaml

model_list:
  - model_name: my-model-name
    litellm_params:
      model: provider/model-name
      api_base: http://host.docker.internal:port
    model_info:
      mode: chat  # or completion, embedding

router_settings:
  enable_logging: true
  health_check_interval: 60
```

## Environment Variables

```bash
# In .env.local (optional)
LM_STUDIO_API_BASE=http://host.docker.internal:1234/v1
OLLAMA_API_BASE=http://host.docker.internal:11434
PROXY_PORT=4000
PROXY_LOG_LEVEL=INFO
```

## Docker Compose Override

```bash
# Build fresh image
docker-compose -f docker-compose.local-models.yml build --no-cache

# Start with custom config
docker-compose -f docker-compose.local-models.yml up -d

# Execute command in container
docker-compose -f docker-compose.local-models.yml exec litellm COMMAND

# View resource usage
docker stats litellm
```

## Verify Services Running

```bash
# Check LM Studio
curl http://localhost:1234/v1/models

# Check Ollama  
curl http://localhost:11434/api/tags

# Check LiteLLM Proxy
curl http://localhost:4000/models

# All three
curl -s http://localhost:1234/v1/models && \
curl -s http://localhost:11434/api/tags && \
curl -s http://localhost:4000/models
```

## Common Issues Quick Fixes

| Issue | Fix |
|-------|-----|
| Can't reach proxy | `docker ps` - is container running? |
| Models not showing | Check `config.local-models.yaml` mounted: `docker exec litellm cat /app/config.yaml` |
| Port in use | `lsof -i :4000` then `kill -9 <PID>` |
| Connection refused | Make sure LM Studio/Ollama running on Mac |
| Slow responses | Use smaller models (7B) or reduce max_tokens |
| Container crashes | `docker logs litellm` to see error |

## Important Notes

- **`host.docker.internal`** = how container reaches Mac host
- **Never hardcode API keys** in config files
- **Keep LM Studio/Ollama running** while using proxy
- **Model names must match exactly** in Ollama and config
- **Larger models need more RAM** (7B < 13B < 70B)
- **First request is slower** as model loads into memory

## Files Created

- `docker-compose.local-models.yml` - Docker configuration
- `config.local-models.yaml` - Proxy model configuration
- `start-local-proxy.sh` - Quick start script
- `examples_local_models.py` - Python examples
- `SETUP_LOCAL_MODELS.md` - Detailed setup guide
- `TROUBLESHOOTING_LOCAL_MODELS.md` - Common issues
- `.env.local.example` - Environment template

## Next Steps

1. **First time setup:**
   - Read `SETUP_LOCAL_MODELS.md` (10 min read)
   - Run `./start-local-proxy.sh check` to verify prerequisites
   - Start proxy: `./start-local-proxy.sh start`

2. **Test the connection:**
   - Run `./start-local-proxy.sh test`
   - Or: `python3 examples_local_models.py`

3. **Integrate with your app:**
   - Use OpenAI SDK with `base_url="http://localhost:4000"`
   - See Python examples in `SETUP_LOCAL_MODELS.md`

4. **Production deployment:**
   - Enable authentication in config
   - Add rate limiting
   - Use persistent database for model tracking
   - See LiteLLM docs for advanced features

## Resources

- **LiteLLM Docs:** https://docs.litellm.ai/
- **Ollama:** https://ollama.ai/
- **LM Studio:** https://lmstudio.ai/
- **OpenAI Python SDK:** https://github.com/openai/openai-python
- **LiteLLM Proxy:** https://docs.litellm.ai/docs/simple_proxy
