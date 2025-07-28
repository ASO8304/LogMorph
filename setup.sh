#!/bin/bash

# -----------------------------
# LogMorph Full Setup Script (Robust with apt-lock handling)
# -----------------------------

set -e
set -o pipefail

LOGSTASH_VERSION="9.0.4"
LOGSTASH_TARBALL="logstash-$LOGSTASH_VERSION-linux-x86_64.tar.gz"
LOGSTASH_URL="https://artifacts.elastic.co/downloads/logstash/$LOGSTASH_TARBALL"
LOGSTASH_INSTALL_DIR="/opt/logstash-$LOGSTASH_VERSION"
LOGSTASH_SYMLINK="/opt/logstash"
LOGSTASH_CONF_SRC="logstash/logstash.conf"
LOGSTASH_CONF_DEST="$LOGSTASH_SYMLINK/config/conf.d/logstash.conf"
SYSTEMD_UNIT_PATH="/etc/systemd/system/logstash.service"
REQUIRED_TOOLS=("wget" "tar" "python3" "python3-venv" "pip" "systemctl" "curl")

echo "📦 Starting LogMorph setup..."

# --- Function: Wait for apt lock ---
wait_for_apt() {
  echo "🔒 Checking for apt/dpkg locks..."
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "⏳ Waiting for apt/dpkg to become available..."
    sleep 5
  done
  echo "✅ apt is available."
}

# --- Step 1: Install missing tools ---
echo "🔍 Checking and installing required tools..."
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v $tool >/dev/null 2>&1; then
    echo "⚠️  '$tool' not found. Installing..."
    wait_for_apt
    sudo apt update
    sudo apt install -y $tool || { echo "❌ Failed to install '$tool'. Aborting."; exit 1; }
  else
    echo "✅ $tool is installed."
  fi
done

# --- Step 2: Download Logstash tarball ---
if [ ! -f "$LOGSTASH_TARBALL" ]; then
  echo "⬇️ Downloading Logstash from $LOGSTASH_URL..."
  wget "$LOGSTASH_URL" -O "$LOGSTASH_TARBALL" || { echo "❌ Failed to download Logstash."; exit 1; }
else
  echo "ℹ️ Logstash tarball already exists. Skipping download."
fi

# --- Step 3: Extract Logstash ---
if [ ! -d "$LOGSTASH_INSTALL_DIR" ]; then
  echo "📂 Extracting Logstash to $LOGSTASH_INSTALL_DIR..."
  sudo tar -xzf "$LOGSTASH_TARBALL" -C /opt || { echo "❌ Failed to extract Logstash."; exit 1; }
else
  echo "ℹ️ Logstash already extracted at $LOGSTASH_INSTALL_DIR"
fi

# --- Step 4: Create symlink ---
echo "🔗 Linking $LOGSTASH_SYMLINK → $LOGSTASH_INSTALL_DIR"
sudo ln -sfn "$LOGSTASH_INSTALL_DIR" "$LOGSTASH_SYMLINK"

# --- Step 5: Copy Logstash config ---
if [ ! -f "$LOGSTASH_CONF_SRC" ]; then
  echo "❌ Logstash config file missing: $LOGSTASH_CONF_SRC"
  exit 1
fi

echo "📝 Copying Logstash config..."
sudo mkdir -p "$LOGSTASH_SYMLINK/config/conf.d"
sudo cp "$LOGSTASH_CONF_SRC" "$LOGSTASH_CONF_DEST"
echo "✅ Config copied to $LOGSTASH_CONF_DEST"

# --- Step 6: Create systemd service ---
echo "🛠️ Creating systemd service: $SYSTEMD_UNIT_PATH"

sudo tee "$SYSTEMD_UNIT_PATH" > /dev/null <<EOF
[Unit]
Description=LogMorph Logstash Service
After=network.target

[Service]
ExecStart=$LOGSTASH_SYMLINK/bin/logstash -f $LOGSTASH_SYMLINK/config/conf.d/logstash.conf
Restart=always
User=$USER
Group=$USER
WorkingDirectory=$LOGSTASH_SYMLINK
StandardOutput=journal
StandardError=journal
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# --- Step 7: Start and enable Logstash service ---
echo "🔄 Enabling and starting Logstash..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl restart logstash
echo "✅ Logstash service is running. View logs with: journalctl -u logstash -f"

# --- Step 8: Python virtual environment setup ---
echo "🐍 Creating Python virtual environment..."
python3 -m venv venv || { echo "❌ Failed to create virtual environment."; exit 1; }
source venv/bin/activate
pip install --upgrade pip
echo "khalaf"

# --- Step 9: Install Python packages ---
if [ ! -f "requirements.txt" ]; then
  echo "❌ requirements.txt not found. Aborting."
  exit 1
fi

echo "📥 Installing Python dependencies..."
pip install -r requirements.txt || { echo "❌ Failed to install Python packages."; exit 1; }

# --- Step 10: Load .env (if exists) ---
if [ -f ".env" ]; then
  echo "📄 Loading environment from .env..."
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️ .env file not found. Ensure DATABASE_URL is set in your code or system."
fi

# --- Step 11: Run FastAPI app ---
echo "🚀 Starting FastAPI (Uvicorn)..."
uvicorn app:app --host 0.0.0.0 --port 10000 --reload
