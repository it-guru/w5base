
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
   lower(FlexSystem.SYSTEMNAME) LW_SYSTEMNAME,
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
   FlexSystem.INSTANCECLOUDID,
   FlexSystem.REALCOMPUTERNAME,
   lower(FlexSystem.REALCOMPUTERNAME) LW_REALCOMPUTERNAME,
   lower(FlexSystem.INSTANCECLOUDID) LW_INSTANCECLOUDID,
   cast(
      regexp_replace(regexp_replace(FlexSystem.W5BASEID,'\..+$',''),'[^0-9].*$','') 
   as int) SYSTEMW5BASEID
from dbo.customDarwinExportDevice@flexerap FlexSystem;

CREATE INDEX "FLEXERA_system_id1"
   ON "mview_FLEXERA_system"(flexerasystemid) online;
CREATE INDEX "FLEXERA_system_id2"
   ON "mview_FLEXERA_system"(systemname) online;
CREATE INDEX "FLEXERA_system_id3"
   ON "mview_FLEXERA_system"(lw_systemname) online;
CREATE INDEX "FLEXERA_system_id4"
   ON "mview_FLEXERA_system"(systeminvhosttype) online;
CREATE INDEX "FLEXERA_system_id5"
   ON "mview_FLEXERA_system"(lw_instancecloudid) online;
CREATE INDEX "FLEXERA_system_id6"
   ON "mview_FLEXERA_system"(realcomputername) online;
CREATE INDEX "FLEXERA_system_id7"
   ON "mview_FLEXERA_system"(lw_realcomputername) online;

-- drop materialized view "mview_FLEXERA_system2w5system";
create materialized view "mview_FLEXERA_system2w5system"
   refresh complete start with sysdate
   next sysdate+(1/24)*2
   as
with 
FlexSystem as ( 
select "mview_FLEXERA_system".flexeradeviceid,
       "mview_FLEXERA_system".systemname,
       "mview_FLEXERA_system".lw_realcomputername,
       "mview_FLEXERA_system".lw_instancecloudid,
       "mview_FLEXERA_system".RealComputername,
       "mview_FLEXERA_system".ipaddrlist
from "mview_FLEXERA_system" 
where "mview_FLEXERA_system".DeviceStatus='ACTIVE' and
      lower("mview_FLEXERA_system".RealComputername)<>'localhost' and
      lower("mview_FLEXERA_system".systemname)<>'localhost'),
W5BaseSystem as (
select "itil::system".id w5baseid,
       "itil::system".name,"itil::system".srcsys,"itil::system".srcid,
       "itil::ipaddress".name ipaddr,
       "itil::system".cdate
   from "itil::system" 
      left outer join "itil::ipaddress" 
         on "itil::ipaddress".systemid="itil::system".id
where ("itil::system".cistatusid in (3,4,5) or
      ("itil::system".cistatusid=6 and
       "itil::system".mdate>current_date-28)) and
      "itil::ipaddress".cistatusid=4 and
      "itil::system".name<>'localhost'),
Level1Link as (
select 
       FlexSystem.flexeradeviceid,
       FlexSystem.systemname,
       W5BaseSystem.w5baseid,
       W5BaseSystem.cdate,
       ROW_NUMBER() OVER ( PARTITION BY flexeradeviceid ORDER BY W5BaseSystem.cdate) rn
 from FlexSystem
 join W5BaseSystem on
      (FlexSystem.lw_realcomputername=W5BaseSystem.name and
         not W5BaseSystem.srcsys in ('AWS','AZURE') and
       FlexSystem.ipaddrlist like '%'||W5BaseSystem.ipaddr||'%'  
       -- if name matching is used, at least one ip must match 
       -- ipaddrlist too
       )
      or (W5BaseSystem.srcid like
          FlexSystem.lw_instancecloudid||'@%@%' and
          W5BaseSystem.srcsys='AWS')
      or (W5BaseSystem.srcid like
          FlexSystem.lw_instancecloudid||'@%' and
          W5BaseSystem.srcsys='AZURE')),
FinalFlex2System as (
select flexeradeviceid,
       systemname,
       w5baseid
from Level1Link
where rn=1) -- if multiple systems matched, use 1st one created in W5Base
select * from FinalFlex2System;

CREATE INDEX "FLEXERA_system2w5system_id1"
   ON "mview_FLEXERA_system2w5system"(FLEXERADEVICEID) online;

grant select on "mview_FLEXERA_system2w5system" to W5I;
create or replace synonym W5I.FLEXERA_system2w5system 
       for "mview_FLEXERA_system2w5system";


' W5I_FLEXERA__systemidmap_of fällt demnächst weg!
'
'
'create or replace view "W5I_FLEXERA_system" as
'select "mview_FLEXERA_system".*,
'       "W5I_FLEXERA__systemidmap_of".systemid
'from "mview_FLEXERA_system"
'   left outer join "W5I_FLEXERA__systemidmap_of"
'        on "mview_FLEXERA_system".flexerasystemid=
'           "W5I_FLEXERA__systemidmap_of".flexerasystemid;

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


-- drop materialized view "mview_FLEXERA_instsoftwareraw";
create materialized view "mview_FLEXERA_instsoftwareraw"
   refresh complete start with sysdate
   next sysdate+(1/24)*18
   as
select ID,FLEXERADEVICEID,
       PRODUCTNAME, PUBLISHERNAME,
       DISPLAYNAME, EDITION,  FULLNAME,CLASSIFICATION
       VERSION, 
       VERSIONRAW, 
       VERSIONWEIGHT,
       "SoftwareTitleID"            SOFTWARETITLEID,
       "File_Evidence"              FILE_EVIDENCE,
       "File_Evidence_File_Version" FILE_EVIDENCE_FILE_VERSION,
       "Installer_Evidence"         INSTALLER_EVIDENCE,
       INSTDATE, 
       INVENTORYDATE,
       DISCDATE
from dbo.customDarwinExportDeviceInstRAW@flexerap;

CREATE INDEX "FLEXERA_instsoftwareraw_id1"
   ON "mview_FLEXERA_instsoftwareraw"(id) online;
CREATE INDEX "FLEXERA_instsoftwareraw_id2"
   ON "mview_FLEXERA_instsoftwareraw"(flexeradeviceid) online;

create or replace view "W5I_FLEXERA_instsoftwareraw" as
select "mview_FLEXERA_instsoftwareraw".*
from "mview_FLEXERA_instsoftwareraw";

grant select on "W5I_FLEXERA_instsoftwareraw" to W5I;
create or replace synonym W5I.FLEXERA_instsoftwareraw for "W5I_FLEXERA_instsoftwareraw";


