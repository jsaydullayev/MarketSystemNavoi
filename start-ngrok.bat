@echo off
chcp 65001 >nul
echo ========================================
echo 🚀 Market System - ngrok Deploy
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
    docker run --name market-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=MarketSystemDB -p 3030:5432 -d postgres:16
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
REM 4. QADAM: ngrok ni ishga tushirish
REM ==========================================
echo [4/4] ngrok ishga tushirilmoqda...

REM ngrok.exe mavjudligini tekshirish
where ngrok >nul 2>&1
if %errorlevel%==0 (
    echo ✅ ngrok topildi
    start "ngrok" cmd /k "ngrok http 5137"
) else (
    echo ❌ ngrok topilmadi!
    echo.
    echo ⚠️ ngrok ni o'rnatish uchun:
    echo    1. https://ngrok.com/download ga boring
    echo    2. Windows versiyasini yuklang
    echo    3. Arxivni oching va ngrok.exe ni PATH ga qo'shing
    echo    4. Yoki shu papkaga ngrok.exe nusxalang
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ BARCHASI TAYYOR!
echo ========================================
echo.
echo 📦 PostgreSQL: http://localhost:3030
echo 🚀 Backend:    http://localhost:5137
echo 🌐 ngrok:      Yangi terminalda ko'ring (URL nusqa oling)
echo.
echo 📚 Swagger: http://localhost:5137/swagger
echo.
echo ⚠️ NGROK URL ni frontend developerga yuboring!
echo    Masalan: https://abc-123.ngrok-free.app
echo.
echo ========================================
echo.
echo 💡 Maslahat: ngrok terminalini yopmang!
echo    Agar yopilsangiz, frontend developer ulana olmaydi
echo.
echo 🛑 Hammasini to'xtatish uchun: Ctrl+C yoki shu terminalni yoping
echo ========================================
echo.

REM Backend health check
echo Backend health check...
timeout /t 5 /nobreak >nul
curl -s http://localhost:5137/health >nul 2>&1
if %errorlevel%==0 (
    echo ✅ Backend sog'lom! (Health check passed)
) else (
    echo ⚠️ Backendga ulanib bo'lmadi
    echo    Lekin davom etyapti...
)

echo.
pause
