drop materialized view "mview_W5I_SystemExtOperationUser";
create materialized view "mview_W5I_SystemExtOperationUser"
   refresh complete start with sysdate
   next sysdate+(1/24)*2
   as
with 
swinstancerunnodes as (
   select "itil::swinstance".id swinstanceid,
          "itil::system".id systemid, 
          "itil::system".name systemname
   from  "itil::swinstance" 
     join "itil::lnkitclustsvc" 
        on "itil::swinstance".itclustsid="itil::lnkitclustsvc".id
     join "itil::itclust" 
        on "itil::lnkitclustsvc".clustid="itil::itclust".id
     join "itil::system" 
        on "itil::itclust".id="itil::system".itclustid
     left outer join "itil::lnkitclustsvcsyspolicy"
        on "itil::lnkitclustsvc".id="itil::lnkitclustsvcsyspolicy".itclustsvcid
        and "itil::system".id="itil::lnkitclustsvcsyspolicy".syssystemid
   where "itil::itclust".cistatusid=4
     and "itil::system".cistatusid<6
     and nvl2("itil::lnkitclustsvcsyspolicy".runpolicy,
               regexp_substr("itil::lnkitclustsvcsyspolicy".runpolicy,
               '[a-z]+'),"itil::itclust".defrunpolicy)='allow'
union
   select "itil::swinstance".id swinstanceid, 
     "itil::system".id systemid,
     "itil::system".name systemname
   from "itil::swinstance"
     join "itil::system" 
        on "itil::swinstance".systemid="itil::system".id
  where "itil::system".cistatusid<6
), system as (
   select id            w5baseid,
          systemid      systemid,
          name          name,
          admid,adm2id,
          adminteamid
   from "itil::system" system where cistatusid<6 and cistatusid>1
), u as (
   select "base::user".userid,
          "base::useremail".email,
          "base::user".dsid,
          "base::user".posix
   from "base::user"
       join "base::useremail" 
          on "base::user".userid="base::useremail".userid and
             "base::useremail".cistatusid='4'
   where "base::user".cistatusid=4
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
  union
    select  system.id w5baseid,system.systemid,system.name,
            SWInstanceAcl.userid,SWInstanceAcl.email,
            SWInstanceAcl.dsid,SWInstanceAcl.posix,
            CASE when SWInstanceAcl.accesslevel>50 then 50
                 else SWInstanceAcl.accesslevel
            END accesslevel
    from "itil::system" system
       join swinstancerunnodes
          on system.id=swinstancerunnodes.systemid
       join "mview_W5I_SWInstanceExtOperationUser" SWInstanceAcl
            on SWInstanceAcl.id=swinstancerunnodes.swinstanceid
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



