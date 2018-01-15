-- --------------------------------------------------------------------------
-- --------------------- Interface Control Table ----------------------------
-- --------------------------------------------------------------------------

-- drop table "IFACE_ACL";
create table "IFACE_ACL" (
   ifuser       varchar2(33) not null,
   assignment   varchar2(128),
   acctno       varchar2(70),
   customerlnk  varchar2(128)
);
insert into "IFACE_ACL" values('CSS.T-COM','TIT',NULL,NULL);
insert into "IFACE_ACL" values('CSS.T-COM','TIT.%',NULL,NULL);
insert into "IFACE_ACL" (ifuser,acctno) values('CSS.T-COM','8111');
insert into "IFACE_ACL" (ifuser,customerlnk) values('CSS.T-COM','DTAG.TEL-IT');
insert into "IFACE_ACL" (ifuser,customerlnk) values('CSS.T-COM','DTAG.TEL-IT.%');
insert into "IFACE_ACL" values('TEL_IT_DARWIN','TIT',NULL,NULL);
insert into "IFACE_ACL" (ifuser,acctno) values('TEL_IT_DARWIN','8111');



-- --------------------------------------------------------------------------
-- --------------------- iface ----------------------------------------------
-- --------------------------------------------------------------------------
--   Erlaubt es den Schnittstellen-Usern ihre eigenen aktiven ACLs 
--   abzufragen.
-- --------------------------------------------------------------------------
CREATE or REPLACE view iface as
   select * from IFACE_ACL
   WHERE ifuser=sys_context('USERENV', 'SESSION_USER'); 

grant select on iface to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::appl   ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Anwendungs Datensatz wird dadurch eingeschraenkt,
--   dass der Schnittstellen-User ueber die IFACE_ACL entweder den Zugriff
--   auf den Buchungskreis, die Assignmentgroup der Anwendung oder den aus
--   dem Kontierungsobjekt resultierenden Customer-Link haben muss.
--   Es wird sichergestellt, das ueber die View "GENERIC_APPL" wirklich
--   jede Anwendung mit Ihren Kerndaten sichtbar wird, um z.B. Schnittstellen
--   zu Anwendungen aufbauen zu koennen, die man normalerweise nicht 
--   sehen duerfte.
-- --------------------------------------------------------------------------

CREATE or REPLACE view appl_acl as
   select distinct amtsicustappl.code id
   from AM2107.amtsicustappl
      left outer join ( SELECT amcostcenter.*
                        FROM AM2107.amcostcenter
                        WHERE amcostcenter.bdelete = 0) amcostcenter
         on amtsicustappl.lcostcenterid = amcostcenter.lcostid
      left outer join AM2107.amemplgroup assigrp
         on amtsicustappl.lassignmentid = assigrp.lgroupid
      left outer join AM2107.amtsiaccsecunit customerlnk
            on amcostcenter.lcustomerlinkid=customerlnk.lunitid
      join IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
             (assigrp.name like acl.assignment 
                or acl.assignment is null) and
             (amcostcenter.acctno like acl.acctno 
                or acl.acctno is null) and
             (customerlnk.identifier like acl.customerlnk 
                or acl.customerlnk is null) and
            (acl.customerlnk is not null or
             acl.acctno is not null or
             acl.assignment is not null);

CREATE or REPLACE view appl as
   SELECT 
      amtsicustappl.code                             "applid",
      concat(concat(concat(amtsicustappl.name,' ('),
      amtsicustappl.code),')')                       "fullname",
      amtsicustappl.ltsicustapplid                   "id",
      amtsicustappl.name                             "name",
      LOWER ( amtsicustappl.status)                  "status",
      amtsicustappl.bdelete                          "deleted",
      amtsicustappl.usage                            "usage",
      amtsicustappl.businessimpact                   "criticality",
      amtsicustappl.priority                         "customerprio",
      amcostcenter.lcustomerlinkid                   "lcustomerid",
      amtsicustappl.lsecurityunitid                  "lsecunitid",
      amtsicustappl.lincidentagid                    "lincidentagid",
      amtsicustappl.lchangeapprid                    "lchhangeapprid",
      amtsicustappl.lchangeimplid                    "lchhangeimplid",
      amtsicustappl.lservicecontactid                "semid",
      amtsicustappl.ltechnicalcontactid              "tsmid",
      amtsicustappl.ldeputytechnicalcontactid        "tsm2id",
      amtsicustappl.lleaddemid                       "opmid",
      amtsicustappl.ldeputydemid                     "opm2id",
      amtsicustappl.lassignmentid                    "lassignmentid",
      amcostcenter.trimmedtitle                      "conumber",
      amtsicustappl.ref                              "ref",
      amtsicustappl.lcostcenterid                    "lcostid",
      amtsicustappl.version                          "version",
      amtsicustappl.soxrelevant                      "issoxappl",
      businessdesc.memcomment                        "description",
      amtsimaint.memcomment                          "maintwindow",
      amcostcenter.alternatebusinesscenter           "altbc",
      amtsicustappl.dtlastmodif                      "replkeypri",
      lpad ( amtsicustappl.code, 35, '0')            "replkeysec",
      amtsicustappl.dtcreation                       "cdate",
      amtsicustappl.dtlastmodif                      "mdate",
      amtsicustappl.dtlastmodif                      "mdaterev",
      amtsicustappl.externalsystem                   "srcsys",
      amtsicustappl.externalid                       "srcid",
      amtsicustappl.dtimport                         "srcload"
   FROM
      AM2107.amtsicustappl
      join appl_acl on amtsicustappl.code=appl_acl.id
      left outer join ( SELECT amcostcenter.* FROM AM2107.amcostcenter
                        WHERE amcostcenter.bdelete = 0) amcostcenter
         on amtsicustappl.lcostcenterid = amcostcenter.lcostid
      left outer join AM2107.amemplgroup assigrp
         on amtsicustappl.lassignmentid = assigrp.lgroupid
      left outer join AM2107.amcomment amtsimaint
         on amtsicustappl.lmaintwindowid = amtsimaint.lcommentid
      left outer join AM2107.amcomment businessdesc
         on amtsicustappl.lcustbusinessdescid = businessdesc.lcommentid
      left outer join AM2107.amtsiaccsecunit customerlnk
         on amcostcenter.lcustomerlinkid=customerlnk.lunitid;

grant select on appl to public;

CREATE or REPLACE view generic_appl as
   SELECT distinct
      amtsicustappl.code                             "applid",
      concat(concat(concat(amtsicustappl.name,' ('),
      amtsicustappl.code),')')                       "fullname",
      amtsicustappl.ltsicustapplid                   "id",
      amtsicustappl.name                             "name",
      LOWER ( amtsicustappl.status)                  "status",
      amtsicustappl.bdelete                          "deleted",
      amtsicustappl.lassignmentid                    "lassignmentid"
   FROM
      AM2107.amtsicustappl
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

grant select on generic_appl to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::system (pre) ------------------------------
-- --------------------------------------------------------------------------


-- drop materialized view system_acl_l0;
CREATE MATERIALIZED VIEW system_acl_l0
  refresh complete start with trunc(sysdate+1)+5.2/24
  next sysdate+0.125
  as
  select distinct acl.ifuser,amportfolio.assettag id
   from AM2107.amportfolio
      left outer join ( SELECT amcostcenter.*
                        FROM AM2107.amcostcenter
                        WHERE amcostcenter.bdelete = 0) amcostcenter
         on amportfolio.lcostid = amcostcenter.lcostid
      left outer join AM2107.amemplgroup assigrp
         on amportfolio.lassignmentid = assigrp.lgroupid
      left outer join AM2107.amtsiaccsecunit customerlnk
            on amcostcenter.lcustomerlinkid=customerlnk.lunitid
      join IFACE_ACL acl
         on  (assigrp.name like acl.assignment
                or acl.assignment is null) and
             (amcostcenter.acctno like acl.acctno
                or acl.acctno is null) and
             (customerlnk.identifier like acl.customerlnk
                or acl.customerlnk is null) and
            (acl.customerlnk is not null or
             acl.acctno is not null or
             acl.assignment is not null);

CREATE INDEX system_acl_l0_i0
   ON system_acl_l0 (id,ifuser) online;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnksharednet ------------------------------
-- --------------------------------------------------------------------------
-- - Der Zugriff auf die Shared-Network Componenten wird dadurch            -
-- - Eingegrenzt, das nur die Shared-Network Componenten an den fuer den    -
-- - Schnittstellen-User sichtbaren logischen Systeme (und zwar nur die     -
-- - logischen Systeme, die er auch wirklich DIREKT sehen darf) dargestellt -
-- - werden.                                                                -
-- --------------------------------------------------------------------------


-- drop materialized view lnksharednet_acl_l0;
CREATE MATERIALIZED VIEW lnksharednet_acl_l0
  refresh complete start with trunc(sysdate+1)+5.4/24
  next sysdate+0.125
  as
   SELECT distinct TsiParentChild.ltsiparentchildid  AS "netlnkid",
      system_acl_l0.ifuser                           AS "IFUSER",
      TsiParentChild.description                     AS "description",
      systemportfolio.assettag                       AS "systemsystemid",
      netportfolio.assettag                          AS "netsystemid",
      netpartnernature.name                          AS "netnature",
      amcomputer.lcomputerid                         AS "lcomputerid",
      current_date                                   AS "gendate"
   FROM AM2107.amcomputer
      JOIN AM2107.amportfolio systemportfolio 
         ON ( amcomputer.litemid = systemportfolio.lportfolioitemid
              AND systemportfolio.bdelete = '0')
      JOIN ( SELECT amTsiParentChild.ltsiparentchildid,
                    amTsiParentChild.lparentid a,
                    amTsiParentChild.lchildid b,
                    amTsiParentChild.description
                 FROM AM2107.amTsiParentChild
                 WHERE externalsystem = 'Autodiscovery'
             UNION ALL
             SELECT amTsiParentChild.ltsiparentchildid,
                    amTsiParentChild.lchildid a,
                    amTsiParentChild.lparentid b,
                    amTsiParentChild.description
             FROM AM2107.amTsiParentChild
             WHERE externalsystem = 'Autodiscovery'
      ) TsiParentChild 
         ON systemportfolio.lportfolioitemid = TsiParentChild.a
      JOIN AM2107.amportfolio netportfolio 
         ON ( TsiParentChild.b = netportfolio.lportfolioitemid
              AND netportfolio.bdelete = '0')
      JOIN AM2107.amcomputer netcomputer 
         ON ( netcomputer.litemid = netportfolio.lportfolioitemid
         AND netcomputer.status <> 'out of operation')
      JOIN AM2107.amportfolio netpartnerportfolio 
         ON netportfolio.lparentid = netpartnerportfolio.lportfolioitemid
      JOIN AM2107.ammodel netpartnermodel 
         ON netpartnerportfolio.lmodelid = netpartnermodel.lmodelid
      JOIN AM2107.amnature netpartnernature 
         ON netpartnermodel.lnatureid = netpartnernature.lnatureid
      LEFT OUTER JOIN AM2107.amtsirelportfappl 
         ON ( systemportfolio.lportfolioitemid = amtsirelportfappl.lportfolioid
              AND amtsirelportfappl.bdelete = '0')
      JOIN system_acl_l0
         ON systemportfolio.assettag=system_acl_l0.id;

CREATE INDEX lnksharednet_acl_l0_i0
   ON lnksharednet_acl_l0 ("netlnkid") online;
CREATE INDEX lnksharednet_acl_l0_i1
   ON lnksharednet_acl_l0 ("lcomputerid") online;
CREATE INDEX lnksharednet_acl_l0_i2
   ON lnksharednet_acl_l0 ("systemsystemid") online;
CREATE INDEX lnksharednet_acl_l0_i3
   ON lnksharednet_acl_l0 ("netsystemid") online;


