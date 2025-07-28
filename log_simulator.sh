#!/bin/bash

# -----------------------------
# Log Simulation Script
# Sends lines from a file to Logstash via UDP every 0.1 sec
# -----------------------------

LOG_FILE="mylogs.txt"    # Replace with your log file if needed
HOST="localhost"         # IP of Logstash listener
PORT=5140                # UDP port where Logstash listens

# --- 1. Check for log file ---
if [ ! -f "$LOG_FILE" ]; then
  echo "❌ Log file not found: $LOG_FILE"
  exit 1
fi

# --- 2. Ensure socat is installed ---
if ! command -v socat >/dev/null 2>&1; then
  echo "🔧 'socat' not found. Installing..."
  sudo apt-get update && sudo apt-get install -y socat
fi

# --- 3. Start sending logs ---
echo "📤 Sending logs from '$LOG_FILE' to $HOST:$PORT (UDP)..."

while IFS= read -r line; do
  echo "$line" | socat - UDP4-DATAGRAM:$HOST:$PORT > /dev/null 2>&1
  echo "$line"
  sleep 0.01            # 100 logs/sec
done < "$LOG_FILE"

echo "✅ Finished sending all logs."
