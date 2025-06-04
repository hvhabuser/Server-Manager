#!/bin/bash

echo "========================================"
echo "  WebPanel Script Manager"
echo "  Starting setup and installation..."
echo "========================================"

# Проверяем наличие Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed"
    echo "Please install Python 3.7+ using your package manager"
    echo "Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
    echo "CentOS/RHEL: sudo yum install python3 python3-pip"
    echo "Arch: sudo pacman -S python python-pip"
    exit 1
fi

# Проверяем наличие pip
if ! command -v pip3 &> /dev/null; then
    echo "Installing pip..."
    python3 -m ensurepip --upgrade
fi

# Создаем виртуальное окружение если его нет
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Активируем виртуальное окружение
echo "Activating virtual environment..."
source venv/bin/activate

# Обновляем pip
echo "Updating pip..."
python -m pip install --upgrade pip

# Устанавливаем зависимости
echo "Installing dependencies..."
pip install -r requirements.txt

# Создаем необходимые папки
mkdir -p uploads projects logs static/css static/js templates

echo ""
echo "========================================"
echo "  Starting WebPanel Server..."
echo "  Open your browser and go to:"
echo "  http://localhost:5000"
echo "========================================"
echo ""

# Запускаем сервер
python app.py 