CREATE or REPLACE VIEW lnksharednet_acl AS
   select distinct lnksharednet_acl_l0."netlnkid" id
   FROM lnksharednet_acl_l0
   WHERE lnksharednet_acl_l0.ifuser=sys_context('USERENV', 'SESSION_USER'); 

CREATE or REPLACE VIEW lnksharednet AS
   SELECT
      distinct lnksharednet_acl_l0."netlnkid",
      lnksharednet_acl_l0."description",
      amtsicustappl.code                             AS "applid",
      amtsicustappl.name                             AS "applname",
      lnksharednet_acl_l0."systemsystemid",
      systemportfolio.name                           AS "systemname",
      lnksharednet_acl_l0."netsystemid",
      netportfolio.name                              AS "netname",
      lnksharednet_acl_l0."netnature",
      lnksharednet_acl_l0."lcomputerid",
      lnksharednet_acl_l0."gendate"
   FROM lnksharednet_acl_l0
      JOIN lnksharednet_acl
         ON lnksharednet_acl_l0."netlnkid"=lnksharednet_acl.id
      JOIN AM2107.amportfolio netportfolio
         ON lnksharednet_acl_l0."netsystemid" = netportfolio.assettag
      JOIN AM2107.amportfolio systemportfolio
         ON lnksharednet_acl_l0."systemsystemid" = systemportfolio.assettag
      LEFT OUTER JOIN AM2107.amtsirelportfappl 
         ON ( systemportfolio.lportfolioitemid = amtsirelportfappl.lportfolioid
              AND amtsirelportfappl.bdelete = '0')
      LEFT OUTER JOIN AM2107.amtsicustappl 
         ON amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid
   WHERE  lnksharednet_acl_l0."netnature" is not null 
      and lnksharednet_acl_l0."netnature" not in ('SERVER','TERMINAL-SERVER');
   
grant select on lnksharednet to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnkapplsystem -----------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf den Relationsdatensatz zwischen Anwendung und System
--   wird dadurch eingeschraenkt, das der Schnittstellen-User einen
--   Relationsdatensatz dann sieht, wenn er die darin aufgefuehrte
--   Anwendung sehen darf.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW lnkapplsystem_acl AS
   select distinct amtsirelportfappl.lrelportfapplid id
   FROM AM2107.amtsirelportfappl
   JOIN appl
      ON amtsirelportfappl.lapplicationid=appl."id";


CREATE or REPLACE VIEW lnkapplsystem AS
   SELECT
      distinct amtsirelportfappl.lrelportfapplid     AS "id",
      amtsicustappl.code                             AS "applid",
      amportfolio.bdelete                            AS "deleted",
      amtsirelportfappl.bactive                      AS "isactive",
      amtsicustappl.description                      AS "appldescription",
      amtsicustappl.usage                            AS "usage",
      amcostcenter.trimmedtitle                      AS "applconumber",
      amcostcenter.field1                            AS "applcodescription",
      amcostcenter.alternatebusinesscenter           AS "altbc",
      amtsicustappl.lservicecontactid                AS "semid",
      amtsicustappl.ltechnicalcontactid              AS "tsmid",
      amtsicustappl.lincidentagid                    AS "lincidentagid",
      sysamcostcenter.trimmedtitle                   AS "sysconumber",
      sysamcostcenter.field1                         AS "syscodescription",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amcomputer.status                              AS "sysstatus",
      amcomputer.lcpunumber                          AS "systemcpucount",
      amcomputer.lcpuspeedmhz                        AS "systemcpuspeed",
      amcomputer.cputype                             AS "systemcputype",
      amcomputer.lProcCalcSpeed                      AS "systemtpmc",
      amcomputer.lmemorysizemb                       AS "systemmemory",
      amportfolio.name                               AS "child",
      amportfolio.assettag                           AS "systemid",
      amcomputer.olaclasssystem                      AS "systemola",
      amcomputer.status                              AS "systemstatus",
      amtsirelportfappl.description                  AS "comments",
      amportfolio.assettag                           AS "lsystemid",
      amtsirelportfappl.lapplicationid               AS "lparentid",
      amtsirelportfappl.lportfolioid                 AS "lchildid",
      amtsirelportfappl.dtlastmodif                  AS "mdate",
      amtsirelportfappl.externalsystem               AS "srcsys",
      amtsirelportfappl.externalid                   AS "srcid",
      amtsirelportfappl.dtimport                     AS "srcload",
      amtsirelportfappl.dtlastmodif                  AS "replkeypri",
      lpad(amtsirelportfappl.lrelportfapplid,35,'0') AS "replkeysec"
   FROM AM2107.amtsirelportfappl
      JOIN lnkapplsystem_acl
         ON amtsirelportfappl.lrelportfapplid=lnkapplsystem_acl.id
      JOIN AM2107.amportfolio
         ON amtsirelportfappl.lportfolioid = amportfolio.lportfolioitemid
      JOIN AM2107.amcomputer
         ON amportfolio.lportfolioitemid = amcomputer.litemid
      JOIN AM2107.amtsicustappl
         ON amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid
      LEFT OUTER JOIN ( SELECT amcostcenter.*
             FROM AM2107.amcostcenter
             WHERE amcostcenter.bdelete = 0) amcostcenter
         ON amtsicustappl.lcostcenterid = amcostcenter.lcostid
      LEFT OUTER JOIN ( SELECT amcostcenter.*
             FROM AM2107.amcostcenter
             WHERE amcostcenter.bdelete = 0) sysamcostcenter
         ON amportfolio.lcostid = sysamcostcenter.lcostid
   WHERE amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid
      AND amcomputer.status <> 'out of operation';

grant select on lnkapplsystem to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::system ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen logischen System Datensatz wird dadurch
--   eingeschraenkt, dass der Schnittstellen-User ueber die IFACE_ACL
--   entweder den Zugriff auf den Buchungskreis, die Assignmentgroup
--   des logischen Systems oder den aus dem Kontierungsobjekt
--   resultierenden Customer-Link haben muss.
--   Desweiteren werden alle System-Datensaetze sichtbar, die als
--   "shared-Network" Componenten erkannt wurden (1x tgl. ermittelt)
-- --------------------------------------------------------------------------

-- drop materialized view system_acl_l1;
CREATE MATERIALIZED VIEW system_acl_l1
  refresh complete start with trunc(sysdate+1)+5.6/24
  next sysdate+0.125
  as
   select distinct * from (
      select ifuser,"netsystemid" id from lnksharednet_acl_l0
      union
      select ifuser,id from system_acl_l0
      union
      select distinct acl.ifuser ifuser,amportfolio.assettag id
        from AM2107.amtsicustappl
           left outer JOIN ( SELECT amcostcenter.*
                             FROM AM2107.amcostcenter
                             WHERE amcostcenter.bdelete = 0) amcostcenter
              ON amtsicustappl.lcostcenterid = amcostcenter.lcostid
           left outer JOIN AM2107.amemplgroup assigrp
              ON amtsicustappl.lassignmentid = assigrp.lgroupid
           left outer JOIN AM2107.amtsiaccsecunit customerlnk
              ON amcostcenter.lcustomerlinkid=customerlnk.lunitid
           JOIN IFACE_ACL acl
              ON  (assigrp.name like acl.assignment
                     or acl.assignment is null) and
                  (amcostcenter.acctno like acl.acctno
                     or acl.acctno is null) and
                  (customerlnk.identifier like acl.customerlnk
                     or acl.customerlnk is null) and
                 (acl.customerlnk is not null or
                  acl.acctno is not null or
                  acl.assignment is not null)
           JOIN AM2107.amtsirelportfappl
              ON amtsirelportfappl.lapplicationid=amtsicustappl.ltsicustapplid
           JOIN AM2107.amportfolio
              ON amtsirelportfappl.lportfolioid = amportfolio.lportfolioitemid
           JOIN AM2107.amcomputer
              ON amcomputer.litemid = amportfolio.lportfolioitemid
   ) acltable;

CREATE INDEX system_acl_l1_i0
   ON system_acl_l1 (id,ifuser) online;

CREATE INDEX system_acl_l1_i1
   ON system_acl_l1 (ifuser) online;

CREATE or REPLACE VIEW system_acl AS
   select distinct id from 
       system_acl_l1 
   where ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW system AS
   SELECT
      concat(concat(concat(amportfolio.name,' ('),
         amportfolio.assettag),')')                  AS "fullname",
      amportfolio.name                               AS "systemname",
      amportfolio.assettag                           AS "systemid",
      LOWER ( amcomputer.status)                     AS "status",
      assetportfolio.bdelete                         AS "deleted",
      amcostcenter.trimmedtitle                      AS "conumber",
      amcostcenter.customerlink                      AS "customerlink",
      amcostcenter.lcostid                           AS "lcostcenterid",
      amcostcenter.customeroffice                    AS "cocustomeroffice",
      amcostcenter.alternatebusinesscenter           AS "bc",
      decode ( amcostcenter.hier0id,
         '', '-', amcostcenter.hier0id
      ) || '.' || decode ( amcostcenter.hier1id,
         '', '-', amcostcenter.hier1id
      ) || '.' || decode ( amcostcenter.hier2id,
         '', '-', amcostcenter.hier2id
      ) || '.' || decode ( amcostcenter.hier3id,
         '', '-', amcostcenter.hier3id
      ) || '.' || decode ( amcostcenter.hier4id,
         '', '-', amcostcenter.hier4id
      ) || '.' || decode ( amcostcenter.hier5id,
         '', '-', amcostcenter.hier5id
      ) || '.' || decode ( amcostcenter.hier6id,
         '', '-', amcostcenter.hier6id
      ) || '.' || decode ( amcostcenter.hier7id,
         '', '-', amcostcenter.hier7id
      ) || '.' || decode ( amcostcenter.hier8id,
         '', '-', amcostcenter.hier8id
      ) || '.' || decode ( amcostcenter.hier9id,
         '', '-', amcostcenter.hier9id
      )                                              AS "saphier",
      amportfolio.lsupervid                          AS "supervid",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amportfolio.lincidentagid                      AS "lincidentagid",
      amportfolio.controlcenter                      AS "controlcenter",
      amportfolio.controlcenter2                     AS "controlcenter2",
      amportfolio.usage                              AS "usage",
      amcomputer.computertype                        AS "type",
      ammodel.name                                   AS "model",
      amnature.name                                  AS "nature",
      decode (amportfolio.soxrelevant,'YES',1,0)     AS "soxrelevant",
      decode ( amcomputer.addsysname,
         '+VS+','VS',      '+VS++','VS',
         '++VS+','VS',     '+GS+','GS',
         '+GS++','GS',     '++GS+','GS',
         'NONE')                                     AS "securitymodel",
      (select amfvportfolio.valstring
       from AM2107.amfvportfolio
          join AM2107.amfeature
             on amfvportfolio.lfeatid=amfeature.lfeatid
          where amfeature.sqlname like 'TSI_NORSolutionClass'
              and amfvportfolio.lportfolioitemid=
                  amportfolio.lportfolioitemid
      )                                              AS "norsolutionclass",
      amcomputer.addsysname                          AS "altname",
      amportfolio.securityset                        AS "securityset",
      amcomputer.itotalnumberofcores                 AS "systemcpucount",
      amcomputer.fcpunumber                          AS "systeminvoicecpucount",
      amcomputer.lcpuspeedmhz                        AS "systemcpuspeed",
      amcomputer.cputype                             AS "systemcputype",
      amcomputer.lProcCalcSpeed                      AS "systemtpmc",
      amcomputer.lmemorysizemb                       AS "systemmemory",
      amcomputer.virtualization                      AS "virtualization",
      TRIM(amcomputer.operatingsystem)               AS "systemos",
      amcomputer.osservicelevel                      AS "systemospatchlevel",
      amcomputer.psystempartofasset                  AS "partofasset",
      amcomputer.psystempartofasset * 100            AS "nativepartofasset",
      amcomputer.olaclasssystem                      AS "systemola",
      amcomputer.operationcategory                   AS "opcategory",
      amcomputer.seappcom                            AS "systemolaclass",
      decode ( amcomputer.seappcom,
         '0','UNDEFINED',    '4','UNIVERSAL',
         '10','CLASSIC',     '20','STANDARDIZED',
         '25','STANDARDIZED SLICE',
         '30','APPCOM',      '33','DCS',
         amcomputer.seappcom || '???'
      )                                              AS "rawsystemolaclass",
      amportfolio.priority                           AS "priority",
      decode(amportfolio.dtinvent,
            NULL,assetportfolio.dtinvent,
            amportfolio.dtinvent)                    AS "installdate",
      amcomputer.psystempartofasset                  AS "partofassetdec",
      amcomputer.lcomputerid                         AS "lcomputerid",
      amportfolio.lparentid                          AS "lassetid",
      amcomputer.lparentid                           AS "lclusterid",
      amportfolio.lportfolioitemid                   AS "lportfolioitemid",
      amcostcenter.alternatebusinesscenter           AS "altbc",
      amcomputer.servicename                         AS "acmdbcontract",
      amcomputer.slanumber                           AS "acmdbcontractnumber",
      amportfolio.dtinvent                           AS "instdate",
      amcomment.memcomment                           AS "tcomments",
      decode(amtsiautodiscovery.name,NULL,'',
         amtsiautodiscovery.name||' ('||
         amtsiautodiscovery.assettag||') - '||
         amtsiautodiscovery.source)                  AS "autodiscent",
      amportfolio.dtcreation                         AS "cdate",
      amportfolio.dtlastmodif                        AS "mdate",
      amportfolio.dtlastmodif                        AS "mdaterev",
      amportfolio.externalsystem                     AS "srcsys",
      amportfolio.externalid                         AS "srcid",
      amportfolio.dtlastmodif                        AS "replkeypri",
      lpad(amportfolio.assettag,35,'0')              AS "replkeysec"
   FROM
      AM2107.amcomputer
      JOIN AM2107.amportfolio 
         ON amcomputer.litemid = amportfolio.lportfolioitemid
      JOIN system_acl 
         ON amportfolio.assettag=system_acl.id
      JOIN AM2107.amportfolio assetportfolio 
         ON amportfolio.lparentid = assetportfolio.lportfolioitemid
      JOIN AM2107.ammodel 
         ON amportfolio.lmodelid = ammodel.lmodelid
      JOIN AM2107.amnature 
         ON ammodel.lnatureid = amnature.lnatureid
      LEFT OUTER JOIN (
         SELECT amcostcenter.*, amtsiaccsecunit.identifier  customerlink
         FROM AM2107.amcostcenter
            LEFT OUTER JOIN AM2107.amtsiaccsecunit 
               ON amcostcenter.lcustomerlinkid = amtsiaccsecunit.lunitid
         WHERE amcostcenter.bdelete = 0 ) amcostcenter 
         ON amportfolio.lcostid = amcostcenter.lcostid
      LEFT OUTER JOIN AM2107.amcomment 
         ON amcomputer.lcommentid = amcomment.lcommentid
      LEFT OUTER JOIN AM2107.amtsiautodiscovery 
         ON amportfolio.assettag = amtsiautodiscovery.assettag
   WHERE amcomputer.bgroup = 0 AND ammodel.name = 'LOGICAL SYSTEM';

