create materialized view "mview_W5I_ACT_costelement"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select "ID","SAPNAME","NAME","SHORTNAME",
       "BPMARK","SAPHIER","COTYPE","OFIENTITY" from (
   select cast("tssapp01::psp".id as VARCHAR2(40)) ID,
          "tssapp01::psp".name SAPNAME,
          "tssapp01::psp".name NAME,
          REGEXP_REPLACE("tssapp01::psp".name,'^[a-zA-Z]-','') SHORTNAME,
          "tssapp01::psp".saphier SAPHIER,
          "tssapp01::psp".bpmark BPMARK,
          'psp' COTYPE,
          "tssapp01::psp".rawofientity RAWOFIENTITY,
          "tssapp01::psp".ofientity OFIENTITY
         from (select max(id) id from (
         select id,REGEXP_REPLACE(name,'^[a-zA-Z]-','') SHORTNAME
      from "tssapp01::psp"  where regexp_like(name,'^[a-z]-[a-z0-9]+$','i')
   ) group by shortname) pspid join "tssapp01::psp"
     on pspid.id="tssapp01::psp".id
   
   union

   select "W5I_OFI_wbs_import".objectid     ID,
          "W5I_OFI_wbs_import".name         SAPNAME,
          "W5I_OFI_wbs_import".name         NAME,
          "W5I_OFI_wbs_import".name         SHORTNAME,
          "W5I_OFI_saphier_import".fullname SAPHIER,
          '-none-'                          BPMARK,
          'psp'                             COTYPE,
          "W5I_OFI_wbs_import".name         RAWOFIENTITY,
          "W5I_OFI_wbs_import".name         OFIENTITY
   from "W5I_OFI_wbs_import"
        left outer join "W5I_OFI_saphier_import"
          on "W5I_OFI_wbs_import".saphierid="W5I_OFI_saphier_import".objectid
   where "W5I_OFI_wbs_import".deleted='0'

   union   
   
   select cast(id as VARCHAR2(40)) ID,
          name SAPNAME,
          REGEXP_REPLACE(name,'^0+','') NAME,
          REGEXP_REPLACE(name,'^0+','') SHORTNAME,
          saphier SAPHIER,
          '-none-' BPMARK,
          'costcenter' COTYPE,
          NULL RAWOFIENTITY,
          NULL OFIENTITY
   from "tssapp01::costcenter"
   
   union
 
   select "W5I_OFI_kost_import".objectid     ID,
          "W5I_OFI_kost_import".name         SAPNAME,
          "W5I_OFI_kost_import".name         NAME,
          "W5I_OFI_kost_import".name         SHORTNAME,
          "W5I_OFI_saphier_import".fullname SAPHIER,
          '-none-'                          BPMARK,
          'psp'                             COTYPE,
          "W5I_OFI_kost_import".name        RAWOFIENTITY,
          "W5I_OFI_kost_import".name        OFIENTITY
   from "W5I_OFI_kost_import"
        left outer join "W5I_OFI_saphier_import"
          on "W5I_OFI_kost_import".saphierid="W5I_OFI_saphier_import".objectid
   where "W5I_OFI_kost_import".deleted='0'
  
) costelement

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
   "OFIENTITY" 
from "W5I_costelement_saphier";


