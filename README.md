# Web Panel Server Control

**EN | RU**

---

## English Version

## Web Panel Server Control

Web Panel Server Control is a lightweight, web-based tool for managing scripts, files, and processes on your local machine or server. It provides a simple graphical interface to upload files, execute shell commands, view running processes, kill them, and monitor logs.

### Features

*   **File Management:** Upload, view, and delete files.
*   **Command Execution:** Run arbitrary shell commands with real-time output.
*   **Process Monitoring:** List running processes, view their status, and terminate them.
*   **Log Viewer:** Access logs for executed commands and running processes.
*   **Cross-Platform:** Designed to work on Windows and Linux.
*   **Easy Deployment:** Single-file scripts for quick setup and launch.

### Installation & Usage

The project includes convenient single-file installation scripts for both Windows and Linux, which handle setting up the Python environment, installing dependencies, and launching the Web Panel.

#### Prerequisites

*   **Windows:** Python 3.8+ installed and added to PATH.
*   **Linux:** `sudo` access, basic packages like `python3`, `python3-pip`, `python3-venv`.

#### On Windows

1.  **Download:** Download or clone the entire repository.
2.  **Run the script:**
    *   Locate `install_and_start_webpanel.bat` (or `установка_и_запуск_webpanel.bat` for Russian).
    *   **For Service Installation (Recommended for production):** Right-click the `.bat` file and select "Run as administrator". The script will ask if you want to install Web Panel as a Windows Service. Type `y` and press Enter. This will install the panel as a background service that starts automatically with Windows. You can close the console window afterwards.
    *   **For Direct Run (Development/Testing):** Double-click the `.bat` file (or run without administrator privileges). When prompted to install as a service, type any key other than `y` and press Enter. The panel will start in the current console window. This window must remain open for the panel to run.
3.  **Access:** Open your web browser and navigate to `http://localhost:5000`.

#### On Linux

1.  **Download:** Download or clone the entire repository.
2.  **Copy files:** It's recommended to copy the project to a system-wide location, e.g., `/opt/webpanel`.
    ```bash
    sudo cp -r /path/to/your/webpanel /opt/webpanel
    cd /opt/webpanel
    ```
3.  **Make script executable:**
    ```bash
    chmod +x install_and_start_webpanel.sh # or ./установка_и_запуск_webpanel.sh
    ```
4.  **Run the script:**
    ```bash
    sudo ./install_and_start_webpanel.sh # or sudo ./установка_и_запуск_webpanel.sh
    ```
    The script will:
    *   Update your system and install necessary Python packages.
    *   Set up a Python virtual environment and install dependencies.
    *   Install and start Web Panel as a `systemd` service (meaning it runs in the background and starts automatically on boot).
    *   **Optionally prompt to install Nginx** as a reverse proxy. If you choose `y`, it will configure Nginx to serve the panel on port 80 (standard HTTP), making it accessible without specifying port 5000.
    *   Configure `ufw` firewall rules.
5.  **Access:**
    *   If Nginx was **not** installed: `http://your_server_ip:5000`
    *   If Nginx **was** installed: `http://your_server_ip` (port 80)

##### Useful Linux Commands:

*   Check service status: `sudo systemctl status webpanel`
*   Restart service: `sudo systemctl restart webpanel`
*   View live logs: `sudo journalctl -u webpanel -f`
*   Stop the service: `sudo systemctl stop webpanel`

### Docker Deployment (Optional)

For containerized deployment, Docker and Docker Compose are provided. This method offers isolated environments and easier scaling.

1.  **Install Docker & Docker Compose:** Follow the official Docker documentation for your OS.
2.  **Build and Run:**
    ```bash
    docker-compose up --build -d
    ```
    *   To also run Nginx as a reverse proxy within Docker:
        ```bash
        docker-compose --profile with-nginx up --build -d
        ```