grant select on system to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::ipaddress ---------------------------------
-- --------------------------------------------------------------------------
-- - Der Zugriff auf einen IP-Adressdatensatz wird dadurch eingeschraenkt,  -
-- - das der Datensatz nur dann sichtbar ist, wenn auch das dazugehoerige   -
-- - logische System fuer den Schnittstellen-User sichtbar ist.             -
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW ipaddress_acl AS
   SELECT
      distinct amnetworkcard.lnetworkcardid          id
   FROM AM2107.amnetworkcard
   JOIN system on system."lcomputerid"=amnetworkcard.lcompid;

CREATE or REPLACE VIEW ipaddress AS
   SELECT
      distinct amnetworkcard.lnetworkcardid          "id",
         amnetworkcard.tcpipaddress|| 
         decode(amnetworkcard.tcpipaddress,NULL,'',
         decode(amnetworkcard.ipv6address,NULL,'',
         ', ')) ||amnetworkcard.ipv6address          AS "ipaddress",
      amnetworkcard.tcpipaddress                     AS "ipv4address",
      amnetworkcard.ipv6address                      AS "ipv6address",
      amportfolio.assettag                           AS "systemid",
      amportfolio.name                               AS "systemname",
      amnetworkcard.status                           AS "status",
      amnetworkcard.code                             AS "code",
      amnetworkcard.subnetmask                       AS "netmask",
      amnetworkcard.dnsname                          AS "dnsname",
      amnetworkcard.dnsalias                         AS "dnsalias",
      amnetworkcard.type                             AS "type",
      amnetworkcard.description                      AS "description",
      amnetworkcard.lcompid                          AS "lcomputerid",
      amnetworkcard.laccountnoid                     AS "laccountnoid",
      amnetworkcard.bdelete                          AS "bdelete",
      amnetworkcard.dtlastmodif                      AS "replkeypri",
      lpad (amnetworkcard.lnetworkcardid,35,'0')     AS "replkeysec"
   FROM
      AM2107.amnetworkcard
      JOIN ipaddress_acl 
         ON amnetworkcard.lnetworkcardid=ipaddress_acl.id
      JOIN AM2107.amcomputer 
         ON amcomputer.lcomputerid = amnetworkcard.lcompid 
      JOIN ( SELECT amportfolio.* FROM AM2107.amportfolio
             WHERE amportfolio.bdelete = 0 ) amportfolio
         ON amportfolio.lportfolioitemid = amcomputer.litemid;

grant select on ipaddress to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::accountno ---------------------------------
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW accountno_acl AS
   SELECT amtsiacctno.ltsiacctnoid id
   FROM
      AM2107.amtsiacctno
      join appl
         ON amtsiacctno.lapplicationid=appl."id"
   UNION
   SELECT amtsiacctno.ltsiacctnoid "id"
   FROM
      AM2107.amtsiacctno
      JOIN ipaddress
         ON amtsiacctno.ltsiacctnoid=ipaddress."laccountnoid";

CREATE or REPLACE VIEW accountno AS
   SELECT
      distinct amtsiacctno.ltsiacctnoid              AS "id",
      amtsiacctno.code                               AS "accnoid",
      amtsiacctno.accountno                          AS "name",
      amtsiacctno.ctrlflag                           AS "ctrlflag",
      amcostcenter.trimmedtitle                      AS "conumber",
      amtsiacctno.description                        AS "description",
      amtsiacctno.lapplicationid                     AS "lapplicationid"
   FROM
      AM2107.amtsiacctno 
      LEFT OUTER JOIN (
         SELECT amcostcenter.* FROM AM2107.amcostcenter
         WHERE amcostcenter.bdelete = 0) amcostcenter
         ON amtsiacctno.lcostcenterid = amcostcenter.lcostid
      JOIN accountno_acl
         on amtsiacctno.ltsiacctnoid=accountno_acl.id
   WHERE
      amtsiacctno.bdelete = 0 AND amtsiacctno.ltsiacctnoid <> 0;

grant select on accountno to public;




-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnksharedstorage --------------------------
-- --------------------------------------------------------------------------
--   Die Relationen zwischen logischem System und shared-Storage
--   Componenten stehen jedem Schnittstellen-User zur Verfuegung. 
--   Es wird keine Filterung durchgefuehrt.
-- --------------------------------------------------------------------------

-- drop materialized view lnksharedstorage_acl_l0;
CREATE MATERIALIZED VIEW lnksharedstorage_acl_l0
  refresh complete start with sysdate
  next trunc(sysdate+1)+6/24
  AS
   SELECT
      distinct storageportfolio.assettag             AS "storageassetid",
      storageportfolio.name                          AS "storagename",
      amtsiprovsto.lprovidedstorageid                AS "storageid",
      amcomputer.lcomputerid                         AS "lcomputerid",
      systemportfolio.assettag                       AS "systemsystemid",
      systemportfolio.name                           AS "systemname",
      amtsicustappl.code                             AS "applid",
      amtsicustappl.name                             AS "applname"
   FROM AM2107.amtsiprovsto
      JOIN AM2107.amportfolio storageportfolio
         ON amtsiprovsto.lassetid = storageportfolio.lastid
      JOIN AM2107.amtsiprovstomounts
         ON amtsiprovsto.lprovidedstorageid=
            amtsiprovstomounts.lprovidedstorageid
      JOIN AM2107.amcomputer
         ON amtsiprovstomounts.lcomputerid = amcomputer.lcomputerid
      JOIN AM2107.amportfolio systemportfolio
         ON amcomputer.litemid = systemportfolio.lportfolioitemid
      JOIN AM2107.amtsirelportfappl
         ON systemportfolio.lportfolioitemid = amtsirelportfappl.lportfolioid
      JOIN AM2107.amtsicustappl
         ON amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid
   WHERE amtsiprovsto.bdelete = '0'
      AND amtsiprovstomounts.bdelete = '0'
      AND amtsirelportfappl.bdelete = 0;

CREATE INDEX lnksharedstorage_acl_l0_i0
   ON lnksharedstorage_acl_l0 ("storageassetid") online;
CREATE INDEX lnksharedstorage_acl_l0_i1
   ON lnksharedstorage_acl_l0 ("lcomputerid") online;
CREATE INDEX lnksharedstorage_acl_l0_i2
   ON lnksharedstorage_acl_l0 ("systemsystemid") online;
CREATE INDEX lnksharedstorage_acl_l0_i3
   ON lnksharedstorage_acl_l0 ("applid") online;

CREATE or REPLACE VIEW lnksharedstorage_acl AS
   SELECT distinct "storageassetid" id
   FROM lnksharedstorage_acl_l0
      JOIN system 
         ON lnksharedstorage_acl_l0."lcomputerid"=system."lcomputerid";

CREATE or REPLACE VIEW lnksharedstorage AS
   SELECT lnksharedstorage_acl_l0.*
   FROM lnksharedstorage_acl_l0
   JOIN lnksharedstorage_acl
      ON lnksharedstorage_acl.id=lnksharedstorage_acl_l0."storageassetid";

grant select on lnksharedstorage to public;


CREATE or REPLACE VIEW sharedstorage AS
   SELECT DISTINCT assetportfolio.assettag           AS "assetid",
      amnature.name                                  AS "nature",
      assetportfolio.name||' ('||
         assetportfolio.assettag||' - '||
         amtsiprovsto.code||')'                      AS "fullname",
      assetportfolio.name                            AS "name",
      amtsiprovsto.code                              AS "storagecode",
      amtsiprovsto.lprovidedstorageid                AS "storageid",
      amtsiprovsto.exportname                        AS "exportname",
      amlocation.fullname                            AS "location",
      assetportfolio.place                           AS "place",
      assetportfolio.llocaid                         AS "locationid",
      amtsiprovsto.lassetid                          AS "lassetid"
   FROM AM2107.amtsiprovsto
      JOIN AM2107.amportfolio assetportfolio
         ON amtsiprovsto.lassetid = assetportfolio.lastid
      JOIN AM2107.ammodel
         ON  assetportfolio.lmodelid = ammodel.lmodelid
      LEFT OUTER JOIN AM2107.amnature
         ON ammodel.lnatureid = amnature.lnatureid 
      LEFT OUTER JOIN AM2107.amlocation
         ON assetportfolio.llocaid = amlocation.llocaid
      JOIN lnksharedstorage_acl
         ON lnksharedstorage_acl.id=assetportfolio.assettag
   WHERE amtsiprovsto.bdelete = '0'
      AND amnature.name IN ('DISKSUBSYSTEM','DISKSUBSYSTEM_COMP','NAS-FILER');

grant select on sharedstorage to public;




