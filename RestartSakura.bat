@echo off
chcp 936
setlocal enabledelayedexpansion

:: ========== 配置区 ==========
set "EXE_PATH=C:\Program Files\SakuraFrpLauncher\SakuraLauncher.exe"
set "LOG_DIR=C:\ProgramData\SakuraFrpService\Logs"
set "LOG_FILE=%LOG_DIR%\定时重启Sakura.log"
set "SLEEP_SECONDS=3"
:: ==========================

echo.
echo ========================================
echo   SakuraFrp 定时重启脚本
echo ========================================
echo.

:: 检查并创建日志目录
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
)

:: 记录开始时间
echo [%date% %time%] 开始执行 SakuraFrp 重启脚本... >> "%LOG_FILE%"

:: 检查 SakuraLauncher.exe 是否存在
if not exist "%EXE_PATH%" (
    echo [%date% %time%] 错误：找不到 SakuraLauncher.exe，路径：%EXE_PATH% >> "%LOG_FILE%"
    echo ❌ 错误：找不到 SakuraLauncher.exe
    echo 请确认 SakuraFrpLauncher 是否正确安装。
    pause
    exit /b 1
)

echo [%date% %time%] 检测到 SakuraLauncher.exe：%EXE_PATH% >> "%LOG_FILE%"
echo ✅ 检测到 SakuraLauncher.exe

:: 查找并关闭 SakuraLauncher.exe 进程
echo [%date% %time%] 正在查找 SakuraFrp 进程... >> "%LOG_FILE%"
echo 正在查找 SakuraFrp 进程...

tasklist ^| findstr /i "SakuraLauncher.exe" >nul
if %errorlevel% equ 0 (
    echo [%date% %time%] 发现正在运行的 SakuraLauncher.exe，准备关闭... >> "%LOG_FILE%"
    echo ✅ 发现正在运行的 SakuraLauncher.exe
    
    echo 正在关闭 SakuraLauncher.exe...
    taskkill /f /im "SakuraLauncher.exe" >nul 2>&1
    
    if %errorlevel% equ 0 (
        echo [%date% %time%] 成功关闭 SakuraLauncher.exe >> "%LOG_FILE%"
        echo ✅ 成功关闭 SakuraLauncher.exe
    ) else (
        echo [%date% %time%] 警告：关闭 SakuraLauncher.exe 失败 >> "%LOG_FILE%"
        echo ⚠️ 警告：关闭 SakuraLauncher.exe 失败
    )
    
    timeout /t %SLEEP_SECONDS% /nobreak >nul
) else (
    echo [%date% %time%] 未发现正在运行的 SakuraLauncher.exe >> "%LOG_FILE%"
    echo ℹ️ 未发现正在运行的 SakuraLauncher.exe
)

:: 清理相关进程（可选）
echo [%date% %time%] 检查相关进程... >> "%LOG_FILE%"
echo 检查相关进程...

:: 查找包含 "Sakura" 的进程（更广泛的匹配）
for /f "tokens=*" %%p in ('tasklist ^| findstr /i "Sakura"') do (
    set "process_line=%%p"
    echo [%date% %time%] 发现相关进程：!process_line! >> "%LOG_FILE%"
    echo ⚠️ 发现相关进程：!process_line!
)

:: 启动 SakuraLauncher.exe
echo [%date% %time%] 正在启动 SakuraLauncher.exe... >> "%LOG_FILE%"
echo 正在启动 SakuraLauncher.exe...

start "" "%EXE_PATH%"

if %errorlevel% equ 0 (
    echo [%date% %time%] SakuraLauncher.exe 启动命令执行成功 >> "%LOG_FILE%"
    echo ✅ SakuraLauncher.exe 启动命令执行成功
    
    timeout /t %SLEEP_SECONDS% /nobreak >nul
    
    :: 验证进程是否成功启动
    tasklist ^| findstr /i "SakuraLauncher.exe" >nul
    if %errorlevel% equ 0 (
        echo [%date% %time%] 验证成功：SakuraLauncher.exe 正在运行 >> "%LOG_FILE%"
        echo ✅ 验证成功：SakuraLauncher.exe 正在运行
    ) else (
        echo [%date% %time%] 警告：SakuraLauncher.exe 可能未成功启动 >> "%LOG_FILE%"
        echo ⚠️ 警告：SakuraLauncher.exe 可能未成功启动
    )
) else (
    echo [%date% %time%] 错误：SakuraLauncher.exe 启动失败 >> "%LOG_FILE%"
    echo ❌ 错误：SakuraLauncher.exe 启动失败
)

echo [%date% %time%] 脚本执行完成 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< >> "%LOG_FILE%"
echo.
echo ✅ 脚本执行完成！

:: 显示日志文件位置
echo.
echo 📋 日志文件位置：%LOG_FILE%
echo 💡 您可以通过以下命令查看详细日志：
echo    notepad "%LOG_FILE%"

:: 调试时取消下面注释，防止窗口闪退
:: pause
exit /b