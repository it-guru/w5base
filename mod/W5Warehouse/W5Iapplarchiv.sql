create table "W5I_applarchive" (
 id                   Number(*,0) not null,
 archivestamp         VARCHAR2(15) not null,
 name                 VARCHAR2(128),
 cistatusid           Number(*,0),
 mandatorname         VARCHAR2(128),
 mandatorgrpname      VARCHAR2(128), 
 businessteam         VARCHAR2(128),
 itemsummary          CLOB,
 snapdate             Date,
 archivedate          Date,
 constraint "W5I_applarchive_pk" primary key (id,archivestamp)
);

CREATE INDEX "W5I_applarchive_i0"
   ON "W5I_applarchive" (name) online;

CREATE INDEX "W5I_applarchive_i1"
   ON "W5I_applarchive" (mandatorgrpname,archivestamp) online;

CREATE OR REPLACE PROCEDURE W5I_applarchive_prog
   AUTHID CURRENT_USER IS 
begin
   MERGE into "W5I_applarchive" x
   USING (
     select "tscddwh::appl".id                 id,
             to_char(current_date,'YYYYMM')    archivestamp,
             "tscddwh::appl".name              name,
             "itil::appl".cistatusid           cistatusid,
             "tscddwh::appl".mandator          mandatorname,
             mandatorgrp.fullname              mandatorgrpname,
             businessteamgrp.fullname          businessteam,
             "tscddwh::appl".itemsummary       itemsummary,
             "_tscddwh::appl".W5REPLLASTSUCC   snapdate
      from "tscddwh::appl"
         join "_tscddwh::appl"
            on "tscddwh::appl".id="_tscddwh::appl".refid
         join "itil::appl"
            on "tscddwh::appl".id="itil::appl".id
         join "base::grp" mandatorgrp
            on "tscddwh::appl".mandatorid=mandatorgrp.grpid
         join "base::grp" businessteamgrp
            on "itil::appl".businessteamid=businessteamgrp.grpid
   ) y
   ON (x.archivestamp=y.archivestamp and x.id=y.id)
   WHEN MATCHED THEN
       UPDATE SET x.itemsummary = y.itemsummary,
                  x.mandatorname = y.mandatorname,
                  x.mandatorgrpname = y.mandatorgrpname,
                  x.businessteam = y.businessteam,
                  x.cistatusid = y.cistatusid,
                  x.snapdate = y.snapdate
       WHERE x.snapdate <> y.snapdate OR 
             x.snapdate is null or
             x.businessteam <> y.businessteam OR 
             x.businessteam is null or
             x.mandatorgrpname <> y.mandatorgrpname OR 
             x.mandatorgrpname is null or
             x.mandatorname <> y.mandatorname OR 
             x.mandatorname is null or
             x.cistatusid <> y.cistatusid OR 
             x.cistatusid is null or
             x.name <> y.name or 
             x.name is null
   WHEN NOT MATCHED THEN
       INSERT(x.id,x.archivestamp,
              x.name,x.cistatusid,
              x.mandatorname,x.mandatorgrpname,x.businessteam,
              x.itemsummary,x.snapdate)
       VALUES(y.id,y.archivestamp,
              y.name,y.cistatusid,
              y.mandatorname,y.mandatorgrpname,y.businessteam,
              y.itemsummary,y.snapdate);
end W5I_applarchive_prog;


BEGIN 
   DBMS_SCHEDULER.CREATE_JOB ( 
      job_name             => 'W5I_applarchive_job', 
      job_type             => 'PLSQL_BLOCK', 
      job_action           => 'begin W5I_applarchive_prog; end;', 
      start_date           => SYSTIMESTAMP, 
      repeat_interval      => 'FREQ=DAILY; BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN', 
      end_date             => NULL, 
      enabled              => TRUE, 
      comments             => 'taeglicher Archiv Job fuer itemsummary'); 

   DBMS_SCHEDULER.ADD_JOB_EMAIL_NOTIFICATION ( 
      job_name              =>  'W5I_applarchive_job', 
      recipients            =>  'hartmut.vogler@t-systems.com', 
      sender                =>  'do_not_reply@pW5Repo.telekom.de', 
      subject               =>  'Scheduler Job ' ||
                            'Notification-%job_owner%.%job_name%-%event_type%', 
      body                  =>  '%event_type% occurred at ' ||
                                '%event_timestamp%. %error_message%', 
      events                =>  'JOB_FAILED, JOB_BROKEN, JOB_DISABLED, ' ||
                            'JOB_SCH_LIM_REACHED, JOB_STARTED, JOB_SUCCEEDED');
   
END;

grant select on "W5I_applarchive" to W5I;
create or replace synonym W5I.applarchive for "W5I_applarchive";


