@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'Recon.psm1'

# Version number of this module.
ModuleVersion = '3.0.0.0'

# ID used to uniquely identify this module
GUID = '7e775ad6-cd3d-4a93-b788-da067274c877'

# Author of this module
Author = 'Matthew Graeber', 'Will Schroeder'

# Copyright statement for this module
Copyright = 'BSD 3-Clause'

# Description of the functionality provided by this module
Description = 'PowerSploit Reconnaissance Module'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Functions to export from this module
FunctionsToExport = @(
    'Add-XxXNetGroupUser',
    'Add-XxXNetUser',
    'Add-XxXObjectAcl',
    'Convert-NameToSid',
    'Convert-SidToName',
    'Convert-ADName',
    'ConvertFrom-UACValue',
    'Export-PowerViewCSV',
    'Find-XxXComputerField',
    'Find-XxXForeignGroup',
    'Find-XxXForeignUser',
    'Find-XxXGPOComputerAdmin',
    'Find-XxXGPOLocation',
    'Find-XxXInterestingFile',
    'Find-XxXLocalAdminAccess',
    'Find-XxXManagedSecurityGroups',
    'Find-XxXUserField',
    'Get-XxXADObject',
    'Get-XxXCachedRDPConnection',
    'Get-ComputerDetails',
    'Get-XxXComputerProperty',
    'Get-XxXDFSshare',
    'Get-XxXDNSRecord',
    'Get-XxXDNSZone',
    'Get-XxXDomainPolicy',
    'Get-XxXDomainSID',
    'Get-XxXExploitableSystem',
    'Get-XxXGUIDMap',
    'Get-HttpStatus',
    'Get-XxXIPAddress',
    'Get-XxXLastLoggedOn',
    'Get-XxXLoggedOnLocal',
    'Get-XxXNetComputer',
    'Get-XxXNetworkDomain',
    'Get-XxXNetDomainController',
    'Get-XxXNetDomainTrust',
    'Get-XxXNetFileServer',
    'Get-XxXNetworkForest',
    'Get-XxXNetForestCatalog',
    'Get-XxXNetForestDomain',
    'Get-XxXNetForestTrust',
    'Get-XxXNetworkGPO',
    'Get-XxXNetGPOGroup',
    'Get-XxXNetworkGroup',
    'Get-XxXNetGroupMember',
    'Get-XxXNetLocalGroup',
    'Get-XxXNetLoggedon',
    'Get-XxXNetOU',
    'Get-XxXNetProcess',
    'Get-XxXNetRDPSession',
    'Get-XxXNetSession',
    'Get-XxXNetShare',
    'Get-XxXNetSite',
    'Get-XxXNetSubnet',
    'Get-XxXNetUser',
    'Get-XxXObjectAcl',
    'Get-XxXPathAcl',
    'Get-XxXProxy',
    'Get-XxXRegistryMountedDrive',
    'Get-XxXSiteName',
    'Get-XxXUserEvent',
    'Get-XxXUserProperty',
    'Invoke-XxXACLScanner',
    'Invoke-XxXCheckLocalAdminAccess',
    'Invoke-XxXDowngradeAccount',
    'Invoke-XxXEnumerateLocalAdmin',
    'Invoke-XxXEventHunter',
    'Invoke-XxXFileFinder',
    'Invoke-XxXMapDomainTrust',
    'Invoke-XxXThreadedFunction',
    'Invoke-Portscan',
    'Invoke-XxXProcessHunter',
    'Invoke-ReverseDnsLookup',
    'Invoke-XxXShareFinder',
    'Invoke-XxXUserHunter',
    'New-XxXGPOImmediateTask',
    'Request-SPNTicket',
    'Set-XxXADObject'
)

# List of all files packaged with this module
FileList = 'Recon.psm1', 'Recon.psd1', 'PowerView.ps1', 'Get-HttpStatus.ps1', 'Invoke-ReverseDnsLookup.ps1',
               'Invoke-Portscan.ps1', 'Get-ComputerDetails.ps1', 'README.md'

}