3.  **Access:**
    *   Without Nginx: `http://localhost:5000`
    *   With Nginx: `http://localhost` (Docker will map port 80 to your host's port 80).

### Project Structure

*   `app.py`: The main Flask application.
*   `requirements.txt`: Python dependencies.
*   `templates/`: HTML templates for the web interface.
*   `uploads/`: Directory for uploaded files (created automatically).
*   `logs/`: Directory for process logs (created automatically).
*   `install_and_start_webpanel.bat`: Consolidated Windows installation and startup script (English).
*   `установка_и_запуск_webpanel.bat`: Consolidated Windows installation and startup script (Russian).
*   `install_and_start_webpanel.sh`: Consolidated Linux installation and startup script (English).
*   `установка_и_запуск_webpanel.sh`: Consolidated Linux installation and startup script (Russian).
*   `Dockerfile`: Docker build instructions.
*   `docker-compose.yml`: Docker Compose configuration for multi-container setup.
*   `webpanel.service`: Systemd service file for Linux.
*   `nginx.conf`: Example Nginx configuration for Docker.

---

## Русская Версия

## Web Panel Server Control

Web Panel Server Control — это легкий веб-инструмент для управления скриптами, файлами и процессами на вашей локальной машине или сервере. Он предоставляет простой графический интерфейс для загрузки файлов, выполнения команд оболочки, просмотра запущенных процессов, их завершения и мониторинга логов.

### Возможности

*   **Управление файлами:** Загрузка, просмотр и удаление файлов.
*   **Выполнение команд:** Запуск произвольных команд оболочки с выводом в реальном времени.
*   **Мониторинг процессов:** Список запущенных процессов, их статус и возможность завершения.
*   **Просмотр логов:** Доступ к логам выполненных команд и запущенных процессов.
*   **Кроссплатформенность:** Разработано для работы в Windows и Linux.
*   **Простое развертывание:** Единые скрипты для быстрой установки и запуска.

### Установка и использование

Проект включает удобные единые скрипты установки для Windows и Linux, которые обрабатывают настройку среды Python, установку зависимостей и запуск Web Panel.

#### Требования

*   **Windows:** Установлен Python 3.8+ и добавлен в PATH.
*   **Linux:** Доступ `sudo`, базовые пакеты, такие как `python3`, `python3-pip`, `python3-venv`.

#### В Windows

1.  **Скачать:** Скачайте или клонируйте весь репозиторий.
2.  **Запустить скрипт:**
    *   Найдите файл `install_and_start_webpanel.bat` (или `установка_и_запуск_webpanel.bat` для русской версии).
    *   **Для установки как службы (рекомендуется для продакшена):** Щелкните правой кнопкой мыши по файлу `.bat` и выберите "Запустить от имени администратора". Скрипт спросит, хотите ли вы установить Web Panel как службу Windows. Введите `y` и нажмите Enter. Это установит панель как фоновую службу, которая запускается автоматически при старте Windows. После этого вы можете закрыть окно консоли.
    *   **Для прямого запуска (разработка/тестирование):** Дважды щелкните по файлу `.bat` (или запустите без прав администратора). Когда появится запрос на установку как службы, введите любую клавишу, кроме `y`, и нажмите Enter. Панель запустится в текущем окне консоли. Это окно должно оставаться открытым для работы панели.
3.  **Доступ:** Откройте веб-браузер и перейдите по адресу `http://localhost:5000`.

#### В Linux

1.  **Скачать:** Скачайте или клонируйте весь репозиторий.
2.  **Скопировать файлы:** Рекомендуется скопировать проект в системное расположение, например, `/opt/webpanel`.
    ```bash
    sudo cp -r /путь/к/вашему/webpanel /opt/webpanel
    cd /opt/webpanel
    ```
3.  **Сделать скрипт исполняемым:**
    ```bash
    chmod +x install_and_start_webpanel.sh # или ./установка_и_запуск_webpanel.sh
    ```
4.  **Запустить скрипт:**
    ```bash
    sudo ./install_and_start_webpanel.sh # или sudo ./установка_и_запуск_webpanel.sh
    ```
    Скрипт выполнит следующие действия:
    *   Обновит вашу систему и установит необходимые пакеты Python.
    *   Настроит виртуальное окружение Python и установит зависимости.
    *   Установит и запустит Web Panel как службу `systemd` (что означает, что она будет работать в фоновом режиме и запускаться автоматически при загрузке).
    *   **Опционально предложит установить Nginx** в качестве обратного прокси. Если вы выберете `y`, он настроит Nginx для обслуживания панели на порту 80 (стандартный HTTP), что сделает ее доступной без указания порта 5000.
    *   Настроит правила брандмауэра `ufw`.
5.  **Доступ:**
    *   Если Nginx **не был** установлен: `http://ваш_ip_сервера:5000`
    *   Если Nginx **был** установлен: `http://ваш_ip_сервера` (порт 80)

##### Полезные команды Linux:

*   Проверить статус службы: `sudo systemctl status webpanel`
*   Перезапустить службу: `sudo systemctl restart webpanel`
*   Просмотреть логи в реальном времени: `sudo journalctl -u webpanel -f`
*   Остановить службу: `sudo systemctl stop webpanel`

### Развертывание с Docker (Необязательно)

Для контейнеризованного развертывания используются Docker и Docker Compose. Этот метод предлагает изолированные среды и более простое масштабирование.

1.  **Установите Docker и Docker Compose:** Следуйте официальной документации Docker для вашей ОС.
2.  **Сборка и запуск:**
    ```bash
    docker-compose up --build -d
    ```
    *   Чтобы также запустить Nginx в качестве обратного прокси внутри Docker:
        ```bash
        docker-compose --profile with-nginx up --build -d
        ```
3.  **Доступ:**
    *   Без Nginx: `http://localhost:5000`
    *   С Nginx: `http://localhost` (Docker сопоставит порт 80 с портом 80 вашего хоста).

### Структура проекта

*   `app.py`: Основное Flask-приложение.
*   `requirements.txt`: Зависимости Python.
*   `templates/`: HTML-шаблоны для веб-интерфейса.
*   `uploads/`: Каталог для загруженных файлов (создается автоматически).
*   `logs/`: Каталог для логов процессов (создается автоматически).
*   `install_and_start_webpanel.bat`: Единый скрипт установки и запуска для Windows (английский).
*   `установка_и_запуск_webpanel.bat`: Единый скрипт установки и запуска для Windows (русский).
*   `install_and_start_webpanel.sh`: Единый скрипт установки и запуска для Linux (английский).
*   `установка_и_запуск_webpanel.sh`: Единый скрипт установки и запуска для Linux (русский).
*   `Dockerfile`: Инструкции по сборке Docker-образа.
*   `docker-compose.yml`: Конфигурация Docker Compose для настройки нескольких контейнеров.
*   `webpanel.service`: Файл службы Systemd для Linux.
*   `nginx.conf`: Пример конфигурации Nginx для Docker.