-- --------------------------------------------------------------------------
-- --------------------- tsacinv::group -------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Assingmentgroup-Datensatz wird dadurch
--   Eingeschraenkt, das der betreffende Schnittstellen-User in der
--   IFACE_ACL aufgefuehrt sein muss. Ist dies der Fall, kann er alle
--   Assignmentgroup Datensaetze abrufen.
-- --------------------------------------------------------------------------

CREATE or replace VIEW grp_acl AS
   SELECT distinct amemplgroup.barcode id
   FROM AM2107.amemplgroup
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER')
   WHERE amemplgroup.lgroupid <> 0;

CREATE or replace VIEW grp AS
   SELECT
      distinct amemplgroup.barcode                   AS "code",
      amemplgroup.lgroupid                           AS "lgroupid",
      amemplgroup.name                               AS "name",
      amemplgroup.name                               AS "fullname",
      amemplgroup.bdelete                            AS "deleted",
      amemplgroup.phone                              AS "phone",
      amemplgroup.lparentid                          AS "parentid",
      amemplgroup.lsupervid                          AS "supervid",
      amemplgroup.lscgroupid                         AS "scgoupid",
      amemplgroup.externalsystem                     AS "srcsys",
      amemplgroup.externalid                         AS "srcid",
      amemplgroup.dtlastmodif                        AS "mdate"
   FROM AM2107.amemplgroup
      JOIN grp_acl
         ON amemplgroup.barcode=grp_acl.id;

grant select on grp to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::user -------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Kontakt-Datensatz wird dadurch
--   Eingeschraenkt, das der betreffende Schnittstellen-User in der
--   IFACE_ACL aufgefuehrt sein muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW usr_acl AS
   select distinct amempldept.lempldeptid id
   FROM AM2107.amempldept
   JOIN IFACE_ACL acl 
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER')
   where amempldept.lempldeptid<>0;

CREATE or REPLACE VIEW usr AS
   SELECT
      distinct amempldept.lempldeptid                AS "lempldeptid",
      amempldept.fullname                            AS "acfullname",
      amempldept.bdelete                             AS "deleted",
      amempldept.userlogin                           AS "loginname",
      amempldept.contactid                           AS "contactid",
      amempldept.name                                AS "name",
      amempldept.firstname                           AS "firstname",
      amempldept.name                                AS "surname",
      amempldept.firstname                           AS "givenname",
      amempldept.email                               AS "email",
      amempldept.ldapid                              AS "ldapid",
      amempldept.idno                                AS "idno",
      amempldept.externeid                           AS "ciamid",
      amempldept.externalsystem                      AS "srcsys",
      amempldept.externalid                          AS "srcid"
   FROM AM2107.amempldept
      JOIN usr_acl 
         on amempldept.lempldeptid=usr_acl.id;

grant select on usr to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnkapplappl ------------------------------
-- --------------------------------------------------------------------------
--   Einen Anwendungsschnittstellen-Datensatz sieht an Schnittstellen-User
--   dann, wenn er die betreffende Parent-Anwendung sieht.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW lnkapplappl_acl AS
   select distinct amtsirelappl.lrelapplid id
   FROM AM2107.amtsirelappl
      JOIN appl
         ON amtsirelappl.lparentid=appl."id";

CREATE or REPLACE VIEW lnkapplappl AS
   SELECT
      amtsirelappl.lrelapplid                        AS "id",
      amtsicustappl.name                             AS "child",
      amtsicustappl.code                             AS "child_applid",
      amtsirelappl.type                              AS "type",
      amtsirelappl.lparentid                         AS "lparentid",
      amtsirelappl.lchildid                          AS "lchildid",
      amtsirelappl.bdelete                           AS "deleted",
      amtsirelappl.dtlastmodif                       AS "mdate",
      amtsirelappl.externalsystem                    AS "srcsys",
      amtsirelappl.externalid                        AS "srcid",
      amtsirelappl.dtlastmodif                       AS "replkeypri",
      lpad ( amtsirelappl.lrelapplid, 35, '0')       AS "replkeysec"
   FROM AM2107.amtsirelappl
      JOIN lnkapplappl_acl
         ON lnkapplappl_acl.id=amtsirelappl.lrelapplid
      JOIN AM2107.amtsicustappl
         ON amtsirelappl.lchildid = amtsicustappl.ltsicustapplid;

grant select on lnkapplappl to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::osrelease ---------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen osrelease-Datensatz wird dadruch eingeschraenkt
--   das der Schnittstellen-User in der IFACE_ACL aufgefuehrt sein muss.
--   Ist dies der Fall, so sieht der Schnittstelle-User ALLE
--   Betriebssystem-Datensaetze.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW osrelease_acl AS
   SELECT distinct amitemlistval.litemlistvalid      AS id
   FROM AM2107.amitemlistval
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW osrelease AS
SELECT
   amitemlistval.litemlistvalid                   AS "id",
   amitemlistval.value                            AS "name",
   amitemlistval.dtlastmodif                      AS "mdate",
   amitemlistval.dtlastmodif                      AS "mdaterev"
FROM AM2107.amitemizedlist
   JOIN AM2107.amitemlistval
      ON amitemizedlist.litemlistid = amitemlistval.litemlistid
   JOIN osrelease_acl
      ON amitemlistval.litemlistvalid=osrelease_acl.id
WHERE amitemizedlist.identifier = 'amOS';

grant select on osrelease to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::asset -------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Asset Datensatz wird dadurch eingeschraenkt, das
--   nur Datensaetze sichtbar sind, bei denen auch min. ein logisches
--   fuer den betreffenden Schnittsttellen-User sichtbar ist.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW asset_acl AS
   SELECT distinct amportfolio.assettag               id
      from AM2107.amportfolio
      JOIN system 
         on amportfolio.lportfolioitemid = system."lassetid";

CREATE or REPLACE VIEW asset AS
   SELECT
      distinct assetportfolio.assettag               AS "assetid",
      LOWER(amasset.status)                          AS "status",
      ammodel.name                                   AS "assetmodel",
      assetportfolio.assettag                        AS "fullname",
      assetportfolio.dtinvent                        AS "install",
      assetportfolio.lassignmentid                   AS "lassignmentid",
      amcostcenter.trimmedtitle                      AS "conumber",
      amcostcenter.lcostid                           AS "lcostcenterid",
      assetportfolio.room                            AS "room",
      assetportfolio.place                           AS "place",
      amasset.cputype                                AS "cputype",
      decode(amasset.lmemorysizemb, 0, NULL, 
             amasset.lmemorysizemb)                  AS "memory",
      decode(amasset.lcpunumber, 0,NULL,
             amasset.lcpunumber)                     AS "cpucount",
      decode(amasset.imaxnumberprocessors, 0,NULL,
             amasset.imaxnumberprocessors)           AS "cpumaxsup",
      decode(amasset.lcpuspeedmhz,0,NULL,
             amasset.lcpuspeedmhz)                   AS "cpuspeed",
      decode(amasset.itotalnumberofcores,0,NULL,
             amasset.itotalnumberofcores)            AS "corecount",
      amasset.serialno                               AS "serialno",
      amasset.inventoryno                            AS "inventoryno",
      amasset.lmaintlevelid                          AS "maintlevelid",
      amasset.seAcquModeTsi                          AS "acqumode",
      amasset.dstartacqu                             AS "startacquisition",
      amasset.mdeprcalc                              AS "mdepr",
      amasset.mmaintrate                             AS "mmaint",
      amasset.maintcond                              AS "maitcond",
      assetportfolio.llocaid                         AS "locationid",
      assetportfolio.lportfolioitemid                AS "lassetid",
      amasset.lastid                                 AS "lassetassetid",
      assetportfolio.lmodelid                        AS "lmodelid",
      assetportfolio.dtlastmodif                     AS "replkeypri",
      lpad(assetportfolio.assettag,35,'0')           AS "replkeysec",
      assetportfolio.bdelete                         AS "deleted",
      assetportfolio.dtcreation                      AS "cdate",
      assetportfolio.dtlastmodif                     AS "mdate",
      assetportfolio.externalsystem                  AS "srcsys",
      assetportfolio.externalid                      AS "srcid"
   FROM AM2107.amasset
      JOIN AM2107.amportfolio assetportfolio
         ON assetportfolio.assettag = amasset.assettag
      JOIN asset_acl
         ON assetportfolio.assettag=asset_acl.id
      JOIN AM2107.ammodel
         ON assetportfolio.lmodelid = ammodel.lmodelid
      LEFT OUTER JOIN AM2107.amlocation
         ON assetportfolio.llocaid = amlocation.llocaid
      LEFT OUTER JOIN ( SELECT amcostcenter.*
            FROM AM2107.amcostcenter
            WHERE amcostcenter.bdelete = 0) amcostcenter
         ON amasset.lsendercostcenterid = amcostcenter.lcostid 
      LEFT OUTER JOIN AM2107.amnature
         ON ammodel.lnatureid = amnature.lnatureid;

grant select on asset to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnkusergroup ------------------------------
-- --------------------------------------------------------------------------
--   Die Relation zwischen User und Assignmentgroup ist dann fuer einen
--   Schnittstellen-User einsehbar, wenn er die zugehorige Assignmentgroup
--   sehen darf.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW lnkusergroup_acl AS
   SELECT
      distinct concat (amrelemplgrp.lgroupid,
         concat ( '-',amrelemplgrp.lempldeptid))     AS id
   FROM
      AM2107.amrelemplgrp
      JOIN grp 
         ON amrelemplgrp.lgroupid=grp."lgroupid";

CREATE or REPLACE VIEW lnkusergroup AS
   SELECT
      distinct concat (amrelemplgrp.lgroupid,
         concat ( '-',amrelemplgrp.lempldeptid))     AS "id",
      amrelemplgrp.lempldeptid                       AS "lempldeptid",
      amrelemplgrp.lgroupid                          AS "lgroupid"
   FROM
      AM2107.amrelemplgrp
      JOIN lnkusergroup_acl 
         ON concat(amrelemplgrp.lgroupid,concat('-',amrelemplgrp.lempldeptid))=
            lnkusergroup_acl.id;

grant select on lnkusergroup to public;

       

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::customer ----------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen CustomerLink-Datensatz wird dadurch
--   Eingeschraenkt, das der betreffende Schnittstellen-User in der
--   IFACE_ACL mit Zugriff auf den bestimmten CustomerLink aufgefuehrt
--   sein muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW customer_acl AS
   SELECT distinct amtsiaccsecunit.lunitid           AS id
   FROM AM2107.amtsiaccsecunit
      JOIN IFACE_ACL acl
         ON acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
             (acl.assignment is null) and
             (acl.acctno is null) and
             (amtsiaccsecunit.identifier like acl.customerlnk 
                or acl.customerlnk is null) and
            (acl.customerlnk is not null or
             acl.acctno is not null or
             acl.assignment is not null);

CREATE or REPLACE VIEW customer AS
   SELECT amtsiaccsecunit.lunitid                    AS "id",
      amtsiaccsecunit.identifier                     AS "name",
      amtsiaccsecunit.description                    AS "fullname",
      amtsiaccsecunit.ldeliverymanagerid             AS "delmgrid",
      amtsiaccsecunit.code                           AS "code",
      amtsiaccsecunit.ldefaultsclocationid           AS "defaultsclocationid",
      amtsiaccsecunit.dtlastmodif                    AS "mdate"
   FROM AM2107.amtsiaccsecunit
      JOIN customer_acl
         ON amtsiaccsecunit.lunitid=customer_acl.id
   WHERE amtsiaccsecunit.lunitid <> 0;

