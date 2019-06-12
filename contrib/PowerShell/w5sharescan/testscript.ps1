[CmdletBinding()]
Param()

$d=Get-Date -Format "yyyyMMdd-HH:mm:ss"
Write-Host ("{0} Start Write-Host {1} - Verbose=$Verbose" -f $d,"aaa");
Write-Error ("{0} Start Write-Error {1}" -f $d,"aaa");
Write-Verbose ("{0} Start Write-Verbose {1}" -f $d,"aaa");
