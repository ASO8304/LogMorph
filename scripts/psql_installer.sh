#!/bin/bash

# -----------------------------
# PostgreSQL Installer (Only installs PostgreSQL)
# -----------------------------

set -e
set -o pipefail

REQUIRED_PACKAGES=("postgresql" "postgresql-contrib")

# --- Wait for apt locks ---
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

echo "🔍 Checking if PostgreSQL is already installed..."
if ! command -v psql >/dev/null 2>&1; then
  echo "📦 Installing PostgreSQL server & contrib packages..."
  wait_for_apt
  sudo apt update
  sudo apt install -y "${REQUIRED_PACKAGES[@]}"
else
  echo "✅ PostgreSQL is already installed."
fi

echo "🔧 Enabling and starting PostgreSQL service..."
sudo systemctl enable postgresql >/dev/null 2>&1 || true
sudo systemctl start postgresql

echo "🎉 PostgreSQL has been installed and started successfully."
