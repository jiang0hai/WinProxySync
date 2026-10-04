function Test-GitProviderAvailable {
    [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Get-GitGlobalValues {
    if (-not (Test-GitProviderAvailable)) {
        return [PSCustomObject]@{ Http = @(); Https = @() }
    }
    [PSCustomObject]@{
        Http = @(git config --global --get-all http.proxy 2>$null)
        Https = @(git config --global --get-all https.proxy 2>$null)
    }
}

function Set-GitGlobalValues {
    param([string]$Key, [string[]]$Values)
    & git config --global --unset-all $Key 2>$null | Out-Null
    foreach ($value in $Values) { & git config --global --add $Key $value }
}

function Remove-GitGlobalKey {
    param([string]$Key)
    & git config --global --unset-all $Key 2>$null | Out-Null
}

function Apply-GitProvider {
    param([Parameter(Mandatory)]$Proxy)

    if (-not (Test-GitProviderAvailable)) {
        return [PSCustomObject]@{ Provider='Git'; Success=$false; Action='Unavailable'; Message='git executable was not found.' }
    }

    $state = Read-WinProxySyncState 'git'
    if (-not $state -or -not $state.managed) {
        $current = Get-GitGlobalValues
        $state = [PSCustomObject]@{
            version='1.0.0'
            managed=$true
            original=[PSCustomObject]@{ http=@($current.Http); https=@($current.Https) }
            lastApplied=[PSCustomObject]@{ http=@(); https=@() }
        }
    }

    $http=@(); $https=@()
    if ($Proxy.Enabled) {
        if ($Proxy.HttpProxy) { $http=@($Proxy.HttpProxy) }
        if ($Proxy.HttpsProxy) { $https=@($Proxy.HttpsProxy) }
    }

    if ($http.Count) { Set-GitGlobalValues 'http.proxy' $http } else { Remove-GitGlobalKey 'http.proxy' }
    if ($https.Count) { Set-GitGlobalValues 'https.proxy' $https } else { Remove-GitGlobalKey 'https.proxy' }

    $state.lastApplied=[PSCustomObject]@{ http=@($http); https=@($https) }
    Write-WinProxySyncState 'git' $state

    [PSCustomObject]@{ Provider='Git'; Success=$true; Action=if($Proxy.Enabled){'Applied'}else{'Cleared'} }
}

function Test-GitValuesEqual {
    param([string[]]$A,[string[]]$B)
    (@($A) -join "`n") -ceq (@($B) -join "`n")
}

function Restore-GitProvider {
    param([switch]$Force)

    if (-not (Test-GitProviderAvailable)) {
        return [PSCustomObject]@{ Provider='Git'; Success=$false; Action='Unavailable'; Message='git executable was not found.' }
    }

    $state=Read-WinProxySyncState 'git'
    if (-not $state -or -not $state.managed) {
        return [PSCustomObject]@{ Provider='Git'; Success=$true; Action='NothingToRestore' }
    }

    $current=Get-GitGlobalValues
    $safe=(Test-GitValuesEqual $current.Http @($state.lastApplied.http)) -and
          (Test-GitValuesEqual $current.Https @($state.lastApplied.https))

    if (-not $safe -and -not $Force) {
        return [PSCustomObject]@{
            Provider='Git'; Success=$false; Action='Conflict'
            Message='Git global proxy changed after WinProxySync applied it. No changes made. Use -Force to restore the original state.'
        }
    }

    if (@($state.original.http).Count) { Set-GitGlobalValues 'http.proxy' @($state.original.http) }
    else { Remove-GitGlobalKey 'http.proxy' }

    if (@($state.original.https).Count) { Set-GitGlobalValues 'https.proxy' @($state.original.https) }
    else { Remove-GitGlobalKey 'https.proxy' }

    Remove-WinProxySyncState 'git'
    [PSCustomObject]@{ Provider='Git'; Success=$true; Action='Restored' }
}

function Get-GitProviderStatus {
    if (-not (Test-GitProviderAvailable)) {
        return [PSCustomObject]@{ Provider='Git'; Available=$false; Managed=$false }
    }
    $values=Get-GitGlobalValues
    $state=Read-WinProxySyncState 'git'
    [PSCustomObject]@{
        Provider='Git'; Available=$true; Managed=[bool]($state -and $state.managed)
        HttpProxy=@($values.Http); HttpsProxy=@($values.Https)
    }
}
