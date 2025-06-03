@echo off
setlocal

echo Installing and starting Web Panel Server Control...

echo.
echo --- 1. Checking Python installation ---
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not found in PATH!
    echo Please install Python 3.8+ from https://www.python.org/downloads/
    echo Script will exit.
    pause
    exit /b 1
)
echo Python found.

echo.
echo --- 2. Creating or activating virtual environment ---
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ERROR: Failed to create virtual environment!
        echo Script will exit.
        pause
        exit /b 1
    )
) else (
    echo Virtual environment already exists. Activating...
)
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment!
    echo Script will exit.
    pause
    exit /b 1
)
echo Virtual environment activated.

echo.
echo --- 3. Installing dependencies ---
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo WARNING: Failed to install all dependencies. Web Panel might not function correctly.
    echo Please check requirements.txt and your internet connection.
    pause
    goto end_script
)
echo Dependencies installed.

echo.
echo --- 4. Starting Web Panel ---
echo Do you want to install Web Panel as a Windows Service?
echo (This requires Administrator privileges and will start the panel automatically on boot)
set /p SERVICE_INSTALL="Type 'y' to install as service, or any other key to run directly: "

if /i "%SERVICE_INSTALL%"=="y" (
    echo.
    echo Attempting to install as Windows Service...
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Running with Administrator privileges. Proceeding with service installation.
        sc stop WebPanel >nul 2>&1
        sc delete WebPanel >nul 2>&1
        sc create WebPanel binpath= "cmd /c cd /d \"%cd%\" ^&^& venv\Scripts\python.exe app.py" start= auto
        if %errorlevel% neq 0 (
            echo ERROR: Failed to create WebPanel service!
            echo Please check if the service already exists or if you have necessary permissions.
            pause
            goto end_script
        )
        sc start WebPanel
        if %errorlevel% neq 0 (
            echo WARNING: Service created but failed to start immediately.
            echo You may need to start it manually from Windows Services (services.msc).
            pause
            goto end_script
        )
        echo Web Panel Service installed and started successfully!
        echo You can now close this window.
        echo Access Web Panel at http://localhost:5000
    ) else (
        echo ERROR: Insufficient privileges. Please run this script as Administrator to install the service.
        echo Web Panel will now start directly without service installation.
        pause
        goto run_directly
    )
) else (
    :run_directly
    echo.
    echo Starting Web Panel directly...
    echo (This window must remain open for Web Panel to run)
    echo Access Web Panel at http://localhost:5000
    echo Press Ctrl+C to stop the panel.
    pause
    python app.py
    if %errorlevel% neq 0 (
        echo ERROR: Web Panel exited with an error!
        pause
    )
)

:end_script
echo.
echo Installation and startup process finished.
echo.
echo For direct run: To stop the panel, close this window (or Ctrl+C).
echo For service: To manage the service, search for "Services" in Windows and find "WebPanel".
echo.
endlocal
pause 