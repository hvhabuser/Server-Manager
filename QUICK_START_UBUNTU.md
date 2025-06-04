# ⚡ WebPanel - Быстрый запуск на Ubuntu

## 🎯 Одна команда для установки всего

### Способ 1: Автоустановщик (Рекомендуется)

```bash
# Скопируйте файл install_ubuntu.sh на ваш Ubuntu сервер
# Затем запустите:
chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

### Способ 2: Скачивание из интернета

```bash
# Если файлы выложены в интернете (GitHub и т.д.)
wget -O install.sh https://your-repo.com/install_ubuntu.sh
chmod +x install.sh
sudo ./install.sh
```

### Способ 3: Копирование через SCP

```bash
# С вашего компьютера скопируйте на сервер:
scp install_ubuntu.sh user@your-server:/tmp/
scp -r webpanel/ user@your-server:/tmp/

# На сервере:
cd /tmp
chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

## 🚀 Что произойдет после запуска

### Автоматически установится:
✅ Python 3 и pip  
✅ Все зависимости (Flask, SocketIO, psutil и др.)  
✅ RAR поддержка  
✅ Виртуальное окружение  
✅ Структура папок  
✅ Systemd служба (если запущено от root)  
✅ Firewall правила  

### Автоматически создастся:
📁 `/opt/webpanel/` (если root) или `~/webpanel/` (если user)  
📁 `uploads/` `projects/` `logs/`  
📄 `app.py` с полным кодом сервера  
📄 `requirements.txt` со всеми зависимостями  
📄 Демо скрипты для тестирования  

## 🌐 После установки

### Доступ к веб-панели:
```
http://your-server-ip:5000
http://localhost:5000
```

### Управление службой (если установлено как root):
```bash
sudo systemctl start webpanel    # Запуск
sudo systemctl stop webpanel     # Остановка  
sudo systemctl restart webpanel  # Перезапуск
sudo systemctl status webpanel   # Статус
```

### Ручной запуск (если установлено как user):
```bash
cd ~/webpanel
source venv/bin/activate
python app.py
```

## 📋 Системные требования

- **OS**: Ubuntu 18.04+ / Debian 10+
- **RAM**: 512MB минимум, 1GB рекомендуется  
- **Диск**: 1GB свободного места
- **Сеть**: Порт 5000 должен быть открыт

## 🔧 Настройка

### Изменить порт:
Отредактируйте `app.py`, строка:
```python
socketio.run(app, host='0.0.0.0', port=5000, debug=False)
```

### Изменить SECRET_KEY:
```python
app.config['SECRET_KEY'] = 'your-new-secret-key'
```

### Добавить HTTPS (с Nginx):
Смотрите [DEPLOY_UBUNTU.md](DEPLOY_UBUNTU.md) для настройки Nginx + SSL

## 🆘 Устранение неполадок

### Порт занят:
```bash
sudo lsof -i :5000
sudo kill -9 PID
```

### Логи службы:
```bash
sudo journalctl -u webpanel -f
```

### Логи приложения:
```bash
tail -f /opt/webpanel/logs/*.log
```

### Права доступа:
```bash
sudo chown -R $USER:$USER ~/webpanel
chmod -R 755 ~/webpanel
```

## 🎉 Готово!

После выполнения установщика ваша WebPanel будет полностью готова к работе на Ubuntu!

---

💡 **Совет**: Сделайте бэкап папки с проектом после настройки:
```bash
sudo tar -czf webpanel-backup.tar.gz /opt/webpanel/
``` 