@echo off
chcp 65001 >nul
echo ========================================
echo 🛑 Market System - To'xtatish
echo ========================================
echo.

REM Backend jarayonlarini to'xtatish
echo [1/3] Backend jarayonlari to'xtatilmoqda...
taskkill /F /IM dotnet.exe >nul 2>&1
if %errorlevel%==0 (
    echo ✅ Backend to'xtatildi
) else (
    echo ℹ️ Backend ishlamayapti
)

REM ngrok jarayonlarini to'xtatish
echo [2/3] ngrok to'xtatilmoqda...
taskkill /F /IM ngrok.exe >nul 2>&1
if %errorlevel%==0 (
    echo ✅ ngrok to'xtatildi
) else (
    echo ℹ️ ngrok ishlamayapti
)

REM PostgreSQL container (ixtiyoriy - to'xtatmaslik kerak!)
echo [3/3] PostgreSQL...
docker ps | findstr "market-postgres" >nul
if %errorlevel%==0 (
    echo ℹ️ PostgreSQL ishlayapti (to'xtatilmadi)
    echo    Agar to'xtatmoqchi bo'lsangiz:
    echo    docker stop market-postgres
) else (
    echo ℹ️ PostgreSQL ishlamayapti
)

echo.
echo ========================================
echo ✅ BARCHASI TO'XTATILDI
echo ========================================
echo.
pause
