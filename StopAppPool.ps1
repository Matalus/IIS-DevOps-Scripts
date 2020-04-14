#Script for Stopping App Pools via Azure DevOps Release 1

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
$null = Import-Module WebAdministration -Cmdlet *WebAppPool* -ErrorAction Inquire

$VerbosePreference = "Continue" 

#Test for App Pool Existence
Try {
   $PoolExists = Get-Item "IIS:\AppPools\$AppPool\" -ErrorAction SilentlyContinue
}
Catch { }

if (!$PoolExists) {
   Write-Verbose "Application Pool : $AppPool : Cannot be found on $($Env:COMPUTERNAME)"
   Write-Error "AppPool Not Found"
}

#Get Pool State
write-verbose "$(Get-Date -format u) : Getting Initial State of $AppPool..."
$State = PoolState -Pool "$AppPool"
write-verbose "$(Get-Date -format u) : Pool State = $(PoolState -Pool "$AppPool")"

if ($State -ne "Stopped") {
   write-verbose "Attempting to Stop App Pool : $AppPool"
   <#
   #Set AutoStart to false
   if($DisableAutoStart){  
      Write-Verbose "Setting AutoStart to False"
      Set-ItemProperty "IIS:\AppPools\$AppPool\" autoStart $false -Verbose
   }
   #>
   
   Stop-WebAppPool -Name "$AppPool" -ErrorAction SilentlyContinue

   $startime = get-date
   $timestamp = (get-date).AddMinutes(1)
   #loop to make sure pool is stopped
   While ((Get-Date) -lt $timestamp -and (PoolState -Pool "$AppPool") -ne "Stopped") {
      $elapsed = ((get-date) - $startime).TotalSeconds
      write-verbose "$(Get-Date -format u) : Waiting for App Pool to Stop | elapsed seconds : $elapsed | Force Kill timeout at 60s"
      Start-Sleep -Seconds 10
   }
            
   #if pool doesn't stop gracefully
   if ((PoolState -Pool "$AppPool") -ne "stopped") {
      # Get list of app pools and owners
      write-verbose "$(Get-Date -format u) : Getting App Pool PIDs.."
      $PoolProcs = Get-Process w3wp | Select-Object Name, ID, @{
         N = "AppPool";
         E = { (Get-WmiObject Win32_Process -Filter "ProcessID=$($_.ID)").GetOwner().User }
      }
      #attempt to find matching pool
      $Pool = $PoolProcs | Where-Object {
         $_.AppPool -eq "$AppPool"
      }
      #if able to find pool with matching name start kill logic
      if ($Pool) {
         write-verbose "$(Get-Date -format u) : Killing PID $($Pool.ID) : $($Pool.AppPool)"
         # force kill proc
         Stop-Process -Id $Pool.ID -Force -Confirm:$false -Verbose
      }
      else {
         Write-Error "Unable to locate PID for: $AppPool"
      }
   } 
	
}
else {
   write-verbose "$(Get-Date -format u) : Pool is Already Stopped"
}

write-verbose "$(Get-Date -format u) : Pool State = $(PoolState -Pool "$AppPool")"