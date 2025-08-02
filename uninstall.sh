#!/bin/bash

# -----------------------------
# LogMorph Uninstall Script
# -----------------------------

set -e
set -o pipefail

LOGSTASH_VERSION="9.0.4"
LOGSTASH_INSTALL_DIR="/opt/logstash-$LOGSTASH_VERSION"
LOGSTASH_SYMLINK="/opt/logstash"
SYSTEMD_UNIT_PATH="/etc/systemd/system/logstash.service"
VENV_DIR="venv"

echo "🧹 Starting LogMorph uninstallation..."

# --- Step 1: Stop and disable systemd service (if systemctl exists) ---
if command -v systemctl >/dev/null 2>&1; then
  echo "🛑 Stopping Logstash service..."
  sudo systemctl stop logstash.service || true
  sudo systemctl disable logstash.service || true
  sudo systemctl daemon-reload
else
  echo "⚠️ systemctl not found. Skipping service management."
fi

# --- Step 2: Remove systemd unit file ---
if [ -f "$SYSTEMD_UNIT_PATH" ]; then
  echo "🗑️ Removing systemd service file..."
  sudo rm -f "$SYSTEMD_UNIT_PATH"
else
  echo "ℹ️ No systemd unit file to remove."
fi

# --- Step 3: Remove Logstash install directory ---
if [ -d "$LOGSTASH_INSTALL_DIR" ]; then
  echo "🗑️ Removing Logstash install directory..."
  sudo rm -rf "$LOGSTASH_INSTALL_DIR"
else
  echo "ℹ️ Logstash install directory not found."
fi

# --- Step 4: Remove symlink ---
if [ -L "$LOGSTASH_SYMLINK" ]; then
  echo "🔗 Removing symlink $LOGSTASH_SYMLINK..."
  sudo rm -f "$LOGSTASH_SYMLINK"
fi

# --- Step 5: Remove Python virtual environment ---
if [ -d "$VENV_DIR" ]; then
  echo "🐍 Removing Python virtual environment..."
  rm -rf "$VENV_DIR"
fi

# --- Step 6: Done ---
echo "✅ LogMorph uninstallation complete."
