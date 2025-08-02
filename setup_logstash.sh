#!/bin/bash

# -----------------------------
# LogMorph Logstash Setup Script
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
REQUIRED_TOOLS=("wget" "tar" "curl" "openjdk-11-jdk")

echo "📦 Setting up Logstash..."

# --- Wait for apt locks ---
wait_for_apt() {
  echo "🔒 Checking for apt/dpkg locks..."
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "⏳ Waiting for apt/dpkg..."
    sleep 5
  done
  echo "✅ apt is ready."
}

# --- Install dependencies ---
echo "🔍 Installing required packages..."
for pkg in "${REQUIRED_TOOLS[@]}"; do
  if ! dpkg -s $pkg >/dev/null 2>&1; then
    echo "📦 Installing $pkg..."
    wait_for_apt
    sudo apt update
    sudo apt install -y $pkg || { echo "❌ Failed to install $pkg"; exit 1; }
  else
    echo "✅ $pkg is installed."
  fi
done

# --- Detect JAVA_HOME ---
JAVA_BIN=$(readlink -f $(which java))
JAVA_HOME=$(dirname $(dirname "$JAVA_BIN"))
echo "🧠 Detected JAVA_HOME: $JAVA_HOME"

# --- Download Logstash ---
if [ ! -f "$LOGSTASH_TARBALL" ]; then
  echo "⬇️ Downloading Logstash..."
  wget "$LOGSTASH_URL" -O "$LOGSTASH_TARBALL"
else
  echo "ℹ️ Logstash tarball already exists."
fi

# --- Extract Logstash ---
if [ ! -d "$LOGSTASH_INSTALL_DIR" ]; then
  echo "📂 Extracting Logstash..."
  sudo tar -xzf "$LOGSTASH_TARBALL" -C /opt
fi

# --- Symlink ---
echo "🔗 Creating symlink..."
sudo ln -sfn "$LOGSTASH_INSTALL_DIR" "$LOGSTASH_SYMLINK"

# --- Copy config ---
if [ ! -f "$LOGSTASH_CONF_SRC" ]; then
  echo "❌ Config not found: $LOGSTASH_CONF_SRC"
  exit 1
fi

echo "📝 Copying config..."
sudo mkdir -p "$LOGSTASH_SYMLINK/config/conf.d"
sudo cp "$LOGSTASH_CONF_SRC" "$LOGSTASH_CONF_DEST"

# --- Setup systemd ---
if command -v systemctl >/dev/null 2>&1; then
  echo "🛠️ Setting up systemd service..."
  sudo tee "$SYSTEMD_UNIT_PATH" > /dev/null <<EOF
[Unit]
Description=LogMorph Logstash Service
After=network.target

[Service]
ExecStart=$LOGSTASH_SYMLINK/bin/logstash -f $LOGSTASH_CONF_DEST
Restart=always
User=$USER
Group=$USER
WorkingDirectory=$LOGSTASH_SYMLINK
Environment=LS_JAVA_HOME=$JAVA_HOME
StandardOutput=journal
StandardError=journal
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable logstash
  sudo systemctl restart logstash

  echo "✅ Logstash service is running. Use: journalctl -u logstash -f"
else
  echo "⚠️ systemctl not found. Run Logstash manually:"
  echo "$LOGSTASH_SYMLINK/bin/logstash -f $LOGSTASH_CONF_DEST"
fi
