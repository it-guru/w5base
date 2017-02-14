-- drop view  w5base.SYSTEM;
create view w5base.SYSTEM as
select ComplianceComputerID                FLEXERASYSTEMID, 
       UUID                                UUID,
       TenantID                            TENANTID,
       ComputerName                        SYSTEMNAME,
       OperatingSystem                     SYSTEMOS,
       ServicePack                         SYSTEMOSPATCHLEVEL,
       NumberOfProcessors                  SYSTEMCPUCOUNT,
       NumberOfLogicalProcessors           SYSTEMLOGICALCPUCOUNT,
       NumberOfCores                       SYSTEMCORECOUNT,
       ProcessorType                       SYSTEMCPUTTYPE,
       MaxClockSpeed                       SYSTEMCPUSPEED,
       TotalMemory                         SYSTENMEMORY,
       ModelNo                             ASSETMODLEL,
       SerialNo                            ASSETSERIALNO,
       HostID                              HOSTID,
       IPAddress                           IPADDRLIST,
       InventoryDate                       INVENTORYDATE,
       HardwareInventoryDate               HARDWAREINVENTORYDATE,
       ServicesInventoryDate               SERVICESINVENTORYDATE,
       CreationDate                        CDATE
from dbo."ComplianceComputer_MT";

