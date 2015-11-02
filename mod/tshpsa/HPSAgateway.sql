/* Diese SQL Gateway definition muß manuell auf dem W5Warehouse System
   in die W5Repo Kennung eingespielt werden. Über diese Definitionen 
   werden dann zyklisch die Daten aus HPSA in eine saubere und 
   indizierte Tabellenform gebracht.
   Auf diese Daten wird dann mittels "W5I_HPSA_*"
   Views von W5Base/Darwin aus zugegriffen (tshpsa::*).
*/ 

/*
  CREATE DATABASE LINK "HPSA"
   CONNECT TO "T03TC_TI_DARWIN" IDENTIFIED BY 'xxxxxxxx'
   USING '(DESCRIPTION=
          (ADDRESS=
          (PROTOCOL=TCP)
          (HOST=164.28.47.244)
          (PORT=1521))
          (CONNECT_DATA=
          (SID=cmdb)))';
*/

/** temporary Import Tabel for CSV Loading Interface **/
create table "W5I_HPSA_system_import" (
 objectid             VARCHAR2(40),
 systemid             VARCHAR2(40),
 hostname             VARCHAR2(128),
 agentip              VARCHAR2(80),
 managementip         VARCHAR2(80),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 constraint "W5I_HPSA_system_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_HPSA_system_import" to W5I;
create or replace synonym W5I.HPSA_system_import
   for "W5I_HPSA_system_import";

create table "W5I_HPSA_lnkswp_import" (
 objectid             VARCHAR2(40),
 class                VARCHAR2(128),
 version              VARCHAR2(40),
 path                 VARCHAR2(255),
 uname                VARCHAR2(40),
 scandate             DATE,
 deleted              Number(*,0) default '0',
 dmodifydate          DATE
);
grant select,insert,update,delete on "W5I_HPSA_lnkswp_import" to W5I;
create or replace synonym W5I.HPSA_lnkswp_import
   for "W5I_HPSA_lnkswp_import";


/** Overflow Tabel **/

-- drop table "W5I_HPSA_lnkswp_of";
create table "W5I_HPSA_lnkswp_of" (
 id                   VARCHAR2(3000),
 denyupd              NUMBER(*,0) default '0',
 denyupdcomments      VARCHAR2(4000),
 ddenyupdvalidto      DATE,
 modifyuser           NUMBER(*,0),
 dmodifydate          DATE,
 constraint "W5I_HPSA_lnkswp_of_pk" primary key (id)
);
grant select,insert,update,delete on "W5I_HPSA_lnkswp_of" to W5I;
create or replace synonym W5I.HPSA_lnkswp_of
   for "W5I_HPSA_lnkswp_of";


/*  ==== tshpsa::lnkswp ====== */

-- drop materialized view "mview_HPSA_lnkswp";
create materialized view "mview_HPSA_lnkswp"
   refresh complete start with sysdate
   next sysdate+(1/24)*7
   as
select attr.item_id sysid,
       basesystem.server_id server_id,
       substr(replace(utl_i18n.string_to_raw(data =>
              swi.swclass||'-HostID'||attr.item_id||'-'||
              swi.swpath||'-'||swi.iname),' ',''),0,3000) id,
       swi.swclass||'-HostID'||attr.item_id||'-'||
           swi.swpath||'-'||swi.iname fullname,
       ddim.curdate,
       swi.swclass,
       swi.swvers,
       swi.swpath,
       swi.iname,
       swi.scandate

from (select DATE_DIMENSION.FULL_DATE_LOCAL curdate 
      from CMDB_DATA.DATE_DIMENSION@hpsa
      where DATE_DIMENSION.FULL_DATE_LOCAL between SYSDATE-1 AND SYSDATE)  ddim
      join  CMDB_DATA.SAS_SERVER_CUST_ATTRIBUTES@hpsa attr
          on ddim.curdate between attr.begin_date and attr.end_date
             and attr.ATTRIBUTE_NAME='TI.CSO_ao_mw_scanner'
      join CMDB_DATA.SAS_SERVERS_BASE@hpsa basesystem
           on attr.item_id=basesystem.item_id,
      XMLTable ( '//x/r'
          passing XMLType( 
           '<x><r><f>' || 
              replace(
                  replace(
                     rtrim(trim( 
                       case when length(attr.ATTRIBUTE_SHORT_VALUE)>2500 then
                       substr(attr.ATTRIBUTE_SHORT_VALUE,0,2500) || '...'
                       else
                       attr.ATTRIBUTE_SHORT_VALUE
                       end
                     ),chr(10)),chr(10),
                     '</f></r><r><f>'
                  ),';','</f><f>'
              ) ||
           '</f></r></x>' 
          )
          columns swid      FOR ORDINALITY,
                  swclass   varchar2(60)  path 'f[1]',
                  swvers    varchar2(40)  path 'f[2]',
                  swpath    varchar2(512) path 'f[3]',
                  iname     varchar2(40)  path 'f[4]',
                  scandate  varchar2(40)  path 'f[5]'
      ) swi
where length(replace(utl_i18n.string_to_raw(data =>
              attr.item_id||'-'||swi.swclass||'-'||
              swi.swpath||'-'||swi.iname),' ',''))<3000;

CREATE INDEX "HPSA_lnkswp_id" 
   ON "mview_HPSA_lnkswp"(id) online;
CREATE INDEX "HPSA_lnkswp_swclass" 
   ON "mview_HPSA_lnkswp"(lower(swclass)) online;

create or replace view "W5I_HPSA_lnkswp" as
select "mview_HPSA_lnkswp".*,
       overflow.id      of_id,
       overflow.denyupd,
       overflow.denyupdcomments,
       overflow.ddenyupdvalidto,
       overflow.modifyuser,
       overflow.dmodifydate
from "mview_HPSA_lnkswp"
     left outer join "W5I_HPSA_lnkswp_of" overflow
        on "mview_HPSA_lnkswp".id=overflow.id;

grant select on "W5I_HPSA_lnkswp" to "W5I";
create or replace synonym W5I.HPSA_lnkswp 
   for "W5I_HPSA_lnkswp";


/*  ==== tshpsa::system ====== */

-- drop materialized view "mview_HPSA_system";
create materialized view "mview_HPSA_system"
   refresh complete start with sysdate
   next sysdate+(1/24)*12
   as
select distinct system.item_id,
       basesystem.server_id server_id,
       ddim.curdate,
       lower(system.host_name) hostname,
       lower(system.display_name) name,
       system.primary_ip pip,
       attr_systemid.ATTRIBUTE_SHORT_VALUE systemid
      

from (select CMDB_DATA.DATE_DIMENSION.FULL_DATE_LOCAL curdate
      from CMDB_DATA.DATE_DIMENSION@hpsa
      where CMDB_DATA.DATE_DIMENSION.FULL_DATE_LOCAL
            between SYSDATE-1 AND SYSDATE)  ddim
     join CMDB_DATA.SAS_SERVERS@hpsa system
          on ddim.curdate between system.begin_date and system.end_date
     join CMDB_DATA.SAS_SERVERS_BASE@hpsa basesystem
          on system.item_id=basesystem.item_id
     join CMDB_DATA.SAS_SERVER_CUST_ATTRIBUTES@hpsa attr_systemid
          on ddim.curdate
             between attr_systemid.begin_date and attr_systemid.end_date
             and system.item_id=attr_systemid.item_id
             and attr_systemid.ATTRIBUTE_NAME='ITM_Service_ID'
     join CMDB_DATA.SAS_SERVER_AGENT@hpsa agent
          on system.item_id=agent.item_id;


CREATE INDEX "HPSA_system_id" 
   ON "mview_HPSA_system"(item_id) online;
CREATE INDEX "HPSA_system_hostname" 
   ON "mview_HPSA_system"(hostname) online;

create or replace view "W5I_HPSA_system" as
select * from "mview_HPSA_system";
grant select on "W5I_HPSA_system" to "W5I";
create or replace synonym W5I.HPSA_system 
   for "W5I_HPSA_system";

















