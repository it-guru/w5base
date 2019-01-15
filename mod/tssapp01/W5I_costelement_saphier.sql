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
) costelement;


create or replace view "W5I_tssapp01::costcenter" as
  select 
    rowid                            w5id,
    "W5_key"                         w5name,
    "C03_company_code"               w5accarea,
    "C02_description"                w5description,
    'C04_cost_center_type'           w5etype,
    "C05_supervisor"                 w5responsiblewiw,
(decode("C09_hierarchy_TSI_ID",NULL,'-',"C09_hierarchy_TSI_ID")||'.'||decode("C11_hierarchy_ESS_BSS_ID",NULL,'-',"C11_hierarchy_ESS_BSS_ID")||'.'||decode("C13_hierarchy_ITO_SSM_ID",NULL,'-',"C13_hierarchy_ITO_SSM_ID")||'.'||decode("C15_hierarchy_SL_IL_ID",NULL,'-',"C15_hierarchy_SL_IL_ID")||'.'||decode("C17_business_center_ID",NULL,'-',"C17_business_center_ID")||'.'||decode("C19_customer_center_ID",NULL,'-',"C19_customer_center_ID")||'.'||decode("C21_customer_team_ID",NULL,'-',"C21_customer_team_ID")||'.'||decode("C23_customer_office_ID",NULL,'-',"C23_customer_office_ID")||'.'||decode("C25_hierarchy_9_ID",NULL,'-',"C25_hierarchy_9_ID")||'.'||decode("C27_hierarchy_10_ID",NULL,'-',"C27_hierarchy_10_ID")) as saphier,
    "C09_hierarchy_TSI_ID"           saphier1,
    "C11_hierarchy_ESS_BSS_ID"       saphier2,
    "C13_hierarchy_ITO_SSM_ID"       saphier3,
    "C15_hierarchy_SL_IL_ID"         saphier4,
    "C17_business_center_ID"         saphier5,
    "C19_customer_center_ID"         saphier6,
    "C21_customer_team_ID"           saphier7,
    "C23_customer_office_ID"         saphier8,
    "C25_hierarchy_9_ID"             saphier9,
    "C27_hierarchy_10_ID"            saphier10,
    "W5_cdate"                       w5createdate,
    "W5_mdate"                       w5modifydate,
    'P01DE'                          w5srcsys,
    "W5_key"                         w5srcid
  from w5ftpgw1."w5sapp01_P01DE_kostl_h";

grant select on "W5I_tssapp01::costcenter" to W5I;
create or replace synonym W5I."tssapp01::costcenter" for "W5I_tssapp01::costcenter";


create or replace view "W5I_tssapp01::psp" as
  select 
    rowid                            w5id,
    "W5_key"                         w5name,
    "C04_company_code"               w5accarea,
    "C03_description"                w5description,
    ''                               w5etype,
    "C07_delete"                     isdeleted,
    "C08_status"                     status,
    "C10_supervisor_wiw"             w5responsiblewiw,
    "C13_customer_ID"                sapcustomer,
(decode("C19_hierarchy_TSI_ID",NULL,'-',"C19_hierarchy_TSI_ID")||'.'||decode("C21_hierarchy_ESS_BSS_ID",NULL,'-',"C21_hierarchy_ESS_BSS_ID")||'.'||decode("C23_hierarchy_ITO_SSM_ID",NULL,'-',"C23_hierarchy_ITO_SSM_ID")||'.'||decode("C25_hierarchy_BB_1_ID",NULL,'-',"C25_hierarchy_BB_1_ID")||'.'||decode("C27_business_center_ID",NULL,'-',"C27_business_center_ID")||'.'||decode("C29_customer_center_ID",NULL,'-',"C29_customer_center_ID")||'.'||decode("C31_customer_team_ID",NULL,'-',"C31_customer_team_ID")||'.'||decode("C33_customer_office_ID",NULL,'-',"C33_customer_office_ID")||'.'||decode("C35_hierarchy_9_ID",NULL,'-',"C35_hierarchy_9_ID")||'.'||decode("C37_hierarchy_10_ID",NULL,'-',"C37_hierarchy_10_ID")) as saphier,
    "C19_hierarchy_TSI_ID"           saphier1,
    "C21_hierarchy_ESS_BSS_ID"       saphier2,
    "C23_hierarchy_ITO_SSM_ID"       saphier3,
    "C25_hierarchy_BB_1_ID"          saphier4,
    "C27_business_center_ID"         saphier5,
    "C29_customer_center_ID"         saphier6,
    "C31_customer_team_ID"           saphier7,
    "C33_customer_office_ID"         saphier8,
    "C35_hierarchy_9_ID"             saphier9,
    "C37_hierarchy_10_ID"            saphier10,
    "C47_Business_Prozess_Informati" bpmark,
    "C48_ICTO_Nummer"                ictono,
    "W5_cdate"                       w5createdate,
    "W5_mdate"                       w5modifydate,
    'P01DE'                          w5srcsys,
    "W5_key"                         w5srcid
  from w5ftpgw1."w5sapp01_P01DE_order_hier";

grant select on "W5I_tssapp01::psp" to W5I;
create or replace synonym W5I."tssapp01::psp" for "W5I_tssapp01::psp";




