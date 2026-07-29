#!/usr/bin/env bash
#
# install_zenpdv.sh
# Instala dependências do sistema, clona o repositório ZenPdv,
# cria o ambiente virtual Python, instala as dependências do
# requirements.txt e configura o app.py como serviço systemd.
#
# Uso:
#   sudo bash install_zenpdv.sh
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configurações (ajuste conforme necessário)
# ---------------------------------------------------------------------------
REPO_URL="https://github.com/dariodfm/ZenPdv"
INSTALL_DIR="/opt/ZenPdv"
SERVICE_NAME="zenpdv"
SERVICE_USER="${SUDO_USER:-$(whoami)}"
PYTHON_BIN="python3"
VENV_DIR="${INSTALL_DIR}/venv"
APP_ENTRY="app.py"

# ---------------------------------------------------------------------------
# 0. Precisa ser root (sudo)
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "Este script precisa ser executado com sudo. Ex: sudo bash $0"
  exit 1
fi

echo "==> 1/6 Atualizando repositórios e instalando dependências de sistema..."
apt update
apt install -y \
  git \
  python3 \
  python3-venv \
  python3-pip \
  libpq-dev \
  python3-dev \
  build-essential

echo "==> 2/6 Clonando o repositório ZenPdv em ${INSTALL_DIR}..."
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  echo "Repositório já existe em ${INSTALL_DIR}, atualizando (git pull)..."
  git -C "${INSTALL_DIR}" pull
else
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}"

echo "==> 3/6 Criando ambiente virtual Python em ${VENV_DIR}..."
sudo -u "${SERVICE_USER}" "${PYTHON_BIN}" -m venv "${VENV_DIR}"

echo "==> 4/6 Instalando dependências do requirements.txt..."
sudo -u "${SERVICE_USER}" "${VENV_DIR}/bin/pip" install --upgrade pip
sudo -u "${SERVICE_USER}" "${VENV_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

echo "==> 5/6 Criando serviço systemd (${SERVICE_NAME}.service)..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=ZenPdv - Serviço app.py
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=${VENV_DIR}/bin/python ${INSTALL_DIR}/${APP_ENTRY}
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

echo "==> 6/6 Ativando e iniciando o serviço..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo ""
echo "Instalação concluída."
echo "Verifique o status com: sudo systemctl status ${SERVICE_NAME}"
echo "Acompanhe os logs com:  sudo journalctl -u ${SERVICE_NAME} -f"