grant select on customer to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::location ----------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Standort-Datensaetze wird dadurch eingefschrankt
--   das der Schnittstellen-User in der IFACE_ACL aufgefuert sein muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW location_acl AS
   SELECT distinct amlocation.llocaid      AS id
   FROM AM2107.amlocation
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW location AS
   SELECT
      distinct amlocation.llocaid                    AS "locationid",
      amlocation.fullname                            AS "fullname",
      amlocation.address1                            AS "address1",
      amlocation.zip                                 AS "zipcode",
      amcountry.isocode                              AS "country",
      amlocation.city                                AS "location",
      amlocation.locationtype                        AS "locationtype",
      amlocation.name                                AS "name",
      amlocation.barcode                             AS "code",
      amlocation.dtlastmodif                         AS "replkeypri",
      lpad(amlocation.llocaid,35,'0')                AS "replkeysec",
      amlocation.dtlastmodif                         AS "mdate"
   FROM AM2107.amlocation
      JOIN location_acl
         ON amlocation.llocaid=location_acl.id
      LEFT OUTER JOIN AM2107.amcountry
         ON amlocation.lcountryid = amcountry.lcountryid
   WHERE amlocation.bdelete = 0 AND amlocation.llocaid > 0
      AND amlocation.llocaid IS NOT NULL AND amlocation.dtlastmodif IS NOT NULL;

grant select on location to public;

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnksystemsoftware -------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Software-Installationsdatensaetze wird dadurch
--   eingeschraenkt, das nur die Software-Installationen sichtbar sind,
--   fuer die auch die betreffenden Systeme sichtbar sind.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW lnksystemsoftware_acl AS
   SELECT
      distinct amportfolio.assettag                  AS id
   from AM2107.amportfolio
      JOIN system 
         ON amportfolio.lparentid=system."lportfolioitemid";

CREATE or REPLACE VIEW lnksystemsoftware AS
   SELECT
      distinct amportfolio.assettag                  AS "id",
      ammodel.name                                   AS "name",
      amsoftinstall.lusecount                        AS "quantity",
      ammodel.versionlevel                           AS "version",
      amsoftinstall.folder                           AS "instpath",
      amportfolio.lparentid                          AS "lparentid",
      amsoftinstall.llicenseid                       AS "llicense",
      amportfolio.dtcreation                         AS "cdate",
      amsoftinstall.dtlastmodif                      AS "mdate"
   FROM AM2107.amportfolio
      JOIN lnksystemsoftware_acl
         ON amportfolio.assettag=lnksystemsoftware_acl.id
      JOIN AM2107.ammodel 
         ON amportfolio.lmodelid = ammodel.lmodelid
      LEFT OUTER JOIN AM2107.amnature
         ON ammodel.lnatureid = amnature.lnatureid 
      JOIN AM2107.amsoftinstall
         ON amportfolio.lportfolioitemid = amsoftinstall.litemid
   WHERE ammodel.certification = 'CSS' AND amnature.name = 'SW-INSTALLATION'
      AND amportfolio.bdelete = 0;

grant select on lnksystemsoftware to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::model -------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Model-Datensaetze wird dadurch eingeschraenkt
--   das der Schnittstellen-User in der IFACE_ACL aufgefuert sein muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW model_acl AS
   SELECT assetmodel.lmodelid                        AS id
   FROM AM2107.ammodel assetmodel
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER')
   WHERE assetmodel.lmodelid<>'0';

CREATE or REPLACE VIEW model AS
   SELECT
      assetmodel.lmodelid                            AS "lmodelid",
      assetmodel.name                                AS "name",
      assetmodel.barcode                             AS "barcode",
      amnature.name                                  AS "nature",
      ambrand.name                                   AS "vendor",
      assetpowerinput.powerinput                     AS "assetpowerinput",
      assetmodel.dtlastmodif                         AS "replkeypri",
      lpad(assetmodel.lmodelid,35,'0')               AS "replkeysec",
      assetmodel.dtlastmodif                         AS "mdate"
   FROM AM2107.ammodel assetmodel
      JOIN model_acl
         ON assetmodel.lmodelid=model_acl.id
      LEFT OUTER JOIN AM2107.amnature
         ON assetmodel.lnatureid = amnature.lnatureid 
      LEFT OUTER JOIN (
            SELECT amfvmodel.fval PowerInput,lmodelid
            FROM AM2107.amfvmodel
               JOIN AM2107.amfeature
                  ON amfvmodel.lfeatid = amfeature.lfeatid
            WHERE amfeature.sqlname = 'PowerInput') assetpowerinput
         ON assetmodel.lmodelid = assetpowerinput.lmodelid
      LEFT OUTER JOIN AM2107.ambrand
         ON assetmodel.lbrandid = ambrand.lbrandid;

grant select on model to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::swinstance --------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Software-Instanz Datensatz wird dadurch
--   eingeschraenkt, dass der betreffende Schnittstellen-User ueber die
--   IFACE_ACL entweder den Zugriff auf den Buchungskreis, die
--   Assignmentgroup der Instanz oder den aus  dem Kontierungsobjekt
--   resultierenden Customer-Link haben muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW swinstance_acl AS
   select distinct amtsiswinstance.lportfolioid   AS id
   FROM AM2107.amtsiswinstance
      JOIN (SELECT amportfolio.* FROM AM2107.amportfolio
             WHERE amportfolio.bdelete = 0) amportfolio
         ON amportfolio.lportfolioitemid = amtsiswinstance.lportfolioid
      left outer join AM2107.amemplgroup assigrp
         on amportfolio.lassignmentid = assigrp.lgroupid
      LEFT OUTER JOIN ( SELECT amcostcenter.* FROM AM2107.amcostcenter
            WHERE amcostcenter.bdelete = 0) amcostcenter
      LEFT OUTER JOIN AM2107.amtsiaccsecunit customerlnk
            on amcostcenter.lcustomerlinkid=customerlnk.lunitid
      ON  amportfolio.lcostid = amcostcenter.lcostid
      join IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
             ( assigrp.name like acl.assignment 
               or acl.assignment is null) and
             (amcostcenter.acctno like acl.acctno 
                or acl.acctno is null) and
             (customerlnk.identifier like acl.customerlnk 
                or acl.customerlnk is null) and
            (acl.customerlnk is not null or
             acl.acctno is not null or
             acl.assignment is not null);

CREATE or REPLACE VIEW swinstance AS
   SELECT
      distinct concat(amportfolio.name,
      concat(' (',concat(amportfolio.assettag, ')')))  AS "fullname",
      concat(amportfolio.name,concat(' (',concat(amportfolio.code,
               ')')))                                AS "scfullname",
      amportfolio.name                               AS "name",
      amportfolio.assettag                           AS "swinstanceid",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amportfolio.lincidentagid                      AS "lincidentagid",
      amcostcenter.trimmedtitle                      AS "conumber",
      amcostcenter.lcostid                           AS "lcostcenterid",
      amcostcenter.alternatebusinesscenter           AS "altbc",
      amtsiswinstance.status                         AS "status",
      amtsiswinstance.monitoringname                 AS "monname",
      amtsiswinstance.lportfolioid                   AS "portfolioid",
      amportfolio.dtlastmodif                        AS "mdate",
      amportfolio.externalsystem                     AS "srcsys",
      amportfolio.externalid                         AS "srcid"
   FROM AM2107.amtsiswinstance
      JOIN swinstance_acl
         ON amtsiswinstance.lportfolioid=swinstance_acl.id
      JOIN (SELECT amportfolio.* FROM AM2107.amportfolio
             WHERE amportfolio.bdelete = 0) amportfolio
         ON amportfolio.lportfolioitemid = amtsiswinstance.lportfolioid
      JOIN AM2107.ammodel
         ON amportfolio.lmodelid = ammodel.lmodelid
      LEFT OUTER JOIN ( SELECT amcostcenter.* FROM AM2107.amcostcenter
            WHERE amcostcenter.bdelete = 0) amcostcenter
         ON  amportfolio.lcostid = amcostcenter.lcostid;

grant select on swinstance to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::sclocation --------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die ServiceCenter Location Datensaetze wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW sclocation_acl AS
   SELECT distinct amtsisclocations.ltsisclocationsid id
   FROM AM2107.amtsisclocations
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW sclocation AS
   SELECT  amtsisclocations.ltsisclocationsid        AS "id",
      amtsisclocations.sclocationname                AS "name",
      amtsisclocations.companytxt                    AS "company",
      amtsisclocations.subcompany                    AS "subcompany",
      amtsisclocations.sclocationid                  AS "sclocationid",
      amtsisclocations.dtlastmodif                   AS "mdate"
   FROM AM2107.amtsisclocations
      JOIN sclocation_acl
         ON amtsisclocations.ltsisclocationsid=sclocation_acl.id
   WHERE amtsisclocations.sclocationid like '1%';

grant select on sclocation to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::autodiscsystem ----------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die logisches System im AutoDiscovery wird dadurch
--   eingeschraenkt das der Schnittstellen-User das betreffende System
--   bereits "sehen" muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW autodiscsystem_acl AS
   SELECT distinct amtsiautodiscovery.lautodiscoveryid id
   FROM AM2107.amtsiautodiscovery
   JOIN system_acl_l1
      ON amtsiautodiscovery.assettag=system_acl_l1.id
         AND system_acl_l1.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW autodiscsystem AS
   SELECT
      amtsiautodiscovery.lautodiscoveryid            AS "systemdiscoveryid",
      amtsiautodiscovery.name                        AS "systemname",
      amtsiautodiscovery.name                        AS "fullname",
      amtsiautodiscovery.assettag                    AS "systemid",
      amtsiautodiscovery.model                       AS "model",
      amtsiautodiscovery.os                          AS "osrelease",
      amtsiautodiscovery.lmemorymb                   AS "memory",
      amtsiautodiscovery.lcpucount                   AS "physcpucount",
      amtsiautodiscovery.cputype                     AS "cputype",
      amtsiautodiscovery.lcpuspeedmhz                AS "cpuspeed",
      amtsiautodiscovery.itotalnumberofcores         AS "independcpucount",
      amtsiautodiscovery.itotalnumberofcores * 
         amtsiautodiscovery.smt                      AS "cpucount",
      amtsiautodiscovery.serialno                    AS "serialno",
      amtsiautodiscovery.dtscandate                  AS "scandate",
      amtsiautodiscovery.source                      AS "srcsys"
   FROM AM2107.amtsiautodiscovery
      JOIN autodiscsystem_acl
         ON amtsiautodiscovery.lautodiscoveryid=autodiscsystem_acl.id;

grant select on autodiscsystem to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::autodiscipaddress -------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die AutoDiscovery IP Daten wird dadurch freigegen,
--   dass der Schnittstellen-User Zugriff auf den betreffenden 
--   Datensatz fuer das AutoDiscovery-Logisches System hat.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW autodiscipaddress_acl AS
   SELECT distinct "systemdiscoveryid" id
   FROM autodiscsystem;

CREATE or REPLACE VIEW autodiscipaddress AS
   SELECT
      amtsiautodiscinterfaces.linterfaceid           AS "id",
      amtsiautodiscinterfaces.ipaddress              AS "address",
      amtsiautodiscinterfaces.physicaladdress        AS "physicaladdress",
      amtsiautodiscinterfaces.lsystemautodiscid      AS "systemautodiscid",
      amtsiautodiscinterfaces.dtscan                 AS "scandate",
      amtsiautodiscinterfaces.source                 AS "srcsys"
   FROM AM2107.amtsiautodiscinterfaces
      JOIN autodiscipaddress_acl
         ON amtsiautodiscinterfaces.lsystemautodiscid=autodiscipaddress_acl.id;

grant select on autodiscipaddress to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::autodiscsoftware --------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die AutoDiscovery Software Daten wird dadurch freigegen,
--   dass der Schnittstellen-User Zugriff auf den betreffenden 
--   Datensatz fuer das AutoDiscovery-Logisches System hat.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW autodiscsoftware_acl AS
   SELECT distinct "systemdiscoveryid" id
   FROM autodiscsystem;

CREATE or REPLACE VIEW autodiscsoftware AS
   SELECT
      amtsiautodiscsw.ladswid                        AS "id",
      amtsiautodiscsw.productname                    AS "software",
      amtsiautodiscsw.manufacturer                   AS "producer",
      amtsiautodiscsw.version                        AS "version",
      amtsiautodiscsw.path                           AS "path",
      amtsiautodiscsw.lautodiscsystemid              AS "systemautodiscid",
      amtsiautodiscsw.dtscan                         AS "scandate",
      amtsiautodiscsw.source                         AS "srcsys"
   FROM AM2107.amtsiautodiscsw
      JOIN autodiscsoftware_acl
         ON amtsiautodiscsw.lautodiscsystemid=autodiscsoftware_acl.id;

