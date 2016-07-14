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
             where status='in operation'),
   t4dsp as (select /*+ materialize */
                 lower(regexp_replace(
                 adm.computer.computer_alias,'\..*$','')) systemname,
                 'tad4dp-' || adm.computer.computer_sys_id tad4d_computer_sys_id,
                 upper(decode(adm.agent.custom_data1,NULL,
                 'tad4d_p_miss',adm.agent.custom_data1))  systemid
             from adm.computer@tad4d join adm.agent@tad4d
                  on adm.computer.computer_sys_id=adm.agent.id),
   t4dsi as (select /*+ materialize */
                 lower(regexp_replace(
                 adm.computer.computer_alias,'\..*$','')) systemname,
                 'tad4di-' || adm.computer.computer_sys_id tad4d_computer_sys_id,
                 upper(decode(adm.agent.custom_data1,NULL,
                 'tad4d_i_miss',adm.agent.custom_data1))  systemid
             from adm.computer@tad4di join adm.agent@tad4di
                  on adm.computer.computer_sys_id=adm.agent.id)

      select substr(sysbase.systemname,0,255) systemname,
             upper(sysbase.systemid) systemid,
             decode(w5sysbysysid.id,
                    NULL,decode(w5sysbyname.id,NULL,0,
                                1),1) is_w5,
             decode(w5sysbysysid.id,
                    NULL,decode(w5sysbyname.id,NULL,NULL,
                                w5sysbyname.id),
                    w5sysbysysid.id) w5baseid,
             decode(amsysbysysid.systemid,
                    NULL,decode(amsysbyname.systemid,NULL,0,
                                1),1) is_am,
             decode(amsysbysysid.systemid,
                    NULL,decode(amsysbyname.systemid,NULL,NULL,
                                amsysbyname.systemid),
                    amsysbysysid.systemid) amsystemid,
             decode(t4dspbysysid.systemid,NULL,
                    decode(t4dspbyname.systemname,NULL,0,1),1) is_t4dp,
             decode(t4dspbysysid.systemid,
                    NULL,decode(t4dspbyname.systemid,NULL,NULL,
                                t4dspbyname.systemid),
                    t4dspbysysid.systemid) t4dpsystemid,
             decode(t4dspbysysid.tad4d_computer_sys_id,
                    NULL,decode(t4dspbyname.tad4d_computer_sys_id,NULL,NULL,
                                t4dspbyname.tad4d_computer_sys_id),
                    t4dspbysysid.tad4d_computer_sys_id) t4dpcomputer_sys_id,
             decode(t4dsibysysid.systemid,NULL,
                    decode(t4dsibyname.systemname,NULL,0,1),1) is_t4di,
             decode(t4dsibysysid.systemid,
                    NULL,decode(t4dsibyname.systemid,NULL,NULL,
                                t4dsibyname.systemid),
                    t4dsibysysid.systemid) t4disystemid,
             decode(t4dsibysysid.tad4d_computer_sys_id,
                    NULL,decode(t4dsibyname.tad4d_computer_sys_id,NULL,NULL,
                                t4dsibyname.tad4d_computer_sys_id),
                    t4dsibysysid.tad4d_computer_sys_id) t4dicomputer_sys_id
      from (
         select w5sys.systemname,w5sys.systemid from w5sys
         union
         select amsys.systemname,amsys.systemid from amsys
         union
         select t4dsp.systemname,t4dsp.systemid from t4dsp
         union
         select t4dsi.systemname,t4dsi.systemid from t4dsi
      ) sysbase
     left outer join w5sys w5sysbyname
             on sysbase.systemname=w5sysbyname.systemname
        left outer join w5sys w5sysbysysid
             on sysbase.systemid=w5sysbysysid.systemid

        left outer join amsys amsysbyname
             on upper(sysbase.systemname)=amsysbyname.systemname
        left outer join amsys amsysbysysid
             on sysbase.systemid=amsysbysysid.systemid

        left outer join t4dsp t4dspbyname
             on upper(sysbase.systemname)=t4dspbyname.systemname
        left outer join t4dsp t4dspbysysid
             on sysbase.systemid=t4dspbysysid.systemid

        left outer join t4dsi t4dsibyname
             on upper(sysbase.systemname)=t4dsibyname.systemname
        left outer join t4dsi t4dsibysysid
             on sysbase.systemid=t4dsibysysid.systemid
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


