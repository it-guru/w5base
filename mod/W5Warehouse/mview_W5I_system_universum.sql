-- drop materialized view "mview_W5I_system_universum";
create materialized view "mview_W5I_system_universum" 
  refresh complete start with sysdate
  next trunc(sysdate+1)+6/24
  as
select distinct sysmapped.*,
       w5_costelement.name w5costelement,
       am_costelement.name amcostelement,
       w5_costelement.saphier w5saphier,
       am_costelement.saphier amsaphier,
       decode(am_costelement.saphier,NULL,
          decode(w5_costelement.saphier,NULL,'unknown',
             w5_costelement.saphier),
                am_costelement.saphier) saphier,
       "itil::system".cistatusid w5cistatusid,
       "itil::system".cistatus  w5cistatus,
       "tsacinv::system".status amstatus,
       "tsacinv::system".type   amtype,
       "tsacinv::system".nature amnature,
       "tsacinv::system".model  ammodel,
       "tsacinv::system".usage  amusage,
       replace(sysmapped.systemid || '-' || sysmapped.systemname,' ','_') id
from  (
   with
   w5sys as (select name                          systemname,
                    upper(systemid)               systemid,
                    conumber                      conumber,
                    id                            id
             from "itil::system"
             where cistatusid=4),
   amsys as (select lower(systemname)             systemname,
                    systemid                      systemid,
                    conumber                      conumber
             from "tsacinv::system"
             where status='in operation')


      select substr(sysbase.systemname,0,255) systemname,
             upper(sysbase.systemid) systemid,
             decode(w5sysbysysid.id,
                    NULL,decode(w5sysbyname.id,NULL,0,
                                1),1) is_w5,
             w5sysbysysid.id
                 w5baseid,
             decode(amsysbysysid.systemid,
                    NULL,decode(amsysbyname.systemid,NULL,0,
                                1),1) is_am,
             decode(amsysbysysid.systemid,
                    NULL,decode(amsysbyname.systemid,NULL,NULL,
                                amsysbyname.systemid),
                    amsysbysysid.systemid) amsystemid,
             '0'  is_t4dp,
             ' ' t4dpsystemid,
             ' ' t4dpcomputer_sys_id
      from (
         select w5sys.systemname,w5sys.systemid from w5sys
         union
         select amsys.systemname,amsys.systemid from amsys
      ) sysbase
     left outer join w5sys w5sysbyname
             on sysbase.systemname=w5sysbyname.systemname
        left outer join w5sys w5sysbysysid
             on sysbase.systemid=w5sysbysysid.systemid

        left outer join amsys amsysbyname
             on upper(sysbase.systemname)=amsysbyname.systemname
        left outer join amsys amsysbysysid
             on sysbase.systemid=amsysbysysid.systemid
   ) sysmapped
   left outer join "itil::system"
        on sysmapped.w5baseid="itil::system".id
   left outer join "tsacinv::system"
        on sysmapped.amsystemid="tsacinv::system".systemid

   left outer join "mview_W5I_ACT_costelement" w5_costelement
        on "itil::system".conumber=w5_costelement.sapname
   left outer join "W5I_ACT_costelement" am_costelement
        on "tsacinv::system".conumber=am_costelement.shortname;

CREATE INDEX "mview_W5I_system_universum_i"
   ON "mview_W5I_system_universum" (id) online;

CREATE INDEX "mview_W5I_system_universum_i0"
   ON "mview_W5I_system_universum" (systemid) online;

CREATE INDEX "mview_W5I_system_universum_i1"
   ON "mview_W5I_system_universum" (systemname) online;

CREATE INDEX "mview_W5I_system_universum_i2"
   ON "mview_W5I_system_universum" (saphier) online;

create or replace view "W5I_system_universum" as
select * from "mview_W5I_system_universum";


