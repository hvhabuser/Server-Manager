@echo off
echo Installing Web Panel Server Control...

echo Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed! Please install Python 3.8+ first.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo Creating virtual environment...
python -m venv venv
if %errorlevel% neq 0 (
    echo Failed to create virtual environment!
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo Installing dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo Failed to install dependencies!
    pause
    exit /b 1
)

echo Creating startup script...
echo @echo off > start_webpanel.bat
echo cd /d "%~dp0" >> start_webpanel.bat
echo call venv\Scripts\activate.bat >> start_webpanel.bat
echo python app.py >> start_webpanel.bat
echo pause >> start_webpanel.bat

echo Creating service installer...
echo net session ^>nul 2^>^&1 > install_service.bat
echo if %%errorLevel%% == 0 ( >> install_service.bat
echo     echo Installing as Windows Service... >> install_service.bat
echo     sc create WebPanel binpath= "cmd /c cd /d \"%~dp0\" ^&^& venv\Scripts\python.exe app.py" >> install_service.bat
echo     sc config WebPanel start= auto >> install_service.bat
echo     sc start WebPanel >> install_service.bat
echo     echo Service installed and started! >> install_service.bat
echo ^) else ( >> install_service.bat
echo     echo Please run as Administrator to install as service! >> install_service.bat
echo ^) >> install_service.bat
echo pause >> install_service.bat

echo.
echo Installation completed!
echo.
echo To start the panel:
echo   1. Run start_webpanel.bat
echo   2. Open http://localhost:5000 in browser
echo.
echo To install as Windows service:
echo   1. Run install_service.bat as Administrator
echo.
echo Press any key to start the panel now...
pause >nul
start_webpanel.bat 