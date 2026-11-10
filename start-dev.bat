@echo off
setlocal
set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%backend"
set "FRONTEND_DIR=%ROOT%frontend"

if not exist "%ROOT%backend\.env" (
  copy /Y "%BACKEND_DIR%\.env.example" "%BACKEND_DIR%\.env" >nul
  echo [GenX] Created backend\.env. Add GNANI_API_KEY for audio transcription and GROQ_API_KEY for LLM mode.
)

if not exist "%BACKEND_DIR%\.venv\Scripts\python.exe" (
  echo [GenX] Creating backend virtual environment...
  py -3 -m venv "%BACKEND_DIR%\.venv"
  if errorlevel 1 exit /b 1
  "%BACKEND_DIR%\.venv\Scripts\python.exe" -m pip install -r "%BACKEND_DIR%\requirements.txt"
  if errorlevel 1 exit /b 1
)

if not exist "%FRONTEND_DIR%\node_modules" (
  echo [GenX] Installing frontend packages...
  call npm --prefix "%FRONTEND_DIR%" install
  if errorlevel 1 exit /b 1
)

start "GenX Backend" cmd /k "cd /d ""%BACKEND_DIR%"" && ""%BACKEND_DIR%\.venv\Scripts\python.exe"" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"
start "GenX Frontend" cmd /k "cd /d ""%FRONTEND_DIR%"" && npm run dev"

echo [GenX] Backend:  http://127.0.0.1:8000
echo [GenX] Frontend: http://127.0.0.1:3000
endlocal
