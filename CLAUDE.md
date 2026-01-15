# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Agent Zero is an open-source agentic AI framework (v0.9.7) designed as a personal, organic assistant that grows and learns with users. It uses LLMs to gather information, execute code, cooperate with other agent instances, and accomplish complex tasks through autonomous reasoning.

## Commands

### Running the Application
```bash
python run_ui.py                    # Start web UI (default: localhost:5000)
python run_ui.py --port=5555        # Start on custom port
python run_tunnel.py                # Start tunnel server for remote access
```

### Installation
```bash
pip install -r requirements.txt     # Install dependencies
playwright install chromium         # Install browser for browser agent
pip install -r requirements.dev.txt # Dev dependencies (pytest)
```

### Testing
```bash
pytest tests/                       # Run all tests
pytest tests/test_file.py           # Run specific test file
```

### Docker
```bash
docker pull agent0ai/agent-zero
docker run -p 50001:80 agent0ai/agent-zero

# Build local image
docker build -f DockerfileLocal -t agent-zero-local --build-arg CACHE_DATE=$(date +%Y-%m-%d:%H:%M:%S) .
```

### Debugging
VS Code is pre-configured in `.vscode/launch.json`. Press F5 to start debugging with breakpoints.

## Architecture

### Core Components

**Agent System (`agent.py`)**: Central agent class handling the message loop, tool execution, and multi-agent hierarchy. Agent 0 is the top-level agent that can delegate to subordinate agents.

**LLM Integration (`models.py`)**: Uses LiteLLM for provider abstraction supporting 100+ LLM providers (OpenAI, Anthropic, Google, Ollama, etc.).

**Extension System**: Hook-based architecture for modifying agent behavior at specific lifecycle points:
- `agent_init` - Agent initialization
- `before_main_llm_call` - Pre-LLM processing
- `message_loop_start/end` - Loop lifecycle
- `message_loop_prompts_before/after` - Prompt processing
- `monologue_start/end` - Agent monologue
- Extensions execute alphabetically by filename (use numeric prefixes for ordering)

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `python/api/` | Flask API endpoints (64+ handlers) |
| `python/tools/` | Built-in tools (code execution, search, memory, browser, etc.) |
| `python/extensions/` | Extension hooks organized by lifecycle point |
| `python/helpers/` | Utility modules |
| `python/webui/` | Frontend (vanilla JS, HTML, CSS) |
| `prompts/` | Markdown-based system prompts that define agent behavior |
| `agents/` | Agent profiles with custom configs/tools/extensions |
| `instruments/` | Custom scripts stored in memory, recalled when needed |
| `knowledge/` | RAG knowledge base documents |
| `memory/` | Persistent vector DB memory (FAISS) |

### Key Files

| File | Purpose |
|------|---------|
| `agent.py` | Core Agent class (~922 lines) |
| `models.py` | LLM provider configuration (~919 lines) |
| `initialize.py` | Framework initialization |
| `run_ui.py` | Flask web server entry point |
| `prompts/default/agent.system.main.md` | Central prompt hub |

## Extensibility Patterns

### Custom Tools
1. Create `python/tools/my_tool.py` (global) or `agents/{profile}/tools/my_tool.py` (agent-specific)
2. Inherit from `Tool` base class
3. Implement `execute()` method
4. Agent-specific tools override defaults with same filename

### Custom Extensions
1. Create Python file in `python/extensions/{hook_name}/`
2. Inherit from `Extension` base class
3. Implement `execute()` method
4. Name files with numeric prefix for execution order (e.g., `_10_my_extension.py`)

### Custom Prompts
1. Create directory in `prompts/` (e.g., `prompts/my-custom/`)
2. Copy and modify files from `prompts/default/`
3. Framework merges custom with defaults (custom takes precedence)
4. Variables use `{{var}}` syntax, file includes use `{{ include "file.md" }}`

### Custom Agents
1. Create `agents/{agent_name}/` directory
2. Add any of: `extensions/`, `tools/`, `prompts/`, `settings.json`
3. Only override what you need; rest inherits from defaults

## Development Notes

- The framework is entirely prompt-driven; behavior changes through markdown files in `prompts/`
- Memory uses FAISS vector DB with automatic consolidation
- Message history uses intelligent compression and summarization
- Rate limiting is configurable per-model in settings
- For local development, use RFC (Remote Function Calls) to connect to a Dockerized instance for code execution
- Python 3.12 recommended (tested on 3.13.1)
