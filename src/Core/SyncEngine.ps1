$script:WinProxyProviders=@(
    [PSCustomObject]@{ Name='Environment'; Enabled=$true; Apply='Invoke-EnvironmentProvider'; Status='Get-EnvironmentProviderStatus' },
    [PSCustomObject]@{ Name='Git'; Enabled=$true; Apply='Apply-GitProvider'; Status='Get-GitProviderStatus' }
)

function Get-WinProxyProvider { $script:WinProxyProviders | Select-Object Name,Enabled }

function Set-WinProxyProviderEnabled {
    param([string]$Name,[bool]$Enabled)
    $p=$script:WinProxyProviders | Where-Object {$_.Name -ieq $Name} | Select-Object -First 1
    if (-not $p) { throw "Unknown provider: $Name" }
    $p.Enabled=$Enabled
}

function Invoke-WinProxyProvider {
    param($Provider,$Proxy)
    try { & $Provider.Apply $Proxy }
    catch {
        [PSCustomObject]@{ Provider=$Provider.Name; Success=$false; Action='Error'; Message=$_.Exception.Message }
    }
}

function Sync-WinProxy {
    [CmdletBinding()]
    param()
    $proxy=Get-WinProxyModel
    $results=foreach($provider in $script:WinProxyProviders) {
        if($provider.Enabled){ Invoke-WinProxyProvider $provider $proxy }
    }
    [PSCustomObject]@{ Proxy=$proxy; Results=@($results) }
}

function Disable-WinProxySync {
    [CmdletBinding()]
    param([switch]$Force)
    foreach($provider in $script:WinProxyProviders) {
        if(-not $provider.Enabled){continue}
        try {
            if($provider.Name -eq 'Git'){ if(Test-WinProxyProviderEnabled 'Git'){ Restore-GitProvider } -Force:$Force }
            elseif($provider.Name -eq 'Environment'){ Clear-WinProxyEnvironment }
        } catch { Write-Warning "Provider '$($provider.Name)' restore failed: $($_.Exception.Message)" }
    }
    $global:WinProxySyncEnabled=$false
}

function Enable-WinProxySync {
    $global:WinProxySyncEnabled=$true
    Sync-WinProxy | Out-Null
}

function Get-WinProxyStatus {
    $proxy=Get-WinProxyModel
    [PSCustomObject]@{
        SyncEnabled=[bool]$global:WinProxySyncEnabled
        SystemProxyEnabled=$proxy.Enabled
        HttpProxy=$proxy.HttpProxy; HttpsProxy=$proxy.HttpsProxy
        SocksProxy=$proxy.SocksProxy; NoProxy=$proxy.NoProxy
        Providers=@(foreach($provider in $script:WinProxyProviders){
            if($provider.Status){ & $provider.Status }
        })
    }
}

function Enable-WinProxyProvider {

    param([string]$Name)

    Set-WinProxyProviderEnabled $Name $true

    if($global:WinProxySyncEnabled){
        Sync-WinProxy | Out-Null
    }
    Get-WinProxyProvider
    
}

function Disable-WinProxyProvider {

    param([string]$Name,[switch]$Force)

    $provider=$script:WinProxyProviders |
        Where-Object {$_.Name -ieq $Name} |
        Select-Object -First 1

    if(-not $provider){
        throw "Unknown provider: $Name"
    }

    $result=$null

    if($provider.Name -eq 'Git'){

        if(Test-WinProxyProviderEnabled 'Git'){
            $result=Restore-GitProvider -Force:$Force
        }
        else{
            $result=[PSCustomObject]@{
                Provider='Git'
                Success=$true
                Action='NothingToRestore'
            }
        }

    }
    elseif($provider.Name -eq 'Environment'){
        Clear-WinProxyEnvironment

        $result=[PSCustomObject]@{
            Provider='Environment'
            Success=$true
            Action='Cleared'
        }
    }

    $provider.Enabled=$false

    $result



    [PSCustomObject]@{
        Provider = $provider.Name
        Enabled  = $provider.Enabled
        Action   = "Disabled"
    }
}
