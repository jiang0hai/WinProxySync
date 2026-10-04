
$global:WinProxySyncProviders = @{
    Environment = $true
    Git = $true
}

function Enable-WinProxyProvider {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if($script:WinProxySyncProviders.ContainsKey($Name))
    {
        $script:WinProxySyncProviders[$Name]=$true
    }

    [PSCustomObject]@{
        Provider=$Name
        Enabled=$script:WinProxySyncProviders[$Name]
        Action="Enabled"
    }
}
function global:Disable-WinProxyProvider {

param(
[string]$Name
)


if($global:WinProxySyncProviders.ContainsKey($Name))
{
    $global:WinProxySyncProviders[$Name]=$false
}


Get-WinProxyProvider

}
function Get-WinProxyProvider {
    [PSCustomObject]$WinProxySyncProviders
}

function Test-WinProxyProviderEnabled {
    param([string]$Name)
    return [bool]$WinProxySyncProviders[$Name]
}
