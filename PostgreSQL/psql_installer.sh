#!/bin/bash

# -----------------------------
# PostgreSQL Setup Script for LogMorph
# -----------------------------

DB_USER="aso"
DB_PASS="aso"
DB_NAME="logdb"

echo "🔍 Checking if PostgreSQL is installed..."
if ! command -v psql >/dev/null 2>&1; then
    echo "📦 Installing PostgreSQL..."
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
else
    echo "✅ PostgreSQL is already installed."
fi

echo "🔧 Enabling and starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "👤 Creating PostgreSQL user and database..."

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}'
    ) THEN
        CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '${DB_NAME}'
    ) THEN
        CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
    END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

echo "✅ Database '${DB_NAME}' and user '${DB_USER}' are ready."

# Optional: Test connection
echo "🔍 Testing connection with new user..."
PGPASSWORD=$DB_PASS psql -U $DB_USER -d $DB_NAME -h localhost -c '\dt' || echo "⚠️ Test connection failed (you may need to configure pg_hba.conf)"