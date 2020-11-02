create or replace view "W5I_secscan__findingbase" as
select  'OpSha-' || "w5secscan_ShareData"."W5_id"             as id,
        "w5secscan_ShareData"."W5_isdel"                      as isdel,
        "w5secscan_ShareData"."C01_SecToken"                  as sectoken,
        "w5secscan_ShareData"."C05_SecItem"                   as secitem,
        TO_DATE("w5secscan_ShareData"."C02_ScanDate",
                'YYYY-MM-DD HH24:MI:SS')                      as fndscandate,
        "w5secscan_ShareData"."W5_cdate"                      as fndcdate,
        "w5secscan_ShareData"."W5_mdate"                      as fndmdate,
        LOWER(REPLACE(REGEXP_SUBSTR(
              "w5secscan_ShareData"."C03_HostName",
              '^.*?\.'),'.',''))                              as hostname,
        "W5FTPGW1"."w5secscan_ShareData"."C03_HostName"       as fqdns,
        "w5secscan_ComputerIP"."C02_IPAddress"                as ipaddr,
        'Share=' || "w5secscan_ShareData"."C06_ShareName" || 
         chr(13) ||
        'Items=' || "w5secscan_ShareData"."C08_foundItems"    as detailspec
from "W5FTPGW1"."w5secscan_ShareData"
   join "W5FTPGW1"."w5secscan_ComputerIP"
      on "w5secscan_ComputerIP"."C01_NetComputer"=
         "w5secscan_ShareData"."C03_HostName";


create table "W5I_secscan__finding_of" (
   refid               varchar2(80) not null,
   comments            varchar2(4000),execptionperm varchar2(4000),
   wfhandeled          number(*,0) default '0',
   wfref               varchar2(256),
   respemail           varchar2(128),
   modifyuser          number(*,0),
   modifydate          date,
   constraint "W5I_secscan_finding_of_pk" primary key (refid)
);

grant select,update,insert on "W5I_secscan__finding_of" to W5I;
create or replace synonym W5I.secscan_finding_of for "W5I_secscan__finding_of";


create or replace view "W5I_secscan__finding" as
select "W5I_secscan__findingbase".id,
       "W5I_secscan__findingbase".isdel,
       "W5I_secscan__findingbase".sectoken,
       "W5I_secscan__findingbase".secitem,
       "W5I_secscan__findingbase".fndscandate,
       "W5I_secscan__findingbase".fndcdate,
       "W5I_secscan__findingbase".fndmdate,
       "W5I_secscan__findingbase".hostname,
       "W5I_secscan__findingbase".fqdns,
       "W5I_secscan__findingbase".ipaddr,
       "W5I_secscan__findingbase".detailspec,
       "W5I_secscan__finding_of".refid of_id,
       "W5I_secscan__finding_of".comments,
       decode("W5I_secscan__finding_of".wfhandeled,
              NULL,'0',"W5I_secscan__finding_of".wfhandeled) wfhandeled,
       "W5I_secscan__finding_of".wfref,
       "W5I_secscan__finding_of".respemail,
       "W5I_secscan__finding_of".modifyuser,
       "W5I_secscan__finding_of".modifydate
from "W5I_secscan__findingbase"
     left outer join "W5I_secscan__finding_of"
        on "W5I_secscan__findingbase".keyid=
           "W5I_secscan__finding_of".refid;


grant select on "W5I_secscan__finding" to W5I;
create or replace synonym W5I.secscan__finding for "W5I_secscan__finding";


CREATE OR REPLACE PROCEDURE secscan_cleanup
   AUTHID CURRENT_USER IS
begin
   delete from "W5FTPGW1"."w5secscan_ShareData" 
   where "W5_isdel"='1' and "W5_mdate"<current_date-180;
   -- overflow cleanup
   delete from "W5I_secscan__finding_of" 
   where "W5I_secscan__finding_of".refid in (
      select "W5I_secscan__finding_of".refid
      from "W5I_secscan__finding_of" 
         left outer join "W5I_secscan__findingbase" 
           on "W5I_secscan__finding_of".refid="W5I_secscan__findingbase".keyid
      where "W5I_secscan__findingbase".id is null
);
end;
/


BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name             => 'secscan_cleanup_job',
      job_type             => 'PLSQL_BLOCK',
      job_action           => 'begin secscan_cleanup; end;',
      start_date           => SYSTIMESTAMP,
      repeat_interval      => 'FREQ=DAILY; BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN',
      end_date             => NULL,
      enabled              => TRUE,
      comments             => 'taeglicher cleanup for secscans');
END;
/



