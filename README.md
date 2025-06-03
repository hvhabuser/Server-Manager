# Web Panel Server Control

**EN | RU**

---

## English Version

## Web Panel Server Control

Web Panel Server Control is a lightweight, web-based tool for managing scripts, files, and processes on your local machine or server. It provides a simple graphical interface to upload files, execute shell commands, view running processes, terminate them, and monitor logs.

### Features

*   **File Management:** Upload, view, and delete files. Supported file types for direct upload include `.py`, `.js`, `.sh`, `.bat`, `.txt`, `.exe`.
*   **Command Execution:** Run arbitrary shell commands with real-time output from uploaded scripts or any system command.
*   **Process Monitoring:** List running processes, view their status, and terminate them directly from the web interface.
*   **Log Viewer:** Access logs for executed commands and running processes, providing detailed output including STDOUT, STDERR, and return codes.
*   **Cross-Platform:** Designed to work seamlessly on both Windows and Linux operating systems.
*   **Easy Deployment:** Consolidated scripts for quick setup and launch, handling Python environment, dependencies, and service installation.
*   **Optional Authentication:** Secure access to the web panel with user authentication (username/password).

### Installation & Usage

The project includes convenient consolidated installation scripts for both Windows and Linux, which handle setting up the Python environment, installing dependencies, and launching the Web Panel.

#### Prerequisites

*   **Windows:** Python 3.8+ installed and added to your system's PATH.
*   **Linux:** `sudo` access, and basic packages like `python3`, `python3-pip`, `python3-venv`, `procps`, `curl`.

#### On Windows

1.  **Download:** Download or clone the entire repository to your desired location.
2.  **Run the script:**
    *   Locate `win_en.bat` (for English) or `win_ru.bat` (for Russian) in the project root.
    *   **For Service Installation (Recommended for production):** Right-click the chosen `.bat` file and select "Run as administrator". The script will ask if you want to install Web Panel as a Windows Service. Type `y` and press Enter. This will install the panel as a background service that starts automatically with Windows. You can close the console window afterwards.
    *   **For Direct Run (Development/Testing):** Double-click the chosen `.bat` file (or run without administrator privileges). When prompted to install as a service, type any key other than `y`, and press Enter. The panel will start in the current console window. This window must remain open for the panel to run.
3.  **Access:** Open your web browser and navigate to `http://localhost:5000`.

#### On Linux

1.  **Download:** Download or clone the entire repository to your desired location.
2.  **Copy files:** It's recommended to copy the project to a system-wide location, for example, `/opt/webpanel`.
    ```bash
    sudo cp -r /path/to/your/webpanel /opt/webpanel
    cd /opt/webpanel
    ```
3.  **Make script executable:**
    ```bash
    chmod +x linux_en.sh # or ./linux_ru.sh for Russian version
    ```
4.  **Run the script:**
    ```bash
    sudo ./linux_en.sh # or sudo ./linux_ru.sh for Russian version
    ```
    The script will perform the following actions:
    *   Update your system and install necessary Python packages.
    *   Set up a Python virtual environment and install dependencies.
    *   Install and start Web Panel as a `systemd` service (this means it will run in the background and start automatically on boot).
    *   **Optionally prompt to install Nginx** as a reverse proxy. If you choose `y`, it will configure Nginx to serve the panel on port 80 (standard HTTP), making it accessible without explicitly specifying port 5000.
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

For containerized deployment, Docker and Docker Compose configurations are provided. This method offers isolated environments and easier scaling.

1.  **Install Docker & Docker Compose:** Follow the official Docker documentation for your operating system.
2.  **Build and Run:** From the project root, open your terminal and run:
    ```bash
    docker-compose up --build -d
    ```
    *   To also run Nginx as a reverse proxy within Docker:
        ```bash
        docker-compose --profile with-nginx up --build -d
        ```
3.  **Access:**
    *   Without Nginx: `http://localhost:5000`
    *   With Nginx: `http://localhost` (Docker will map port 80 of the container to port 80 of your host).

### Authentication (Optional)

The Web Panel supports optional user authentication to secure access.

*   To enable user authentication for the web panel:
    1.  Run `python create_admin.py` from the project root. Follow the prompts to set a username and password. This will create a `data/admin.json` file containing the hashed credentials.
    2.  Set the environment variable `ENABLE_AUTH=true`.
        *   **For Docker:** Set `ENABLE_AUTH=true` in the `environment` section of `docker-compose.yml` for the `webpanel` service.
        *   **For Linux Systemd Service:** Edit the `webpanel.service` file (e.g., `sudo nano /etc/systemd/system/webpanel.service`) and add `Environment="ENABLE_AUTH=true"` under the `[Service]` section, then run `sudo systemctl daemon-reload && sudo systemctl restart webpanel`.
        *   **For Windows Service/Direct Run:** Set the environment variable before starting the application, e.g., `set ENABLE_AUTH=true` in your command prompt, or add it to the `start_webpanel.bat` script.
