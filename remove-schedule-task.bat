@echo off
chcp 936
setlocal enabledelayedexpansion
:: SakuraFrp 定时重启任务删除脚本
:: 以管理员身份运行此脚本

echo.
echo ========================================
echo   SakuraFrp 定时任务删除工具
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

:: 设置默认任务名称
set "DEFAULT_TASK_NAME=SakuraFrp定时重启"

:: 显示当前系统中的 Sakura 相关任务
echo [当前系统中的 Sakura 相关任务：]
schtasks /query /fo table ^| findstr /i Sakura

if !errorlevel! neq 0 (
    echo.
    echo [提示] 系统中未找到包含 "Sakura" 的任务
)

echo.
echo 请输入要删除的任务名称 (默认: !DEFAULT_TASK_NAME!):
set /p USER_TASK_NAME=

if "!USER_TASK_NAME!"=="" (
    set "TASK_NAME=!DEFAULT_TASK_NAME!"
) else (
    set "TASK_NAME=!USER_TASK_NAME!"
)

:: 确认删除操作
echo.
echo [警告] 您即将删除计划任务：
echo   任务名称：!TASK_NAME!
echo.
echo 此操作将永久删除该任务，且无法恢复。
echo 是否确认删除？(Y/N)
set /p CONFIRM_DELETE=

if /i not "!CONFIRM_DELETE!"=="Y" (
    echo 操作已取消。
    pause
    exit /b 0
)

:: 检查任务是否存在
echo.
echo [正在检查任务是否存在...]
schtasks /query /tn "!TASK_NAME!" >nul 2>&1

if !errorlevel! neq 0 (
    echo [错误] 未找到任务 "!TASK_NAME!"
    echo.
    echo 可能的原因：
    echo 1. 任务名称输入错误
    echo 2. 任务已被删除
    echo 3. 任务名称包含特殊字符
    pause
    exit /b 1
)

echo [成功] 找到任务 "!TASK_NAME!"

:: 显示任务详情
echo.
echo [任务详情：]
schtasks /query /tn "!TASK_NAME!" /fo list ^| findstr "Task Name Task To Run Next Run Time Status"

:: 执行删除操作
echo.
echo [正在删除任务...]
schtasks /delete /tn "!TASK_NAME!" /f

if !errorlevel! equ 0 (
    echo.
    echo [成功] 任务删除成功！
    echo.
    echo 任务 "!TASK_NAME!" 已被永久删除。
    echo 如果需要重新创建，请运行 setup-schedule-task.bat
) else (
    echo.
    echo [错误] 任务删除失败！
    echo 错误代码：!errorlevel!
    echo.
    echo 可能的原因：
    echo 1. 权限不足
    echo 2. 任务正在被运行
    echo 3. 系统错误
    pause
    exit /b 1
)

:: 显示剩余任务
echo.
echo [当前剩余任务：]
schtasks /query /fo table ^| findstr /i Sakura

echo.
echo 按任意键退出...
pause >nul