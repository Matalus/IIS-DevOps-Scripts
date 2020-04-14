#Script for Setting AutoStart Attribute on App Pool

#load params from inline
Param(
   [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
   [string]
   $AppPool,

   [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
   [string]
   $DisableAutoStart
)

#Load WebAdministration
$VerbosePreference = "SilentlyContinue" 
"Loading WebAdministration Module..."
$null = Import-Module WebAdministration -Cmdlet *WebAppPool* -ErrorAction Inquire
$VerbosePreference = "Continue" 

#convert string to bool
$BoolAutoStart = [System.Convert]::ToBoolean($DisableAutoStart) 

Write-Verbose "Setting AutoStart to $DisableAutoStart"
Set-ItemProperty "IIS:\AppPools\$AppPool\" autoStart $BoolAutoStart -Verbose -ErrorAction Stop
