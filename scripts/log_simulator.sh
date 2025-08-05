#!/bin/bash

LOG_FILE="mylogs.txt"
HOST="localhost"
PORT=5140

if [ ! -f "$LOG_FILE" ]; then
  echo "❌ Log file not found: $LOG_FILE"
  exit 1
fi

exec 3<>/dev/udp/$HOST/$PORT

while IFS= read -r line; do
  echo -n "$line" >&3
done < "$LOG_FILE"

exec 3>&-
