@echo off
cd /d "%~dp0"

if not exist "build\web\index.html" (
  echo Build web belum ada.
  echo Jalankan dulu: flutter build web --release
  pause
  exit /b 1
)

set "NODE_EXE=node"
if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"

start "KasbonKu Server" cmd /k ""%NODE_EXE%" server.js"
timeout /t 2 >nul
start "" "http://localhost:8080"