*   If authentication is enabled, users will be required to log in to access the panel. The default username and password are `admin` and `admin123` if not explicitly set via `create_admin.py` or environment variables, but it is strongly recommended to use `create_admin.py` for security.

### Project Structure

*   `app.py`: The main Flask application, handling API routes and web logic.
*   `config.py`: Configuration settings for the Flask application, including allowed file extensions, authentication flags, and server parameters.
*   `requirements.txt`: Python dependencies required for the project.
*   `create_admin.py`: A utility script to create and manage admin user credentials for authentication.
*   `templates/`: Contains HTML templates for the web interface (e.g., `index.html`).
*   `uploads/`: A directory for uploaded files (created automatically).
*   `logs/`: A directory for storing process execution logs (created automatically).
*   `win_en.bat`: Consolidated Windows installation and startup script (English version).
*   `win_ru.bat`: Consolidated Windows installation and startup script (Russian version).
*   `linux_en.sh`: Consolidated Linux installation and startup script (English version).
*   `linux_ru.sh`: Consolidated Linux installation and startup script (Russian version).
*   `Dockerfile`: Docker build instructions for creating the application container image.
*   `docker-compose.yml`: Docker Compose configuration for multi-container setup, including optional Nginx reverse proxy.
*   `webpanel.service`: Systemd service file for managing the application as a background service on Linux.
*   `nginx.conf`: Example Nginx configuration for Docker deployment.
*   `static/`: Placeholder for static files (CSS, JavaScript, images).
*   `data/`: A directory to store application data, such as `admin.json` for authentication (created automatically).
*   `test.py`: A simple example Python script for testing purposes.

---

## Русская Версия

## Web Panel Server Control

Web Panel Server Control — это легкий веб-инструмент для управления скриптами, файлами и процессами на вашей локальной машине или сервере. Он предоставляет простой графический интерфейс для загрузки файлов, выполнения команд оболочки, просмотра запущенных процессов, их завершения и мониторинга логов.

### Возможности

*   **Управление файлами:** Загрузка, просмотр и удаление файлов. Поддерживаемые типы файлов для прямой загрузки включают `.py`, `.js`, `.sh`, `.bat`, `.txt`, `.exe`.
*   **Выполнение команд:** Запуск произвольных команд оболочки с выводом в реальном времени из загруженных скриптов или любых системных команд.
*   **Мониторинг процессов:** Список запущенных процессов, их статус и возможность завершения прямо из веб-интерфейса.
*   **Просмотр логов:** Доступ к логам выполненных команд и запущенных процессов, предоставляющий подробный вывод, включая STDOUT, STDERR и коды возврата.
*   **Кроссплатформенность:** Разработано для бесперебойной работы как в операционных системах Windows, так и в Linux.
*   **Простое развертывание:** Консолидированные скрипты для быстрой настройки и запуска, обрабатывающие среду Python, зависимости и установку службы.
*   **Дополнительная аутентификация:** Защищенный доступ к веб-панели с аутентификацией пользователя (имя пользователя/пароль).

### Установка и использование

Проект включает удобные консолидированные скрипты установки для Windows и Linux, которые обрабатывают настройку среды Python, установку зависимостей и запуск Web Panel.

#### Требования

*   **Windows:** Установлен Python 3.8+ и добавлен в PATH вашей системы.
*   **Linux:** Доступ `sudo`, базовые пакеты, такие как `python3`, `python3-pip`, `python3-venv`, `procps`, `curl`.

#### В Windows

1.  **Скачать:** Скачайте или клонируйте весь репозиторий в нужное вам место.
2.  **Запустить скрипт:**
    *   Найдите файл `win_en.bat` (для английской версии) или `win_ru.bat` (для русской версии) в корне проекта.
    *   **Для установки как службы (рекомендуется для продакшена):** Щелкните правой кнопкой мыши по выбранному файлу `.bat` и выберите "Запустить от имени администратора". Скрипт спросит, хотите ли вы установить Web Panel как службу Windows. Введите `y` и нажмите Enter. Это установит панель как фоновую службу, которая запускается автоматически при старте Windows. После этого вы можете закрыть окно консоли.
    *   **Для прямого запуска (разработка/тестирование):** Дважды щелкните по выбранному файлу `.bat` (или запустите без прав администратора). Когда появится запрос на установку как службы, введите любую клавишу, кроме `y`, и нажмите Enter. Панель запустится в текущем окне консоли. Это окно должно оставаться открытым для работы панели.
