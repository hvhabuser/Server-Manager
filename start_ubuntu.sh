#!/bin/bash

# WebPanel Startup Script for Ubuntu
echo "🚀 Starting WebPanel on Ubuntu..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies if needed
if [ ! -f "venv/lib/python*/site-packages/flask/__init__.py" ]; then
    echo "⬇️ Installing dependencies..."
    pip install -r requirements.txt
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p uploads projects logs

# Set UTF-8 encoding
export PYTHONIOENCODING=utf-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️ Warning: Running as root is not recommended for security reasons"
    echo "Consider creating a dedicated user for WebPanel"
fi

# Start the application
echo "🌟 Starting WebPanel server..."
echo "📍 Access your panel at: http://localhost:5000"
echo "🔄 Press Ctrl+C to stop"
python app.py 