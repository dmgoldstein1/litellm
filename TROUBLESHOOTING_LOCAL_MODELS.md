# Troubleshooting Guide - LiteLLM Proxy with Local Models

## Common Issues and Solutions

### 1. Docker Container Can't Reach LM Studio or Ollama

**Symptoms:**
- Error messages like `Connection refused` or `Cannot connect to localhost:1234`
- Proxy logs show connection errors to local services

**Solution:**
```bash
# Make sure services are actually running
# Check LM Studio
curl http://localhost:1234/v1/models

# Check Ollama
curl http://localhost:11434/api/tags

# Test from inside Docker container
docker-compose -f docker-compose.local-models.yml exec litellm \
  curl http://host.docker.internal:1234/v1/models
```

**Key points:**
- `host.docker.internal` is required for Docker on Mac to reach host services
- Verify `docker-compose.local-models.yml` has `extra_hosts` section
- LM Studio must be running and server started in the UI
- Ollama might need to be explicitly started: `ollama serve`

---

### 2. Port Already in Use

**Symptoms:**
- Error: `Port 4000 already in use` or `bind: address already in use`

**Solution:**
```bash
# Find what's using port 4000
lsof -i :4000

# Stop the existing process
kill -9 <PID>

# Or change the port in docker-compose.local-models.yml
# Change "4000:4000" to "4001:4000"
```

---

### 3. Proxy Container Crashes or Won't Start

**Symptoms:**
- Container exits immediately
- Status shows "Exited"

**Solution:**
```bash
# Check logs for error messages
docker-compose -f docker-compose.local-models.yml logs litellm

# Verify config file is valid YAML
# Try to recreate container
docker-compose -f docker-compose.local-models.yml down
docker-compose -f docker-compose.local-models.yml build --no-cache
docker-compose -f docker-compose.local-models.yml up
```

**Common causes:**
- Invalid YAML syntax in `config.local-models.yaml`
- Missing indentation or quotes
- Invalid model names

---

### 4. Can't Connect to Proxy from Host

**Symptoms:**
- `curl: (7) Failed to connect to localhost port 4000`
- Browser can't reach `http://localhost:4000/models`

**Solution:**
```bash
# Verify container is running
docker ps | grep litellm

# Check if port is actually exposed
docker port litellm

# Test from inside container
docker-compose -f docker-compose.local-models.yml exec litellm \
  wget http://localhost:4000/health/liveliness

# Restart container
docker-compose -f docker-compose.local-models.yml restart litellm
```

---

### 5. Model Not Found / Not in Model List

**Symptoms:**
- Error: `Model not found`
- `/models` endpoint returns empty list
- Errors like: `Unknown model name`

**Solution:**
```bash
# Verify models are in config.local-models.yaml
cat config.local-models.yaml | grep model_name

# Check exact model names in LM Studio/Ollama
# LM Studio: Check the dropdown in the server tab
# Ollama: Run: ollama list

# Update config.local-models.yaml with correct names
# Then restart container
docker-compose -f docker-compose.local-models.yml restart litellm

# Verify models appear
curl http://localhost:4000/models
```

---

### 6. Model Inference Is Very Slow

**Symptoms:**
- Takes 30+ seconds to get a response
- Response seems stuck

**Solutions:**

1. **Check available system resources:**
   ```bash
   # Check available RAM in Activity Monitor on Mac
   # Local LLMs need 4-16GB depending on model size
   ```

2. **Reduce max_tokens:**
   ```python
   # Instead of max_tokens=2000, use smaller value
   response = client.chat.completions.create(
       model="ollama-llama2",
       messages=[...],
       max_tokens=100  # Smaller = faster
   )
   ```

3. **Use smaller models:**
   - 7B parameter models are much faster than 13B or 70B
   - Example: Mistral 7B > Llama 2 13B > Llama 2 70B

4. **Check if model is actually loaded:**
   ```bash
   # For Ollama
   ollama list
   
   # For LM Studio, check the UI
   ```

5. **Monitor resource usage:**
   ```bash
   # Open Activity Monitor on Mac
   # Watch CPU, Memory, and GPU usage during inference
   ```

---

### 7. Authentication/Authorization Errors

**Symptoms:**
- Error: `Unauthorized` or `Invalid API key`
- Status 401 responses

**Solution:**

If authentication is enabled:
```bash
# Get your master key
grep -i "master_key\|LITELLM_MASTER_KEY" config.local-models.yaml .env

# Use it in requests
curl http://localhost:4000/models \
  -H "Authorization: Bearer YOUR_MASTER_KEY"

# Or in Python
client = OpenAI(
    base_url="http://localhost:4000",
    api_key="YOUR_MASTER_KEY"
)
```

