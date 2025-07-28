#!/bin/bash

# -----------------------------
# PostgreSQL Setup Script for LogMorph (robust, idempotent, no chdir warnings)
# -----------------------------

set -e
set -o pipefail

DB_USER="aso"
DB_PASS="aso"
DB_NAME="logdb"

# --- Helper: wait for apt locks (only used if we need to install packages) ---
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

echo "🔍 Checking if PostgreSQL (psql) is installed..."
if ! command -v psql >/dev/null 2>&1; then
  echo "📦 Installing PostgreSQL server & contrib..."
  wait_for_apt
  sudo apt update
  sudo apt install -y postgresql postgresql-contrib
else
  echo "✅ PostgreSQL client is available."
fi

echo "🔧 Enabling and starting PostgreSQL service..."
sudo systemctl enable postgresql >/dev/null 2>&1 || true
sudo systemctl start postgresql

# --- Helpers to run as postgres from a readable directory ---
# Use -H to set HOME, and 'cd ~' so we don't inherit the caller's PWD.
psql_as_postgres() {
  sudo -u postgres -H bash -lc "cd ~; psql -v ON_ERROR_STOP=1 -d postgres -Atqc \"$1\""
}
psql_exec_postgres() {
  sudo -u postgres -H bash -lc "cd ~; psql -v ON_ERROR_STOP=1 -d postgres -c \"$1\""
}
createdb_as_postgres() {
  sudo -u postgres -H bash -lc "cd ~; createdb -O \"$1\" \"$2\""
}

echo "👤 Ensuring role '$DB_USER' exists with LOGIN and password..."
if psql_as_postgres "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q '^1$'; then
  echo "ℹ️ Role '$DB_USER' already exists. Ensuring LOGIN and password..."
  psql_exec_postgres "ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';"
else
  psql_exec_postgres "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';"
  echo "✅ Role '$DB_USER' created."
fi

echo "🗄️ Ensuring database '$DB_NAME' exists and is owned by '$DB_USER'..."
if psql_as_postgres "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q '^1$'; then
  echo "ℹ️ Database '$DB_NAME' already exists."
  # Uncomment if you want to force ownership each run:
  # psql_exec_postgres "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};"
else
  createdb_as_postgres "${DB_USER}" "${DB_NAME}"
  echo "✅ Database '$DB_NAME' created with owner '$DB_USER'."
fi

echo "🔐 Granting privileges on database '$DB_NAME' to '$DB_USER' (safe if already owner)..."
psql_exec_postgres "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

echo "🧪 Testing connection as '${DB_USER}' to database '${DB_NAME}'..."
export PGPASSWORD="${DB_PASS}"
if psql -U "${DB_USER}" -d "${DB_NAME}" -h localhost -c '\dt' >/dev/null 2>&1; then
  echo "✅ Connection test succeeded (user='${DB_USER}', db='${DB_NAME}')."
else
  echo "⚠️ Connection test failed. Common fixes:"
  echo "   • Ensure the service is running:  sudo systemctl status postgresql"
  echo "   • Check pg_hba.conf for local auth method (md5) and reload:  sudo systemctl reload postgresql"
  echo "   • Try: psql -U ${DB_USER} -h 127.0.0.1 -d ${DB_NAME}"
  exit 1
fi

echo "🎉 PostgreSQL is ready: user='${DB_USER}', database='${DB_NAME}'."
