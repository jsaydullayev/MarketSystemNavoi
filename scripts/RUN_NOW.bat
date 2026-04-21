@echo off
echo ========================================
echo Deploy ishga tushirilmoqda...
echo ========================================

REM 1. PostgreSQL
echo [1/3] PostgreSQL ishga tushirilmoqda...
docker ps | findstr "market-postgres" >nul
if %errorlevel%==0 (
    echo ✅ PostgreSQL ishlayapti
) else (
    docker run --name market-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=MarketSystemDB -p 5433:5432 -d postgres:16
    echo ✅ PostgreSQL ishga tushdi
)

timeout /t 3 /nobreak >nul

REM 2. Backend
echo [2/3] Backend ishga tushirilmoqda...
cd /d "%~dp0MarketSystem.API"
start "Backend API" cmd /k "dotnet run"

timeout /t 15 /nobreak >nul

REM 3. ngrok
echo [3/3] ngrok ishga tushirilmoqda...
start "ngrok" cmd /k "ngrok http 5137"

echo.
echo ========================================
echo ✅ BARCHA TAYYOR!
echo ========================================
echo 📦 PostgreSQL: http://localhost:5433
echo 🚀 Backend:    http://localhost:5137
echo 🌐 ngrok:      Yangi terminalda ko'ring
echo.
echo ⚠️ ngrok URL ni nusqa oling!
echo ========================================
pause