3.  **Доступ:** Откройте веб-браузер и перейдите по адресу `http://localhost:5000`.

#### В Linux

1.  **Скачать:** Скачайте или клонируйте весь репозиторий в нужное вам место.
2.  **Скопировать файлы:** Рекомендуется скопировать проект в системное расположение, например, `/opt/webpanel`.
    ```bash
    sudo cp -r /путь/к/вашему/webpanel /opt/webpanel
    cd /opt/webpanel
    ```
3.  **Сделать скрипт исполняемым:**
    ```bash
    chmod +x linux_en.sh # или ./linux_ru.sh для русской версии
    ```
4.  **Запустить скрипт:**
    ```bash
    sudo ./linux_en.sh # или sudo ./linux_ru.sh для русской версии
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
2.  **Сборка и запуск:** Из корня проекта откройте терминал и выполните:
    ```bash
    docker-compose up --build -d
    ```
    *   Чтобы также запустить Nginx в качестве обратного прокси внутри Docker:
        ```bash
        docker-compose --profile with-nginx up --build -d
        ```
3.  **Доступ:**
    *   Без Nginx: `http://localhost:5000`
    *   С Nginx: `http://localhost` (Docker сопоставит порт 80 контейнера с портом 80 вашего хоста).

### Аутентификация (Необязательно)

Web Panel поддерживает дополнительную аутентификацию пользователя для защиты доступа.

*   Чтобы включить аутентификацию пользователя для веб-панели:
    1.  Запустите `python create_admin.py` из корня проекта. Следуйте инструкциям для установки имени пользователя и пароля. Это создаст файл `data/admin.json`, содержащий хэшированные учетные данные.
    2.  Установите переменную окружения `ENABLE_AUTH=true`.
        *   **Для Docker:** Установите `ENABLE_AUTH=true` в разделе `environment` службы `webpanel` в `docker-compose.yml`.
        *   **Для службы Systemd Linux:** Отредактируйте файл `webpanel.service` (например, `sudo nano /etc/systemd/system/webpanel.service`) и добавьте `Environment="ENABLE_AUTH=true"` в раздел `[Service]`, затем выполните `sudo systemctl daemon-reload && sudo systemctl restart webpanel`.
        *   **Для службы Windows/Прямого запуска:** Установите переменную окружения перед запуском приложения, например, `set ENABLE_AUTH=true` в командной строке или добавьте ее в скрипт `start_webpanel.bat`.
*   Если аутентификация включена, пользователям потребуется войти в систему для доступа к панели. Имя пользователя и пароль по умолчанию — `admin` и `admin123`, если они не были явно заданы через `create_admin.py` или переменные окружения, но настоятельно рекомендуется использовать `create_admin.py` для безопасности.

### Структура проекта

*   `app.py`: Основное Flask-приложение, обрабатывающее маршруты API и веб-логику.
*   `config.py`: Настройки конфигурации для Flask-приложения, включая разрешенные расширения файлов, флаги аутентификации и параметры сервера.
*   `requirements.txt`: Зависимости Python, необходимые для проекта.
*   `create_admin.py`: Вспомогательный скрипт для создания и управления учетными данными администратора для аутентификации.
*   `templates/`: Содержит HTML-шаблоны для веб-интерфейса (например, `index.html`).
*   `uploads/`: Каталог для загруженных файлов (создается автоматически).
*   `logs/`: Каталог для хранения логов выполнения процессов (создается автоматически).
*   `win_en.bat`: Консолидированный скрипт установки и запуска для Windows (английская версия).
*   `win_ru.bat`: Консолидированный скрипт установки и запуска для Windows (русская версия).
*   `linux_en.sh`: Консолидированный скрипт установки и запуска для Linux (английская версия).
*   `linux_ru.sh`: Консолидированный скрипт установки и запуска для Linux (русская версия).
*   `Dockerfile`: Инструкции по сборке Docker-образа контейнера приложения.
*   `docker-compose.yml`: Конфигурация Docker Compose для настройки нескольких контейнеров, включая дополнительный обратный прокси Nginx.
*   `webpanel.service`: Файл службы Systemd для управления приложением как фоновой службой в Linux.
*   `nginx.conf`: Пример конфигурации Nginx для развертывания в Docker.
*   `static/`: Заполнитель для статических файлов (CSS, JavaScript, изображения).
*   `data/`: Каталог для хранения данных приложения, таких как `admin.json` для аутентификации (создается автоматически).
*   `test.py`: Простой пример Python-скрипта для тестирования.