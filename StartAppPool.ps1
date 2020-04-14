#Script for Starting App Pools via Azure DevOps Release

#load params from inline
Param(
   [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
   [string]
   $AppPool
)

Function PoolState($Pool) {
   $PoolState = Get-Item "IIS:\AppPools\$Pool\"
   Return $PoolState.State
}

$VerbosePreference = "SilentlyContinue" 
"Loading WebAdministration Module..."
$null = Import-Module WebAdministration -Cmdlet *WebAppPool*

$VerbosePreference = "Continue" 

#Start App Pool
write-verbose "$(Get-Date -format u) : Attempting to Start App Pool : $AppPool"

<#
#Set AutoStart to True
if($DisableAutoStart){
   Write-Verbose "Setting AutoStart to True"
   Set-ItemProperty "IIS:\AppPools\$AppPool\" autoStart $true -Verbose
}
#>

Start-WebAppPool -Name "$AppPool" -ErrorAction SilentlyContinue

$startime = get-date
$timestamp = (get-date).AddMinutes(1)
#loop to make sure pool is stated
While ((Get-Date) -lt $timestamp -and (PoolState -Pool "$AppPool") -ne "Started") {
   $elapsed = ((get-date) - $startime).TotalSeconds
   Write-Verbose "Current State: $(PoolState -Pool "$AppPool")"
   write-verbose "$(Get-Date -format u) : Waiting for App Pool to Start | elapsed seconds : $elapsed"
   Start-Sleep -Seconds 10
}

#if pool doesn't start
if ((PoolState -Pool "$AppPool") -ne "started") {
   Write-Verbose "Error Starting : $AppPool"
   Write-Error "Error Starting Pool" -ErrorAction Stop
}
else {
   Write-Verbose "Success"
}
