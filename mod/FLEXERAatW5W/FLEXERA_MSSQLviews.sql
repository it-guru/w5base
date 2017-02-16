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

-- drop view w5base.INSTSOFTWARE;
create view w5base.INSTSOFTWARE as
select InstalledSoftware_MT.InstalledSoftwareID    ID,
       ComplianceComputerID                        FLEXERASYSTEMID,
       InstalledSoftware_MT.InstallDate            INSTDATE,
       SoftwareTitle_S.Fullname                    FULLNAME,
       SoftwareTitle_S.Comments                    CMTS,
       SoftwareTitleProduct_S.ProductName          PRODUCTNAME,
       SoftwareTitleVersion_S.VersionName          VERSION,
       SoftwareTitleVersion_S.VersionWeight        VERSIONWEIGHT,
       SoftwareTitlePublisher_S.PublisherName      PUBLISHERNAME,
       InstalledSoftware_MT.DiscoveryDate          DISCDATE
                     
from dbo.InstalledSoftware_MT
   join SoftwareTitle_S 
      on InstalledSoftware_MT.SoftwareTitleID=
         SoftwareTitle_S.SoftwareTitleID
   join SoftwareTitleProduct_S
      on SoftwareTitle_S.SoftwareTitleProductID=
         SoftwareTitleProduct_S.SoftwareTitleProductID
   join SoftwareTitlePublisher_S
      on SoftwareTitleProduct_S.SoftwareTitlePublisherID=
         SoftwareTitlePublisher_S.SoftwareTitlePublisherID
   join SoftwareTitleVersion_S
      on SoftwareTitle_S.SoftwareTitleVersionID=
         SoftwareTitleVersion_S.SoftwareTitleVersionID;