If authentication is NOT enabled but getting 401:
- Remove authentication from config: comment out `key_management_system` section
- Restart container

---

### 8. Memory Issues / Out of Memory

**Symptoms:**
- Container becomes unresponsive
- System slows down dramatically
- "Cannot allocate memory" errors

**Solution:**
```bash
# Check Docker memory limits
docker stats litellm

# Stop resource-heavy processes
docker-compose -f docker-compose.local-models.yml down

# Restart LM Studio/Ollama to free memory
# On Mac: Quit apps or restart

# Use smaller models (7B instead of 13B or 70B)
```

---

### 9. Configuration File Not Loaded

**Symptoms:**
- Models list is empty
- Error messages about missing config

**Solution:**
```bash
# Verify volume mount is working
docker-compose -f docker-compose.local-models.yml exec litellm \
  ls -la /app/config.yaml

# Check if file exists locally
ls -la /path/to/litellm/config.local-models.yaml

# Verify docker-compose.yml has correct volume mount
grep -A2 "volumes:" docker-compose.local-models.yml

# If using wrong path, update docker-compose.local-models.yml:
# volumes:
#   - ./config.local-models.yaml:/app/config.yaml
```

---

### 10. LM Studio Server Not Starting

**Symptoms:**
- Port 1234 not listening
- Error in LM Studio UI

**Solution:**
```bash
# Verify LM Studio is installed and running
# Check System Preferences -> General -> "Allow LM Studio"

# Try restarting LM Studio
# Quit completely and reopen

# Check if model is loaded
# In LM Studio UI, select a model from dropdown first

# Try different port
# Edit docker-compose.local-models.yaml to use different port
```

---

### 11. Ollama Models Not Showing Up

**Symptoms:**
- Config says `ollama-llama2` but model doesn't exist
- Error: `model llama2 not found`

**Solution:**
```bash
# List installed models
ollama list

# Pull missing models
ollama pull llama2
ollama pull llama3
ollama pull mistral

# Verify Ollama is running
curl http://localhost:11434/api/tags

# Make sure Ollama is not stopping due to inactivity
# Keep Ollama running: brew services start ollama
```

---

### 12. Docker Networking Issues

**Symptoms:**
- `host.docker.internal` not resolving
- Works on Linux but not on Mac

**Solution:**
```bash
# For Docker Desktop Mac, this should work automatically
# But if not, verify:

# 1. Docker Desktop is running
# 2. Extra hosts are configured in docker-compose.local-models.yml

# Check docker-compose file has:
# extra_hosts:
#   - "host.docker.internal:host-gateway"

# Test DNS resolution
docker-compose -f docker-compose.local-models.yml exec litellm \
  getent hosts host.docker.internal
```

---

## Diagnostic Checklist

Use this checklist when troubleshooting:

- [ ] Is Docker running? `docker ps`
- [ ] Is LM Studio running on Mac? Check UI
- [ ] Is Ollama running? `curl http://localhost:11434/api/tags`
- [ ] Is proxy container running? `docker ps | grep litellm`
- [ ] Can you reach proxy? `curl http://localhost:4000/models`
- [ ] Are models in config? `cat config.local-models.yaml | grep model_name`
- [ ] Is config mounted? `docker exec litellm cat /app/config.yaml`
- [ ] Are logs helpful? `docker-compose -f docker-compose.local-models.yml logs`

---

## Getting Help

If you're still stuck:

1. **Check the logs:**
   ```bash
   docker-compose -f docker-compose.local-models.yml logs -f
   ```

2. **Enable debug logging:**
   Edit `config.local-models.yaml` and restart:
   ```yaml
   router_settings:
     enable_logging: true
   ```

3. **Check repo documentation:**
   - LiteLLM: https://docs.litellm.ai/docs/providers/ollama
   - LM Studio: https://lmstudio.ai/docs/
   - Ollama: https://github.com/ollama/ollama

4. **Test each component separately:**
   ```bash
   # Test LM Studio
   curl http://localhost:1234/v1/models
   
   # Test Ollama
   curl http://localhost:11434/api/tags
   
   # Test Proxy
   curl http://localhost:4000/models
   ```

5. **Create a minimal test case:**
   ```python
   from openai import OpenAI
   client = OpenAI(base_url="http://localhost:4000", api_key="test")
   response = client.chat.completions.create(
       model="ollama-llama2",  # Simple model name
       messages=[{"role": "user", "content": "hi"}],
       max_tokens=10
   )
   print(response)
   ```
