@echo off
chcp 936 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   SakuraFrp 定时任务状态查看工具  
echo ========================================
echo.

set "TASK_NAME=SakuraFrp"
echo 要查看的任务名称(默认: !TASK_NAME!):
set /p USER_TASK_NAME=
if not "!USER_TASK_NAME!"=="" set "TASK_NAME=!USER_TASK_NAME!"

echo.
echo [正在检查任务状态...]

:: 先检查任务是否存在
schtasks /query /tn "!TASK_NAME!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [成功] 找到任务 "!TASK_NAME!"
    echo.
    echo [任务信息：]
    schtasks /query /tn "!TASK_NAME!" /fo list /v
) else (
    echo [警告] 未找到任务 "!TASK_NAME!"
    echo.
    echo 是否要查看所有相关任务？(Y/N)
    set /p SHOW_ALL=
    if /i "!SHOW_ALL!"=="Y" (
        echo.
        echo [所有包含 Sakura 的任务：]
        schtasks /query /fo table ^| findstr /i Sakura
    )
)

echo.
echo [快捷操作：]
echo   1. 立即运行任务：
echo      schtasks /run /tn "!TASK_NAME!"
echo.
echo   2. 启用/禁用任务：
echo      schtasks /change /tn "!TASK_NAME!" /enable
echo      schtasks /change /tn "!TASK_NAME!" /disable
echo.
echo   3. 查看最近日志：
echo      notepad "C:\ProgramData\SakuraFrpService\Logs\定时重启Sakura.log"
echo.
pause