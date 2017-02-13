/* Diese SQL Gateway definition muß manuell auf dem W5Warehouse System
   in die W5Repo Kennung eingespielt werden. Über diese Definitionen 
   werden dann zyklisch die Daten aus TAD4D (prod und integ) mittels
   Oracle-Transparent-Gateway über Database-Links ins W5Warehouse als
   mat-Views kopiert. Auf diese Daten wird dann mittels "W5I_TAD4D_*"
   Views von W5Base/Darwin aus zugegriffen (TAD4DatW5W::*).
*/ 

-- drop materialized view "mview_TAD4D_adm_computer";
create materialized view "mview_TAD4D_adm_computer"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select computer_sys_id,
       computer_alias,
       os_name,
       computer_model,
       sys_ser_num,
       to_date(substr(adm_computer.create_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               create_time,
       to_date(substr(adm_computer.update_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               update_time
from adm_computer@tad4d
union all
select computer_sys_id,
       computer_alias,
       os_name,
       computer_model,
       sys_ser_num,
       to_date(substr(adm_computer.create_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               create_time,
       to_date(substr(adm_computer.update_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               update_time
from adm_computer@tad4di;

CREATE INDEX "TAD4D_adm_computer_id" 
   ON "mview_TAD4D_adm_computer"(computer_sys_id) online;
CREATE INDEX "TAD4D_adm_lcomputer_alias" 
   ON "mview_TAD4D_adm_computer"(lower(computer_alias)) online;


-- drop materialized view "mview_TAD4D_adm_agent";
create materialized view "mview_TAD4D_adm_agent"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select agent_id,
       agent_node_id,
       enviroment,
       agent_custom_data1,
       agent_version,
       agent_ip_address,
       agent_hostname,
       agent_statusid,
       decode(adm_agent.status,
              '1','ok',
              '2','initializing',
              '3','not connecting',
              '4','failed',
              '5','unknown',
              '6','incomplete',
              '7','missing software scan',
              '8','missing capacity scan',
              '-?-')                           agent_status,
       agent_osname,
       agent_osversion,
       agent_active,

       to_date(substr(adm_agent.scan_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_scan_time,
       to_date(substr(adm_agent.catalog_version,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_catalog_version,
       to_date(substr(adm_agent.full_hwscan_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_full_hwscan_time,
       to_date(substr(adm_agent.deleted_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_deleted_time
   from adm_agent@tad4d
union all
select agent_id,
       agent_node_id,
       enviroment,
       agent_custom_data1,
       agent_version,
       agent_ip_address,
       agent_hostname,
       agent_statusid,
       decode(adm_agent.status,
              '1','ok',
              '2','initializing',
              '3','not connecting',
              '4','failed',
              '5','unknown',
              '6','incomplete',
              '7','missing software scan',
              '8','missing capacity scan',
              '-?-')                           agent_status,
       agent_osname,
       agent_osversion,
       agent_active,

       to_date(substr(adm_agent.scan_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_scan_time,
       to_date(substr(adm_agent.catalog_version,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_catalog_version,
       to_date(substr(adm_agent.full_hwscan_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_full_hwscan_time,
       to_date(substr(adm_agent.deleted_time,0,19),'YYYY-MM-DD-HH24.MI.SS')
                                               agent_deleted_time
   from adm_agent@tad4di;


CREATE INDEX "TAD4D_adm_agent_id" 
   ON "mview_TAD4D_adm_agent"(agent_id) online;
CREATE INDEX "TAD4D_adm_agent_nodeid" 
   ON "mview_TAD4D_adm_agent"(agent_node_id) online;
CREATE INDEX "TAD4D_adm_agent_systemid" 
   ON "mview_TAD4D_adm_agent"(lower(agent_custom_data1)) online;

-- drop materialized view "mview_TAD4D_adm_instnativesw";
create materialized view "mview_TAD4D_adm_instnativesw"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select * from adm_instnativesw@tad4d
union all
select * from adm_instnativesw@tad4di;

CREATE INDEX "TAD4D_adm_instnativesw_id1" 
   ON "mview_TAD4D_adm_instnativesw"(agent_id) online;
CREATE INDEX "TAD4D_adm_instnativesw_id2" 
   ON "mview_TAD4D_adm_instnativesw"(native_id) online;


-- drop materialized view "mview_TAD4D_adm_nativesw";
create materialized view "mview_TAD4D_adm_nativesw"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select 'tad4dp-'||adm_native_sw.id              native_id,
       adm_native_sw.package_name               package_name,
       adm_native_sw.package_version            package_version
from adm.native_sw@tad4d  adm_native_sw
union all
select 'tad4di-'||adm_native_sw.id              native_id,
       adm_native_sw.package_name               package_name,
       adm_native_sw.package_version            package_version
from adm.native_sw@tad4di  adm_native_sw;

CREATE INDEX "TAD4D_adm_nativesw_id" 
   ON "mview_TAD4D_adm_nativesw"(native_id) online;
CREATE INDEX "TAD4D_adm_nativesw_name" 
   ON "mview_TAD4D_adm_nativesw"(lower(package_name)) online;



-- drop materialized view "mview_TAD4D_adm_prod_inv";
create materialized view "mview_TAD4D_adm_prod_inv"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select prod_inv_id,
       agent_id,
       product_id,
       branch_id,
       component_id,
       prod_inv_scope,
       to_date(substr(
          decode(adm_prod_inv.start_time,
             '9999-12-31-00.00.00.000000',NULL,
             adm_prod_inv.start_time
          ),0,19),'YYYY-MM-DD-HH24.MI.SS')     prod_inv_start_time,
       to_date(substr(
          decode(adm_prod_inv.end_time,
             '9999-12-31-00.00.00.000000',NULL,
             adm_prod_inv.end_time
          ),0,19),'YYYY-MM-DD-HH24.MI.SS')     prod_inv_end_time,
       prod_inv_is_remote,
       prod_inv_confidence_level,
       stype
from adm_prod_inv@tad4d
union all
select prod_inv_id,
       agent_id,
       product_id,
       branch_id,
       component_id,
       prod_inv_scope,
       to_date(substr(
          decode(adm_prod_inv.start_time,
             '9999-12-31-00.00.00.000000',NULL,
             adm_prod_inv.start_time
          ),0,19),'YYYY-MM-DD-HH24.MI.SS')     prod_inv_start_time,
       to_date(substr(
          decode(adm_prod_inv.end_time,
             '9999-12-31-00.00.00.000000',NULL,
             adm_prod_inv.end_time
          ),0,19),'YYYY-MM-DD-HH24.MI.SS')     prod_inv_end_time,
       prod_inv_is_remote,
       prod_inv_confidence_level,
       stype
from adm_prod_inv@tad4di;

CREATE INDEX "TAD4D_adm_prod_inv_id1" 
   ON "mview_TAD4D_adm_prod_inv"(prod_inv_id) online;
CREATE INDEX "TAD4D_adm_prod_inv_id2" 
   ON "mview_TAD4D_adm_prod_inv"(agent_id) online;
CREATE INDEX "TAD4D_adm_prod_inv_id3" 
   ON "mview_TAD4D_adm_prod_inv"(product_id) online;
CREATE INDEX "TAD4D_adm_prod_inv_id4" 
   ON "mview_TAD4D_adm_prod_inv"(component_id) online;


-- drop materialized view "mview_TAD4D_swcat_branch";
-- create materialized view "mview_TAD4D_swcat_branch"
--    refresh complete start with sysdate
--    next sysdate+(1/24)*6
--    as
-- select * from swcat_branch@tad4d
-- union all
-- select * from swcat_branch@tad4di;
-- 
-- CREATE INDEX "TAD4D_swbranch_id1" 
--    ON "mview_TAD4D_swcat_branch"(branch_id) online;


-- drop materialized view "mview_TAD4D_adm_vendor";
create materialized view "mview_TAD4D_adm_vendor"
   refresh complete start with sysdate
   next sysdate+(1/24)*6
   as
select * from adm_vendor@tad4d
union all
select * from adm_vendor@tad4di;

CREATE INDEX "TAD4D_adm_vendor_id1" 
   ON "mview_TAD4D_adm_vendor"(vendor_id) online;


-- drop materialized view "mview_TAD4D_adm_component";
create materialized view "mview_TAD4D_adm_component"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select * from adm_component@tad4d
union all
select * from adm_component@tad4di;

CREATE INDEX "TAD4D_adm_component_id1" 
   ON "mview_TAD4D_adm_component"(component_id) online;



-- drop materialized view "mview_TAD4D_adm_swproduct";
create materialized view "mview_TAD4D_adm_swproduct"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select * from adm_swproduct@tad4d
union all
select * from adm_swproduct@tad4di;

CREATE INDEX "TAD4D_adm_swproduct_id1" 
   ON "mview_TAD4D_adm_swproduct"(swproduct_id) online;
CREATE INDEX "TAD4D_adm_swproduct_id2" 
   ON "mview_TAD4D_adm_swproduct"(vendor_id) online;


/* Ebene 2 - Rekonstruktion der Datenzusammenhänge auf Basis
   der mat-Views:
*/

-- Für TAD4D::system (IT-Universum->System):
-- =========================================
-- adm.computer.computer_sys_id          => computer_sys_id
-- adm.computer.computer_alias           => computer_alias
-- adm.agent.custom_data1                => custom_data1
-- adm.computer.os_name                  => os_name
-- adm.computer.computer_model           => computer_model
-- adm.computer.sys_ser_num              => sys_ser_num
-- adm.agent.version                     => agent_version
-- adm.agent.ip_address                  => agent_ip_address
-- adm.agent.hostname                    => agent_hostname
-- adm.agent.node_id                     => agent_node_id
-- adm.agent.id                          => agent_id
-- adm.computer.create_time              => create_time
-- adm.computer.update_time              => update_time

create or replace view "W5I_TAD4D_system" as
select "mview_TAD4D_adm_computer".computer_sys_id     computer_sys_id,
       "mview_TAD4D_adm_computer".computer_alias      computer_alias,
       "mview_TAD4D_adm_agent".agent_custom_data1     custom_data1,
       "mview_TAD4D_adm_computer".os_name             os_name,
       "mview_TAD4D_adm_computer".computer_model      computer_model,
       "mview_TAD4D_adm_computer".sys_ser_num         sys_ser_num,
       "mview_TAD4D_adm_agent".agent_version          agent_version,
       "mview_TAD4D_adm_agent".agent_ip_address       agent_ip_address,
       "mview_TAD4D_adm_agent".agent_hostname         agent_hostname,
       "mview_TAD4D_adm_agent".agent_node_id          agent_node_id,
       "mview_TAD4D_adm_agent".agent_id               agent_id,
       "mview_TAD4D_adm_agent".enviroment             enviroment,
       "mview_TAD4D_adm_computer".create_time         create_time,
       "mview_TAD4D_adm_computer".update_time         update_time,
       "mview_TAD4D_adm_agent".agent_scan_time        scan_time
from "mview_TAD4D_adm_computer","mview_TAD4D_adm_agent"
where "mview_TAD4D_adm_computer".computer_sys_id
         ="mview_TAD4D_adm_agent".agent_id;
grant select on "W5I_TAD4D_system" to "W5I";
create or replace synonym W5I.TAD4D_system 
   for "W5I_TAD4D_system";


-- Für TAD4D::nativesoftware (IT-Universum->System->nativ Software):
-- =================================================================
-- adm.inst_native_sw.native_id          => native_id
-- adm.native_sw.package_name            => package_name
-- adm.native_sw.package_version         => package_version
-- adm.agent.hostname                    => agent_hostname
-- adm.agent.id                          => agent_id
-- adm.agent.scan_time                   => scan_time

create or replace view "W5I_TAD4D_nativesoftware" as
select "mview_TAD4D_adm_instnativesw".native_id||'-'||
       "mview_TAD4D_adm_instnativesw".agent_id        nativeinst_id,
       "mview_TAD4D_adm_nativesw".native_id           native_id,
       "mview_TAD4D_adm_nativesw".package_name        package_name,
       "mview_TAD4D_adm_nativesw".package_version     package_version,
       "mview_TAD4D_adm_agent".agent_hostname         agent_hostname,
       "mview_TAD4D_adm_agent".agent_id               agent_id,
       "mview_TAD4D_adm_agent".agent_scan_time        scan_time,
       "mview_TAD4D_adm_agent".enviroment             enviroment
from "mview_TAD4D_adm_agent",
     "mview_TAD4D_adm_nativesw",
     "mview_TAD4D_adm_instnativesw"
where "mview_TAD4D_adm_agent".agent_id
         ="mview_TAD4D_adm_instnativesw".agent_id and
      "mview_TAD4D_adm_instnativesw".native_id
         ="mview_TAD4D_adm_nativesw".native_id;
grant select on "W5I_TAD4D_nativesoftware" to "W5I";
create or replace synonym W5I.TAD4D_nativesoftware 
   for "W5I_TAD4D_nativesoftware";


-- Für TAD4D::software (IT-Universum->System->Software):
-- =====================================================
-- adm.prod_inv.id                       => prod_inv_id
-- adm.vendor.name                       => vendor_name
-- adm.component.name                    => component_name
-- adm.swproduct.name                    => swproduct_name
-- adm.swproduct.version                 => swproduct_version
-- adm.prod_inv.scope                    => prod_inv_scope
-- adm.prod_inv.start_time               => prod_inv_start_time
-- adm.prod_inv.end_time                 => prod_inv_end_time
-- adm.prod_inv.is_remote                => prod_inv_is_remote
-- adm.prod_inv.confidence_level         => prod_inv_confidence_level
-- adm.swproduct.is_pvu                  => is_pvu
-- adm.swproduct.is_rvu                  => is_rvu
-- adm.swproduct.is_sub_cap              => is_sub_cap
-- adm.component.is_free_only            => is_free_only
-- adm.agent.id                          => agent_id
-- adm.agent.hostname                    => agent_hostname
-- adm.agent.scan_time                   => scan_time

create or replace view "W5I_TAD4D_software" as
select "mview_TAD4D_adm_prod_inv".prod_inv_id         prod_inv_id,
       "mview_TAD4D_adm_prod_inv".prod_inv_scope      prod_inv_scope,
       "mview_TAD4D_adm_prod_inv".prod_inv_start_time prod_inv_start_time,
       "mview_TAD4D_adm_prod_inv".prod_inv_end_time   prod_inv_end_time,
       "mview_TAD4D_adm_prod_inv".prod_inv_is_remote  prod_inv_is_remote,
       "mview_TAD4D_adm_prod_inv".prod_inv_confidence_level,
       "mview_TAD4D_adm_swproduct".swproduct_name     swproduct_name,
       "mview_TAD4D_adm_swproduct".swproduct_version  swproduct_version,
       "mview_TAD4D_adm_swproduct".is_pvu             is_pvu,
       "mview_TAD4D_adm_swproduct".is_rvu             is_rvu,
       "mview_TAD4D_adm_swproduct".is_sub_cap         is_sub_cap,
       "mview_TAD4D_adm_component".is_free_only       is_free_only,
       "mview_TAD4D_adm_vendor".vendor_name           vendor_name,
       "mview_TAD4D_adm_component".component_name     component_name,
       "mview_TAD4D_adm_agent".agent_id               agent_id,
       "mview_TAD4D_adm_agent".agent_hostname         agent_hostname,
       "mview_TAD4D_adm_agent".agent_scan_time        scan_time,
       "mview_TAD4D_adm_agent".enviroment             enviroment,
      decode("mview_TAD4D_adm_vendor".vendor_name,'IBM',
         decode("mview_TAD4D_adm_component".is_free_only,1,1,
          decode("mview_TAD4D_adm_prod_inv".stype,'10',1,0))
      ,NULL)                                         isfreeofcharge
from "mview_TAD4D_adm_prod_inv"
     join "mview_TAD4D_adm_agent" 
       on "mview_TAD4D_adm_prod_inv".agent_id
             ="mview_TAD4D_adm_agent".agent_id
           and
           "mview_TAD4D_adm_agent".agent_active=1
     join "mview_TAD4D_adm_swproduct"   
        on "mview_TAD4D_adm_prod_inv".product_id
              ="mview_TAD4D_adm_swproduct".swproduct_id
     join "mview_TAD4D_adm_component"
        on "mview_TAD4D_adm_prod_inv".component_id
              ="mview_TAD4D_adm_component".component_id
     join "mview_TAD4D_adm_vendor"
        on "mview_TAD4D_adm_swproduct".vendor_id
              ="mview_TAD4D_adm_vendor".vendor_id;
grant select on "W5I_TAD4D_software" to "W5I";
create or replace synonym W5I.TAD4D_software 
   for "W5I_TAD4D_software";