grant select on autodiscsoftware to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itfarm ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Serverfarm wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itfarm_acl AS
   SELECT distinct clu.litemid            AS id
   FROM
      AM2107.amcomputer sys
      JOIN AM2107.amportfolio sysportfolio 
         ON sysportfolio.lportfolioitemid = sys.litemid
      JOIN AM2107.amportfolio assportfolio 
         ON assportfolio.Lportfolioitemid = sysportfolio.lparentid
      JOIN AM2107.amasset ass 
         ON assportfolio.assettag = ass.assettag
      JOIN AM2107.amcomputer clu 
         ON sys.lparentid = clu.lcomputerid
      JOIN AM2107.amportfolio cluportfolio 
         ON cluportfolio.assettag = clu.assettag
      JOIN IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER')
   WHERE sysportfolio.usage LIKE 'OSY-_: KONSOLSYSTEM %'
      AND sys.status <> 'out of operation';

CREATE or REPLACE VIEW itfarm AS
   SELECT
      distinct clu.litemid                           AS "lfarmid",
      cluportfolio.name                              AS "name",
      clu.assettag                                   AS "clusterid",
      clu.status                                     AS "status"
   FROM
      AM2107.amcomputer sys
      JOIN AM2107.amportfolio sysportfolio 
         ON sysportfolio.lportfolioitemid = sys.litemid
      JOIN AM2107.amportfolio assportfolio 
         ON assportfolio.Lportfolioitemid = sysportfolio.lparentid
      JOIN AM2107.amasset ass 
         ON assportfolio.assettag = ass.assettag
      JOIN AM2107.amcomputer clu 
         ON sys.lparentid = clu.lcomputerid
      JOIN itfarm_acl
         ON clu.litemid=itfarm_acl.id
      JOIN AM2107.amportfolio cluportfolio 
         ON cluportfolio.assettag = clu.assettag
   WHERE sysportfolio.usage LIKE 'OSY-_: KONSOLSYSTEM %'
      AND sys.status <> 'out of operation';

grant select on itfarm to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::schain ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Serviceketten wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW schain_acl AS
   SELECT distinct amtsisalessrvcpkg.lsrvcpkgid      AS id
   FROM
      AM2107.amtsisalessrvcpkg
      JOIN IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW schain AS
   SELECT amtsisalessrvcpkg.lsrvcpkgid          AS "schainid",
      amtsisalessrvcpkg.code                         AS "code",
      amtsisalessrvcpkg.name                         AS "fullname",
      amcomment.memcomment                           AS "comments",
      amtsisalessrvcpkg.dtlastmodif                  AS "replkeypri",
      lpad(amtsisalessrvcpkg.code,35,'0')            AS "replkeysec",
      amtsisalessrvcpkg.dtlastmodif                  AS "mdate"
   FROM AM2107.amtsisalessrvcpkg
      JOIN schain_acl
         ON amtsisalessrvcpkg.lsrvcpkgid=schain_acl.id
      LEFT OUTER JOIN AM2107.amcomment
         ON amtsisalessrvcpkg.lcommentid=amcomment.lcommentid
   WHERE amtsisalessrvcpkg.bdelete = 0;

grant select on schain to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnkschain ---------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Serviceketten Verknuepfungen wird dadurch
--   eingeschraenkt das der Schnittstellen-User die betreffende Servicekette
--   sehen muss, um den Zugriff auf den Verknuepfungsdatensatz zu bekommen.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW lnkschain_acl AS
   SELECT distinct "schainid" id
   FROM  schain;

CREATE or REPLACE VIEW lnkschain AS
   SELECT
      distinct schainrel.id                          AS "id",
      schainrel.lsspid                               AS "lsspid",
      schainrel.itemid                               AS "itemid",
      schainrel.itemname                             AS "name",
      schainrel.itemclass                            AS "class",
      schainrel.dtlastmodif                          AS "replkeypri",
      lpad(schainrel.lsspid,35,'0')                  AS "replkeysec",
      schainrel.dtlastmodif                          AS "mdate"
   FROM (SELECT
            'P' || amtsirelsspport.LTSIRELSSPPORTID id,
            amtsirelsspport.lsspid lsspid,
            CAST(amportfolio.assettag  AS VARCHAR2 (40))    itemid,
            CAST(amportfolio.name  AS VARCHAR2 (4000))      itemname,
            CAST(amportfolio.dfe547e741   AS VARCHAR2 (80)) itemclass,
            NULL                                            itemdataobj,
            amtsirelsspport.dtlastmodif                   
         FROM AM2107.amtsirelsspport, AM2107.amportfolio
         WHERE
            amtsirelsspport.lportfolioid = amportfolio.lportfolioitemid
            AND amportfolio.bdelete = 0
            AND amtsirelsspport.bdelete = 0
            UNION ALL
         SELECT
            'A' || amtsirelsspappl.LTSIRELSSPAPPLID id,
            amtsirelsspappl.lsspid lsspid,
            CAST(amtsicustappl.code  AS VARCHAR (40))       itemid,
            CAST(amtsicustappl.name  AS VARCHAR2 (4000))    itemname,
            CAST('APPLICATION' AS VARCHAR2 (80))            itemclass,
            NULL                                            itemdataobj,
            amtsirelsspappl.dtlastmodif
         FROM AM2107.amtsirelsspappl, AM2107.amtsicustappl
         WHERE
            amtsirelsspappl.lapplicationid = amtsicustappl.ltsicustapplid
            AND amtsicustappl.bdelete = 0
            AND amtsirelsspappl.bdelete = 0
      ) schainrel
      JOIN lnkschain_acl 
         ON schainrel.lsspid=lnkschain_acl.id;

grant select on lnkschain to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::license -----------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Lizenz-Datensatz wird dadurch eingeschraenkt,     
--   dass der Schnittstellen-User ueber die IFACE_ACL entweder den Zugriff 
--   auf den Buchungskreis, die Assignmentgroup der Lizenz oder den aus
--   dem Kontierungsobjekt resultierenden Customer-Link haben muss. 
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW license_acl AS
   SELECT distinct amportfolio.assettag  id
   FROM AM2107.amasset
      JOIN (SELECT * FROM AM2107.amportfolio 
            WHERE amportfolio.bdelete=0) amportfolio
         ON amasset.assettag = amportfolio.assettag
      LEFT OUTER JOIN (SELECT * 
                       FROM AM2107.amcostcenter 
                       WHERE amcostcenter.bdelete=0) amcostcenter
         ON amportfolio.lcostid = amcostcenter.lcostid
      left outer join AM2107.amemplgroup assigrp
         on amportfolio.lassignmentid = assigrp.lgroupid
      left outer join AM2107.amtsiaccsecunit customerlnk
            on amcostcenter.lcustomerlinkid=customerlnk.lunitid
      join IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
             (assigrp.name like acl.assignment 
                or acl.assignment is null) and
             (amcostcenter.acctno like acl.acctno 
                or acl.acctno is null) and
             (customerlnk.identifier like acl.customerlnk 
                or acl.customerlnk is null) and
            (acl.customerlnk is not null or
             acl.acctno is not null or
             acl.assignment is not null);

CREATE or REPLACE VIEW license AS
   SELECT
      amportfolio.assettag                           AS "licenseid",
      amasset.status                                 AS "status",
      ammodel.name                                   AS "name",
      amportfolio.label                              AS "label",
      amportfolio.lsupervid                          AS "supervid",
      amcostcenter.lcostid                           AS "lcostcenterid",
      amcostcenter.trimmedtitle                      AS "cocustomeroffice",
      amcostcenter.alternatebusinesscenter           AS "bc",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amportfolio.lparentid                          AS "lassetid",
      amportfolio.lportfolioitemid                   AS "lportfolioitemid",
      amportfolio.lastid                             AS "lastid",
      amcostcenter.alternatebusinesscenter           AS "altbc",
      amcomment.memcomment                           AS "comments",
      amportfolio.externalsystem                     AS "srcsys",
      amportfolio.externalid                         AS "srcid"
   FROM AM2107.amasset
      JOIN (SELECT * FROM AM2107.amportfolio 
            WHERE amportfolio.bdelete=0) amportfolio
         ON amasset.assettag = amportfolio.assettag
      JOIN license_acl 
         ON amportfolio.assettag=license_acl.id
      JOIN AM2107.ammodel
         ON amportfolio.lmodelid = ammodel.lmodelid
      JOIN AM2107.amnature
         ON ammodel.lnatureid = amnature.lnatureid
      LEFT OUTER JOIN AM2107.amcomment
         ON amasset.lcommentid = amcomment.lcommentid
      LEFT OUTER JOIN (SELECT * 
                       FROM AM2107.amcostcenter 
                       WHERE amcostcenter.bdelete=0) amcostcenter
         ON amportfolio.lcostid = amcostcenter.lcostid
   WHERE amnature.name = 'SW-LICENSE';

grant select on license to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itclust  ----------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Cluster-Datensatz wird dadurch eingeschraenkt,     
--   dass der Schnittstellen-User min. ein logisches System des betreffenden
--   Clusters sehen muss. Ist dies der Fall, dann wird der Cluster-Datensatz
--   sichtbar.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itclust_acl AS
   SELECT distinct amportfolio.assettag  id
   FROM AM2107.amcomputer
      JOIN AM2107.amportfolio
         ON amportfolio.lportfolioitemid = amcomputer.litemid
      JOIN AM2107.amasset
         ON amasset.assettag = amportfolio.assettag
      JOIN AM2107.ammodel
         ON amportfolio.lmodelid = ammodel.lmodelid and
            ammodel.name = 'CLUSTER'
      LEFT OUTER JOIN AM2107.amemplgroup assigrp
         on amportfolio.lassignmentid = assigrp.lgroupid
      LEFT OUTER JOIN IFACE_ACL acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
             (assigrp.name like acl.assignment) and
             (acl.acctno is null) and
             (acl.customerlnk is null) 
       LEFT OUTER JOIN system
         ON amcomputer.lcomputerid=system."lclusterid"
   WHERE system."lclusterid" is not null or acl.ifuser is not null;

CREATE or REPLACE VIEW itclust AS
   SELECT
      distinct concat(amportfolio.name,concat(' (',
               concat(amportfolio.assettag,')')))    AS "fullname",
      amportfolio.name                               AS "name",
      amportfolio.assettag                           AS "clusterid",
      amcomputer.status                              AS "status",
      amportfolio.usage                              AS "usage",
      amcomputer.clustertype                         AS "clustertype",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amportfolio.lincidentagid                      AS "lincidentagid",
      decode(amportfolio.soxrelevant, 'YES', 1, 0)   AS "soxrelevant",
      amcomputer.lcomputerid                         AS "lclusterid",
      amportfolio.lportfolioitemid                   AS "lportfolio",
      amportfolio.lportfolioitemid                   AS "lportfolioitemid",
      amportfolio.llocaid                            AS "locationid",
      amportfolio.externalsystem                     AS "srcsys",
      amportfolio.externalid                         AS "srcid"
   FROM AM2107.amcomputer
      JOIN ( SELECT amportfolio.*
             FROM AM2107.amportfolio
             WHERE amportfolio.bdelete = 0) amportfolio
         ON amportfolio.lportfolioitemid = amcomputer.litemid
      JOIN itclust_acl 
         ON amportfolio.assettag=itclust_acl.id
      JOIN AM2107.ammodel
         ON amportfolio.lmodelid = ammodel.lmodelid
      LEFT OUTER JOIN  ( SELECT amcostcenter.*
              FROM AM2107.amcostcenter
              WHERE amcostcenter.bdelete = 0) amcostcenter
         ON amportfolio.lcostid = amcostcenter.lcostid
   WHERE ammodel.name = 'CLUSTER'
      AND ( amcomputer.clustertype = 'Cluster'
         OR amcomputer.clustertype = 'Oracle RAC Cluster'
      )
      AND amcomputer.status <> 'out of operation';

