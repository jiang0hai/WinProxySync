# Configuration

```powershell
Enable-WinProxySync
Sync-WinProxy
Get-WinProxyStatus
Get-WinProxyProvider
Enable-WinProxyProvider Git
Disable-WinProxyProvider Git
Disable-WinProxySync
```

Force Git restoration only when explicitly intended:

```powershell
Disable-WinProxySync -Force
```

Profile:

```powershell
. "C:\Path\To\WinProxySync\src\WinProxySync.ps1"
Enable-WinProxySync
```
