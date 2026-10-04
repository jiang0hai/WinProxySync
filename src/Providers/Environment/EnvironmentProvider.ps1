function Get-WinProxyEnvironmentNames {
    @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY')
}

function Set-WinProxyEnvironment {
    param([Parameter(Mandatory)]$Proxy)
    $values = @{
        HTTP_PROXY  = $Proxy.HttpProxy
        HTTPS_PROXY = $Proxy.HttpsProxy
        ALL_PROXY   = $Proxy.SocksProxy
        NO_PROXY    = $Proxy.NoProxy
    }
    foreach ($name in $values.Keys) {
        [Environment]::SetEnvironmentVariable($name, $values[$name], 'Process')
    }
}

function Clear-WinProxyEnvironment {
    foreach ($name in Get-WinProxyEnvironmentNames) {
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
}

function Invoke-EnvironmentProvider {
    param([Parameter(Mandatory)]$Proxy)
    if ($Proxy.Enabled) { Set-WinProxyEnvironment $Proxy }
    else { Clear-WinProxyEnvironment }
    [PSCustomObject]@{
        Provider = 'Environment'
        Success = $true
        Action = if ($Proxy.Enabled) { 'Applied' } else { 'Cleared' }
    }
}

function Get-EnvironmentProviderStatus {
    [PSCustomObject]@{
        Provider = 'Environment'
        Available = $true
        HTTP_PROXY = [Environment]::GetEnvironmentVariable('HTTP_PROXY','Process')
        HTTPS_PROXY = [Environment]::GetEnvironmentVariable('HTTPS_PROXY','Process')
        ALL_PROXY = [Environment]::GetEnvironmentVariable('ALL_PROXY','Process')
        NO_PROXY = [Environment]::GetEnvironmentVariable('NO_PROXY','Process')
    }
}
