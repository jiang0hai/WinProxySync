function Get-WinProxySystemSettings {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $item = Get-ItemProperty -Path $path -ErrorAction Stop
    [PSCustomObject]@{
        ProxyEnable   = [int]($item.ProxyEnable -as [int])
        ProxyServer   = [string]$item.ProxyServer
        ProxyOverride = [string]$item.ProxyOverride
        AutoConfigURL  = [string]$item.AutoConfigURL
    }
}

function ConvertTo-WinProxyEndpoint {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $v = $Value.Trim()
    if ($v -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') { return $v }
    "http://$v"
}

function ConvertFrom-WinProxyOverride {
    param([string]$Override)
    if ([string]::IsNullOrWhiteSpace($Override)) { return $null }
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($part in ($Override -split ';')) {
        $p = $part.Trim()
        if (-not $p) { continue }
        if ($p -eq '<local>') { $result.Add('localhost'); continue }
        $p = $p -replace '^\*://', ''
        if ($p) { $result.Add($p) }
    }
    if ($result.Count -eq 0) { return $null }
    $result -join ','
}

function Get-WinProxyModel {
    $settings = Get-WinProxySystemSettings
    $enabled = $settings.ProxyEnable -eq 1
    $http = $null; $https = $null; $socks = $null; $default = $null

    if ($enabled -and $settings.ProxyServer) {
        foreach ($entry in ($settings.ProxyServer -split ';')) {
            $entry = $entry.Trim()
            if (-not $entry) { continue }
            if ($entry -match '^(?<scheme>[^=]+)=(?<value>.+)$') {
                $scheme = $Matches.scheme.ToLowerInvariant()
                $value = ConvertTo-WinProxyEndpoint $Matches.value.Trim()
                switch ($scheme) {
                    'http'  { $http = $value }
                    'https' { $https = $value }
                    'socks' { $socks = $value }
                }
            } else {
                $default = ConvertTo-WinProxyEndpoint $entry
            }
        }
        if (-not $http) { $http = $default }
        if (-not $https) { $https = $default }
    }

    [PSCustomObject]@{
        Enabled       = $enabled
        HttpProxy     = $http
        HttpsProxy    = $https
        SocksProxy    = $socks
        NoProxy       = ConvertFrom-WinProxyOverride $settings.ProxyOverride
        ProxyServer   = $settings.ProxyServer
        ProxyOverride = $settings.ProxyOverride
        AutoConfigURL  = $settings.AutoConfigURL
    }
}
