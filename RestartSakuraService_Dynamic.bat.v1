@echo off
setlocal enabledelayedexpansion
:: 设置utf8编码，注意本脚本文件也是utf8编码
chcp 65001 >nul

:: 动态关键字配置：多个词用管道符分割。例如：aaa|bbb
set "KEYWORDS=An existing connection was forcibly closed by the remote host"
set "LOG_DIR=C:\ProgramData\SakuraFrpService\Logs"
set "LOG_FILE=%LOG_DIR%\RestartSakuraService.log"
:: 日志函数（每次调用都获取当前时间）
goto :main

:: ==============================
:: 函数: log
:: 用法: call :log "日志内容"
:: ==============================
:log
setlocal enabledelayedexpansion
for /f "skip=1" %%t in ('wmic os get LocalDateTime ^| findstr /r /v "^$"') do set "dt=%%t" & goto :got_time
:got_time
set "D=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%"
set "T=%dt:~8,2%:%dt:~10,2%:%dt:~12,2%.%dt:~15,3%"
set "TS=%D% %T%"
>>"%LOG_FILE%" echo [%TS%] %*
endlocal
goto :eof

:: ==============================
:: 函数: log_file_content
:: 作用: 读取指定文件的每一行，并调用 :log 写入带时间戳的日志
:: 用法: call :log_file_content "文件路径"
:: 示例: call :log_file_content "%temp_out%"
:: ==============================
:log_file_content
setlocal enabledelayedexpansion
set "input_file=%*"
echo "%input_file%"

if not exist "!input_file!" (
    call :log "[WARNING] File not found: !input_file!"
    endlocal
    goto :eof
)
for /f "usebackq delims=" %%i in ("!input_file!") do (
    set "line=%%i"
    call :log "!line!"
)

endlocal
goto :eof

:: ==============================
:: 函数: run_and_log
:: 作用: 执行传入的命令，捕获其全部输出（stdout+stderr），逐行带时间戳写入日志
:: 用法: call :run_and_log 命令 [参数...]
:: ==============================
:run_and_log
setlocal enabledelayedexpansion

:: 构造完整命令（%* 包含所有参数）
set "cmd=%*"

:: 生成临时文件
set "temp_out=%temp%\sc_output_%RANDOM%.txt"

:: 执行命令，重定向 stdout 和 stderr 到临时文件
%cmd% > "%temp_out%" 2>&1

:: 逐行读取并记录到日志
if exist "%temp_out%" (
    echo 命令: %cmd%
    call :log_file_content %temp_out%
    del "%temp_out%" >nul 2>&1
) else (
    call :log "[ERROR] Failed to create temp output file for command: %cmd%"
)

endlocal
goto :eof

:: ==============================
:: 函数: main
:: 作用: 主函数，执行重启逻辑
:: ==============================
:main
:: 创建日志目录
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: 获取当前日期
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "DT=%%a"
set "LOG_DATE=%DT:~0,8%"
set "LOG_FILE_PATH=C:\ProgramData\SakuraFrpService\Logs\SakuraFrpService.%LOG_DATE%.log"

call :log 脚本执行开始............................................
call :log 当前日期: %LOG_DATE%
call :log 日志文件: %LOG_FILE_PATH%

:: 检查日志文件是否存在
if not exist "%LOG_FILE_PATH%" (
    call :log 日志文件不存在，需要重启服务
    goto RESTART
)

call :log 日志文件存在，检查最后10行关键字

:: 获取总行数
set "TOTAL_LINES=0"
for /f %%i in ('type "%LOG_FILE_PATH%" ^| find /c /v ""') do set "TOTAL_LINES=%%i"

:: 计算开始行（最后10行）
set /a "START_LINE=%TOTAL_LINES%-10"
if %START_LINE% lss 0 set "START_LINE%=0"

call :log 检查行范围（总行数: %TOTAL_LINES%）: %START_LINE% 到 %TOTAL_LINES%

:: 提取最后10行到临时文件
set "TEMP_FILE=%TEMP%\last10lines.txt"
more +%START_LINE% "%LOG_FILE_PATH%" > "%TEMP_FILE%"

:: 动态解析KEYWORDS并检查 - 核心改进
set "FOUND=0"
call :log 开始检查关键字...
call :log 配置的关键字列表: "!KEYWORDS!"

:: 使用for循环动态解析管道分隔的关键字
for %%k in ("%KEYWORDS:|=" "%") do (
    set "KEYWORD=%%~k"
    @REM call :log 
    @REM call :log 检查关键字: !KEYWORD!
    findstr /i "!KEYWORD!" "%TEMP_FILE%" >nul
    if !errorlevel!==0 (
        echo.
        call :log 提取的最后10行内容:
        call :log_file_content %TEMP_FILE%
        :: type "%TEMP_FILE%"
        echo.
        call :log [发现] 关键字: !KEYWORD!
        set "FOUND=1"
        goto FOUND_KEYWORD
    ) else (
        @REM call :log [未找到] 关键字: !KEYWORD!
    )
)

:: 清理临时文件
del "%TEMP_FILE%"

if %FOUND%==1 (
    call :log 发现关键字，需要重启服务
) else (
    call :log 未发现关键字，无需重启服务
    goto :to_exit
)

:FOUND_KEYWORD
del "%TEMP_FILE%"
call :log 关键字检测完成，准备重启服务

:RESTART
call :log 开始重启 SakuraFrpService 服务...

:: 停止服务
call :log 正在停止服务...
call :run_and_log sc stop SakuraFrpService

:: 等待服务停止
:WAIT_STOP
sc query SakuraFrpService | find "STOPPED" >nul
if errorlevel 1 (
    timeout /t 1 >nul
    goto WAIT_STOP
)
call :log 服务已停止

:: 启动服务
call :log 正在启动服务...
call :run_and_log sc start SakuraFrpService

if errorlevel 1 (
    call :log 服务启动失败！
) else (
    call :log 服务重启成功！
)
goto :to_exit

:: ===========================
:: 退出，统一日志
:: ===========================
:to_exit
call :log 脚本执行完成............................................
exit /b 0
goto :eof