#!/bin/bash

# Quick-start script for LiteLLM Proxy with Local Models (LM Studio + Ollama)
# Usage: ./start-local-proxy.sh [command]
# Commands: start, stop, restart, logs, status, test

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE="docker-compose.local-models.yml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_info "Docker found: $(docker --version)"
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed"
        exit 1
    fi
    print_info "docker-compose found: $(docker-compose --version)"
    
    # Check if config file exists
    if [ ! -f "$SCRIPT_DIR/config.local-models.yaml" ]; then
        print_error "config.local-models.yaml not found"
        echo "Please ensure you're in the litellm directory"
        exit 1
    fi
    print_info "Config file found"
}

# Function to check if services are running
check_services() {
    echo ""
    echo "Checking local services..."
    
    # Check LM Studio
    if curl -s http://localhost:1234/v1/models > /dev/null 2>&1; then
        print_info "LM Studio is running at localhost:1234"
    else
        print_warning "LM Studio is not responding at localhost:1234"
        echo "  Make sure LM Studio is running on your Mac"
    fi
    
    # Check Ollama
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_info "Ollama is running at localhost:11434"
        echo "  Available models:"
        curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*' | cut -d'"' -f4 | sed 's/^/    - /'
    else
        print_warning "Ollama is not responding at localhost:11434"
        echo "  Make sure Ollama is running on your Mac"
    fi
}

# Function to start proxy
start_proxy() {
    echo ""
    print_info "Starting LiteLLM Proxy..."
    
    if [ -z "$1" ] || [ "$1" != "daemon" ]; then
        echo "Starting in foreground. Press Ctrl+C to stop."
        echo ""
        docker-compose -f "$COMPOSE_FILE" up
    else
        docker-compose -f "$COMPOSE_FILE" up -d
        print_info "LiteLLM Proxy started in background"
    fi
}

# Function to stop proxy
stop_proxy() {
    echo ""
    print_info "Stopping LiteLLM Proxy..."
    docker-compose -f "$COMPOSE_FILE" down
    print_info "LiteLLM Proxy stopped"
}

# Function to restart proxy
restart_proxy() {
    echo ""
    print_info "Restarting LiteLLM Proxy..."
    docker-compose -f "$COMPOSE_FILE" restart
    print_info "LiteLLM Proxy restarted"
}

# Function to show logs
show_logs() {
    echo ""
    print_info "Showing LiteLLM Proxy logs..."
    docker-compose -f "$COMPOSE_FILE" logs -f
}

# Function to show status
show_status() {
    echo ""
    print_info "LiteLLM Proxy status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    # Check if proxy is responding
    echo ""
    if curl -s http://localhost:4000/health/liveliness > /dev/null 2>&1; then
        print_info "Proxy is healthy and responding"
        
        # Try to get models
        echo ""
        print_info "Available models:"
        curl -s http://localhost:4000/models | grep -o '"model_name":"[^"]*' | cut -d'"' -f4 | sed 's/^/  - /'
    else
        print_warning "Proxy is not responding at localhost:4000"
    fi
}

# Function to test proxy
test_proxy() {
    echo ""
    print_info "Testing LiteLLM Proxy..."
    
    if ! curl -s http://localhost:4000/health/liveliness > /dev/null 2>&1; then
        print_error "Proxy is not running at localhost:4000"
        exit 1
    fi
    
    print_info "Proxy is healthy"
    
    # Get available models
    echo ""
    echo "Fetching available models..."
    MODELS=$(curl -s http://localhost:4000/models | grep -o '"model_name":"[^"]*' | cut -d'"' -f4 | head -1)
    
    if [ -z "$MODELS" ]; then
        print_error "No models found in proxy configuration"
        exit 1
    fi
    
    print_info "Found model: $MODELS"
    
    # Try a test request
    echo ""
    print_info "Sending test request to $MODELS..."
    
    RESPONSE=$(curl -s -X POST http://localhost:4000/chat/completions \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"$MODELS\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Say 'hello' in one word\"}],
        \"max_tokens\": 10
      }")
    
    if echo "$RESPONSE" | grep -q '"content"'; then
        print_info "Test request successful!"
        echo ""
        echo "Response preview:"
        echo "$RESPONSE" | grep -o '"content":"[^"]*' | cut -d'"' -f4 | head -1
    else
        print_error "Test request failed"
        echo "Response: $RESPONSE"
        exit 1
    fi
}

# Function to show help
show_help() {
    cat << EOF
LiteLLM Proxy Quick Start Script

Usage: $0 [command]

Commands:
  start              Start proxy in foreground (interactive)
  start-daemon       Start proxy in background
  stop               Stop the proxy
  restart            Restart the proxy
  logs               Show proxy logs (follow mode)
  status             Show proxy status and available models
  test               Test proxy connectivity and models
  check              Check prerequisites and local services
  help               Show this help message

Examples:
  $0 start           # Start and see logs
  $0 start-daemon    # Start in background
  $0 status          # Check if proxy is running
  $0 test            # Test with a sample request
  $0 logs            # Stream logs

For more information, see SETUP_LOCAL_MODELS.md
EOF
}

# Main script
main() {
    local command="${1:-help}"
    
    case "$command" in
        start)
            check_prerequisites
            check_services
            start_proxy
            ;;
        start-daemon)
            check_prerequisites
            check_services
            start_proxy daemon
            echo ""
            echo "Waiting for proxy to start..."
            sleep 3
            show_status
            ;;
        stop)
            stop_proxy
            ;;
        restart)
            restart_proxy
            sleep 2
            show_status
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        test)
            test_proxy
            ;;
        check)
            check_prerequisites
            check_services
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
