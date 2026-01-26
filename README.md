# SakuraFrp-Tools

SakuraFrp 内网穿透工具的智能化管理脚本，提供基于错误检测的条件性重启、详细日志记录等功能，确保服务稳定运行的同时避免无谓的重启操作。

## 🎯 项目背景

SakuraFrp 是一款流行的内网穿透工具，但在长时间运行过程中可能会出现连接不稳定等问题（比如以下错误）。本项目提供自动化解决方案，通过定时重启机制保持服务的稳定性和可靠性。

> `frpc[pitool2|Info] 2025/12/22 09:53:58 [E] [16/xxx/dc8f] 网络波动导致数据连接断开, 正在重试: read tcp x.x.x.x:63581->x.x.x.x:8088: wsarecv: An existing connection was forcibly closed by the remote host.`

## 📋 功能特性

### ✅ 核心功能
- **智能重启**: 基于错误日志的条件性重启，仅在检测到特定错误时才触发
- **关键字检测**: 可配置多个错误关键字，实时监控服务日志
- **日志记录**: 详细记录每次操作的时间、结果和状态
- **服务管理**: 智能管理 SakuraFrpService Windows 服务
- **错误处理**: 完善的错误检测和日志记录机制

### 🔧 技术特点
- **零依赖**: 纯 Windows 批处理脚本，无需额外安装
- **轻量级**: 占用系统资源极少
- **可配置**: 灵活的错误关键字配置，适应不同环境
- **稳定可靠**: 经过充分测试，运行稳定
- **UTF-8 编码**: 完整支持中文和特殊字符

## 🚀 快速开始

### 1. 下载和配置
1. 下载 `RestartSakuraService_Dynamic.bat` 脚本文件
2. 根据需要修改脚本开头的配置参数：
   ```batch
   set "KEYWORDS=An existing connection was forcibly closed by the remote host"
   set "LOG_DIR=C:\ProgramData\SakuraFrpService\Logs"
   set "LOG_FILE=%LOG_DIR%\RestartSakuraService.log"
   ```

### 2. 自定义错误关键字
修改 `KEYWORDS` 变量以监控不同的错误类型：
- 单个关键字：`set "KEYWORDS=connection error"`
- 多个关键字（用|分隔）：`set "KEYWORDS=connection error|network timeout|wsarecv"`

### 3. 测试运行
双击运行 `RestartSakuraService_Dynamic.bat`，查看日志文件确认正常运行：
```
C:\ProgramData\SakuraFrpService\Logs\RestartSakuraService.log
```

### 4. 设置计划任务（推荐）
按照下面的 Windows 计划任务配置，设置定期监控和执行。

## ⚙️ 配置说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `KEYWORDS` | 要监控的错误关键字（支持多个，用`|`分隔） | `An existing connection was forcibly closed by the remote host` |
| `LOG_DIR` | 日志文件存储目录 | `C:\ProgramData\SakuraFrpService\Logs` |
| `LOG_FILE` | 脚本运行日志文件路径 | `%LOG_DIR%\RestartSakuraService.log` |

## 📊 日志格式

日志文件采用标准格式，包含时间戳和操作详情：
```
[2024-12-16 14:30:00.123] 脚本执行开始...........................................
[2024-12-16 14:30:00.125] 配置的关键字列表: "An existing connection was forcibly closed"
[2024-12-16 14:30:00.130] 日志文件: C:\ProgramData\SakuraFrpService\Logs\SakuraFrpService.20241216.log
[2024-12-16 14:30:00.135] 开始检查关键字...
[2024-12-16 14:30:00.140] [发现] 关键字: An existing connection was forcibly closed
[2024-12-16 14:30:00.145] 发现关键字，需要重启服务
[2024-12-16 14:30:00.150] 开始重启 SakuraFrpService 服务...
[2024-12-16 14:30:00.155] 正在停止服务...
命令: sc stop SakuraFrpService
[2024-12-16 14:30:02.789] 服务已停止
[2024-12-16 14:30:03.120] 正在启动服务...
命令: sc start SakuraFrpService
[2024-12-16 14:30:03.789] 服务重启成功！
[2024-12-16 14:30:03.790] 脚本执行完成........................................
```

## 🔄 工作原理

1. **日志文件检测**: 检查 SakuraFrpService 的日志文件是否存在
2. **关键字扫描**: 如果日志存在，读取最后10行内容进行关键字匹配
3. **条件判断**: 
   - 如果找到配置的关键字或日志文件不存在，触发重启
   - 如果未找到关键字，跳过重启，节约资源
4. **服务停止**: 使用Windows服务管理命令停止 SakuraFrpService
5. **等待状态**: 确保服务完全停止后再继续
6. **服务启动**: 重新启动 SakuraFrpService
7. **结果记录**: 详细记录整个检测和操作过程

## 🛠️ Windows 计划任务配置

### 方法一：使用图形界面

1. **打开任务计划程序**
   - 按 `Win + R`，输入 `taskschd.msc` 回车
   - 或搜索"任务计划程序"

2. **创建基本任务**
   - 点击右侧"创建基本任务"
   - 名称：`SakuraFrp智能重启监控`
   - 描述：`监控 SakuraFrp 服务状态，发现错误时智能重启`

3. **设置触发器**
   - 选择"每小时"
   - 设置开始时间（建议：凌晨 3:00）
   - 重复间隔：1 小时

4. **设置操作**
   - 操作类型：启动程序
   - 程序/脚本：浏览选择 `RestartSakuraService_Dynamic.bat`
   - 起始于：脚本所在目录

