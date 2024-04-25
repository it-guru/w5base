drop materialized view "mview_W5I_SystemExtOperationUser";
create materialized view "mview_W5I_SystemExtOperationUser"
   refresh complete start with sysdate
   next sysdate+(1/24)*2
   as
with 
system as (
   select id            w5baseid,
          systemid      systemid,
          name          name,
          admid,adm2id,
          adminteamid
   from "itil::system" system where cistatusid<6 and cistatusid>1
), u as (
   select userid,email,dsid,posix 
   from "base::user"
   where cistatusid=4
), g as (
   select *
   from "base::grp"
   where cistatusid=4
)
select W5BASEID ID,SYSTEMID,NAME,USERID,EMAIL,DSID,POSIX,
       max(ACCESSLEVEL) ACCESSLEVEL from (
    select  system.w5baseid,system.systemid,system.name,
            ApplAcl.userid,ApplAcl.email,ApplAcl.dsid,ApplAcl.posix,
            ApplAcl.accesslevel
    from system 
       join "W5I_itil::lnkapplsystem" lnkapplsystem
            on lnkapplsystem.systemid=system.w5baseid
       join "mview_W5I_ApplExtOperationUser" ApplAcl
            on ApplAcl.id=lnkapplsystem.applid
  union
    select system.w5baseid,system.systemid,system.name,
           adm."USERID",adm."EMAIL",adm."DSID",adm."POSIX",
           90 ACCESSLEVEL
    from system join u adm on system.admid=adm.userid
  union
    select system.w5baseid,system.systemid,system.name,
           adm2."USERID",adm2."EMAIL",adm2."DSID",adm2."POSIX",
           85 ACCESSLEVEL
    from system join u adm2 on system.adm2id=adm2.userid
  union
    select system.w5baseid,system.systemid,system.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              39 ACCESSLEVEL
    from system
       join g on system.adminteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select system.w5baseid,system.systemid,system.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              38 ACCESSLEVEL
    from system
       join g on system.adminteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss2)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select system.w5baseid,system.systemid,system.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              37 ACCESSLEVEL
    from system
       join g on system.adminteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(REmployee)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select system.w5baseid,system.systemid,system.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              12 ACCESSLEVEL
    from system
       join g on system.adminteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RFreelancer)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select system.w5baseid,system.systemid,system.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              2 ACCESSLEVEL
    from system
       join g on system.adminteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RApprentice)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
) BASELIST group by W5BASEID,SYSTEMID,NAME,USERID,EMAIL,DSID,POSIX;

CREATE INDEX "mview_W5I_SystemExtOperationUser_i1" 
   ON "mview_W5I_SystemExtOperationUser"(ID) online;
CREATE INDEX "mview_W5I_SystemExtOperationUser_i2" 
   ON "mview_W5I_SystemExtOperationUser"(EMAIL) online;
CREATE INDEX "mview_W5I_SystemExtOperationUser_i3" 
   ON "mview_W5I_SystemExtOperationUser"(POSIX) online;

create or replace view "W5I_SystemExtOperationUser" as
select "ID","SYSTEMID","NAME","USERID","EMAIL","DSID","POSIX","ACCESSLEVEL" 
from "mview_W5I_SystemExtOperationUser";

grant select on "W5I_SystemExtOperationUser" to W5I;
grant select on "W5I_SystemExtOperationUser" to W5I;
create or replace synonym W5I.SystemExtOperationUser 
for "W5I_SystemExtOperationUser";



