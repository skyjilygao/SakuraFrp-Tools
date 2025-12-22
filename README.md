# SakuraFrp-Tools

SakuraFrp 内网穿透工具的自动化管理脚本，提供定时重启、日志记录等功能，确保服务稳定运行。

## 🎯 项目背景

SakuraFrp 是一款流行的内网穿透工具，但在长时间运行过程中可能会出现连接不稳定等问题（比如以下错误）。本项目提供自动化解决方案，通过定时重启机制保持服务的稳定性和可靠性。

> `frpc[pitool2|Info] 2025/12/22 09:53:58 [E] [16/xxx/dc8f] 网络波动导致数据连接断开, 正在重试: read tcp x.x.x.x:63581->x.x.x.x:8088: wsarecv: An existing connection was forcibly closed by the remote host.`

## 📋 功能特性

### ✅ 核心功能
- **自动重启**: 定时重启 SakuraFrp 服务，释放内存资源
- **日志记录**: 详细记录每次重启操作的时间、结果和状态
- **进程管理**: 智能检测和终止 SakuraFrp 进程
- **错误处理**: 完善的错误检测和日志记录机制

### 🔧 技术特点
- **零依赖**: 纯 Windows 批处理脚本，无需额外安装
- **轻量级**: 占用系统资源极少
- **可配置**: 灵活的配置参数，适应不同环境
- **稳定可靠**: 经过充分测试，运行稳定

## 🚀 快速开始

### 1. 下载和配置
1. 下载 `RestartSakura.bat` 脚本文件
2. 根据需要修改脚本开头的配置参数：
   ```batch
   set "EXE_PATH=C:\Program Files\SakuraFrpLauncher\SakuraLauncher.exe"
   set "LOG_DIR=C:\ProgramData\SakuraFrpService\Logs"
   set "SLEEP_SECONDS=3"
   ```

### 2. 测试运行
双击运行 `RestartSakura.bat`，查看日志文件确认正常运行：
```
C:\ProgramData\SakuraFrpService\Logs\定时重启Sakura.log
```

### 3. 设置计划任务（推荐）
按照下面的 Windows 计划任务配置，设置每天自动执行。

## ⚙️ 配置说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `EXE_PATH` | SakuraFrp 可执行文件路径 | `C:\Program Files\SakuraFrpLauncher\SakuraLauncher.exe` |
| `LOG_DIR` | 日志文件存储目录 | `C:\ProgramData\SakuraFrpService\Logs` |
| `SLEEP_SECONDS` | 重启间隔时间（秒） | `3` |

## 📊 日志格式

日志文件采用标准格式，包含时间戳和操作详情：
```
[2024-12-16 14:30:00.123] 脚本开始执行...
[2024-12-16 14:30:00.125] 检测到 SakuraLauncher.exe 正在运行，尝试终止...
[2024-12-16 14:30:00.456] 停止成功：SakuraLauncher.exe 已终止。
[2024-12-16 14:30:03.789] 启动成功：SakuraLauncher.exe 已启动。
```

## 🔄 工作原理

1. **进程检测**: 检查 SakuraLauncher.exe 是否正在运行
2. **优雅终止**: 如果运行中，强制终止进程
3. **等待间隔**: 等待配置的间隔时间，确保资源释放
4. **重新启动**: 启动新的 SakuraFrp 进程
5. **状态验证**: 确认进程启动成功
6. **日志记录**: 记录整个操作过程和结果

## 🛠️ Windows 计划任务配置

### 方法一：使用图形界面

1. **打开任务计划程序**
   - 按 `Win + R`，输入 `taskschd.msc` 回车
   - 或搜索"任务计划程序"

2. **创建基本任务**
   - 点击右侧"创建基本任务"
   - 名称：`SakuraFrp定时重启`
   - 描述：`每天定时重启 SakuraFrp 服务`

3. **设置触发器**
   - 选择"每天"
   - 设置开始时间（建议：凌晨 3:00）
   - 重复间隔：1 天

4. **设置操作**
   - 操作类型：启动程序
   - 程序/脚本：浏览选择 `RestartSakura.bat`
   - 起始于：脚本所在目录

5. **完成任务设置**
   - 勾选"使用最高权限运行"
   - 点击"完成"

### 方法二：使用命令行（推荐）

以管理员身份运行命令提示符，执行以下命令：

```batch
# 创建计划任务（每天凌晨3点执行）
schtasks /create ^
  /tn "SakuraFrp定时重启" ^
  /tr "D:\\path\\to\\RestartSakura.bat" ^
  /sc daily ^
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
schtasks /query /tn "SakuraFrp定时重启" /v /fo list

# 查看任务是否启用
schtasks /query /tn "SakuraFrp定时重启" /fo table
```

### 手动运行测试
```batch
# 手动运行任务（测试用）
schtasks /run /tn "SakuraFrp定时重启"

# 查看任务最后运行结果
schtasks /query /tn "SakuraFrp定时重启" /v /fo list | findstr "最后运行时间"
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
schtasks /delete /tn "SakuraFrp定时重启" /f

# 重新创建（修改参数）
schtasks /create /tn "SakuraFrp定时重启" /tr "新路径" /sc daily /st 02:00 /ru SYSTEM /rl HIGHEST /f
```

### 禁用/启用任务
```batch
# 禁用任务
schtasks /change /tn "SakuraFrp定时重启" /disable

# 启用任务
schtasks /change /tn "SakuraFrp定时重启" /enable
```

## 文件说明

- **[RestartSakura.bat](RestartSakura.bat)**: 主脚本文件，负责重启 SakuraFrp 服务
- **[setup-schedule-task.bat](setup-schedule-task.bat)**: 配置计划任务的脚本文件，记录重启操作和结果
- **[remove-schedule-task.bat](remove-schedule-task.bat)**: 删除任务的脚本文件
- **[view-task-status.bat](view-task-status.bat)**: 查看任务状态的脚本文件

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

#### 5. 编码问题
- **脚本编码**: 确认脚本使用 `GB2312` 编码保存，测试发现使用 `UTF-8` 编码会导致乱码并且任务执行失败
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
