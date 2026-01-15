#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Functions for output
print_header() { echo -e "\n${CYAN}$1${NC}"; }
print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_error() { echo -e "  ${RED}✗${NC} $1"; }
print_info() { echo -e "  ${BLUE}→${NC} $1"; }
print_warn() { echo -e "  ${YELLOW}!${NC} $1"; }

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║     Agent Zero Installation Setup     ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Select installation method
select_install_method() {
    print_header "Select installation method:"
    echo "  1) Native Python (recommended for local LLM development)"
    echo "  2) Docker (recommended for quick start / cloud models)"
    echo ""
    read -p "  Choice [1-2]: " INSTALL_METHOD

    case $INSTALL_METHOD in
        1) INSTALL_TYPE="native" ;;
        2) INSTALL_TYPE="docker" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
}

# Check Python version
check_python() {
    print_header "[1/5] Checking system requirements..."

    if command -v python3 &> /dev/null; then
        PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        PY_MAJOR=$(echo $PY_VERSION | cut -d. -f1)
        PY_MINOR=$(echo $PY_VERSION | cut -d. -f2)

        if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 12 ]; then
            print_success "Python $PY_VERSION found"
        else
            print_error "Python 3.12+ required (found $PY_VERSION)"
            echo ""
            echo "  Install Python 3.12+:"
            echo "    Ubuntu/Debian: sudo apt install python3.12"
            echo "    macOS: brew install python@3.12"
            echo "    Arch: sudo pacman -S python"
            exit 1
        fi
    else
        print_error "Python 3 not found"
        exit 1
    fi

    if command -v pip3 &> /dev/null || python3 -m pip --version &> /dev/null 2>&1; then
        print_success "pip available"
    else
        print_error "pip not found"
        echo "  Install pip: python3 -m ensurepip --upgrade"
        exit 1
    fi
}

# Check Docker
check_docker() {
    print_header "[1/5] Checking Docker..."

    if command -v docker &> /dev/null; then
        print_success "Docker found"
        if docker info &> /dev/null; then
            print_success "Docker daemon running"
        else
            print_error "Docker daemon not running. Start it with: sudo systemctl start docker"
            exit 1
        fi
    else
        print_error "Docker not found"
        echo "  Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

# Select LLM provider
select_provider() {
    print_header "[2/5] Select your LLM provider:"
    echo "  1) OpenAI (GPT-4, GPT-4o)"
    echo "  2) Anthropic (Claude)"
    echo "  3) Ollama / LM Studio (Local models)"
    echo "  4) OpenRouter (Multiple providers)"
    echo "  5) Custom (Manual configuration later)"
    echo ""
    read -p "  Choice [1-5]: " PROVIDER_CHOICE

    case $PROVIDER_CHOICE in
        1) configure_openai ;;
        2) configure_anthropic ;;
        3) configure_local ;;
        4) configure_openrouter ;;
        5) configure_skip ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
}

configure_openai() {
    print_header "[3/5] Configure OpenAI:"
    read -sp "  API Key: " OPENAI_KEY; echo ""
    read -p "  Model [gpt-4o]: " OPENAI_MODEL
    OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

    CHAT_MODEL_PROVIDER="openai"
    CHAT_MODEL_NAME="$OPENAI_MODEL"
    UTILITY_MODEL_PROVIDER="openai"
    UTILITY_MODEL_NAME="gpt-4o-mini"
    API_KEY_NAME="OPENAI_API_KEY"
    API_KEY_VALUE="$OPENAI_KEY"
    CTX_LENGTH=128000
}

configure_anthropic() {
    print_header "[3/5] Configure Anthropic:"
    read -sp "  API Key: " ANTHROPIC_KEY; echo ""
    read -p "  Model [claude-sonnet-4-20250514]: " ANTHROPIC_MODEL
    ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-claude-sonnet-4-20250514}

    CHAT_MODEL_PROVIDER="anthropic"
    CHAT_MODEL_NAME="$ANTHROPIC_MODEL"
    UTILITY_MODEL_PROVIDER="anthropic"
    UTILITY_MODEL_NAME="claude-haiku-4-20250514"
    API_KEY_NAME="ANTHROPIC_API_KEY"
    API_KEY_VALUE="$ANTHROPIC_KEY"
    CTX_LENGTH=200000
}

