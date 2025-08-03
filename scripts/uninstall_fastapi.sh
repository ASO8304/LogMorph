#!/bin/bash

# -----------------------------
# LogMorph FastAPI Uninstaller
# -----------------------------

set -e
set -o pipefail

APP_NAME="fastapi"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
INSTALL_DIR="/opt/fastapi"
FASTAPI_USER="fastapi"

echo "🗑️ Uninstalling FastAPI service from $INSTALL_DIR..."

# --- Stop and disable systemd service ---
if systemctl list-units --full -all | grep -q "${APP_NAME}.service"; then
  echo "🛑 Stopping $APP_NAME service..."
  sudo systemctl stop "$APP_NAME" || true
  echo "❌ Disabling $APP_NAME service..."
  sudo systemctl disable "$APP_NAME" || true
else
  echo "ℹ️ No active $APP_NAME systemd service found."
fi

# --- Remove systemd unit file ---
if [ -f "$SERVICE_FILE" ]; then
  echo "🧽 Removing systemd service file..."
  sudo rm -f "$SERVICE_FILE"
else
  echo "ℹ️ No systemd service file found at $SERVICE_FILE"
fi

# --- Reload systemd ---
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# --- Remove app directory ---
if [ -d "$INSTALL_DIR" ]; then
  echo "🗑️ Removing FastAPI app directory at $INSTALL_DIR..."
  sudo rm -rf "$INSTALL_DIR"
else
  echo "ℹ️ No install directory found at $INSTALL_DIR"
fi

# --- Optionally remove fastapi user ---
read -p "❓ Do you want to delete the 'fastapi' system user? (y/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  if id "$FASTAPI_USER" &>/dev/null; then
    echo "👤 Deleting user '$FASTAPI_USER'..."
    sudo userdel "$FASTAPI_USER" || true
  else
    echo "ℹ️ User '$FASTAPI_USER' does not exist."
  fi
else
  echo "ℹ️ Skipping deletion of user '$FASTAPI_USER'."
fi

echo "✅ FastAPI service and files removed successfully."
