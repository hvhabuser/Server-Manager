#!/bin/bash

echo_status() {
    echo -e "\n--- $1 ---\n"
}

echo "Начинается установка Web Panel Server Control..."

if [ "$EUID" -ne 0 ]; then
    echo "ОШИБКА: Пожалуйста, запустите этот скрипт с sudo: sudo ./установка_и_запуск_webpanel.sh"
    exit 1
fi

echo_status "1. Обновление системы и установка необходимых компонентов"
apt update && apt upgrade -y
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось обновить или обновить систему."
    exit 1
fi
apt install python3 python3-pip python3-venv procps curl -y
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось установить Python или другие необходимые компоненты."
    exit 1
fi

echo_status "2. Подготовка каталога приложения"
APP_DIR="/opt/webpanel"
mkdir -p "$APP_DIR"
cp -r "$(dirname "$0")"/* "$APP_DIR"/
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось скопировать файлы приложения в $APP_DIR."
    exit 1
fi
chmod +x "$APP_DIR"/examples/*.py

echo_status "3. Настройка виртуального окружения и установка зависимостей"
cd "$APP_DIR" || { echo "ОШИБКА: Не удалось перейти в каталог $APP_DIR"; exit 1; }
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось создать виртуальное окружение."
    exit 1
fi
./venv/bin/pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "ПРЕДУПРЕЖДЕНИЕ: Не удалось установить все зависимости. Web Panel может работать некорректно."
    echo "Пожалуйста, проверьте requirements.txt и подключение к интернету."
fi
chown -R www-data:www-data "$APP_DIR"
chmod +x "$APP_DIR"/venv/bin/python

echo_status "4. Установка службы systemd"
cp webpanel.service /etc/systemd/system/webpanel.service
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось скопировать файл webpanel.service."
    exit 1
fi
systemctl daemon-reload
systemctl enable webpanel
systemctl start webpanel
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось включить или запустить службу webpanel."
    echo "Проверьте 'sudo journalctl -u webpanel -f' для получения подробностей."
fi
echo "Служба Web Panel установлена и запущена."

echo_status "5. Настройка обратного прокси Nginx (Необязательно)"
read -p "Хотите установить обратный прокси Nginx для Web Panel? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install nginx -y
    if [ $? -ne 0 ]; then
        echo "ПРЕДУПРЕЖДЕНИЕ: Не удалось установить Nginx. Пропуск настройки Nginx."
    else
        tee /etc/nginx/sites-available/webpanel > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ln -sf /etc/nginx/sites-available/webpanel /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        systemctl restart nginx
        if [ $? -ne 0 ]; then
            echo "ПРЕДУПРЕЖДЕНИЕ: Nginx установлен, но не удалось настроить или перезапустить."
        else
            echo "Nginx успешно настроен."
        fi
    fi
else
    echo "Пропуск установки Nginx."
fi

echo_status "6. Настройка брандмауэра"
ufw allow 22
ufw allow 80
ufw allow 5000
ufw --force enable
if [ $? -ne 0 ]; then
    echo "ПРЕДУПРЕЖДЕНИЕ: Не удалось настроить брандмауэр UFW. Проверьте вручную."
fi
echo "Брандмауэр настроен."

echo_status "Установка завершена!"
echo "Web Panel работает по адресу http://your_server_ip:5000"
echo "Или http://your_server_ip, если был установлен Nginx."
echo ""
echo "Полезные команды:"
echo "  sudo systemctl status webpanel    - Проверить статус службы"
echo "  sudo systemctl restart webpanel   - Перезапустить службу"
echo "  sudo journalctl -u webpanel -f    - Просмотр логов"
echo "Чтобы остановить панель, используйте 'sudo systemctl stop webpanel'"
echo "" 