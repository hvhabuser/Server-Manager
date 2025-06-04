# 🚀 Развертывание WebPanel на Ubuntu Server

## ✅ Совместимость
Веб-панель **полностью совместима** с Ubuntu и готова к развертыванию!

## 📋 Подготовка сервера

### 1. Обновление системы
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Установка Python 3 и pip
```bash
sudo apt install python3 python3-pip python3-venv -y
```

### 3. Установка системных зависимостей
```bash
# Для обработки RAR архивов
sudo apt install unrar -y

# Для мониторинга процессов
sudo apt install htop -y

# Git (если нужно клонировать репозиторий)
sudo apt install git -y
```

## 📂 Развертывание приложения

### 1. Создание директории проекта
```bash
mkdir -p /opt/webpanel
cd /opt/webpanel
```

### 2. Загрузка файлов проекта
```bash
# Скопировать все файлы проекта в /opt/webpanel/
# Или клонировать из репозитория:
# git clone <your-repo-url> .
```

### 3. Создание виртуального окружения
```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. Установка зависимостей
```bash
pip install -r requirements.txt
```

### 5. Создание необходимых директорий
```bash
mkdir -p uploads projects logs
```

### 6. Настройка прав доступа
```bash
# Создание пользователя для веб-панели
sudo useradd -r -s /bin/false webpanel

# Назначение владельца
sudo chown -R webpanel:webpanel /opt/webpanel

# Права доступа
sudo chmod -R 755 /opt/webpanel
sudo chmod -R 777 /opt/webpanel/uploads
sudo chmod -R 777 /opt/webpanel/projects  
sudo chmod -R 777 /opt/webpanel/logs
```

## 🔧 Настройка как системная служба

### 1. Создание service файла
```bash
sudo nano /etc/systemd/system/webpanel.service
```

### 2. Содержимое service файла:
```ini
[Unit]
Description=WebPanel - Script Manager
After=network.target

[Service]
Type=simple
User=webpanel
WorkingDirectory=/opt/webpanel
Environment=PATH=/opt/webpanel/venv/bin
Environment=PYTHONIOENCODING=utf-8
ExecStart=/opt/webpanel/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 3. Активация службы
```bash
sudo systemctl daemon-reload
sudo systemctl enable webpanel
sudo systemctl start webpanel
```

### 4. Проверка статуса
```bash
sudo systemctl status webpanel
```

## 🌐 Настройка Nginx (опционально)

### 1. Установка Nginx
```bash
sudo apt install nginx -y
```

### 2. Создание конфигурации
```bash
sudo nano /etc/nginx/sites-available/webpanel
```

### 3. Содержимое конфигурации:
```nginx
server {
    listen 80;
    server_name your_domain.com;  # Замените на ваш домен

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4. Активация конфигурации
```bash
sudo ln -s /etc/nginx/sites-available/webpanel /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔒 Настройка firewall

```bash
# UFW firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS (если нужен SSL)
sudo ufw allow 5000/tcp  # WebPanel (если без Nginx)
sudo ufw enable
```

## 🔍 Мониторинг и логи

### Просмотр логов службы:
```bash
sudo journalctl -u webpanel -f
```

### Просмотр логов приложения:
```bash
tail -f /opt/webpanel/logs/*.log
```

### Перезапуск службы:
```bash
sudo systemctl restart webpanel
```

## ⚡ Быстрый запуск (для тестирования)

Если нужно быстро запустить для тестирования:

```bash
cd /path/to/webpanel
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

Затем откройте: `http://your-server-ip:5000`

## 🎯 Особенности работы на Ubuntu

### ✅ Что работает отлично:
- Все файловые операции
- Загрузка и распаковка архивов
- Выполнение Python/Shell скриптов
- Терминал с навигацией по истории
- Мониторинг процессов
- WebSocket соединения

### 🔄 Автоматические адаптации:
- Пути файлов нормализуются для Linux
- UTF-8 кодировка настроена правильно
- Процессы корректно завершаются через psutil

### 📝 Рекомендации:
- Используйте systemd service для автозапуска
- Настройте Nginx для production
- Регулярно делайте бэкапы папки `/opt/webpanel`
- Мониторьте логи через `journalctl`

## 🚨 Безопасность

1. **Смените SECRET_KEY** в app.py на случайную строку
2. **Ограничьте доступ** через firewall или Nginx auth
3. **Используйте HTTPS** в production
4. **Регулярно обновляйте** зависимости

---

**Готово!** 🎉 Ваша веб-панель будет работать на Ubuntu без проблем! 