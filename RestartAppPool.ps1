#Script for Restarting App Pools via Az DevOps Release

#load params from inline
Param(
   [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
   [string]
   $AppPool
)

Function PoolState($AppPool){
   $PoolState = Get-WebAppPoolState -Name $AppPool
   Return $PoolState.Value
}

#Load Web Admin
$VerbosePreference = "SilentlyContinue" 
"Loading WebAdministration Module..."
$null = Import-Module WebAdministration -Cmdlet *WebAppPool*

$VerbosePreference = "Continue" 

Get-Module "WebAdministration"

#Get Pool State
Write-Verbose "Getting Initial State..."
$State = PoolState -AppPool $AppPool
Write-Verbose "Pool State = $(PoolState -AppPool $AppPool)"

if($State -ne "Stopped"){
   Write-Verbose "Attempting to Stop App Pool : $AppPool"
   Stop-WebAppPool -Name $AppPool -ErrorAction SilentlyContinue

   $startime = get-date
   $timestamp = (get-date).AddMinutes(1)
   #loop to make sure pool is stopped
   While((Get-Date) -lt $timestamp -and (PoolState -AppPool $AppPool) -ne "Stopped"){
      $elapsed = (get-date) - $startime
      Write-Verbose "Waiting for App Pool to Stop | elapsed seconds : $($elapsed.TotalSeconds) | Force Kill timeout at 60s"
      Start-Sleep -Seconds 10
   }

   #if pool doesn't stop gracefully
   if((PoolState -AppPool $AppPool) -ne "stopped"){
      # Get list of app pools and owners
      Write-Verbose "Getting App Pool PIDs.."
      $PoolProcs = Get-Process w3wp | Select-Object Name,ID,@{
         N="AppPool";
         E={(Get-WmiObject Win32_Process -Filter "ProcessID=$($_.ID)").GetOwner().User}
      }
      #attempt to find matching pool
      $Pool = $PoolProcs | Where-Object {
         $_.AppPool -eq $AppPool
      }
      #if able to find pool with matching name start kill logic
      if($Pool){
         Write-Verbose "Killing PID $($Pool.ID) : $($Pool.AppPool)"
         # force kill proc
         Stop-Process -Id $Pool.ID -Force -Confirm:$false -Verbose
      }else{
         Write-Error "Unable to locate PID for: $AppPool"
      }
   }



}else{
   Write-Verbose "Pool is Already Stopped"
}

Write-Verbose "Pool State = $(PoolState -AppPool $AppPool)"

#Start App Pool
Write-Verbose "Attempting to Start App Pool : $AppPool"
Start-WebAppPool -Name $AppPool -ErrorAction SilentlyContinue

#get state
$State = PoolState -AppPool $AppPool
Write-Verbose "Pool State = $(PoolState -AppPool $AppPool)"
Write-Verbose "Script Complete!"
Exit