#!/usr/bin/env bash
#
# install.sh
# Cria (ou reutiliza) um ambiente virtual Python 3.12 e instala as
# dependências listadas em requirements.txt.
#
# Uso:
#   chmod +x install.sh
#   ./install.sh
#
# Variáveis opcionais:
#   VENV_DIR   -> diretório do virtualenv (padrão: .venv)
#   REQ_FILE   -> caminho do requirements.txt (padrão: requirements.txt)

set -euo pipefail

VENV_DIR="${VENV_DIR:-.venv}"
REQ_FILE="${REQ_FILE:-requirements.txt}"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"

log() { printf '\n\033[1;32m[install]\033[0m %s\n' "$1"; }
err() { printf '\n\033[1;31m[erro]\033[0m %s\n' "$1" >&2; }

# ---------------------------------------------------------------------------
# 1. Verifica se o Python 3.12 está instalado
# ---------------------------------------------------------------------------
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    err "$PYTHON_BIN não encontrado no PATH."
    echo "Instale o Python 3.12 antes de continuar. Exemplos:"
    echo "  Ubuntu/Debian:"
    echo "    sudo add-apt-repository ppa:deadsnakes/ppa"
    echo "    sudo apt update"
    echo "    sudo apt install python3.12 python3.12-venv python3.12-dev"
    echo "  macOS (Homebrew):"
    echo "    brew install python@3.12"
    exit 1
fi

PY_VERSION="$("$PYTHON_BIN" -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
log "Usando $PYTHON_BIN (versão $PY_VERSION)"

# ---------------------------------------------------------------------------
# 2. Verifica se o requirements.txt existe
# ---------------------------------------------------------------------------
if [ ! -f "$REQ_FILE" ]; then
    err "Arquivo '$REQ_FILE' não encontrado no diretório atual ($(pwd))."
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. (Opcional/Linux) Aviso sobre bibliotecas nativas para lxml/cryptography
# ---------------------------------------------------------------------------
if [ "$(uname -s)" = "Linux" ]; then
    log "Dica: lxml, cryptography e signxml podem exigir libs nativas de sistema."
    echo "  Se a instalação falhar ao compilar, instale antes (Debian/Ubuntu):"
    echo "    sudo apt install -y build-essential libxml2-dev libxslt1-dev \\"
    echo "        libssl-dev libffi-dev zlib1g-dev libjpeg-dev"
fi

# ---------------------------------------------------------------------------
# 4. Cria o virtualenv (se ainda não existir)
# ---------------------------------------------------------------------------
if [ -d "$VENV_DIR" ]; then
    log "Virtualenv '$VENV_DIR' já existe, reutilizando."
else
    log "Criando virtualenv em '$VENV_DIR'..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# ---------------------------------------------------------------------------
# 5. Atualiza pip/setuptools/wheel e instala as dependências
# ---------------------------------------------------------------------------
log "Atualizando pip, setuptools e wheel..."
python -m pip install --upgrade pip setuptools wheel

log "Instalando dependências de $REQ_FILE..."
python -m pip install -r "$REQ_FILE"

log "Instalação concluída com sucesso!"
echo
echo "Para ativar o ambiente virtual em novas sessões, use:"
echo "  source $VENV_DIR/bin/activate"
