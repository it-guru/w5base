[CmdletBinding()]
param(
   [string]$Config = "d:\etc\w5sharescan.ini",
   [string]$DatabaseDir = "c:\etc\w5sharescan.ini",
   [string]$ExportDir = "c:\etc\w5sharescan.ini",
   [long]$MaxWorkTime = 3600,
   [long]$PackSize = 3000
)

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Write-Host "Path      : '$MyDir'";
$env:PSModulePath = $env:PSModulePath + ';'+$MyDir+'';


Import-Module -Name Recon 
Import-Module -Name ConfigFile 

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config 

$StartDate=Get-Date;
$TimedOut=$false;

Write-Host "Tmp         : '$DatabaseDir'"
Write-Host "ExportDir   : '$ExportDir'"
Write-Host "MaxWorkTime : '$MaxWorkTime'"
Write-Host ""

if ( -not (Test-Path $DatabaseDir) ){
   Write-Error "Directory Tmp='$DatabaseDir' not exists"
   exit
}

function Start-CleanupTempDirectory {
   #Write-Host "Cleanup '$DatabaseDir' "
   #Remove-Item -path $DatabaseDir\* -Recurse
}


function Start-HostScan {
   $linecount=0;
   $nodefileno=0;
   $nodefilename="";
   Get-XxXNetComputer |  % { 
      if ($nodefileno -lt 999){
         if ( ($linecount -ge $PackSize) -or ($nodefilename -eq "") ) {
            if ( $nodefilename -ne "" ) {
               $finename=$nodefilename -replace ".tmp$",".txt";
               Move-Item -Force -Path $nodefilename -Destination $finename
            }
            $now=Get-Date;
            if ((New-TimeSpan -Start $StartDate -End $now).TotalSeconds `
                -gt $MaxWorkTime){
               $TimedOut=$true;
               throw "MaxWorkTime $MaxWorkTime reached"
            }
            $nodefileno++; 
            $linecount=0;
            $nodefilename="$DatabaseDir\RawNetComputer_{0:d3}.tmp" -f $nodefileno;
            $d=Get-Date -Format "yyyyMMdd-HH:mm:ss"  
            $s="{0} Start writing {1} width {2} max entries" `
                   -f $d,$nodefilename,$PackSize;
            Write-Host $s;
            if ( Test-Path $nodefilename ){
               Remove-Item $nodefilename;
            }
         } 
         Add-Content $nodefilename "$_"; 
         $linecount++; 
      }
      else{
         throw "PackCount limit reached"
      }
   }
   if ( $nodefilename -ne "" ) {
      $finename=$nodefilename -replace ".tmp$",".txt";
      Move-Item -Force -Path $nodefilename -Destination $finename
   }
   if (-not ($TimedOut)){
      Write-Host "start cleanup"
      for(;$nodefileno -lt 1000;$nodefileno++){
         $nodefilefilter="$DatabaseDir\RawNetComputer_{0:d3}.*" -f $nodefileno;
         Get-Item $nodefilefilter | Remove-Item -Force 
      }
   }
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
       $tmpfile="$InFile.tmp";
       $tmpfile=$tmpfile -replace "Raw","";
       Get-Content $InFile | %{
          $NetComputer=$_;
          #Write-Host "NetComputer=$NetComputer";
          $IPAddress="";
          $iprec=Get-XxXIPAddress -ComputerName $NetComputer
          if ($iprec){
             $IPAddress=$iprec.IPAddress;
             Add-Content $OutFile "$NetComputer;$IPAddress";
             Write-Output $NetComputer;
          }
       } > $tmpfile
       $fineinfile=$InFile -replace "^Raw","";
       Move-Item -Force -Path $tmpfile -Destination $fineinfile
    }
}


function Start-ResolvIPAddresses {
   Get-ChildItem $DatabaseDir -Filter RawNetComputer_*.txt | Foreach-Object {
       $f=$_.fullname;
       $OutFile=$f -replace "RawNetComputer_","ComputerIP_";
       $OutFile=$OutFile -replace ".txt$",".csv";
       
       $d=Get-Date -Format "yyyyMMdd-HH:mm:ss"  
       $s="{0} Start processing {1}" -f $d,$f;
       Write-Host $s;
       Process-NetComputerFile -InFile $f -OutFile $OutFile;
   }
   Get-Item "$ExportDir\ComputerIP_*.csv" | Remove-Item -Force
   $d=Get-Date -Format "yyyyMMdd-HHmmss";
   $OutFile="$ExportDir\ComputerIP_$d.csv";
   Set-Content $OutFile -Value "NetComputer;IPAddress";
   Get-Content "$DatabaseDir\ComputerIP_*.csv" | Add-Content $OutFile
}


#Start-CleanupTempDirectory
Start-HostScan
Start-ResolvIPAddresses





