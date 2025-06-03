@echo off
setlocal

chcp 65001 >nul 2>&1
echo Установка и запуск Web Panel Server Control...

echo.
echo --- 1. Проверка установки Python ---
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ОШИБКА: Python не установлен или не найден в PATH!
    echo Пожалуйста, установите Python 3.8+ с сайта https://www.python.org/downloads/
    echo Скрипт будет завершен.
    pause
    exit /b 1
)
echo Python найден.

echo.
echo --- 2. Создание или активация виртуального окружения ---
if not exist venv (
    echo Создание виртуального окружения...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ОШИБКА: Не удалось создать виртуальное окружение!
        echo Скрипт будет завершен.
        pause
        exit /b 1
    )
) else (
    echo Виртуальное окружение уже существует. Активация...
)
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ОШИБКА: Не удалось активировать виртуальное окружение!
    echo Скрипт будет завершен.
    pause
    exit /b 1
)
echo Виртуальное окружение активировано.

echo.
echo --- 3. Установка зависимостей ---
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ПРЕДУПРЕЖДЕНИЕ: Не удалось установить все зависимости. Web Panel может работать некорректно.
    echo Проверьте requirements.txt и подключение к интернету.
    pause
    goto end_script
)
echo Зависимости установлены.

echo.
echo --- 4. Запуск Web Panel ---
echo Хотите установить Web Panel как службу Windows?
echo (Это требует прав администратора и будет запускать панель автоматически при загрузке)
set /p SERVICE_INSTALL="Введите 'y' для установки как службы, или любую другую клавишу для прямого запуска: "

if /i "%SERVICE_INSTALL%"=="y" (
    echo.
    echo Попытка установки как службы Windows...
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Запуск с правами администратора. Продолжение установки службы.
        sc stop WebPanel >nul 2>&1
        sc delete WebPanel >nul 2>&1
        sc create WebPanel binpath= "cmd /c cd /d \"%cd%\" ^&^& venv\Scripts\python.exe app.py" start= auto
        if %errorlevel% neq 0 (
            echo ОШИБКА: Не удалось создать службу WebPanel!
            echo Проверьте, существует ли служба уже или есть ли у вас необходимые разрешения.
            pause
            goto end_script
        )
        sc start WebPanel
        if %errorlevel% neq 0 (
            echo ПРЕДУПРЕЖДЕНИЕ: Служба создана, но не удалось запустить немедленно.
            echo Возможно, вам потребуется запустить ее вручную через "Службы" (services.msc).
            pause
            goto end_script
        )
        echo Служба Web Panel установлена и запущена успешно!
        echo Вы можете закрыть это окно.
        echo Доступ к Web Panel по адресу http://localhost:5000
    ) else (
        echo ОШИБКА: Недостаточно прав. Пожалуйста, запустите этот скрипт от имени администратора для установки службы.
        echo Web Panel будет запущен напрямую без установки службы.
        pause
        goto run_directly
    )
) else (
    :run_directly
    echo.
    echo Запуск Web Panel напрямую...
    echo (Это окно должно оставаться открытым для работы Web Panel)
    echo Доступ к Web Panel по адресу http://localhost:5000
    echo Нажмите Ctrl+C, чтобы остановить панель.
    pause
    python app.py
    if %errorlevel% neq 0 (
        echo ОШИБКА: Web Panel завершил работу с ошибкой!
        pause
    )
)

:end_script
echo.
echo Процесс установки и запуска завершен.
echo.
echo Для прямого запуска: Чтобы остановить панель, закройте это окно (или Ctrl+C).
echo Для службы: Для управления службой, найдите "Службы" в Windows и найдите "WebPanel".
echo.
endlocal
pause 