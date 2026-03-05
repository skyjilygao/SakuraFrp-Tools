@echo off
setlocal enabledelayedexpansion
:: 设置utf8编码，注意本脚本文件也是utf8编码
chcp 65001 >nul

:: 动态关键字配置：多个词用管道符分割。例如：aaa|bbb
set "KEYWORDS=An existing connection was forcibly closed by the remote host|重试连接节点失败|i/o timeout"
set "LOG_DIR=C:\ProgramData\SakuraFrpService\Logs"
set "LOG_FILE=%LOG_DIR%\RestartSakuraService.log"
:: 上一次执行日期（用于日志轮转）
set "LAST_EXEC_DATE="
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
:: echo %*
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
REM echo "%input_file%"

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
    REM echo 命令: %cmd%
    call :log_file_content %temp_out%
    del "%temp_out%" >nul 2>&1
) else (
    call :log "[ERROR] Failed to create temp output file for command: %cmd%"
)

endlocal
goto :eof

:: ==============================
:: 函数: rotate_log
:: 作用: 日志轮转 - 按日期重命名日志文件
:: ==============================
:rotate_log
setlocal enabledelayedexpansion

:: 获取当前日期 (yyyyMMdd)
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "CURRENT_DATE=%%a"
set "CURRENT_DATE=!CURRENT_DATE:~0,8!"

:: 检查是否需要轮转
if "!LAST_EXEC_DATE!"=="" (
    :: 首次执行，检查日志文件是否存在
    if exist "%LOG_FILE%" (
        :: 必须先获取最后一行内容后才能写入其他日志
        set "LAST_LINE="
        for /f "delims=" %%i in ('type "%LOG_FILE%"') do set "LAST_LINE=%%i"
        REM echo "!LAST_LINE!"
        :: 从日志行中提取日期部分 [yyyy-MM-dd HH:mm:ss.sss]
        if defined LAST_LINE (
            echo !LAST_LINE! | find "[" >nul
            if !errorlevel!==0 (
                :: 使用简单可靠的日期提取方法
                for /f "tokens=1 delims=[]" %%a in ("!LAST_LINE!") do (
                    for /f "tokens=1 delims= " %%b in ("%%a") do (
                        for /f "tokens=1-3 delims=-" %%c in ("%%b") do (
                            set "LAST_EXEC_DATE=%%c%%d%%e"
                        )
                    )
                )
                if defined LAST_EXEC_DATE (
                    @REM call :log Extracted last execution date: !LAST_EXEC_DATE!
                ) else (
                    call :log Cannot extract date from log, using current date: !CURRENT_DATE!
                    set "LAST_EXEC_DATE=!CURRENT_DATE!"
                )
            ) else (
                :: 无法提取日期，使用当前日期
                call :log Cannot extract date from log, using current date: !CURRENT_DATE!
                set "LAST_EXEC_DATE=!CURRENT_DATE!"
            )
        ) else (
            :: 无法提取日期，使用当前日期
            call :log Cannot extract date from log, using current date: !CURRENT_DATE!
            set "LAST_EXEC_DATE=!CURRENT_DATE!"
        )
    ) else (
        :: 日志文件不存在，使用当前日期
        call :log "首次执行，设置上次执行日期: !CURRENT_DATE!"
        set "LAST_EXEC_DATE=!CURRENT_DATE!"
    )
    
    :: 判断是否需要轮转
    if not "!LAST_EXEC_DATE!"=="!CURRENT_DATE!" (
        call :log "日期变更 (!LAST_EXEC_DATE! -> !CURRENT_DATE!)，执行日志轮转"
        :: 检查日志文件是否存在
        if exist "%LOG_FILE%" (
            :: 重命名日志文件
            set "OLD_LOG_FILE=%LOG_DIR%\RestartSakuraService.!LAST_EXEC_DATE!.log"
            call :log "重命名日志文件: %LOG_FILE% -> !OLD_LOG_FILE!"
            
            :: 使用 move 命令重命名文件
            move "%LOG_FILE%" "!OLD_LOG_FILE!" >nul 2>&1
            
            if exist "!OLD_LOG_FILE!" (
                call :log "日志文件重命名成功"
            ) else (
                call :log "[WARNING] 日志文件重命名失败"
            )
            :: 创建新的日志文件
            echo. > "%LOG_FILE%"
            call :log "创建新的日志文件: %LOG_FILE%"
        ) else (
            call :log "日志文件不存在，无需轮转"
        )
        :: 更新上次执行日期
        set "LAST_EXEC_DATE=!CURRENT_DATE!"
        call :log "更新上次执行日期: !LAST_EXEC_DATE!"
    ) else (
        @REM call :log "日期未变更 (!CURRENT_DATE!)，跳过日志轮转"
    )
    
)
endlocal & set "LAST_EXEC_DATE=%LAST_EXEC_DATE%"
goto :eof
:: ==============================
:: 函数: main
:: 作用: 主函数，执行重启逻辑
:: ==============================
:main
:: 创建日志目录
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: 执行日志轮转检查
call :rotate_log

:: 获取当前日期
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "DT=%%a"
set "LOG_DATE=%DT:~0,8%"
set "LOG_FILE_PATH=C:\ProgramData\SakuraFrpService\Logs\SakuraFrpService.%LOG_DATE%.log"

:: 记录脚本开始时间（用于计算执行时间）
set "START_TIME=%DT%"

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
call :calculate_execution_time
exit /b 0
goto :eof

:: ==============================
:: 函数: calculate_execution_time
:: 作用: 计算脚本执行时间并显示
:: ==============================
:calculate_execution_time
setlocal enabledelayedexpansion

:: 获取当前时间
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "END_TIME=%%a"

:: 提取开始时间和结束时间的各个部分
set "START_YEAR=!START_TIME:~0,4!"
set "START_MONTH=!START_TIME:~4,2!"
set "START_DAY=!START_TIME:~6,2!"
set "START_HOUR=!START_TIME:~8,2!"
set "START_MINUTE=!START_TIME:~10,2!"
set "START_SECOND=!START_TIME:~12,2!"
set "START_MILLISECOND=!START_TIME:~15,3!"

set "END_YEAR=!END_TIME:~0,4!"
set "END_MONTH=!END_TIME:~4,2!"
set "END_DAY=!END_TIME:~6,2!"
set "END_HOUR=!END_TIME:~8,2!"
set "END_MINUTE=!END_TIME:~10,2!"
set "END_SECOND=!END_TIME:~12,2!"
set "END_MILLISECOND=!END_TIME:~15,3!"

:: 计算总秒数（简化计算，假设在同一天）
set /a "START_TOTAL_SECONDS=(!START_HOUR!*3600)+(!START_MINUTE!*60)+!START_SECOND!"
set /a "END_TOTAL_SECONDS=(!END_HOUR!*3600)+(!END_MINUTE!*60)+!END_SECOND!"

:: 计算时间差（秒）
set /a "ELAPSED_SECONDS=END_TOTAL_SECONDS - START_TOTAL_SECONDS"

:: 处理负数情况（跨天）
if !ELAPSED_SECONDS! lss 0 (
    set /a "ELAPSED_SECONDS=ELAPSED_SECONDS + 86400"  :: 86400秒 = 24小时
)

:: 转换为分钟和秒
set /a "ELAPSED_MINUTES=ELAPSED_SECONDS / 60"
set /a "ELAPSED_REMAINING_SECONDS=ELAPSED_SECONDS %% 60"

:: 显示执行时间
call :log 脚本执行完成............................................ : !ELAPSED_MINUTES!分!ELAPSED_REMAINING_SECONDS!秒
endlocal
goto :eof