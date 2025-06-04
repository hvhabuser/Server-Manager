@echo off
echo ========================================
echo   WebPanel Script Manager
echo   Starting setup and installation...
echo ========================================

:: Проверяем наличие Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://python.org
    pause
    exit /b 1
)

:: Создаем виртуальное окружение если его нет
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

:: Активируем виртуальное окружение
echo Activating virtual environment...
call venv\Scripts\activate.bat

:: Обновляем pip
echo Updating pip...
python -m pip install --upgrade pip

:: Устанавливаем зависимости
echo Installing dependencies...
pip install -r requirements.txt

:: Создаем необходимые папки
if not exist "uploads" mkdir uploads
if not exist "projects" mkdir projects
if not exist "logs" mkdir logs
if not exist "static" mkdir static
if not exist "static\css" mkdir static\css
if not exist "static\js" mkdir static\js
if not exist "templates" mkdir templates

echo.
echo ========================================
echo   Starting WebPanel Server...
echo   Open your browser and go to:
echo   http://localhost:5000
echo ========================================
echo.

:: Запускаем сервер
python app.py

pause 