-- drop view  w5base.SYSTEM;
create view w5base.SYSTEM as
select ComplianceComputerID                        FLEXERASYSTEMID, 
       UUID                                        UUID,
       TenantID                                    TENANTID,
       ComputerName                                SYSTEMNAME,
       OperatingSystem                             SYSTEMOS,
       ServicePack                                 SYSTEMOSPATCHLEVEL,
       NumberOfProcessors                          SYSTEMCPUCOUNT,
       NumberOfLogicalProcessors                   SYSTEMLOGICALCPUCOUNT,
       NumberOfCores                               SYSTEMCORECOUNT,
       ProcessorType                               SYSTEMCPUTTYPE,
       MaxClockSpeed                               SYSTEMCPUSPEED,
       TotalMemory                                 SYSTENMEMORY,
       ModelNo                                     ASSETMODLEL,
       SerialNo                                    ASSETSERIALNO,
       HostID                                      HOSTID,
       IPAddress                                   IPADDRLIST,
       InventoryDate                               INVENTORYDATE,
       HardwareInventoryDate                       HARDWAREINVENTORYDATE,
       ServicesInventoryDate                       SERVICESINVENTORYDATE,
       CreationDate                                CDATE
from dbo.ComplianceComputer_MT;

-- drop view w5base.INSTPKGSOFTWARE;
create view w5base.INSTPKGSOFTWARE as
select InstalledSoftware_MT.InstalledSoftwareID    ID,
       ComplianceComputerID                        FLEXERASYSTEMID,
       InstalledSoftware_MT.InstallDate            INSTDATE,
       SoftwareTitle_S.Fullname                    FULLNAME,
       SoftwareTitle_S.Comments                    COMMENTS,
       SoftwareTitleProduct_S.ProductName          PRODUCTNAME,
       SoftwareTitleVersion_S.VersionName          VERSION,
       InstalledSoftware_MT.DiscoveryDate          DISCDATE
                     
from dbo.InstalledSoftware_MT
   join SoftwareTitle_S 
      on InstalledSoftware_MT.SoftwareTitleID=
         SoftwareTitle_S.SoftwareTitleID
   join SoftwareTitleProduct_S
      on SoftwareTitle_S.SoftwareTitleProductID=
         SoftwareTitleProduct_S.SoftwareTitleProductID
   join SoftwareTitleVersion_S
      on SoftwareTitle_S.SoftwareTitleVersionID=
         SoftwareTitleVersion_S.SoftwareTitleVersionID;

