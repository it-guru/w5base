create materialized view "W5I_costelement_saphier"
   refresh complete start with sysdate
   next sysdate+(1/24)*4
   as
select "ID","SAPNAME","NAME","SHORTNAME",
       "BPMARK","SAPHIER","COTYPE","OFIENTITY" from (

   select "tssapp01::psp".id ID,
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
   select id ID,
          name SAPNAME,
          REGEXP_REPLACE(name,'^0+','') NAME,
          REGEXP_REPLACE(name,'^0+','') SHORTNAME,
          saphier SAPHIER,
          '-none-' BPMARK,
          'costcenter' COTYPE,
          NULL RAWOFIENTITY,
          NULL OFIENTITY
   from "tssapp01::costcenter"
) costelement

