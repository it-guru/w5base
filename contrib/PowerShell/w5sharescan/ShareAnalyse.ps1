[CmdletBinding()]
param(
   [string]$Config = "d:\etc\w5sharescan.ini",
   [string]$DatabaseDir = "c:\etc\w5sharescan.ini",
   [string]$ExportDir = "c:\etc\w5sharescan.ini",
   [long]$MaxWorkTime = 3600
)

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$now=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
Write-Output ("{0} [{1}] Start ShareAnalyse" -f $now,$pid);

Write-Output " [$pid] Path        : '$MyDir'";
$env:PSModulePath = $env:PSModulePath + ';'+$MyDir+'';


Import-Module -Name Recon 
Import-Module -Name ConfigFile 

Import-ConfigFile -Ini -ErrorAction Stop -ConfigFilePath $Config 

$StartDate=Get-Date;
$TimedOut=$false;

Write-Output " [$pid] DatabaseDir : '$DatabaseDir'"
Write-Output " [$pid] ExportDir   : '$ExportDir'"
Write-Output " [$pid] MaxWorkTime : '$MaxWorkTime'"

$exclude = @("APPS", "apps", "print", "print$", "IPC$",
             "WsusContent", "Performance", "O365_RAWSOURCE", 
             "CBCUPDATE", "REMINST", "NETLOGON", "SYSVOL", 
             "SMSSIG$", "SMSPKGD$", "SCCMContentLib$", 
             "UpdateServicesPackages", "PrintBackup$");

if ( -not (Test-Path $DatabaseDir) ){
   Write-Error "Directory Tmp='$DatabaseDir' not exists"
   exit
}

function CleanupJobList {
   #Get-Job -Name "Share-Analyse";
   Get-Job -Name "Share-Analyse" -ChildJobState Completed | Receive-Job;
 #  Get-Job -Name "Share-Analyse" -ChildJobState Completed | Remove-Job
   
}

function Process-ShareFileAnalyse {
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('File')]
        [String]
        $InFile="",
        [String]
        $OutFile=""

    )
    If ((Get-Item $InFile).length -gt 0) {
       $ShareList=Get-Content $InFile;

       $FileFinderBlock = {
          param($ComputerName,$Depth,$Exclude)

          $ShareName=$ComputerName;
          $HostName  = $ShareName -split "\\" | 
                           Where-Object {$_ -ne ""} | 
                           Select-Object -First 1;
          $Share = ($ShareName -split "\\")[-1]

          $foundItems=0;
          $foundFiles=0;

          if ($Exclude.Contains($Share)){
             return @{
                'ShareName'=$ComputerName
                'Share'=$Share
                'exclude'=1
             }
          }
          else{
             if (!(Test-Connection -Quiet -Count 2 $HostName)) {
                return @{
                   'ShareName'=$ComputerName
                   'Share'=$Share
                   'notReachable'=1
                }
             } 
          }
          $chk1=0;
          Get-ChildItem -Path $ComputerName | Foreach-Object {
             $chk1++;
          }
          if ($chk1 -gt 0){
             Get-ChildItem -Path $ComputerName -Recurse -Force -Depth $Depth `
                           | Foreach-Object {
                $foundItems++;
                if ( -not ($_.Attributes  `
                           -band [System.IO.FileAttributes]::Directory) ){
                   $foundFiles++;
                }
             }
          }
          $d=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
          return @{
             'HostName'=$HostName
             'ShareName'=$ComputerName
             'Share'=$Share
             'foundItems'=$foundItems
             'foundFiles'=$foundFiles
             'scanDate'=$d
          }
          $j=Start-Job -ScriptBlock $chkCode;
       };

       $ScriptParams = @{
           'Depth' = 10
           'Exclude' = $exclude
       }
       $DatabaseDirOutFile="$OutFile.tmp";
       Set-Content $DatabaseDirOutFile -Value '' -Force -NoNewline;
       #if (Test-Path($DatabaseDirOutFile)){
       #   Clear-Content $DatabaseDirOutFile;
       #}

       $d=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
       $s="{0} [{1}] Start processing {2} to {3}" -f $d,$pid,$InFile,$OutFile;
       Write-Output $s;


       Invoke-XxXThreadedFunction -ComputerName $ShareList `
                                  -ScriptBlock $FileFinderBlock `
                                  -ScriptParameters $ScriptParams `
                                  -Threads 100 | Foreach-Object {
          if ($_.foundItems){
             $SecToken="OpenShare:$($_.ShareName)".replace("\","_");
             $csvline="";
             $csvline+="$SecToken;$($_.scanDate);$($_.HostName)";
             $csvline+=";EnforceRemove, GetStatement";
             $csvline+=";OPENSHARE001";
             $csvline+=";$($_.ShareName);$($_.Share)";
             $csvline+=";$($_.foundItems);$($_.foundFiles)";
             Write-Output "$csvline" >> $DatabaseDirOutFile
          }
       }
       $d=(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss");
       $s="{0} done {1}" -f $d,$OutFile;
       Move-Item -Force -Path "$OutFile.tmp" -Destination "$OutFile.csv1"
       Copy-Item -Force -Path "$OutFile.csv1" -Destination "$OutFile.csv"

       Write-Output $s;
    }
}


function Start-ShareAnalyse {
   $inset=$true;
   for($fno=1;$fno -lt 1000;$fno++){
      $f="$DatabaseDir\ComputerShare_{0:d3}.csv" -f $fno;
      $OutFile="$DatabaseDir\ShareData_{0:d3}" -f $fno;
      $now=Get-Date;
      if ((New-TimeSpan -Start $StartDate -End $now).TotalSeconds `
           -gt $MaxWorkTime){
         $TimedOut=$true;
      }
      else{
         if ($inset){
            if (Test-Path($f)){
               if (-not (Test-Path("$OutFile.csv1"))){
                  Process-ShareFileAnalyse -InFile $f -OutFile $OutFile;
               }
            }
            else{
               $inset=$false;
            }
         }
         if (-not($inset)){
            Get-Item "$OutFile.*" | Remove-Item -Force
         }
      }
   }
   if (-not ($TimedOut)){
      Get-Item "$DatabaseDir\ShareData_*.csv1" | Remove-Item -Force
   }

   Get-Item "$ExportDir\ShareData_*.csv" | Remove-Item -Force
   $d=Get-Date -Format "yyyyMMdd-HHmmss";
   $OutFile="$ExportDir\ShareData_$d.csv";
   Set-Content $OutFile -Value "SecToken;ScanDate;TreadRules;SecItem"+
                               "ShareName;HostName;Share;"+
                               "foundItems;foundFiles";
   Get-Content "$DatabaseDir\ShareData_*.csv" | Add-Content $OutFile
}


Start-ShareAnalyse





