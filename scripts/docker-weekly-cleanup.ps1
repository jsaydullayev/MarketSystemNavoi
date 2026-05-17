# =====================================================================
# Docker weekly cleanup — prune unused stuff + shrink VHDX
# Run as Administrator (required for Optimize-VHD)
#
# To schedule weekly:
#   1. Open Task Scheduler
#   2. Create Basic Task -> "Docker Weekly Cleanup"
#   3. Trigger: Weekly, e.g. Monday 03:00
#   4. Action: Start a program
#      Program: powershell.exe
#      Arguments: -ExecutionPolicy Bypass -File "C:\Users\joo\Desktop\MarketSystem\scripts\docker-weekly-cleanup.ps1"
#      Check "Run with highest privileges"
# =====================================================================

$ErrorActionPreference = "Continue"
$VhdxPaths = @(
    "C:\Users\joo\AppData\Local\Docker\wsl\main\ext4.vhdx",
    "C:\Users\joo\AppData\Local\Docker\wsl\data\ext4.vhdx",
    "C:\Users\joo\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
)

$LogFile = "$env:USERPROFILE\Desktop\MarketSystem\scripts\docker-cleanup.log"
function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Log "=== Weekly Docker Cleanup Started ==="

# ---- Admin check ----
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Log "[ERROR] Not running as Administrator. Optimize-VHD will be skipped."
}

# ---- Snapshot sizes BEFORE ----
$BeforeTotal = 0
foreach ($p in $VhdxPaths) {
    if (Test-Path $p) {
        $sz = [math]::Round((Get-Item $p).Length / 1GB, 2)
        $BeforeTotal += $sz
        Log "Before: $p = $sz GB"
    }
}

# ---- Prune Docker if daemon is up ----
$DockerOk = $false
try {
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $DockerOk = $true }
} catch {}

if ($DockerOk) {
    Log "Pruning Docker system (containers, networks, dangling images)..."
    docker container prune -f
    docker image prune -a -f
    docker network prune -f
    docker volume prune -f
    docker builder prune -a -f
    Log "Docker prune finished."
} else {
    Log "Docker daemon not running. Skipping prune (VHDX shrink will still run)."
}

# ---- Stop Docker Desktop + WSL ----
Log "Stopping Docker Desktop and WSL..."
Get-Process "Docker Desktop","com.docker.backend","com.docker.build","com.docker.dev-envs","com.docker.extensions" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
wsl --shutdown
Start-Sleep -Seconds 5

# ---- Shrink each VHDX ----
if ($IsAdmin) {
    $HyperVAvailable = $false
    try { Import-Module Hyper-V -ErrorAction Stop; $HyperVAvailable = $true } catch {}

    foreach ($p in $VhdxPaths) {
        if (-not (Test-Path $p)) { continue }
        Log "Shrinking $p ..."
        try {
            if ($HyperVAvailable) {
                Optimize-VHD -Path $p -Mode Full
            } else {
                $script = "select vdisk file=`"$p`"`r`nattach vdisk readonly`r`ncompact vdisk`r`ndetach vdisk`r`n"
                $tmp = [System.IO.Path]::GetTempFileName()
                $script | Out-File -FilePath $tmp -Encoding ASCII
                diskpart /s $tmp | Out-Null
                Remove-Item $tmp -Force
            }
            Log "  Shrink OK"
        } catch {
            Log "  Shrink FAILED: $_"
        }
    }
}

# ---- Snapshot sizes AFTER ----
$AfterTotal = 0
foreach ($p in $VhdxPaths) {
    if (Test-Path $p) {
        $sz = [math]::Round((Get-Item $p).Length / 1GB, 2)
        $AfterTotal += $sz
        Log "After: $p = $sz GB"
    }
}

$Saved = [math]::Round($BeforeTotal - $AfterTotal, 2)
Log "=== Cleanup Done. Total before: $BeforeTotal GB, after: $AfterTotal GB, freed: $Saved GB ==="
