$script:WinProxySyncRoot =
Split-Path -Parent $MyInvocation.MyCommand.Path


$script:WinProxySyncModules=@(
    'Core\ProxyReader.ps1',
    'Core\StateManager.ps1',
    'Core\ProviderManager.ps1',
    'Providers\Environment\EnvironmentProvider.ps1',
    'Providers\Git\GitProvider.ps1',
    'Core\SyncEngine.ps1'
)


foreach($module in $script:WinProxySyncModules){

    $path=Join-Path $script:WinProxySyncRoot $module

    if(Test-Path $path){

        try{

            . $path

        }
        catch{

            Write-Warning "Load failed: $module"
            Write-Warning $_

        }

    }
    else{

        Write-Warning "Missing: $module"

    }

}
if($null -eq $global:WinProxySyncEnabled){$global:WinProxySyncEnabled=$false}

function Install-WinProxySyncPromptHook {
    if($global:WinProxySyncPromptHookInstalled){return}
    $existing=Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
    if($existing){$global:WinProxySyncOriginalPrompt=$function:prompt}else{$global:WinProxySyncOriginalPrompt=$null}

    function global:prompt {
        if($global:WinProxySyncEnabled){try{Sync-WinProxy | Out-Null}catch{}}
        if($global:WinProxySyncOriginalPrompt){& $global:WinProxySyncOriginalPrompt}
        else{"PS $($executionContext.SessionState.Path.CurrentLocation)> "}
    }
    $global:WinProxySyncPromptHookInstalled=$true
}

Install-WinProxySyncPromptHook
Set-Alias -Name wpsync -Value Sync-WinProxy -Scope Global
Set-Alias -Name wpstatus -Value Get-WinProxyStatus -Scope Global
function Test-WinProxySyncInstall {


$cmds=@(
"Sync-WinProxy",
"Get-WinProxyStatus",
"Enable-WinProxyProvider",
"Disable-WinProxyProvider",
"Get-WinProxyProvider"
)


foreach($c in $cmds){

    if(Get-Command $c -ErrorAction SilentlyContinue){

        Write-Host "$c OK"

    }
    else{

        Write-Host "$c Missing"

    }

}

}