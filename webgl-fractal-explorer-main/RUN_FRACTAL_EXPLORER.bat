@echo off
setlocal
title WebGL Fractal Explorer

:: 1. Navigate to the project directory (quoted for paths with spaces)
cd /d "%~dp0"

echo ========================================================
echo             WebGL Fractal Explorer Launcher
echo ========================================================
echo.

:: 2. Verify index.html exists
if not exist "%~dp0index.html" (
    echo [ERROR] index.html not found in:
    echo "%~dp0"
    echo Please make sure RUN_FRACTAL_EXPLORER.bat is in the project root directory.
    echo.
    pause
    exit /b 1
)

:: 3. Detect available runtime (Python, py launcher, or Node.js)
set "RUNNER="
set "RUNNER_NAME="

python --version >nul 2>&1
if not errorlevel 1 (
    set "RUNNER=PYTHON"
    set "RUNNER_NAME=Python"
    goto :runtime_checked
)

py --version >nul 2>&1
if not errorlevel 1 (
    set "RUNNER=PY"
    set "RUNNER_NAME=Python (py launcher)"
    goto :runtime_checked
)

node -v >nul 2>&1
if not errorlevel 1 (
    set "RUNNER=NODE"
    set "RUNNER_NAME=Node.js"
    goto :runtime_checked
)

echo [ERROR] No supported runtime found on PATH!
echo Neither Python nor Node.js could be detected on your computer.
echo.
echo To run WebGL Fractal Explorer, please install either:
echo   1. Python 3: https://www.python.org/downloads/
echo      (Make sure to check "Add python.exe to PATH" during installation)
echo   2. Node.js:  https://nodejs.org/
echo.
pause
exit /b 1

:runtime_checked
echo [OK] Runtime detected: %RUNNER_NAME%
echo [INFO] Dependencies: Zero external packages required (static HTML5/WebGL).

:: 4. Check if an instance of Fractal Explorer is already active on port 8000
set "PORT=8000"
if "%RUNNER%"=="PYTHON" (
    python -c "import urllib.request, sys; sys.exit(0 if 'WebGL Fractal Explorer' in urllib.request.urlopen('http://127.0.0.1:8000/', timeout=1).read().decode('utf-8', 'ignore') else 2)" >nul 2>&1
) else if "%RUNNER%"=="PY" (
    py -c "import urllib.request, sys; sys.exit(0 if 'WebGL Fractal Explorer' in urllib.request.urlopen('http://127.0.0.1:8000/', timeout=1).read().decode('utf-8', 'ignore') else 2)" >nul 2>&1
) else if "%RUNNER%"=="NODE" (
    node -e "fetch('http://127.0.0.1:8000/').then(r=>r.text()).then(t=>process.exit(t.includes('WebGL Fractal Explorer')?0:2)).catch(()=>process.exit(1))" >nul 2>&1
)

if not errorlevel 1 (
    echo.
    echo [INFO] Fractal Explorer server is ALREADY running at http://localhost:8000
    echo Opening application in your default web browser...
    start "" "http://localhost:8000"
    echo.
    echo Server is already active in another window.
    echo You can now use the application in your browser.
    pause
    exit /b 0
)

:: Check if port 8000 is occupied by a different program
if "%RUNNER%"=="PYTHON" (
    python -c "import socket, sys; s = socket.socket(); sys.exit(0 if s.connect_ex(('127.0.0.1', 8000)) == 0 else 1)" >nul 2>&1
) else if "%RUNNER%"=="PY" (
    py -c "import socket, sys; s = socket.socket(); sys.exit(0 if s.connect_ex(('127.0.0.1', 8000)) == 0 else 1)" >nul 2>&1
) else if "%RUNNER%"=="NODE" (
    node -e "const s=require('net').connect(8000,'127.0.0.1',()=>{s.destroy();process.exit(0)}).on('error',()=>process.exit(1))" >nul 2>&1
)

if not errorlevel 1 (
    echo [NOTICE] Port 8000 is currently in use by another program.
    echo Switching to port 8080...
    set "PORT=8080"
)

set "URL=http://localhost:%PORT%"
echo [INFO] Server address: %URL%
echo.

:: 5. Launch browser opener helper in background
if "%RUNNER%"=="PYTHON" (
    start /B "" python -c "import time, webbrowser; time.sleep(0.4); webbrowser.open('http://localhost:' + str(%PORT%))"
) else if "%RUNNER%"=="PY" (
    start /B "" py -c "import time, webbrowser; time.sleep(0.4); webbrowser.open('http://localhost:' + str(%PORT%))"
) else if "%RUNNER%"=="NODE" (
    start /B "" node -e "setTimeout(()=>{const {exec}=require('child_process');exec('start http://localhost:%PORT%')}, 400)"
)

echo --------------------------------------------------------
echo  Starting Fractal Explorer server on port %PORT%...
echo  URL: %URL%
echo.
echo  Your default browser will open automatically.
echo  Keep this console window open while using the application.
echo  To stop the server, press Ctrl+C in this window.
echo --------------------------------------------------------
echo.

:: 6. Launch static server using detected runtime
if "%RUNNER%"=="PYTHON" (
    python -m http.server %PORT% --bind 127.0.0.1
) else if "%RUNNER%"=="PY" (
    py -m http.server %PORT% --bind 127.0.0.1
) else if "%RUNNER%"=="NODE" (
    node -e "const http=require('http'),fs=require('fs'),path=require('path');const m={'.html':'text/html','.js':'application/javascript','.css':'text/css','.png':'image/png','.svg':'image/svg+xml','.json':'application/json'};http.createServer((q,s)=>{let p=q.url.split('?')[0];if(p==='/'||!p)p='/index.html';let f=path.join(process.cwd(),p);if(!fs.existsSync(f)){s.writeHead(404);s.end('Not Found');return;}s.writeHead(200,{'Content-Type':m[path.extname(f)]||'application/octet-stream'});fs.createReadStream(f).pipe(s);}).listen(%PORT%,'127.0.0.1');"
)

if errorlevel 1 (
    echo.
    echo [ERROR] Web server stopped unexpectedly.
    pause
    exit /b 1
)

pause
