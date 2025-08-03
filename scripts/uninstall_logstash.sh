#!/bin/bash

# -----------------------------
# LogMorph Logstash Uninstaller
# -----------------------------

set -e
set -o pipefail

SERVICE_NAME="logstash"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
LOGSTASH_DIR="/opt/logstash-9.0.4"
LOGSTASH_SYMLINK="/opt/logstash"
LOGSTASH_USER="logstash"

echo "🧹 Uninstalling Logstash service..."

# --- Stop and disable the service ---
if systemctl list-units --full -all | grep -q "${SERVICE_NAME}.service"; then
  echo "🛑 Stopping Logstash service..."
  sudo systemctl stop "$SERVICE_NAME" || true
  echo "❌ Disabling Logstash service..."
  sudo systemctl disable "$SERVICE_NAME" || true
else
  echo "ℹ️ Logstash service is not active."
fi

# --- Remove systemd unit file ---
if [ -f "$SERVICE_FILE" ]; then
  echo "🗑️ Removing systemd service file..."
  sudo rm -f "$SERVICE_FILE"
else
  echo "ℹ️ No systemd service file found at $SERVICE_FILE"
fi

# --- Reload systemd ---
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# --- Remove Logstash files ---
if [ -d "$LOGSTASH_DIR" ]; then
  echo "🗑️ Removing Logstash directory: $LOGSTASH_DIR"
  sudo rm -rf "$LOGSTASH_DIR"
fi

if [ -L "$LOGSTASH_SYMLINK" ]; then
  echo "🗑️ Removing symlink: $LOGSTASH_SYMLINK"
  sudo rm -f "$LOGSTASH_SYMLINK"
fi

# --- Optionally remove logstash user ---
read -p "❓ Do you want to delete the 'logstash' user? (y/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  if id "$LOGSTASH_USER" &>/dev/null; then
    echo "👤 Deleting user $LOGSTASH_USER..."
    sudo userdel "$LOGSTASH_USER" || true
  else
    echo "ℹ️ User $LOGSTASH_USER does not exist."
  fi
else
  echo "ℹ️ Skipping deletion of user '$LOGSTASH_USER'."
fi

echo "✅ Logstash service and files have been removed."
