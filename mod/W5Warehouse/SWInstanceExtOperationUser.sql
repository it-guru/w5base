drop materialized view "mview_W5I_SWInstanceExtOperationUser";
create materialized view "mview_W5I_SWInstanceExtOperationUser"
   refresh complete start with sysdate
   next sysdate+(1/24)*2
   as
with 
swinstance as (
   select id            w5baseid,
          swinstanceid  swinstanceid,
          fullname      name,
          applid,
          admid,adm2id,
          swteamid
   from "itil::swinstance" swinstance where cistatusid<6 and cistatusid>1
), u as (
   select userid,email,dsid,posix 
   from "base::user"
   where cistatusid=4
), g as (
   select *
   from "base::grp"
   where cistatusid=4
)
select W5BASEID ID,SWINSTANCEID,NAME,USERID,EMAIL,DSID,POSIX,
       max(ACCESSLEVEL) ACCESSLEVEL from (
    select  swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
            ApplAcl.userid,ApplAcl.email,ApplAcl.dsid,ApplAcl.posix,
            ApplAcl.accesslevel
    from swinstance 
       join "mview_W5I_ApplExtOperationUser" ApplAcl
            on ApplAcl.id=swinstance.applid
  union
    select  swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
            ApplAcl.userid,ApplAcl.email,ApplAcl.dsid,ApplAcl.posix,
            CASE when ApplAcl.accesslevel>50 then 50
                 else ApplAcl.accesslevel
            END accesslevel
    from swinstance 
       join "itil::swinstancerule" swinstancerule
          on swinstance.w5baseid=swinstancerule.swinstanceid
             and swinstancerule.cistatusid=4
             and swinstancerule.rawruletype='RESLNK'
       join "mview_W5I_ApplExtOperationUser" ApplAcl
            on ApplAcl.id=swinstancerule.refid
  union
    select swinstance.w5baseid,swinstanceid,name,
           adm."USERID",adm."EMAIL",adm."DSID",adm."POSIX",
           90 ACCESSLEVEL
    from swinstance join u adm on swinstance.admid=adm.userid
  union
    select swinstance.w5baseid,swinstanceid,name,
           adm2."USERID",adm2."EMAIL",adm2."DSID",adm2."POSIX",
           85 ACCESSLEVEL
    from swinstance join u adm2 on swinstance.adm2id=adm2.userid
  union
    select swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              39 ACCESSLEVEL
    from swinstance
       join g on swinstance.swteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              38 ACCESSLEVEL
    from swinstance
       join g on swinstance.swteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss2)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              37 ACCESSLEVEL
    from swinstance
       join g on swinstance.swteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(REmployee)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              12 ACCESSLEVEL
    from swinstance
       join g on swinstance.swteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RFreelancer)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select swinstance.w5baseid,swinstance.swinstanceid,swinstance.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              2 ACCESSLEVEL
    from swinstance
       join g on swinstance.swteamid=g.grpid
       join "base::lnkgrpuser" lnkgrp on
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RApprentice)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
) BASELIST group by W5BASEID,SWINSTANCEID,NAME,USERID,EMAIL,DSID,POSIX;

CREATE INDEX "mview_W5I_SWInstanceExtOperationUser_i1" 
   ON "mview_W5I_SWInstanceExtOperationUser"(ID) online;
CREATE INDEX "mview_W5I_SWInstanceExtOperationUser_i2" 
   ON "mview_W5I_SWInstanceExtOperationUser"(EMAIL) online;
CREATE INDEX "mview_W5I_SWInstanceExtOperationUser_i3" 
   ON "mview_W5I_SWInstanceExtOperationUser"(POSIX) online;

create or replace view "W5I_SWInstanceExtOperationUser" as
select "ID","SWINSTANCEID","NAME","USERID","EMAIL","DSID","POSIX","ACCESSLEVEL" 
from "mview_W5I_SWInstanceExtOperationUser";

grant select on "W5I_SWInstanceExtOperationUser" to W5I;
grant select on "W5I_SWInstanceExtOperationUser" to W5I;
create or replace synonym W5I.SWInstanceExtOperationUser 
for "W5I_SWInstanceExtOperationUser";



