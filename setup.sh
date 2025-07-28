#!/bin/bash

# -----------------------------
# LogMorph Setup Script (with Logstash systemd service)
# -----------------------------

set -e

LOGSTASH_VERSION="9.0.4"
LOGSTASH_INSTALL_DIR="/opt/logstash-$LOGSTASH_VERSION"
LOGSTASH_SYMLINK="/opt/logstash"
LOGSTASH_TARBALL="logstash-$LOGSTASH_VERSION-linux-x86_64.tar.gz"
LOGSTASH_URL="https://artifacts.elastic.co/downloads/logstash/$LOGSTASH_TARBALL"

echo "📦 Installing Logstash $LOGSTASH_VERSION..."

# --- 1. Download and extract Logstash to /opt ---
if [ ! -d "$LOGSTASH_INSTALL_DIR" ]; then
  echo "⬇️ Downloading Logstash tarball..."
  wget -q "$LOGSTASH_URL"
  sudo tar -xzf "$LOGSTASH_TARBALL" -C /opt
  rm "$LOGSTASH_TARBALL"
  echo "✅ Extracted to $LOGSTASH_INSTALL_DIR"
fi

# --- 2. Create version-independent symlink ---
sudo ln -sfn "$LOGSTASH_INSTALL_DIR" "$LOGSTASH_SYMLINK"

# --- 3. Add custom config ---
echo "⚙️ Adding Logstash pipeline config..."
sudo mkdir -p "$LOGSTASH_SYMLINK/config/conf.d"
sudo cp logstash/logstash.conf "$LOGSTASH_SYMLINK/config/conf.d/logstash.conf"

# --- 4. Create systemd service file for Logstash ---
echo "📝 Creating systemd unit: /etc/systemd/system/logstash.service"

sudo tee /etc/systemd/system/logstash.service > /dev/null <<EOF
[Unit]
Description=LogMorph Logstash Service
After=network.target

[Service]
ExecStart=$LOGSTASH_SYMLINK/bin/logstash -f $LOGSTASH_SYMLINK/config/conf.d/logstash.conf
Restart=always
WorkingDirectory=$LOGSTASH_SYMLINK
StandardOutput=journal
StandardError=journal
User=$USER
Group=$USER
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# --- 5. Reload systemd and enable service ---
echo "🔄 Reloading systemd and enabling Logstash service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl restart logstash

# --- 6. Python Virtual Environment Setup ---
echo "🐍 Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

# --- 7. Load environment variables from .env (if available) ---
if [ -f ".env" ]; then
  echo "📄 Loading environment variables from .env"
  export $(grep -v '^#' .env | xargs)
fi

# --- 8. Start FastAPI Server ---
echo "🚀 Starting FastAPI with uvicorn (http://0.0.0.0:10000)..."
uvicorn app:app --host 0.0.0.0 --port 10000 --reload
