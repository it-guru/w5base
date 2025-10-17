drop materialized view "mview_W5I_ApplExtOperationUser";
create materialized view "mview_W5I_ApplExtOperationUser"
   refresh complete start with sysdate
   next sysdate+(1/24)*2
   as
with 
appl as (
   select id        w5baseid,
          applid    applid,
          name      name,
          applmgrid,tsmid,tsm2id,opmid,opm2id,
          contacts,businessteamid
   from "itil::appl" appl where cistatusid<6 and cistatusid>1
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
), r as (
   select appl.w5baseid,contact.targetid,contact.target,role.*
   from appl,
     XMLTable('//struct/entry'
         PASSING XMLType(contacts)
         COLUMNS 
           targetid    NUMBER(38)    PATH 'targetid/text()',
           target      VARCHAR2(40)  PATH 'target/text()',
           rolesxml    XmlType       PATH 'roles'
     ) contact,
     XMLTable('/roles'
         PASSING contact.rolesxml
         COLUMNS role VARCHAR2(40) PATH '/roles'
     ) role
   where appl.contacts is not null
)
select W5BASEID ID,APPLID,NAME,USERID,EMAIL,DSID,POSIX,
       max(ACCESSLEVEL) ACCESSLEVEL from (
    select appl.w5baseid,applid,name,
           roleusr."USERID",roleusr."EMAIL",roleusr."DSID",roleusr."POSIX", 
           95 ACCESSLEVEL
    from appl
       join r on appl.w5baseid=r.w5baseid
                 and r.target='base::user'
                 and r.role='applmgr2'
       join u roleusr
              on r.targetid=roleusr.userid
  union
    select appl.w5baseid,applid,name,
           roleusr."USERID",roleusr."EMAIL",roleusr."DSID",roleusr."POSIX",
           92 ACCESSLEVEL
    from appl
       join r on appl.w5baseid=r.w5baseid
                 and r.target='base::user'
                 and r.role='techapprove'
       join u roleusr
              on r.targetid=roleusr.userid
  union
    select appl.w5baseid,applid,name,
           roleusr."USERID",roleusr."EMAIL",roleusr."DSID",roleusr."POSIX",
           55 ACCESSLEVEL
    from appl
       join r on appl.w5baseid=r.w5baseid
                 and r.target='base::user'
                 and r.role='techpriv'
       join u roleusr
              on r.targetid=roleusr.userid              
  union
    select appl.w5baseid,applid,name,
           roleusr."USERID",roleusr."EMAIL",roleusr."DSID",roleusr."POSIX",
           36 ACCESSLEVEL
    from appl
       join r on appl.w5baseid=r.w5baseid
                 and r.target='base::user'
                 and r.role='businessemployee'
       join u roleusr
              on r.targetid=roleusr.userid              
  union
    select appl.w5baseid,applid,name,
           applmgr."USERID",applmgr."EMAIL",applmgr."DSID",applmgr."POSIX",
           100 ACCESSLEVEL
    from appl join u applmgr on appl.applmgrid=applmgr.userid
  union
    select appl.w5baseid,applid,name,
           tsm."USERID",tsm."EMAIL",tsm."DSID",tsm."POSIX",
           90 ACCESSLEVEL
    from appl join u tsm on appl.tsmid=tsm.userid
  union
    select appl.w5baseid,applid,name,
           tsm2."USERID",tsm2."EMAIL",tsm2."DSID",tsm2."POSIX",
           85 ACCESSLEVEL
    from appl join u tsm2 on appl.tsm2id=tsm2.userid
  union
    select appl.w5baseid,applid,name,
           opm."USERID",opm."EMAIL",opm."DSID",opm."POSIX",
           70 ACCESSLEVEL
    from appl join u opm on appl.opmid=opm.userid
  union
    select appl.w5baseid,applid,name,
           opm2."USERID",opm2."EMAIL",opm2."DSID",opm2."POSIX",
           65 ACCESSLEVEL
    from appl join u opm2 on appl.opm2id=opm2.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              39 ACCESSLEVEL
    from appl 
       join g on appl.businessteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              38 ACCESSLEVEL
    from appl 
       join g on appl.businessteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss2)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              37 ACCESSLEVEL
    from appl 
       join g on appl.businessteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(REmployee)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              12 ACCESSLEVEL
    from appl 
       join g on appl.businessteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RFreelancer)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
              2 ACCESSLEVEL
    from appl 
       join g on appl.businessteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          g.grpid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RApprentice)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           25 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join u urole on swi.admid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           24 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join u urole on swi.adm2id=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           19 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join g on swi.swteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          swi.swteamid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           18 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join g on swi.swteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          swi.swteamid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RBoss2)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           17 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join g on swi.swteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          swi.swteamid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(REmployee)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           11 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join g on swi.swteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          swi.swteamid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RFreelancer)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
  union
    select appl.w5baseid,appl.applid,appl.name,
           urole."USERID",urole."EMAIL",urole."DSID",urole."POSIX",
           11 ACCESSLEVEL
    from appl 
       join "itil::swinstance" swi on 
          swi.applid=appl.w5baseid and
          swi.cistatusid='4'
       join g on swi.swteamid=g.grpid 
       join "base::lnkgrpuser" lnkgrp on 
          swi.swteamid=lnkgrp.grpid and
          regexp_like(roles,'(^|; )(RApprentice)(;|$)')
       join u urole on
          lnkgrp.userid=urole.userid
) BASELIST group by W5BASEID,APPLID,NAME,USERID,EMAIL,DSID,POSIX;

CREATE INDEX "mview_W5I_ApplExtOperationUser_i1" 
   ON "mview_W5I_ApplExtOperationUser"(ID) online;
CREATE INDEX "mview_W5I_ApplExtOperationUser_i2" 
   ON "mview_W5I_ApplExtOperationUser"(EMAIL) online;
CREATE INDEX "mview_W5I_ApplExtOperationUser_i3" 
   ON "mview_W5I_ApplExtOperationUser"(POSIX) online;

create or replace view "W5I_ApplExtOperationUser" as
select "ID","APPLID","NAME","USERID","EMAIL","DSID","POSIX","ACCESSLEVEL" from "mview_W5I_ApplExtOperationUser";

grant select on "W5I_ApplExtOperationUser" to W5I;
grant select on "W5I_ApplExtOperationUser" to W5I;
create or replace synonym W5I.ApplExtOperationUser for "W5I_ApplExtOperationUser";