grant select on itclust to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itclustservice ----------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen ClusterSerice-Datensatz ist dann gestattet,
--   wenn der betreffende Cluster fuer den Schnittstellen-User sichtbar
--   ist.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itclustservice_acl AS
   SELECT distinct "lclusterid" id
   FROM itclust;

CREATE or REPLACE VIEW itclustservice AS
   SELECT
      distinct concat(amportfolio.name,concat(' (',
            concat(amportfolio.assettag,')')))       AS "fullname",
      amportfolio.name                               AS "name",
      amcomputer.clustertype                         AS "type",
      'Cluster-Service'                              AS "description",
      amportfolio.assettag                           AS "serviceid",
      amclusterportfolio.assettag                    AS "clusterid",
      amportfolio.lassignmentid                      AS "lassignmentid",
      amportfolio.lincidentagid                      AS "lincidentagid",
      amcomputer.status                              AS "status",
      amportfolio.usage                              AS "usage",
      decode(amportfolio.soxrelevant,'YES',1,0)      AS "soxrelevant",
      amcomputer.lparentid                           AS "lclusterid",
      amcomputer.lcomputerid                         AS "lcomputerid",
      amportfolio.externalsystem                     AS "srcsys",
      amportfolio.externalid                         AS "srcid"
   FROM AM2107.amcomputer
      JOIN ( SELECT amportfolio.*
             FROM AM2107.amportfolio
             WHERE amportfolio.bdelete = 0) amportfolio 
          ON amportfolio.lportfolioitemid = amcomputer.litemid
      JOIN AM2107.ammodel 
          ON amportfolio.lmodelid = ammodel.lmodelid 
             AND ammodel.name = 'CLUSTER'
      LEFT OUTER JOIN ( SELECT amcostcenter.*
                        FROM AM2107.amcostcenter 
                        WHERE amcostcenter.bdelete = 0) amcostcenter 
          ON amportfolio.lcostid = amcostcenter.lcostid
      JOIN AM2107.amcomputer amcluster 
          ON amcomputer.lparentid = amcluster.lcomputerid
      JOIN ( SELECT amportfolio.*
         FROM AM2107.amportfolio
         WHERE amportfolio.bdelete = 0) amclusterportfolio 
         ON amclusterportfolio.lportfolioitemid = amcluster.litemid
      JOIN itclustservice_acl
         ON amcomputer.lparentid=itclustservice_acl.id
   WHERE (amcomputer.clustertype = 'Cluster-Service'
          OR amcomputer.clustertype = 'Cluster-Package'
          OR amcomputer.clustertype = 'Cluster-Packages'
         ) AND amcomputer.status <> 'out of operation';

grant select on itclustservice to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::schain ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Serviceketten wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW service_acl AS
   SELECT distinct amtsiservice.lserviceid id
   FROM AM2107.amtsiservice
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW service AS
   SELECT
      distinct amtsiservice.lserviceid               AS "serviceid",
      amportfolio.assettag                           AS "systemid",
      amtsiservicetype.identifier                    AS "name",
      amtsiservicetype.type                          AS "type",
      amtsiservicetype.unit                          AS "unit",
      amtsiservice.description                       AS "description",
      decode(amtsiservice.btechnical,0,1,1,0)        AS "isordered",
      amtsiservice.btechnical                        AS "isdelivered",
      amtsiservice.ammount                           AS "ammount"
   FROM AM2107.amtsiservicetype
      JOIN AM2107.amtsiservice
         ON amtsiservice.lservicetypeid = amtsiservicetype.ltsiservicetypeid
      JOIN service_acl
         ON amtsiservice.lserviceid=service_acl.id
      JOIN AM2107.amportfolio
         ON amportfolio.lportfolioitemid = amtsiservice.lportfolioid
      JOIN AM2107.amcomputer
         ON amportfolio.lportfolioitemid = amcomputer.litemid
   WHERE amtsiservice.bdelete = 0 AND amportfolio.bdelete = 0;

grant select on service to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::sharedstoragemnt --------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Storage-Mountpoints wird dadurch eingeschraenkt,
--   das der betreffende Schnittstellen-User auch das dazugehoerige
--   System "sehen" muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW sharedstoragemnt_acl AS
   SELECT DISTINCT amtsiprovstomounts.lmountpointid      id
   FROM  AM2107.amtsiprovstomounts
   JOIN AM2107.amcomputer
      ON amtsiprovstomounts.lcomputerid = amcomputer.lcomputerid
   JOIN AM2107.amportfolio systemportfolio
      ON amcomputer.litemid = systemportfolio.lportfolioitemid
   JOIN system_acl_l0
      ON systemportfolio.assettag=system_acl_l0.id
         AND system_acl_l0.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW sharedstoragemnt AS
   SELECT
      DISTINCT amtsiprovstomounts.lmountpointid      AS "id",
      concat (concat(systemportfolio.name, ':'),
         amtsiprovstomounts.mountpoint)              AS "fullname",
      amtsiprovstomounts.mountpoint                  AS "name",
      amcomputer.lcomputerid                         AS "lcomputerid",
      systemportfolio.name                           AS "systemname",
      systemportfolio.assettag                       AS "systemid",
      amcomputer.status                              AS "systemstatus",
      assetportfolio.assettag                        AS "storageassetid",
      concat (assetportfolio.name,
         concat(' (',concat (assetportfolio.assettag,
               ')')))                                AS "storagefullname",
      assetportfolio.name                            AS "storagename",
      amtsiprovstomounts.lprovidedstorageid          AS "sharedstorageid"
   FROM AM2107.amtsiprovstomounts
      JOIN sharedstoragemnt_acl
         ON amtsiprovstomounts.lmountpointid=sharedstoragemnt_acl.id
      JOIN AM2107.amcomputer
         ON amtsiprovstomounts.lcomputerid = amcomputer.lcomputerid 
      JOIN AM2107.amportfolio systemportfolio
         ON amcomputer.litemid = systemportfolio.lportfolioitemid
      JOIN AM2107.amtsiprovsto
         ON amtsiprovstomounts.lprovidedstorageid=
            amtsiprovsto.lprovidedstorageid
      JOIN AM2107.amportfolio assetportfolio
         ON  amtsiprovsto.lassetid = assetportfolio.lastid
   WHERE amtsiprovstomounts.bdelete = '0';

grant select on sharedstoragemnt to public;




-- --------------------------------------------------------------------------
-- --------------------- tsacinv::fixedasset --------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Fixed-Asset Elemente wird dadurch eingeschraenkt,
--   das der betreffende Schnittstellen-User auch das dazugehoerige
--   Asset "sehen" muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW fixedasset_acl AS
   SELECT DISTINCT amfixedasset.fixedastno id 
   FROM AM2107.amfixedasset
      JOIN asset 
         ON amfixedasset.assettag=asset."assetid";

CREATE or REPLACE VIEW fixedasset AS
   SELECT DISTINCT amfixedasset.fixedastno           AS "name",
      amfixedasset.name                              AS "description",
      amfixedasset.assettag                          AS "assetid",
      amfixedasset.ddeprstart                        AS "deprstart",
      amfixedasset.ddeprend                          AS "deprend",
      amfixedasset.mdeprbasis                        AS "deprbase",
      amfixedasset.mresidualvalue                    AS "residualvalue",
      amfixedasset.mdeprrate                         AS "deprrate",
      amfixedasset.inventoryno                       AS "inventoryno"
   FROM
      AM2107.amfixedasset
      JOIN fixedasset_acl
         ON amfixedasset.fixedastno=fixedasset_acl.id
      JOIN AM2107.amrelfixedasset
         ON amfixedasset.lfixedastid = amrelfixedasset.lfixedastid
   WHERE amfixedasset.bdelete = '0';

grant select on fixedasset to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::contract ----------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Serviceketten wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW contract_acl AS
   SELECT distinct amcontract.lcntrid   id
   FROM AM2107.amcontract
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW contract AS
   SELECT amcontract.lcntrid                         AS "contractid",
      amcontract.name                                AS "name",
      ammodel.name                                   AS "model"
   FROM AM2107.amcontract
      JOIN contract_acl
         ON amcontract.lcntrid=contract_acl.id
      JOIN AM2107.ammodel
         ON amcontract.lmodelid = ammodel.lmodelid
      JOIN AM2107.amnature
         ON ammodel.lnatureid = amnature.lnatureid;

grant select on contract to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itfarmsystem ------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Datensatz wird dadurch eingeschraenkt,
--   das der betreffende Schnittstellen-User auch das dazugehoerige
--   System "sehen" muss.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itfarmsystem_acl AS
   SELECT DISTINCT sys.litemid id
   FROM AM2107.amcomputer sys
      JOIN system_acl_l1 on
         sys.assettag=system_acl_l1.id
   WHERE system_acl_l1.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW itfarmsystem AS
   SELECT DISTINCT sys.litemid                       AS "lsysid",
      clu.litemid                                    AS "lfarmid",
      sysportfolio.name                              AS "name",
      sys.assettag                                   AS "systemid",
      ass.assettag                                   AS "assetid",
      clu.assettag                                   AS "clusterid",
      sys.status                                     AS "status"
   FROM AM2107.amcomputer con
      JOIN AM2107.amportfolio conportfolio 
         ON conportfolio.lportfolioitemid = con.litemid
      JOIN AM2107.amportfolio assportfolio 
         ON assportfolio.Lportfolioitemid = conportfolio.lparentid
      JOIN AM2107.amasset ass 
         ON assportfolio.assettag = ass.assettag
      JOIN AM2107.amcomputer clu 
         ON con.lparentid = clu.lcomputerid
      JOIN AM2107.amportfolio sysportfolio 
         ON assportfolio.Lportfolioitemid = sysportfolio.lparentid
      JOIN AM2107.amcomputer sys 
         ON sysportfolio.lportfolioitemid = sys.litemid
      JOIN itfarmsystem_acl
         ON sys.litemid=itfarmsystem_acl.id
   WHERE conportfolio.usage LIKE 'OSY-_: KONSOLSYSTEM %'
      AND sysportfolio.usage NOT LIKE 'OSY-_: KONSOLSYSTEM %'
      AND clu.litemid <> '0';

grant select on itfarmsystem to public;





-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itfarmconsole -----------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Datensaetze wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itfarmconsole_acl AS
   SELECT distinct amcomputer.litemid id
   FROM AM2107.amcomputer
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW itfarmconsole AS
SELECT
   DISTINCT con.litemid                           AS "lconsid",
   clu.litemid                                    AS "lfarmid",
   conportfolio.name                              AS "name",
   con.assettag                                   AS "systemid",
   ass.assettag                                   AS "assetid",
   clu.assettag                                   AS "clusterid",
   con.status                                     AS "status"
FROM AM2107.amcomputer con
   JOIN itfarmconsole_acl
      ON con.litemid=itfarmconsole_acl.id
   JOIN AM2107.amportfolio conportfolio 
      ON conportfolio.lportfolioitemid = con.litemid
   JOIN AM2107.amportfolio assportfolio 
      ON assportfolio.Lportfolioitemid = conportfolio.lparentid
   JOIN AM2107.amasset ass 
      ON assportfolio.assettag = ass.assettag
   JOIN AM2107.amcomputer clu 
      ON con.lparentid = clu.lcomputerid
WHERE conportfolio.usage LIKE 'OSY-_: KONSOLSYSTEM %'
   AND clu.litemid <> '0';

grant select on itfarmconsole to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::itfarmasset -------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Datensaetze wird dadurch
--   eingeschraenkt das der Schnittstellen-User in der IFACE_ACL aufgefuert
--   sein muss.     
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW itfarmasset_acl AS
   SELECT DISTINCT assportfolio.lportfolioitemid id
   FROM AM2107.amportfolio assportfolio
   JOIN IFACE_ACL acl
      on acl.ifuser=sys_context('USERENV', 'SESSION_USER');

