-- drop materialized view "mview_W5I_ACT_costelement";
create materialized view "mview_W5I_ACT_costelement"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select "ID","ACCAREA","SAPNAME","NAME","SHORTNAME",
       "BPMARK","SAPHIER","COTYPE","OFIENTITY",
       "RESPONSIBLEWIW" from (
   select cast("W5I_tssapp01::psp".w5id as VARCHAR2(40)) ID,
          "W5I_tssapp01::psp".w5name SAPNAME,
          "W5I_tssapp01::psp".w5name NAME,
          "W5I_tssapp01::psp".w5name SHORTNAME,
          "W5I_tssapp01::psp".saphier SAPHIER,
          "W5I_tssapp01::psp".bpmark BPMARK,
          'psp' COTYPE,
          "W5I_tssapp01::psp".w5accarea ACCAREA,
          cast(NULL as varchar2(40)) RAWOFIENTITY,
          cast(NULL as varchar2(40)) OFIENTITY,
          W5RESPONSIBLEWIW RESPONSIBLEWIW
   from "W5I_tssapp01::psp"
   where isdeleted=0 or isdeleted is null
   
   union   
   
   select cast(w5id as VARCHAR2(40)) ID,
          w5name SAPNAME,
          REGEXP_REPLACE(w5name,'^0+','') NAME,
          REGEXP_REPLACE(w5name,'^0+','') SHORTNAME,
          saphier SAPHIER,
          '-none-' BPMARK,
          'costcenter' COTYPE,
          w5accarea ACCAREA,
          cast(NULL as varchar2(40)) RAWOFIENTITY,
          cast(NULL as varchar2(40)) OFIENTITY,
          W5RESPONSIBLEWIW RESPONSIBLEWIW
   from "W5I_tssapp01::costcenter"
) costelement;

CREATE INDEX "mview_W5I_ACT_costelement_name"
   ON "mview_W5I_ACT_costelement"(sapname) online;



create or replace view "W5I_ACT_costelement" as
select
   "ID",
   "NAME",
   "SHORTNAME",
   "BPMARK",
   "SAPHIER",
   "COTYPE",
   "OFIENTITY",
   "RESPONSIBLEWIW"
from "mview_W5I_ACT_costelement";


-- drop materialized view "mview_W5I_mviewmon";
create materialized view "mview_W5I_mviewmon"
   refresh complete start with sysdate
   next sysdate+(1/24)
   as
select user_mviews.mview_name             name, 
       user_mviews.last_refresh_type      last_refresh_type, 
       user_mviews.last_refresh_date      last_refresh_date, 
       user_mviews.staleness              staleness,
       user_refresh_children.next_date    next_refresh_date,
       user_jobs.failures                 failcount,
       decode(user_jobs.broken,'N',0,1)   is_broken
from user_mviews
     left outer join user_refresh_children
          on  user_mviews.mview_name=user_refresh_children.rname
     left outer join user_jobs
          on user_refresh_children.job=user_jobs.job;
 
create or replace view "W5I_mviewmon" as
select * from "mview_W5I_mviewmon";

grant select on "W5I_mviewmon" to W5I;
create or replace synonym W5I.mviewmon for "W5I_mviewmon";
 