5. **完成任务设置**
   - 勾选"使用最高权限运行"
   - 点击"完成"

### 方法二：使用命令行（推荐）

以管理员身份运行命令提示符，执行以下命令：

```batch
# 创建计划任务（每小时检查一次）
schtasks /create ^
  /tn "SakuraFrp智能重启监控" ^
  /tr "D:\\path\\to\\RestartSakuraService_Dynamic.bat" ^
  /sc hourly ^
  /st 03:00 ^
  /ru SYSTEM ^
  /rl HIGHEST ^
  /f

# 参数说明：
# /tn: 任务名称
# /tr: 要运行的程序路径（注意双反斜杠）
# /sc: 计划类型（daily=每天）
# /st: 开始时间（24小时制）
# /ru: 运行用户（SYSTEM=系统账户）
# /rl: 运行级别（HIGHEST=最高权限）
# /f: 强制创建（如果已存在则覆盖）
```

### 方法三：使用 PowerShell（高级）

```powershell
# 以管理员身份运行 PowerShell
$action = New-ScheduledTaskAction -Execute "D:\path\to\RestartSakura.bat"
$trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "SakuraFrp定时重启" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
```

## 📋 验证计划任务

### 检查任务状态
```batch
# 查看任务详细信息
schtasks /query /tn "SakuraFrp智能重启监控" /v /fo list

# 查看任务是否启用
schtasks /query /tn "SakuraFrp智能重启监控" /fo table
```

### 手动运行测试
```batch
# 手动运行任务（测试用）
schtasks /run /tn "SakuraFrp智能重启监控"

# 查看任务最后运行结果
schtasks /query /tn "SakuraFrp智能重启监控" /v /fo list | findstr "最后运行时间"
```

### 查看任务历史记录
1. 打开"任务计划程序"
2. 找到任务 `SakuraFrp定时重启`
3. 查看"历史记录"选项卡
4. 或查看事件查看器：`应用程序和服务日志` → `Microsoft` → `Windows` → `TaskScheduler` → `Operational`

## 🔧 任务管理

### 修改任务
```batch
# 删除现有任务
schtasks /delete /tn "SakuraFrp智能重启监控" /f

# 重新创建（修改参数）
schtasks /create /tn "SakuraFrp智能重启监控" /tr "新路径" /sc hourly /st 02:00 /ru SYSTEM /rl HIGHEST /f
```

### 禁用/启用任务
```batch
# 禁用任务
schtasks /change /tn "SakuraFrp智能重启监控" /disable

# 启用任务
schtasks /change /tn "SakuraFrp智能重启监控" /enable
```

## 文件说明

- **[RestartSakuraService_Dynamic.bat](RestartSakuraService_Dynamic.bat)**: 主脚本文件，智能监控 SakuraFrp 服务日志，发现错误时自动重启

## 🚨 故障排除

### 常见问题

#### 1. 任务不执行
- **检查路径**: 确认脚本路径正确，使用绝对路径
- **权限问题**: 确保以管理员身份创建任务
- **用户账户**: 确认运行用户有足够权限

#### 2. 日志文件无记录
- **目录权限**: 检查日志目录是否可写
- **路径问题**: 确认日志目录存在
- **脚本错误**: 手动运行脚本测试

#### 3. 进程无法终止
- **进程名称**: 确认进程名称正确（区分大小写）
- **权限不足**: 使用 SYSTEM 账户运行任务
- **进程保护**: 检查是否有安全软件阻止

#### 4. 启动失败
- **文件路径**: 确认 SakuraLauncher.exe 路径正确
- **依赖问题**: 检查是否缺少运行库
- **配置文件**: 确认配置文件完整

#### 5. 关键字检测不触发
- **日志文件路径**: 确认 SakuraFrpService 日志路径正确（默认：`C:\ProgramData\SakuraFrpService\Logs\SakuraFrpService.YYYYMMDD.log`）
- **关键字匹配**: 检查配置的关键字是否与实际日志中的错误信息完全匹配（大小写不敏感）
- **日志更新**: 确认 SakuraFrpService 正在正常运行并生成日志
- **测试方法**: 手动在日志文件中添加关键字，测试脚本是否能正确检测

#### 6. 编码问题
- **脚本编码**: 确认脚本使用 `UTF-8` 编码保存（此脚本已优化支持UTF-8）
- **文件属性**: 检查文件属性，确保没有隐藏或系统属性
- **路径包含特殊字符**: 避免路径中包含特殊字符（如空格、中文字符）

### 调试方法

1. **手动运行脚本**：双击脚本文件，观察窗口输出
2. **检查事件日志**：查看系统事件日志中的任务执行记录
3. **验证路径**：在命令行中测试脚本路径是否有效
4. **权限测试**：以不同用户身份运行脚本

## 💡 最佳实践

### 时间安排建议
- **重启时间**: 选择业务低峰期（凌晨 2-4 点）
- **频率控制**: 每天重启一次通常足够
- **间隔考虑**: 避免与其他维护任务冲突

### 监控建议
- **日志检查**: 每周检查一次日志文件
- **任务验证**: 每月验证任务是否正常运行
- **性能监控**: 观察重启后的系统性能
- **备份策略**: 定期备份重要配置文件

### 安全考虑
- **最小权限**: 使用最小必要权限运行任务
- **路径安全**: 确保脚本路径安全，防止篡改
- **日志保护**: 适当保护日志文件，防止泄露
- **更新维护**: 及时更新 SakuraFrp 到最新版本