CREATE or REPLACE VIEW itfarmasset AS
   SELECT
      DISTINCT assportfolio.lportfolioitemid         AS "lconsid",
      clu.litemid                                    AS "lfarmid",
      assportfolio.llocaid                           AS "locationid",
      ass.assettag                                   AS "name",
      ass.status                                     AS "status"
   FROM AM2107.amcomputer sys
      JOIN AM2107.amportfolio sysportfolio 
         ON sysportfolio.lportfolioitemid = sys.litemid
      JOIN AM2107.amportfolio assportfolio 
         ON assportfolio.Lportfolioitemid = sysportfolio.lparentid
      JOIN AM2107.amasset ass 
         ON assportfolio.assettag = ass.assettag
      JOIN AM2107.amcomputer clu 
         ON sys.lparentid = clu.lcomputerid
      JOIN itfarmasset_acl
         ON assportfolio.lportfolioitemid=itfarmasset_acl.id
   WHERE sysportfolio.usage LIKE 'OSY-_: KONSOLSYSTEM %'
      AND sys.status <> 'out of operation' AND clu.litemid <> '0';

grant select on itfarmasset to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::backup ------------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Datensatz wird dadurch eingeschraenkt,
--   das der betreffende Schnittstellen-User auch das dazugehoerige
--   System "sehen" muss.
-- --------------------------------------------------------------------------
CREATE or REPLACE VIEW backup_acl AS
   SELECT distinct amtsibackup.lbackupid id
   FROM AM2107.amtsibackup
      JOIN system on system."lcomputerid"=amtsibackup.lcomputerid;

CREATE or REPLACE VIEW backup AS
   SELECT
      DISTINCT amtsibackup.lbackupid                 AS "id",
      amtsibackup.code                               AS "backupid",
      amtsibackup.setype                             AS "stype",
      amtsibackup.setype                             AS "type",
      amtsibackup.setype                             AS "typeid",
      amtsibackup.subtype                            AS "subtype",
      amtsibackup.backupservice                      AS "name",
      amtsibackup.groupname                          AS "bgroup",
      concat(amtsibackup.expectedquantity,
         concat(' ',amtsibackup.quantityunit))       AS "hexpectedquantity",
      amtsibackup.savetimeframefrom                  AS "tfrom",
      amtsibackup.savetimeframeto                    AS "tto",
      amtsibackup.dbtype                             AS "dbtype",
      amtsibackup.policy                             AS "policy",
      amtsibackup.dbinstance                         AS "dbinstance",
      amtsibackup.bactive                            AS "isactive",
      amtsibackup.lcomputerid                        AS "lcomputerid"
   FROM AM2107.amtsibackup
      JOIN backup_acl
         ON amtsibackup.lbackupid=backup_acl.id
   WHERE amtsibackup.bdelete = 0;

grant select on backup to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::costcenter --------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf einen Kontierungs-Datensatz wird explizit NICHT
--   durch die Filter in der IFACE_ACL eingeschraenkt (der Schnittstellen
--   User muss darin nur mit min. einem Datensatz vorhanden sein), da
--   dadurch Informationen zu Kontierungsobjekten zugaenglich werden 
--   muessen, um z.B. auch Ansprechparnter ausfindig machen zu koennen.
-- --------------------------------------------------------------------------

-- drop materialized view costcenter_acl_l0;
CREATE MATERIALIZED VIEW costcenter_acl_l0
  refresh complete start with trunc(sysdate+1)+7.0/24
  next sysdate+0.300
  as
   select distinct ifuser,lcostid from (
      -- costcenter self by iface_acl
      select acl.ifuser                                   ifuser,
             amcostcenter.lcostid                         lcostid
      from AM2107.amcostcenter
         left outer join AM2107.amtsiaccsecunit customerlnk
               on amcostcenter.lcustomerlinkid=customerlnk.lunitid
         join IFACE_ACL acl
            on (acl.assignment is null) and
                (amcostcenter.acctno like acl.acctno
                   or acl.acctno is null) and
                (customerlnk.identifier like acl.customerlnk
                   or acl.customerlnk is null) and
               (acl.customerlnk is not null or
                acl.acctno is not null or
                acl.assignment is not null)
      union all
      -- appl costcenter
      select acl.ifuser                                   ifuser,
             amcostcenter.lcostid                         lcostid
      from AM2107.amtsicustappl
         left outer join ( SELECT amcostcenter.*
                           FROM AM2107.amcostcenter
                           WHERE amcostcenter.bdelete = 0) amcostcenter
            on amtsicustappl.lcostcenterid = amcostcenter.lcostid
         left outer join AM2107.amemplgroup assigrp
            on amtsicustappl.lassignmentid = assigrp.lgroupid
         left outer join AM2107.amtsiaccsecunit customerlnk
               on amcostcenter.lcustomerlinkid=customerlnk.lunitid
         join IFACE_ACL acl
            on (assigrp.name like acl.assignment
                   or acl.assignment is null) and
                (amcostcenter.acctno like acl.acctno
                   or acl.acctno is null) and
                (customerlnk.identifier like acl.customerlnk
                   or acl.customerlnk is null) and
               (acl.customerlnk is not null or
                acl.acctno is not null or
                acl.assignment is not null)
      union all
      -- system costcenter
      select system_acl_l1.ifuser                         ifuser,
               amportfolio.lcostid                        lcostid
        from system_acl_l1
          JOIN AM2107.amportfolio
               ON amportfolio.assettag=system_acl_l1.id
      union all
      -- asset costenter
      select system_acl_l1.ifuser                         ifuser,
             assetportfolio.lcostid                       lcostid
        from system_acl_l1
          JOIN AM2107.amportfolio
               ON amportfolio.assettag=system_acl_l1.id
          JOIN AM2107.amportfolio assetportfolio
               ON amportfolio.lparentid=assetportfolio.lportfolioitemid
      ) costcenter_acl;

CREATE INDEX costcenter_acl_l0_i0
   ON costcenter_acl_l0 (lcostid,ifuser) online;

CREATE or REPLACE VIEW costcenter_acl AS
   SELECT distinct amcostcenter.lcostid              AS id
   FROM AM2107.amcostcenter
      join costcenter_acl_l0 acl
         on acl.ifuser=sys_context('USERENV', 'SESSION_USER') and
            acl.lcostid=amcostcenter.lcostid;

CREATE or REPLACE VIEW costcenter AS
   SELECT amcostcenter.lcostid                       AS "id",
      amcostcenter.trimmedtitle                      AS "name",
      amcostcenter.title                             AS "untrimmedname",
      decode(amcostcenter.flag9,'X', 1, 0)           AS "islocked",
      amcostcenter.code                              AS "code",
      amcostcenter.field1                            AS "description",
      amcostcenter.alternatebusinesscenter           AS "bc",
      amcostcenter.orgunit                           AS "orgunit",
      (
         SELECT decode(COUNT(*),0,0,1)
         FROM AM2107.amportfolio p1
            JOIN AM2107.amcomputer c1
               ON p1.lportfolioitemid = c1.litemid 
         WHERE p1.lcostid = amcostcenter.lcostid
           AND LOWER(c1.status)!='out of operation') AS "usedbyactivesystems",
      amcostcenter.ictonr                            AS "ictonr",
      amcostcenter.bdelete                           AS "deleted",
      amcostcenter.norsolutionmodel                  AS "norsolutionmodel",
      amcostcenter.norinstructiontyp                 AS "norinstructiontyp",
      amcostcenter.lleadingdeliverymanagerid         AS "delmgrid",
      amcostcenter.lproductionplanningossid          AS "productionplanningossid",
      amcostcenter.lcustomerlinkid                   AS "lcustomerid",
      amtsiaccsecunit.identifier                     AS "customerlink",
      amtsisclocations.sclocationid                  AS "defsclocationid",
      amcostcenter.lservicemanagerid                 AS "semid",
      decode ( amcostcenter.hier0id,'','-',
         amcostcenter.hier0id)
      || '.' || decode ( amcostcenter.hier1id,
         '','-',amcostcenter.hier1id)
      || '.' || decode ( amcostcenter.hier2id,
         '','-',amcostcenter.hier2id)
      || '.' || decode ( amcostcenter.hier3id,
         '','-',amcostcenter.hier3id)
      || '.' || decode ( amcostcenter.hier4id,
         '','-',amcostcenter.hier4id)
      || '.' || decode ( amcostcenter.hier5id,
         '','-',amcostcenter.hier5id)
      || '.' || decode ( amcostcenter.hier6id,
         '','-',amcostcenter.hier6id)
      || '.' || decode ( amcostcenter.hier7id,
         '','-',amcostcenter.hier7id)
      || '.' || decode ( amcostcenter.hier8id,
         '','-',amcostcenter.hier8id)
      || '.' || decode ( amcostcenter.hier9id,
         '','-',amcostcenter.hier9id)                AS "saphier",
      amcostcenter.hier0id                           AS "saphier0id",
      amcostcenter.hier1id                           AS "saphier1id",
      amcostcenter.hier2id                           AS "saphier2id",
      amcostcenter.hier3id                           AS "saphier3id",
      amcostcenter.hier4id                           AS "saphier4id",
      amcostcenter.hier5id                           AS "saphier5id",
      amcostcenter.hier6id                           AS "saphier6id",
      amcostcenter.hier7id                           AS "saphier7id",
      amcostcenter.hier8id                           AS "saphier8id",
      amcostcenter.hier9id                           AS "saphier9id",
      amcostcenter.externalsystem                    AS "srcsys",
      amcostcenter.externalid                        AS "srcid",
      amcostcenter.dtimport                          AS "srcload",
      amcostcenter.dtlastmodif                       AS "mdate"
   FROM AM2107.amcostcenter
      JOIN costcenter_acl
         ON amcostcenter.lcostid=costcenter_acl.id
      LEFT OUTER JOIN AM2107.amtsiaccsecunit 
         ON amcostcenter.lcustomerlinkid = amtsiaccsecunit.lunitid
      LEFT OUTER JOIN AM2107.amtsisclocations 
         ON amtsiaccsecunit.ldefaultsclocationid = 
            amtsisclocations.ltsisclocationsid
   WHERE amcostcenter.lcostid<>'0';

grant select on costcenter to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::dlvpartner --------------------------------
-- --------------------------------------------------------------------------
--   Der Zugriff auf die Delivery-Partner eines Kontierungsobjektes
--   wird dann gewaehrt, wenn der Zugriff auf das betreffende
--   Kontierungsobjekt erlaubt ist.
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW dlvpartner_acl AS
   SELECT
      distinct amtsidlvpartner.ldeliverypartnerid    AS id
   FROM
      AM2107.amtsidlvpartner
         JOIN costcenter_acl
           ON amtsidlvpartner.lcostcenterid = costcenter_acl.id;

CREATE or REPLACE VIEW dlvpartner AS
   SELECT
      distinct amtsidlvpartner.ldeliverypartnerid    AS "id",
      amcostcenter.trimmedtitle                      AS "name",
      amtsidlvpartner.ldeliverymanagementid          AS "ldeliverymanagementid",
      amtsidlvpartner.description                    AS "description",
      amtsidlvpartner.ldeliverymanagerid             AS "delmgrid",
      amtsidlvpartner.ldeputydeliverymanagerid       AS "delmgr2id",
      amtsidlvpartner.dtlastmodif AS "mdate"
   FROM
      AM2107.amtsidlvpartner
         JOIN AM2107.amcostcenter
           ON amtsidlvpartner.lcostcenterid = amcostcenter.lcostid
         JOIN dlvpartner_acl 
           ON amtsidlvpartner.ldeliverypartnerid=dlvpartner_acl.id
   WHERE amcostcenter.bdelete = 0
      AND amtsidlvpartner.bdelete = 0;

grant select on dlvpartner to public;



