/* Diese SQL Gateway definition muß manuell auf dem W5Warehouse System
   in die W5Repo Kennung eingespielt werden. Über diese Definitionen 
   werden dann zyklisch die Daten aus Flexera mittels
   Oracle-Transparent-Gateway über Database-Links ins W5Warehouse als
   mat-Views kopiert. Auf diese Daten wird dann mittels "W5I_FLEXERA_*"
   Views von W5Base/Darwin aus zugegriffen (FLEXERAatW5W::*).
*/

/* Views auf der MSSQL Seite werden benoetigt!!!  */

-- drop materialized view "mview_FLEXERA_system";
create materialized view "mview_FLEXERA_system"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select "ComplianceComputerID"   ComplianceComputerID,
       "ComputerName"           SystemName,
       substr("OperatingSystem",1,4000)        osname,
       "SerialNo"               serialno,
       "NumberOfProcessors"     cpucount,
       "NumberOfCores"          corecount,
       "ProcessorType"          cputype,
       "TotalMemory"            memory,
       "UUID"                   uuid,
       "ILMTAgentID"            ILMTAgentID,
       "CreationDate"           cdate,
       "InventoryDate"          mdate,
       "HardwareInventoryDate"  hardware_mdate,
       "ServicesInventoryDate"  services_mdate
from "ComplianceComputer_MT"@flexerap;



