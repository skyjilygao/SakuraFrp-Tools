@echo off
chcp 936
setlocal enabledelayedexpansion
:: SakuraFrp 定时重启任务配置脚本
:: 以管理员身份运行此脚本

echo.
echo ========================================
echo   SakuraFrp 定时重启任务配置工具
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo [错误] 请以管理员身份运行此脚本！
    echo.
    echo 操作步骤：
    echo 1. 右键点击此脚本文件
    echo 2. 选择"以管理员身份运行"
    pause
    exit /b 1
)

:: 获取当前脚本路径
set "SCRIPT_PATH=%~dp0RestartSakura.bat"

:: 检查主脚本是否存在
if not exist "!SCRIPT_PATH!" (
    echo [错误] 找不到 RestartSakura.bat 文件！
    echo 请确保本文件与 RestartSakura.bat 在同一目录下。
    pause
    exit /b 1
)

echo [成功] 检测到 RestartSakura.bat 文件
echo [路径] !SCRIPT_PATH!
echo.

:: 设置默认参数
set "TASK_NAME=SakuraFrp定时重启"
set "TASK_TIME=03:00"
set "DESCRIPTION=每天定时重启 SakuraFrp 服务，确保连接稳定性"

:: 显示当前配置
echo [当前配置：]
echo   任务名称：!TASK_NAME!
echo   执行时间：!TASK_TIME!
echo   脚本路径：!SCRIPT_PATH!
echo.

:: 询问用户是否修改配置
echo 是否要修改配置？(Y/N，默认N)
set /p MODIFY_CONFIG=

if /i "!MODIFY_CONFIG!"=="Y" (
    echo.
    echo 请输入新的配置：
    
    echo 任务名称 (默认: !TASK_NAME!):
    set /p NEW_TASK_NAME=
    if not "!NEW_TASK_NAME!"=="" set "TASK_NAME=!NEW_TASK_NAME!"
    
    echo 执行时间，格式 HH:MM (默认: !TASK_TIME!):
    set /p NEW_TASK_TIME=
    if not "!NEW_TASK_TIME!"=="" set "TASK_TIME=!NEW_TASK_TIME!"
    
    echo.
    echo [更新后的配置：]
    echo   任务名称：!TASK_NAME!
    echo   执行时间：!TASK_TIME!
    echo   脚本路径：!SCRIPT_PATH!
    echo.
)

:: 确认创建任务
echo 即将创建计划任务，是否继续？(Y/N)
set /p CONFIRM=

if /i not "!CONFIRM!"=="Y" (
    echo 操作已取消。
    pause
    exit /b 0
)

:: 删除已存在的任务（如果存在）
echo.
echo [检查是否存在同名任务...]
schtasks /query /tn "!TASK_NAME!" >nul 2>&1
if !errorlevel! equ 0 (
    echo [警告] 发现已存在的任务 "!TASK_NAME!"，正在删除...
    schtasks /delete /tn "!TASK_NAME!" /f
    if !errorlevel! equ 0 (
        echo [成功] 旧任务删除成功
    ) else (
        echo [错误] 删除旧任务失败
    )
)

:: 创建新任务
echo.
echo [正在创建计划任务...]
schtasks /create ^
    /tn "!TASK_NAME!" ^
    /tr "\"!SCRIPT_PATH!\"" ^
    /sc daily ^
    /st !TASK_TIME! ^
    /ru SYSTEM ^
    /rl HIGHEST ^
    /f ^
    /np

if !errorlevel! equ 0 (
    echo.
    echo [成功] 任务创建成功！
    echo.
    echo [任务详情：]
    schtasks /query /tn "!TASK_NAME!" /fo list ^| findstr "Task Name Next Run Time Status"
) else (
    echo.
    echo [错误] 任务创建失败！
    echo 错误代码：!errorlevel!
    pause
    exit /b 1
)

:: 显示后续操作选项
echo.
echo ========================================
echo   任务配置完成！
echo ========================================
echo.
echo [后续操作：]
echo   1. 测试任务：
echo      schtasks /run /tn "!TASK_NAME!"
echo.
echo   2. 查看任务状态：
echo      schtasks /query /tn "!TASK_NAME!" /fo table
echo.
echo   3. 删除任务：
echo      schtasks /delete /tn "!TASK_NAME!" /f
echo.
echo   4. 查看日志文件：
echo      notepad "C:\ProgramData\SakuraFrpService\Logs\定时重启Sakura.log"
echo.
echo [详细说明请参考 README.md 文件]
echo.
echo 按任意键退出...
pause >nul