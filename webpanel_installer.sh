#!/bin/bash

# 🚀 WebPanel Quick Installer для Ubuntu
# Этот скрипт скачивает полный установщик и запускает его

echo "🚀 WebPanel Quick Installer"
echo "📥 Скачивание установщика..."

# Скачать полный установщик (замените URL на ваш)
if command -v wget >/dev/null 2>&1; then
    wget -O install_ubuntu.sh https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_ubuntu.sh
elif command -v curl >/dev/null 2>&1; then
    curl -o install_ubuntu.sh https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install_ubuntu.sh
else
    echo "❌ Установите wget или curl для скачивания"
    exit 1
fi

# Сделать исполняемым
chmod +x install_ubuntu.sh

echo "✅ Установщик скачан"
echo "🚀 Запуск установки..."

# Запустить полный установщик
sudo ./install_ubuntu.sh

echo "🎉 Готово!" 