#!/usr/bin/env python3
"""
Example Python scripts for using LiteLLM Proxy with Local Models
Run any of these scripts to test the proxy connection

Prerequisites:
- pip install openai
- LiteLLM Proxy running at localhost:4000
- LM Studio and/or Ollama running on your Mac
"""

import sys
from openai import OpenAI

# Initialize OpenAI client pointing to LiteLLM Proxy
client = OpenAI(
    base_url="http://localhost:4000",
    api_key="sk-1234"  # Dummy key (no auth enabled by default)
)


def chat_with_ollama():
    """Example: Chat with an Ollama model"""
    print("=" * 60)
    print("Chat with Ollama Model")
    print("=" * 60)
    
    response = client.chat.completions.create(
        model="ollama-llama2",  # Must exist in config.local-models.yaml
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant. Keep responses concise."
            },
            {
                "role": "user", 
                "content": "What is the capital of France?"
            }
        ],
        max_tokens=200,
        temperature=0.7
    )
    
    print(f"\nModel: {response.model}")
    print(f"Response: {response.choices[0].message.content}")
    print(f"Tokens used - Prompt: {response.usage.prompt_tokens}, Completion: {response.usage.completion_tokens}")


def chat_with_lm_studio():
    """Example: Chat with an LM Studio model"""
    print("=" * 60)
    print("Chat with LM Studio Model")
    print("=" * 60)
    
    response = client.chat.completions.create(
        model="lm-studio-chat",  # Must exist in config.local-models.yaml
        messages=[
            {
                "role": "system",
                "content": "You are a helpful Python expert."
            },
            {
                "role": "user",
                "content": "Write a simple Python function that adds two numbers"
            }
        ],
        max_tokens=200,
        temperature=0.7
    )
    
    print(f"\nModel: {response.model}")
    print(f"Response: {response.choices[0].message.content}")
    print(f"Tokens used - Prompt: {response.usage.prompt_tokens}, Completion: {response.usage.completion_tokens}")


def stream_response():
    """Example: Streaming response from a model"""
    print("=" * 60)
    print("Streaming Response")
    print("=" * 60)
    
    print("\nStreaming response (word by word):\n")
    
    with client.chat.completions.create(
        model="ollama-llama2",
        messages=[
            {"role": "user", "content": "Tell me a short story about a cat"}
        ],
        max_tokens=150,
        temperature=0.8,
        stream=True
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)
    
    print("\n")


def list_available_models():
    """Example: Get list of available models from proxy"""
    print("=" * 60)
    print("Available Models")
    print("=" * 60)
    
    # Note: This is a direct HTTP call, not part of OpenAI SDK
    import requests
    
    try:
        response = requests.get("http://localhost:4000/models")
        models = response.json().get("data", [])
        
        print(f"\nFound {len(models)} models:\n")
        for model in models:
            model_name = model.get("model_name", "unknown")
            mode = model.get("mode", "unknown")
            print(f"  • {model_name:30} [{mode}]")
    except Exception as e:
        print(f"Error fetching models: {e}")


def multi_turn_conversation():
    """Example: Multi-turn conversation (chat history)"""
    print("=" * 60)
    print("Multi-Turn Conversation")
    print("=" * 60)
    
    messages = [
        {"role": "system", "content": "You are a helpful assistant."}
    ]
    
    # Turn 1
    print("\nUser: What is machine learning?")
    messages.append({
        "role": "user",
        "content": "What is machine learning?"
    })
    
    response = client.chat.completions.create(
        model="ollama-llama2",
        messages=messages,
        max_tokens=150,
        temperature=0.7
    )
    
    assistant_message = response.choices[0].message.content
    print(f"Assistant: {assistant_message}")
    messages.append({"role": "assistant", "content": assistant_message})
    
    # Turn 2
    print("\nUser: Can you give me an example?")
    messages.append({
        "role": "user",
        "content": "Can you give me an example?"
    })
    
    response = client.chat.completions.create(
        model="ollama-llama2",
        messages=messages,
        max_tokens=150,
        temperature=0.7
    )
    
    assistant_message = response.choices[0].message.content
    print(f"Assistant: {assistant_message}")


def check_proxy_health():
    """Example: Check if proxy is healthy"""
    print("=" * 60)
    print("Proxy Health Check")
    print("=" * 60)
    
    import requests
    
    try:
        response = requests.get("http://localhost:4000/health/liveliness")
        if response.status_code == 200:
            print("\n✓ Proxy is healthy and responding")
            return True
        else:
            print(f"\n✗ Proxy returned status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"\n✗ Cannot reach proxy at localhost:4000: {e}")
        return False


def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("LiteLLM Proxy Examples - Local Models")
    print("=" * 60)
    
    # Check if proxy is running
    if not check_proxy_health():
        print("\nMake sure LiteLLM Proxy is running:")
        print("  ./start-local-proxy.sh start")
        sys.exit(1)
    
    # Available examples
    examples = {
        "1": ("List available models", list_available_models),
        "2": ("Chat with Ollama", chat_with_ollama),
        "3": ("Chat with LM Studio", chat_with_lm_studio),
        "4": ("Streaming response", stream_response),
        "5": ("Multi-turn conversation", multi_turn_conversation),
    }
    
    print("\nAvailable examples:\n")
    for key, (description, _) in examples.items():
        print(f"  {key}. {description}")
    print("\n  0. Run all examples")
    print("  q. Quit\n")
    
    # If running with argument, execute specific example
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in examples:
            print(f"\nRunning: {examples[arg][0]}\n")
            examples[arg][1]()
        elif arg == "0":
            for key in sorted(examples.keys()):
                print("\n")
                examples[key][1]()
        elif arg != "q":
            print(f"Unknown example: {arg}")
            sys.exit(1)
    else:
        # Interactive mode
        choice = input("Select an example (1-5, 0=all, q=quit): ").strip().lower()
        
        if choice == "0":
            for key in sorted(examples.keys()):
                print("\n")
                examples[key][1]()
        elif choice in examples:
            print("\n")
            examples[choice][1]()
        elif choice != "q":
            print(f"Invalid choice: {choice}")
            sys.exit(1)
    
    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)
