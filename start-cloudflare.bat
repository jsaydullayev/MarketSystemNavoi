@echo off
chcp 65001 >nul
echo ========================================
echo 🌐 CloudFlare Tunnel Deploy
echo ========================================
echo.

REM ==========================================
REM 1. QADAM: PostgreSQL ni ishga tushirish
REM ==========================================
echo [1/4] PostgreSQL ni tekshiramiz...
docker ps | findstr "market-postgres" >nul
if %errorlevel%==0 (
    echo ✅ PostgreSQL allaqachon ishlayapti
) else (
    echo 📦 PostgreSQL ishga tushirilmoqda...
    docker run --name market-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=MarketSystemDB -p 5433:5432 -d postgres:16
    if %errorlevel%==0 (
        echo ✅ PostgreSQL muvaffaqiyatli ishga tushdi
    ) else (
        echo ❌ PostgreSQL ishga tushirishda xatolik
        echo Docker Desktop ishlayaptimi? Tekshiring!
        pause
        exit /b 1
    )
)

echo.
timeout /t 3 /nobreak >nul

REM ==========================================
REM 2. QADAM: Eski backend jarayonlarini to'xtatish
REM ==========================================
echo [2/4] Eski backend jarayonlari to'xtatilmoqda...
for /f "tokens=2" %%a in ('tasklist ^| findstr "dotnet.exe"') do taskkill /F /PID %%a >nul 2>&1
echo ✅ Eski jarayonlar to'xtatildi

echo.
timeout /t 2 /nobreak >nul

REM ==========================================
REM 3. QADAM: Backend API ni ishga tushirish
REM ==========================================
echo [3/4] Backend API ishga tushirilmoqda...
start "MarketSystem API" cmd /k "cd /d \"%~dp0MarketSystem.API\" && dotnet run"

echo ⏳ Backend ishga tushishi kutilmoqda (15 soniya)...
timeout /t 15 /nobreak >nul

echo ✅ Backend ishga tushdi deb taxmin qilinyapti
echo    Port: http://localhost:5137
echo    Swagger: http://localhost:5137/swagger

echo.
timeout /t 3 /nobreak >nul

REM ==========================================
REM 4. QADAM: CloudFlare Tunnel (cloudflared)
REM ==========================================
echo [4/4] cloudflared tekshirilmoqda...

where cloudflared >nul 2>&1
if %errorlevel%==0 (
    echo ✅ cloudflared topildi
    echo 🌐 Tunnel ishga tushirilmoqda...
    start "CloudFlare Tunnel" cmd /k "cloudflared tunnel --url http://localhost:5137"
) else (
    echo ❌ cloudflared topilmadi!
    echo.
    echo ⚠️ cloudflared ni o'rnatish uchun:
    echo    1. https://github.com/cloudflare/cloudflared/releases ga boring
    echo    2. Windows amd64 versiyasini yuklang
    echo    3. Arxivni oching va cloudflared.exe ni PATH ga qo'shing
    echo    4. Yoki shu papkaga nusxalang
    echo.
    echo 💡 Yoki ngrok o'rnatish osonroq:
    echo    https://ngrok.com/download
    echo.

    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ BARCHASI TAYYOR!
echo ========================================
echo.
echo 📦 PostgreSQL: http://localhost:5433
echo 🚀 Backend:    http://localhost:5137
echo 🌐 Tunnel:     Yangi terminalda ko'ring (URL nusqa oling)
echo.
echo 📚 Swagger: http://localhost:5137/swagger
echo.
echo ⚠️ TUNNEL URL ni frontend developerga yuboring!
echo.
echo ========================================
echo.
pause
