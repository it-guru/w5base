NetComputerCollect.ps1:
=======================
  Default-Config : D:\etc\w5sharescan.ini
  Input          : ADS
  Output         : $DatabaseDir\RawNetComputer*
                   $DatabaseDir\NetComputer*
                   $DatabaseDir\ComputerIP*
                   $ExportDir\ComputerIP*.csv

Read of all computer nodes from current domain to $DatabaseDir\RawNetComputer. 
Then detect nodes with IP-Addresses to new list in $DatabaseDir\NetComputer. 
The list of nodes is splited in files with $PackSize lines. The max. time to 
start of processing new files is set by $MaxWorkTime .

  $ExportDir\ComputerIP*.csv
  NetComputer : Name of the node in the windows domain (ADS)
  IPAddress   : List of IP-Addresses for the given node with space seperated,
                if there are more then one



ComputerShareScan.ps1:
======================
  Default-Config : D:\etc\w5sharescan.ini
  Input          : $DatabaseDir\NetComputer*.csv
  Output         : $DatabaseDir\ComputerShare*

Creates a list of Shares, found on the NetComputer nodes from the Input.
The max. time to start of processing new files is set by $MaxWorkTime .



ShareAnalyse.ps1:
=================
  Default-Config : D:\etc\w5sharescan.ini
  Input          : $DatabaseDir\ComputerShare*.csv
  Output         : $DatabaseDir\ShareData*
                   $ExportDir\ShareData*.csv

Analyses all input-Shares if there are accessable by anybody and if it is, if 
there are files/directories readable/writeable.
A classification of SecItem is done, how it is need to be treaded.
The max. time to start of processing new files is set by $MaxWorkTime .

  $ExportDir\ShareData*.csv
  SecToken    : A token (unique string) to find/detect recurring SecItems.
  ScanDate    : The UTC timestamp, the record was detected.
  TreadRules  : Tags, how the entry should be handled as comma seperated
                list:

                - EnforceRemove      = The problem must be remove/cleared 
                                       on the associated system.
                                       Query the responsible on which 
                                       date the problem is fixed on the 
                                       associated system.
                                    
                - AllowArgument      = Allows the responsible to argument, why
                                       the case is not a problem. (Makes no
                                       sense in combination with EnforceRemove)
                                    
                - GetStatement       = Query a explanation from the responsible
                                       how the case accrued.
                
                - IsDSGVOcompromised = Query responsible, if DSGVO has been
                                       compromised by the case.
 


