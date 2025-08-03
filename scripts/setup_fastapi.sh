#!/bin/bash

# -----------------------------
# LogMorph FastAPI Setup Script
# -----------------------------

set -e
set -o pipefail

APP_NAME="fastapi"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
APP_PORT=10000
INSTALL_DIR="/opt/fastapi"
VENV_PATH="$INSTALL_DIR/venv"
FASTAPI_USER="fastapi"

REQUIRED_TOOLS=("python3" "python3-venv" "python3-pip")

echo "🐍 Setting up FastAPI app in $INSTALL_DIR..."

# --- Install required tools ---
echo "🔍 Checking Python environment..."
for pkg in "${REQUIRED_TOOLS[@]}"; do
  if ! dpkg -s $pkg >/dev/null 2>&1; then
    echo "📦 Installing $pkg..."
    sudo apt update
    sudo apt install -y $pkg || { echo "❌ Failed to install $pkg"; exit 1; }
  else
    echo "✅ $pkg is installed."
  fi
done

# --- Create fastapi user if missing ---
if ! id "$FASTAPI_USER" &>/dev/null; then
  echo "👤 Creating system user: $FASTAPI_USER"
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin $FASTAPI_USER
else
  echo "✅ User '$FASTAPI_USER' already exists."
fi

# --- Copy project to /opt/fastapi ---
echo "📁 Installing FastAPI app to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo rsync -a --exclude venv ../ "$INSTALL_DIR/"
sudo chown -R $FASTAPI_USER:$FASTAPI_USER "$INSTALL_DIR"

# --- Create virtual environment ---
echo "🐍 Creating virtual environment in $VENV_PATH..."
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"
pip install --upgrade pip

# --- Install requirements ---
if [ ! -f "$INSTALL_DIR/requirements.txt" ]; then
  echo "❌ Missing requirements.txt in $INSTALL_DIR"
  exit 1
fi

echo "📥 Installing Python dependencies..."
pip install -r "$INSTALL_DIR/requirements.txt"

# --- Set ownership for venv ---
sudo chown -R $FASTAPI_USER:$FASTAPI_USER "$VENV_PATH"

# --- Warn if .env is missing ---
if [ ! -f "$INSTALL_DIR/.env" ]; then
  echo "⚠️ WARNING: .env file not found in $INSTALL_DIR"
  echo "   Be sure to add one with DATABASE_URL if needed."
fi

# --- Create systemd service ---
echo "🛠️ Creating systemd service at $SERVICE_FILE..."

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=LogMorph FastAPI Service
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
ExecStart=$VENV_PATH/bin/uvicorn app:app --host 0.0.0.0 --port $APP_PORT
Restart=always
User=$FASTAPI_USER
Group=$FASTAPI_USER
EnvironmentFile=$INSTALL_DIR/.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# --- Reload and start service ---
echo "🔄 Reloading systemd and starting FastAPI service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $APP_NAME
sudo systemctl restart $APP_NAME

echo "✅ FastAPI is running in the background on port $APP_PORT!"
echo "📝 Check logs with: sudo journalctl -u $APP_NAME -f"
