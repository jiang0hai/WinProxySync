# WinProxySync

> Windows 系统代理 → PowerShell / CLI 环境变量 / Git 同步工具
> 
> ## 项目简介

WinProxySync 是一个 Windows 系统代理同步工具。

它读取 Windows 标准系统代理状态，并将代理信息同步到开发环境，包括：

-   PowerShell 环境变量
-   CLI 工具
-   Git 全局代理

设计目标：

> 系统代理开启时自动使用代理，系统代理关闭时恢复用户原始环境。

------------------------------------------------------------------------

## 特性

- 自动读取 Windows 系统代理（WinINET）
- 不绑定 Clash、Mihomo、v2rayN 或固定端口
- 同步 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`、`NO_PROXY`
- 可选 Git Provider，同步 Git 全局 `http.proxy` / `https.proxy`
- Git Provider 保存原配置，并支持冲突检测后恢复
- Provider 模块化设计，可扩展 npm、pip、cargo 等
- PowerShell 5.1 / 7+
- 无第三方 PowerShell 模块
- 不需要管理员权限

## 快速开始

```powershell
. .\src\WinProxySync.ps1
Enable-WinProxySync
Sync-WinProxy
Get-WinProxyStatus
```
#### 定位PowerShell Profile
```powershell
notepad $PROFILE     
```
将主文件路径与启动参数加入 PowerShell Profile：
以下示例
```powershell
. "C:\Path\To\WinProxySync\src\WinProxySync.ps1"
Enable-WinProxySync
```

## 常用命令


```powershell
Sync-WinProxy
Get-WinProxyStatus
Get-WinProxyProvider
Enable-WinProxyProvider Git
Disable-WinProxyProvider Git
Disable-WinProxySync
```
更多可输入```Get-Command *WinProxy*```查询
非常用命令是否可用未知

## 工作原理

读取：

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings
```

主要使用 `ProxyEnable`、`ProxyServer`、`ProxyOverride`，因此不会通过检查 7897 等固定端口判断代理状态。

系统代理关闭时，Environment Provider 清理由 WinProxySync 管理的代理环境变量。

## Git 安全策略

首次接管 Git 时保存原始 `http.proxy` / `https.proxy`。停用时，如果当前配置仍等于 WinProxySync 最近写入的值，则恢复原配置；如果用户期间手动修改，则默认报告冲突而不覆盖。

需要强制恢复时：

```powershell
Disable-WinProxySync -Force
```
可行性待商榷
可用以下命令进行git代理手动修改
```
git config --global --unset http.proxy #解除http代理

git config --global --unset https.proxy #解除https代理

git config --global <proxy_url>:<proxy_port>

git config --global <proxy_url>:<proxy_port>

#示例git config --global http.proxy http://proxyuser:proxypwd@proxy.server.com:8080
```

## 限制

- 自动同步是 PowerShell Prompt Hook，不是后台服务。
- 系统代理变化后在下一次 Prompt 或手动 `Sync-WinProxy` 时生效。
- 已运行进程不会自动刷新环境变量。
- Windows `ProxyOverride` 与标准 `NO_PROXY` 并非完全等价，转换采用保守策略。
- Git Provider 不会把仅 SOCKS 代理强制写入 Git。
- WinHTTP（`netsh winhttp`）目前不管理。


## AI 辅助开发

本项目使用 AI 工具辅助设计、编码和文档整理；代码由维护者审查、测试和修改。

## License

MIT，详见 `LICENSE`。
