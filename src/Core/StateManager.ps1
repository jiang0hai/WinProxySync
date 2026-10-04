$script:WinProxySyncStateRoot = Join-Path $env:LOCALAPPDATA 'WinProxySync\providers'

function Initialize-WinProxySyncState {
    if (-not (Test-Path -LiteralPath $script:WinProxySyncStateRoot)) {
        New-Item -ItemType Directory -Path $script:WinProxySyncStateRoot -Force | Out-Null
    }
}

function Get-WinProxySyncStatePath {
    param([Parameter(Mandatory)][string]$ProviderName)
    Initialize-WinProxySyncState
    Join-Path $script:WinProxySyncStateRoot ($ProviderName.ToLowerInvariant() + '.json')
}

function Read-WinProxySyncState {
    param([Parameter(Mandatory)][string]$ProviderName)
    $path = Get-WinProxySyncStatePath $ProviderName
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
}

function Write-WinProxySyncState {
    param([Parameter(Mandatory)][string]$ProviderName, [Parameter(Mandatory)]$State)
    Initialize-WinProxySyncState
    $path = Get-WinProxySyncStatePath $ProviderName
    $tmp = "$path.tmp"
    $State | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tmp -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Remove-WinProxySyncState {
    param([Parameter(Mandatory)][string]$ProviderName)
    $path = Get-WinProxySyncStatePath $ProviderName
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
