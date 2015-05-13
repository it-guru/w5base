-- drop table "W5I_TAD4Dsup__stat";
create table "W5I_TAD4Dsup__stat" (
   statdate            varchar2(8) not null,
   sdata_container     clob,
   modifydate          date,
   constraint "W5I_TAD4Dsup__stat_pk" primary key (statdate)
);

alter table "W5I_TAD4Dsup__stat" add (total_cnt number(*));
alter table "W5I_TAD4Dsup__stat" add (telit_cnt number(*));

CREATE OR REPLACE PROCEDURE "W5I_TAD4Dsup__stat_proc" 
   AUTHID CURRENT_USER IS 
BEGIN 
   delete from "W5I_TAD4Dsup__stat" where TO_CHAR(sysdate, 'YYYYMMDD')=statdate;
   insert into "W5I_TAD4Dsup__stat" (statdate,modifydate,
                                     total_cnt,
                                     telit_cnt
      )
      with
      totalsys as (
        select *
        from "W5I_TAD4Dsup__system"
        where cenv<>'None'
      ),
      telitsys as (
        select *
        from "W5I_TAD4Dsup__system"
        where saphier='9TS_ES.9DTIT' or saphier like '9TS_ES.9DTIT.%'
      )
      select TO_CHAR(sysdate, 'YYYYMMDD'),
             sysdate,
             (select count(*) from totalsys) total_cnt,
             (select count(*) from telitsys) telit_cnt
      from dual;
END "W5I_TAD4Dsup__stat_proc";

CREATE OR REPLACE PROCEDURE "W5I_TAD4Dsup__stat_proc" 
   AUTHID CURRENT_USER IS 
BEGIN 
   delete from "W5I_TAD4Dsup__stat" where TO_CHAR(sysdate, 'YYYYMMDD')=statdate;
   insert into "W5I_TAD4Dsup__stat" (statdate,modifydate,sdata_container)
      select TO_CHAR(sysdate, 'YYYYMMDD') statdate,
             sysdate modifydate,
             (
              select listagg(label||'='''||value||'''='||label,chr(10))
                     within group (order by label) metric
              from (
                 with
                 totalsys as (
                   select *
                   from "W5I_TAD4Dsup__system"
                   where cenv<>'None'
                 ),
                 telitsys as (
                   select *
                   from "W5I_TAD4Dsup__system"
                   where (saphier='9TS_ES.9DTIT' or 
                          saphier like '9TS_ES.9DTIT.%')
                 )
                 select
                    'totalsys.count'                                      label,
                    (select count(*) from totalsys)                       value
                 from dual
                 union all
                 select 'totalsys.cur.'||
                        lower(decode(cenv,
                                     null,'empty',
                              cenv)||'.count')                            label,
                        count(*)                                          value
                 from totalsys 
                 where denv<>'OUT' 
                 group by cenv
                 union all
                 select 'totalsys.dst.'||
                        lower(decode(denv,
                                     null,'empty',
                              denv)||'.count')                            label,
                        count(*)                                          value 
                 from totalsys group by denv
                 union all
                 select 'totalsys.status.'||
                        replace(lower(decode(agent_status,
                                     null,'empty',
                              agent_status)||'.count'),' ','_')           label,
                        count(*)                                          value
                 from totalsys
                 where denv<>'OUT'
                 group by agent_status
                 union all
                 select 'totalsys.agentversion.'||
                        replace(lower(decode(agent_version,
                                     null,'empty',
                              agent_version)),'.','_')||'.count'          label,
                        count(*)                                          value
                 from  totalsys
                 where denv<>'OUT'
                 group by agent_version
                 union all
                 select
                    'telitsys.count'                                      label,
                    (select count(*) from telitsys
                     where  denv<>'OUT'    )                              value
                 from dual
                 union all
                 select 'telitsys.cur.'||
                        lower(decode(cenv,
                                     null,'empty',
                              cenv)||'.count')                            label,
                        count(*)                                          value
                 from telitsys 
                 where denv<>'OUT' 
                 group by cenv
                 union all
                 select 'telitsys.dst.'||
                        lower(decode(denv,
                                     null,'empty',
                              denv)||'.count')                            label,
                        count(*)                                          value 
                 from telitsys group by denv
                 union all
                 select 'telitsys.status.'||
                        replace(lower(decode(agent_status,
                                     null,'empty',
                              agent_status)||'.count'),' ','_')           label,
                        count(*)                                          value
                 from telitsys
                 where denv<>'OUT'
                 group by agent_status
                 union all
                 select 'telitsys.agentversion.'||
                        replace(lower(decode(agent_version,
                                     null,'empty',
                              agent_version)),'.','_')||'.count'          label,
                        count(*)                                          value
                 from  telitsys
                 where denv<>'OUT'
                 group by agent_version
              ) metrics
             ) sdata_container
      from dual;
END "W5I_TAD4Dsup__stat_proc";


begin 
 "W5I_TAD4Dsup__stat_proc"; 
end; 

begin 
   DBMS_SCHEDULER.CREATE_JOB ( 
      job_name             => 'W5I_TAD4Dsup__stat_job', 
      job_type             => 'PLSQL_BLOCK', 
      job_action           => 'begin "W5I_TAD4Dsup__stat_proc"; end;', 
      start_date           => SYSTIMESTAMP, 
      repeat_interval      => 'FREQ=DAILY', 
      end_date             => NULL, 
      enabled              => TRUE, 
      comments             => 'taeglicher Backup Job fuer overflow tables');
end;




