#!/bin/bash

# -----------------------------
# LogMorph FastAPI Setup Script
# -----------------------------

set -e
set -o pipefail

REQUIRED_TOOLS=("python3" "python3-venv" "python3-pip")

echo "🐍 Setting up FastAPI app..."

# --- Install required tools ---
echo "🔍 Checking Python environment..."
for pkg in "${REQUIRED_TOOLS[@]}"; do
  if ! dpkg -s $pkg >/dev/null 2>&1; then
    echo "📦 Installing $pkg..."
    sudo apt update
    sudo apt install -y $pkg || { echo "❌ Failed to install $pkg"; exit 1; }
  else
    echo "✅ $pkg is installed."
  fi
done

# --- Create venv ---
echo "📁 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# --- Install requirements ---
if [ ! -f "requirements.txt" ]; then
  echo "❌ Missing requirements.txt"
  exit 1
fi

echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

# --- Load .env if available ---
if [ -f ".env" ]; then
  echo "📄 Loading environment from .env..."
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️ .env file not found. Make sure DATABASE_URL is set."
fi

# --- Launch FastAPI ---
echo "🚀 Starting FastAPI..."
uvicorn app:app --host 0.0.0.0 --port 10000 --reload
