@echo off
chcp 65001 >nul
title 五子棋 - 联机服务器

echo.
echo   ╔══════════════════════════════════╗
echo   ║     🎮  五子棋 联机服务器        ║
echo   ╚══════════════════════════════════╝
echo.

:: 检查 Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo   ❌ 未找到 Node.js，请先安装 Node.js
    pause
    exit /b 1
)

:: 检查 cloudflared
if not exist "%~dp0cloudflared.exe" (
    echo   📥 首次运行，下载 Cloudflare Tunnel...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile '%~dp0cloudflared.exe'"
    if %errorlevel% neq 0 (
        echo   ❌ 下载失败，请检查网络
        pause
        exit /b 1
    )
    echo   ✅ 下载完成
)

:: 杀掉旧进程
echo   🔄 清理旧进程...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING" 2^>nul') do (
    taskkill /f /pid %%a >nul 2>nul
)

:: 启动 Node.js 服务器（后台）
echo   🚀 启动中继服务器...
start /min "GomokuServer" node "%~dp0server.js" 3000

:: 等待服务器就绪
timeout /t 2 /nobreak >nul

:: 启动 Cloudflare 隧道
echo   🌐 启动公网隧道...
echo.
echo   ═══════════════════════════════════
echo   公网地址（发给好友）：
echo.

"%~dp0cloudflared.exe" tunnel --url http://localhost:3000 2>&1 | powershell -Command "
$input | ForEach-Object {
    Write-Output $_
    if ($_ -match 'https://[a-z0-9-]+\.trycloudflare\.com') {
        $url = $matches[0]
        Write-Host ''
        Write-Host '  ✅ 隧道已建立！' -ForegroundColor Green
        Write-Host '  🔗 游戏地址: ' -NoNewline
        Write-Host $url -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  1. 你和好友都打开这个网址' -ForegroundColor Yellow
        Write-Host '  2. 你点【创建房间】获得房间号' -ForegroundColor Yellow
        Write-Host '  3. 好友输入房间号点【加入】' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  按 Ctrl+C 停止服务器' -ForegroundColor Gray
        Write-Host ''
        Start-Process $url
    }
}
"

echo.
echo   服务器已停止。
pause
