#!/bin/bash
#
# update_configs.sh – Deploy Logstash & FastAPI configuration
# Assumes this script lives in project_root/scripts/
# ├─ app.py                    (at ../ relative to this script)
# └─ logstash/                 (at ../logstash relative to this script)
#     ├─ jvm.options
#     ├─ logstash.yml
#     └─ logstash.conf
set -euo pipefail

# ─────────── Source paths ───────────
LOGSTASH_SRC_DIR="$(realpath "$(dirname "$0")/../logstash")"
FASTAPI_SRC_APP="$(realpath "$(dirname "$0")/../app.py")"

# ─────────── Destination paths ──────
LOGSTASH_DEST_DIR="/opt/logstash/config"
FASTAPI_DEST_APP="/opt/fastapi/app.py"

# ─────────── Ownership ──────────────
LOGSTASH_USER="logstash"
FASTAPI_USER="fastapi"

echo "📦 Copying Logstash configuration to ${LOGSTASH_DEST_DIR} …"
sudo install -Dm644 "${LOGSTASH_SRC_DIR}/jvm.options"  "${LOGSTASH_DEST_DIR}/jvm.options"
sudo install -Dm644 "${LOGSTASH_SRC_DIR}/logstash.yml" "${LOGSTASH_DEST_DIR}/logstash.yml"

# Ensure conf.d exists and copy pipeline file
sudo install -d "${LOGSTASH_DEST_DIR}/conf.d"
sudo install -m644 "${LOGSTASH_SRC_DIR}/logstash.conf" "${LOGSTASH_DEST_DIR}/conf.d/logstash.conf"

echo "📦 Copying FastAPI app.py to ${FASTAPI_DEST_APP} …"
sudo install -Dm644 "${FASTAPI_SRC_APP}" "${FASTAPI_DEST_APP}"

echo "🔑 Setting ownership …"
sudo chown "${LOGSTASH_USER}:${LOGSTASH_USER}" \
            "${LOGSTASH_DEST_DIR}/jvm.options" \
            "${LOGSTASH_DEST_DIR}/logstash.yml" \
            "${LOGSTASH_DEST_DIR}/conf.d/logstash.conf"

sudo chown "${FASTAPI_USER}:${FASTAPI_USER}" "${FASTAPI_DEST_APP}"

echo "🔄 Restarting Logstash …"
sudo systemctl restart logstash
sudo systemctl status  logstash --no-pager

echo "🔄 Restarting FastAPI …"
sudo systemctl restart fastapi
sudo systemctl status  fastapi --no-pager

echo "✅ Deployment complete."
