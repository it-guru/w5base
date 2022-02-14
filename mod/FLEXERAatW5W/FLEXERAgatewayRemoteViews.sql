
-- drop materialized view "mview_FLEXERA_system";
create materialized view "mview_FLEXERA_system"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select 
   FlexSystem.FLEXERADEVICEID,
   FlexSystem.FLEXERADEVICEID flexerasystemid,
   upper(FlexSystem.DEVICESTATUS) DEVICESTATUS,
   FlexSystem.UUID,
   FlexSystem.TENANTID,
   FlexSystem.SYSTEMNAME,
   FlexSystem.SYSTEMOS,
   FlexSystem.SYSTEMOSPATCHLEVEL,
   FlexSystem.SYSTEMCPUCOUNT,
   FlexSystem.SYSTEMLOGICALCPUCOUNT,
   FlexSystem.SYSTEMCORECOUNT,
   FlexSystem.SYSTEMCPUTTYPE,
   FlexSystem.SYSTEMCPUSPEED,
   FlexSystem.SYSTEMINVHOSTTYPE,
   FlexSystem.SYSTEMMEMORY,
   FlexSystem.ASSETMODELL ASSETMODLEL,
   FlexSystem.ASSETSERIALNO,
   FlexSystem.HOSTID,
   FlexSystem.IPADDRLIST,
   FlexSystem.INVENTORYDATE,
   FlexSystem.HARDWAREINVENTORYDATE,
   FlexSystem.SERVICESINVENTORYDATE,
   FlexSystem.CDATE,
   FlexSystem.SYSTEMID "SystemID_at_Flexera",
   FlexSystem.BEACONID,
   FlexSystem.ISVM,
   FlexSystem.ISVMHOSTMISSING,
   "itil::system".id SYSTEMW5BASEID
from dbo.customDarwinExportDevice@flexerap FlexSystem
   left outer join "W5I_FLEXERA__systemidmap_of"
      on FlexSystem.FLEXERADEVICEID=
         "W5I_FLEXERA__systemidmap_of".FLEXERASYSTEMID
   left outer join "itil::system" 
      on "W5I_FLEXERA__systemidmap_of".systemid=
         "itil::system".systemid;

CREATE INDEX "FLEXERA_system_id1"
   ON "mview_FLEXERA_system"(flexerasystemid) online;
CREATE INDEX "FLEXERA_system_id2"
   ON "mview_FLEXERA_system"(systemname) online;
CREATE INDEX "FLEXERA_system_id3"
   ON "mview_FLEXERA_system"(systeminvhosttype) online;


create or replace view "W5I_FLEXERA_system" as
select "mview_FLEXERA_system".*,
       "W5I_FLEXERA__systemidmap_of".systemid
from "mview_FLEXERA_system"
   left outer join "W5I_FLEXERA__systemidmap_of"
        on "mview_FLEXERA_system".flexerasystemid=
           "W5I_FLEXERA__systemidmap_of".flexerasystemid;

grant select on "W5I_FLEXERA_system" to W5I;
create or replace synonym W5I.FLEXERA_system for "W5I_FLEXERA_system";

-- drop materialized view "mview_FLEXERA_instsoftware";
create materialized view "mview_FLEXERA_instsoftware"
   refresh complete start with sysdate
   next sysdate+(1/24)*18
   as
select ID,
       FLEXERADEVICEID FLEXERASYSTEMID,
       INSTDATE,
       FULLNAME,
       PRODUCTNAME,
       VERSION,
       VERSIONWEIGHT,
       VERSIONRAW,
       PUBLISHERNAME,
       DISCDATE,
       INVENTORYDATE,
       CLASSIFICATION,
       EDITION,
       STARTOFLIFEDATE,ENDOFLIFEDATE,
       RELEASEDATE,ENDOFSALESDATE,
       SUPPORTEDUNTIL,EXTENDEDSUPPORTUNTIL
from dbo.customDarwinExportDeviceInst@flexerap;

CREATE INDEX "FLEXERA_instsoftware_id1"
   ON "mview_FLEXERA_instsoftware"(id) online;
CREATE INDEX "FLEXERA_instsoftware_id2"
   ON "mview_FLEXERA_instsoftware"(flexerasystemid) online;

create or replace view "W5I_FLEXERA_instsoftware" as
select "mview_FLEXERA_instsoftware".*
from "mview_FLEXERA_instsoftware";

grant select on "W5I_FLEXERA_instsoftware" to W5I;
create or replace synonym W5I.FLEXERA_instsoftware for "W5I_FLEXERA_instsoftware";


