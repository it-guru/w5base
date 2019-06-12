[CmdletBinding()]
param(
   [string]$Config = "d:\etc\w5sharescan.ini",
   [string]$DatabaseDir = "c:\etc\w5sharescan.ini",
   [string]$ExportDir = "c:\etc\w5sharescan.ini"
)

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Write-Host "Path      : '$MyDir'";
$env:PSModulePath = $env:PSModulePath + ';'+$MyDir+'';


Import-Module -Name Recon 
Import-Module -Name ConfigFile 

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config 

Write-Host "Tmp       : '$DatabaseDir'"
Write-Host "ExportDir : '$ExportDir'"
Write-Host ""

if ( -not (Test-Path $DatabaseDir) ){
   Write-Error "Directory Tmp='$DatabaseDir' not exists"
   exit
}

function Process-NetComputerFile {
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('File')]
        [String]
        $InFile="",
        [String]
        $OutFile=""

    )
    if ( -not ($OutFile -eq "")){
       if (Test-Path($OutFile)){
          Clear-Content $OutFile;
       }
       If ((Get-Item $InFile).length -gt 0) {
          Invoke-XxXShareFinder -ComputerFile $InFile -Threads 100 | %{
              $ShareName=$_ -replace " .*$","";
              Write-Output $ShareName;
          } > $OutFile
       }
    }
}


function Start-ShareScan {
   $inset=$true;
   for($fno=1;$fno -lt 1000;$fno++){
      $f="$DatabaseDir\NetComputer_{0:d3}.txt" -f $fno;
      $OutFile="$DatabaseDir\ComputerShare_{0:d3}" -f $fno;
      if ($inset){
         if (Test-Path($f)){
            $d=Get-Date -Format "yyyyMMdd-HH:mm:ss"  
            $s="{0} Start processing {1}" -f $d,$f;
            Write-Host $s;
            Process-NetComputerFile -InFile $f -OutFile "$OutFile.tmp";
            Move-Item -Force -Path "$OutFile.tmp" -Destination "$OutFile.csv"
         }
         else{
            $inset=$false;
         }
      }
      if (-not ($inset)){
         Get-Item "$OutFile.*" | Remove-Item -Force
      }
   }
}


Start-ShareScan