configure_local() {
    print_header "[3/5] Configure Ollama/LM Studio:"
    read -p "  API Base URL [http://localhost:1234/v1]: " LOCAL_URL
    LOCAL_URL=${LOCAL_URL:-http://localhost:1234/v1}
    read -p "  Model name [local-model]: " LOCAL_MODEL
    LOCAL_MODEL=${LOCAL_MODEL:-local-model}
    read -p "  Context window size [16384]: " LOCAL_CTX
    LOCAL_CTX=${LOCAL_CTX:-16384}

    CHAT_MODEL_PROVIDER="openai"
    CHAT_MODEL_NAME="$LOCAL_MODEL"
    UTILITY_MODEL_PROVIDER="openai"
    UTILITY_MODEL_NAME="$LOCAL_MODEL"
    API_BASE="$LOCAL_URL"
    CTX_LENGTH=$LOCAL_CTX
    SMALL_CONTEXT=true
}

configure_openrouter() {
    print_header "[3/5] Configure OpenRouter:"
    read -sp "  API Key: " OPENROUTER_KEY; echo ""
    echo ""
    echo "  Popular models:"
    echo "    openai/gpt-4o, anthropic/claude-3.5-sonnet"
    echo "    google/gemini-pro-1.5, meta-llama/llama-3-70b"
    read -p "  Model [openai/gpt-4o]: " OR_MODEL
    OR_MODEL=${OR_MODEL:-openai/gpt-4o}

    CHAT_MODEL_PROVIDER="openrouter"
    CHAT_MODEL_NAME="$OR_MODEL"
    UTILITY_MODEL_PROVIDER="openrouter"
    UTILITY_MODEL_NAME="openai/gpt-4o-mini"
    API_KEY_NAME="OPENROUTER_API_KEY"
    API_KEY_VALUE="$OPENROUTER_KEY"
    CTX_LENGTH=128000
}

configure_skip() {
    print_header "[3/5] Skipping model configuration..."
    print_info "You can configure models in the web UI Settings"
    SKIP_CONFIG=true
}

# Optional auth
configure_auth() {
    print_header "[4/5] Optional settings:"
    read -p "  Enable web UI authentication? [y/N]: " ENABLE_AUTH

    if [[ "$ENABLE_AUTH" =~ ^[Yy]$ ]]; then
        read -p "  Username: " AUTH_USER
        read -sp "  Password: " AUTH_PASS; echo ""
    fi

    # For Docker with host networking, ask for allowed origins
    if [ "$INSTALL_TYPE" = "docker" ]; then
        echo ""
        read -p "  Allow remote access? Enter your IP (or leave blank for localhost only): " REMOTE_IP
        if [ -n "$REMOTE_IP" ]; then
            ALLOWED_ORIGINS="*://localhost:*,*://127.0.0.1:*,*://0.0.0.0:*,*://$REMOTE_IP:*"
        else
            ALLOWED_ORIGINS="*://localhost:*,*://127.0.0.1:*,*://0.0.0.0:*"
        fi
    fi
}

# Install dependencies (native)
install_deps_native() {
    print_header "[5/5] Installing dependencies..."

    # Create venv
    if [ -d ".venv" ]; then
        print_warn "Virtual environment already exists, reusing..."
    else
        print_info "Creating virtual environment..."
        python3 -m venv .venv
    fi

    source .venv/bin/activate
    print_success "Virtual environment ready"

    # Install packages
    print_info "Installing Python packages (this may take several minutes)..."
    pip install --upgrade pip -q 2>/dev/null

    if pip install -r requirements.txt -q 2>/dev/null; then
        print_success "Python packages installed"
    else
        print_warn "Some packages may have failed, trying verbose install..."
        pip install -r requirements.txt
        print_success "Python packages installed"
    fi

    # Playwright (optional, for browser agent)
    print_info "Installing browser for web automation..."
    if playwright install chromium 2>/dev/null; then
        print_success "Playwright browser installed"
    else
        print_warn "Playwright browser install failed (optional - browser agent won't work)"
    fi
}

# Install via Docker
install_docker() {
    print_header "[5/5] Setting up Docker..."

    print_info "Pulling Agent Zero image..."
    docker pull agent0ai/agent-zero

    print_success "Docker image ready"

    # Generate run script
    cat > run-docker.sh << 'DOCKEREOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Container name
CONTAINER_NAME="agent-zero"

# Stop existing container
docker rm -f $CONTAINER_NAME 2>/dev/null

# Run Agent Zero with all services
docker run -d --network host \
DOCKEREOF

    # Add environment variables
    echo "  -e ALLOWED_ORIGINS=\"$ALLOWED_ORIGINS\" \\" >> run-docker.sh
    [ -n "$API_KEY_NAME" ] && echo "  -e $API_KEY_NAME=\"$API_KEY_VALUE\" \\" >> run-docker.sh
    [ -n "$AUTH_USER" ] && echo "  -e AUTH_LOGIN=\"$AUTH_USER\" \\" >> run-docker.sh
    [ -n "$AUTH_PASS" ] && echo "  -e AUTH_PASSWORD=\"$AUTH_PASS\" \\" >> run-docker.sh

    cat >> run-docker.sh << 'DOCKEREOF'
  --name $CONTAINER_NAME \
  agent0ai/agent-zero \
  /bin/bash -c "
    # Start cron for scheduled tasks
    /usr/sbin/cron

    # Start SearXNG search engine
    export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml
    cd /usr/local/searxng/searxng-src
    su searxng -c 'source /usr/local/searxng/searx-pyenv/bin/activate && python /usr/local/searxng/searxng-src/searx/webapp.py' &

    sleep 2

    # Start Agent Zero
    source /opt/venv-a0/bin/activate
    . /ins/copy_A0.sh
    python /a0/run_ui.py --dockerized=true --host=0.0.0.0 --port=5001
  "

echo "Agent Zero started!"
echo "Open: http://localhost:5001"
DOCKEREOF

    chmod +x run-docker.sh
    print_success "Created run-docker.sh"

    # Generate stop script
    cat > stop-docker.sh << 'STOPEOF'
#!/bin/bash
docker rm -f agent-zero 2>/dev/null && echo "Agent Zero stopped" || echo "Agent Zero was not running"
STOPEOF
    chmod +x stop-docker.sh
    print_success "Created stop-docker.sh"
}

# Generate config files (native)
generate_config_native() {
    print_info "Generating configuration..."

    # Ensure tmp directory exists
    mkdir -p tmp

    # .env file
    cat > .env << ENVEOF
# Agent Zero Configuration
# Generated by install.sh on $(date)

${API_KEY_NAME:+$API_KEY_NAME=$API_KEY_VALUE}
${AUTH_USER:+AUTH_LOGIN=$AUTH_USER}
${AUTH_PASS:+AUTH_PASSWORD=$AUTH_PASS}
ENVEOF

    # settings.json with selected provider
    if [ "$SKIP_CONFIG" != "true" ]; then
        cat > tmp/settings.json << JSONEOF
{
  "chat_model_provider": "$CHAT_MODEL_PROVIDER",
  "chat_model_name": "$CHAT_MODEL_NAME",
  "chat_model_ctx_length": $CTX_LENGTH,
  ${API_BASE:+"chat_model_api_base": "$API_BASE",}
  "utility_model_provider": "$UTILITY_MODEL_PROVIDER",
  "utility_model_name": "$UTILITY_MODEL_NAME",
  ${API_BASE:+"utility_model_api_base": "$API_BASE",}
  "embedding_model_provider": "huggingface",
  "embedding_model_name": "sentence-transformers/all-MiniLM-L6-v2"${SMALL_CONTEXT:+,
  "small_context_mode": true,
  "session_continuation_enabled": true}
}
JSONEOF
    fi

    print_success "Configuration saved"
}

# Show completion (native)
show_complete_native() {
    echo -e "\n${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║        Installation Complete!         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  Start Agent Zero:"
    echo "    ${CYAN}source .venv/bin/activate${NC}"
    echo "    ${CYAN}python run_ui.py${NC}"
    echo ""
    echo "  Then open: ${CYAN}http://localhost:5000${NC}"
    if [ -n "$AUTH_USER" ]; then
        echo "  Login: ${CYAN}$AUTH_USER${NC} / ****"
    fi
    if [ "$SMALL_CONTEXT" = "true" ]; then
        echo ""
        echo "  ${YELLOW}Small Context Mode enabled${NC} - optimized for local LLMs"
        echo "  Session continuation is ON - say 'continue' in new chats"
    fi
    echo ""
    echo "  For more options:"
    echo "    python run_ui.py --help"
    echo ""
}

# Show completion (docker)
show_complete_docker() {
    echo -e "\n${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║        Installation Complete!         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  Start Agent Zero:"
    echo "    ${CYAN}./run-docker.sh${NC}"
    echo ""
    echo "  Stop Agent Zero:"
    echo "    ${CYAN}./stop-docker.sh${NC}"
    echo ""
    echo "  Then open: ${CYAN}http://localhost:5001${NC}"
    if [ -n "$REMOTE_IP" ]; then
        echo "  Remote access: ${CYAN}http://$REMOTE_IP:5001${NC}"
    fi
    if [ -n "$AUTH_USER" ]; then
        echo "  Login: ${CYAN}$AUTH_USER${NC} / ****"
    fi
    echo ""
    echo "  View logs:"
    echo "    docker logs -f agent-zero"
    echo ""
}

# Main
main() {
    show_banner
    select_install_method

    if [ "$INSTALL_TYPE" = "native" ]; then
        check_python
        select_provider
        configure_auth
        install_deps_native
        generate_config_native
        show_complete_native
    else
        check_docker
        select_provider
        configure_auth
        install_docker
        show_complete_docker
    fi
}

main "$@"
