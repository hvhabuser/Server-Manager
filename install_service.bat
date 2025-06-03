net session >nul 2>&1 
if %errorLevel% == 0 ( 
    echo Installing as Windows Service... 
    sc create WebPanel binpath= "cmd /c cd /d \"C:\Users\2025\Desktop\code\_python\webpanel\\" ^&^& venv\Scripts\python.exe app.py" 
    sc config WebPanel start= auto 
    sc start WebPanel 
    echo Service installed and started! 
) else ( 
    echo Please run as Administrator to install as service! 
) 
pause 
