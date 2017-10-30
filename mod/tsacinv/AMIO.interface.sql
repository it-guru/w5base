-- --------------------------------------------------------------------------
-- ---------- Pruefsystem, ob alle notwendigen Tabellen erreichbar ----------
-- --------------------------------------------------------------------------

-- drop table "IFACE_REQ_OBJECTS";
create table "IFACE_REQ_OBJECTS" (
   owner        varchar2(33) not null,
   object_name   varchar2(33) not null,
   constraint "IFACE_REQ_OBJECTS_pk" primary key (owner,table_name)
);

insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSICUSTAPPL');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMCOSTCENTER');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMEMPLGROUP');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSISERVICE');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSISERVICETYPE');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSIRELPORTFAPPL');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMPORTFOLIO');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMCOMMENT');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTENANT');

insert into "IFACE_REQ_OBJECTS" values('AM2107','AMCOMPUTER');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMMODEL');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMNATURE');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSIACCSECUNIT');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSIAUTODISCOVERY');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSIRELPORTFAPPL');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSISERVICE');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMTSISERVICETYPE');
insert into "IFACE_REQ_OBJECTS" values('AM2107','AMNETWORKCARD');


create or replace view "IFACE_MISS_OBJECTS" as
select "IFACE_REQ_OBJECTS".owner,"IFACE_REQ_OBJECTS".object_name
from "IFACE_REQ_OBJECTS"
   left outer join ALL_OBJECTS
      on "IFACE_REQ_OBJECTS".owner=ALL_OBJECTS.owner and
         "IFACE_REQ_OBJECTS".object_name=ALL_OBJECTS.object_name
where ALL_OBJECTS.object_name is null;


select 'grant select on "'||owner||'"."'||object_name||
                        '" to TEL_IT_DARWIN WITH GRANT OPTION;' sqlcmd 
from ALL_OBJECTS 
where owner='AM2107' and object_type in ('TABLE','VIEW');  


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
-- --------------------- tsacinv::system ------------------------------------
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
      concat(concat(concat(amtsicustappl.name,' ('),amtsicustappl.code),')')
                                                     "fullname",
      amtsicustappl.ltsicustapplid                   "id",
      amtsicustappl.name                             "name",
      LOWER ( amtsicustappl.status)                  "status",
      '0'                                            "deleted",
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
      decode ( tbsm.ordered, 'XMBSM', 1, 0)          "tbsm_ordered",
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
      left outer join (
         SELECT
            DISTINCT amtsiservicetype.identifier ordered,
            amtsicustappl.ltsicustapplid
         FROM
            AM2107.amtsiservice,
            AM2107.amtsiservicetype,
            AM2107.amtsirelportfappl,
            AM2107.amtsicustappl,
            AM2107.amportfolio
         WHERE
            amtsiservice.lservicetypeid = amtsiservicetype.ltsiservicetypeid
            AND amtsiservicetype.identifier = 'XMBSM'
            AND amtsiservice.bdelete = 0
            AND amtsirelportfappl.bdelete = 0
            AND amtsiservice.lportfolioid = amtsirelportfappl.lportfolioid
            AND amtsirelportfappl.bactive = 1
            AND amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid
            AND amtsirelportfappl.lportfolioid = amportfolio.lportfolioitemid
            AND amportfolio.bdelete = 0
         ) tbsm 
         on amtsicustappl.ltsicustapplid = tbsm.ltsicustapplid
      left outer join AM2107.amcomment amtsimaint
         on amtsicustappl.lmaintwindowid = amtsimaint.lcommentid
      left outer join AM2107.amcomment businessdesc
         on amtsicustappl.lcustbusinessdescid = businessdesc.lcommentid
      left outer join AM2107.amtsiaccsecunit customerlnk
         on amcostcenter.lcustomerlinkid=customerlnk.lunitid;

grant select on appl to public;

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::system (pre) ------------------------------
-- --------------------------------------------------------------------------
CREATE or REPLACE VIEW system_acl_level0 AS     -- level0 = without shared
   select distinct amportfolio.assettag id
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

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::ipaddress ---------------------------------
-- --------------------------------------------------------------------------

CREATE or REPLACE VIEW ipaddress_acl AS
   SELECT
      DISTINCT amnetworkcard.lnetworkcardid          id
   FROM AM2107.amnetworkcard
   JOIN system on system."lcomputerid"=amnetworkcard.lcompid;


CREATE VIEW ipaddress AS
   SELECT
      DISTINCT amnetworkcard.lnetworkcardid          id,
      amnetworkcard.tcpipaddress || 
         decode ( amnetworkcard.tcpipaddress,
         NULL, '', decode ( amnetworkcard.ipv6address,
            NULL, '', ', '))
         || amnetworkcard.ipv6address                AS "ipaddress",
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
      DISTINCT amtsiacctno.ltsiacctnoid              AS "id",
      amtsiacctno.code                               AS "accnoid",
      amtsiacctno.accountno                          AS "name",
      amtsiacctno.ctrlflag                           AS "ctrlflag",
      amcostcenter.trimmedtitle                      AS "conumber",
      amtsiacctno.description                        AS "description",
      amtsiacctno.lapplicationid                     AS "lapplicationid",
      amtsiacctno.lcostcenterid                      AS "lcostcenterid"
   FROM
      AM2107.amtsiacctno 
      LEFT OUTER JOIN (
         SELECT amcostcenter.* FROM AM2107.amcostcenter
         WHERE amcostcenter.bdelete = 0) amcostcenter
         ON amtsiacctno.lcostcenterid = amcostcenter.lcostid
      JOIN accountno_acl
         on amtsiacctno.ltsiacctnoid=accountno_acl."id"
   WHERE
      amtsiacctno.bdelete = 0 AND amtsiacctno.ltsiacctnoid <> 0;

grant select on accountno to public;




-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnksharednet ------------------------------
-- --------------------------------------------------------------------------

-- drop materialized view mview_lnknet;
CREATE MATERIALIZED VIEW mview_lnknet
  refresh complete start with sysdate
  next trunc(sysdate+1)+6/24
  as
   SELECT
      DISTINCT TsiParentChild.ltsiparentchildid      AS "netlnkid",
      TsiParentChild.description                     AS "description",
      amtsicustappl.code                             AS "applid",
      amtsicustappl.name                             AS "applname",
      systemportfolio.assettag                       AS "systemsystemid",
      systemportfolio.name                           AS "systemname",
      netportfolio.assettag                          AS "netsystemid",
      netportfolio.name                              AS "netname",
      netpartnernature.name                          AS "netnature",
      amcomputer.lcomputerid                         AS "lcomputerid"
   FROM
      AM2107.amcomputer
      JOIN AM2107.amportfolio systemportfolio 
         ON ( amcomputer.litemid = systemportfolio.lportfolioitemid
              AND systemportfolio.bdelete = '0')
      JOIN (
         SELECT
            amTsiParentChild.ltsiparentchildid,
            amTsiParentChild.lparentid a,
            amTsiParentChild.lchildid b,
            amTsiParentChild.description
         FROM AM2107.amTsiParentChild
         WHERE externalsystem = 'Autodiscovery'
         UNION ALL
         SELECT
            amTsiParentChild.ltsiparentchildid,
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
      LEFT OUTER JOIN AM2107.amtsicustappl 
         ON amtsirelportfappl.lapplicationid = amtsicustappl.ltsicustapplid;

CREATE INDEX mview_lnknet_i0
   ON mview_lnknet ("netlnkid") online;
CREATE INDEX mview_lnknet_i1
   ON mview_lnknet ("lcomputerid") online;
CREATE INDEX mview_lnknet_i2
   ON mview_lnknet ("systemsystemid") online;
CREATE INDEX mview_lnknet_i3
   ON mview_lnknet ("applid") online;
CREATE INDEX mview_lnknet_i4
   ON mview_lnknet ("netsystemid") online;


CREATE or REPLACE VIEW lnksharednet AS
   select * 
   from system_acl_level0
      join mview_lnknet 
         on system_acl_level0.id=mview_lnknet."systemsystemid"
   where "netnature" is not null 
      and "netnature" not in ('SERVER','TERMINAL-SERVER');
   



---
---
---  TTOODDOO:  Zugriff auf Shared-Resources !!!
---
---

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnksharedstorage --------------------------
-- --------------------------------------------------------------------------

-- drop materialized view mview_lnksharedstorage;
CREATE MATERIALIZED VIEW mview_lnksharedstorage
  refresh complete start with sysdate
  next trunc(sysdate+1)+6/24
  AS
   SELECT
      DISTINCT storageportfolio.assettag             AS "storageassetid",
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

CREATE INDEX mview_lnksharedstorage_i0
   ON mview_lnksharedstorage ("storageassetid") online;
CREATE INDEX mview_lnksharedstorage_i1
   ON mview_lnksharedstorage ("lcomputerid") online;
CREATE INDEX mview_lnksharedstorage_i2
   ON mview_lnksharedstorage ("systemsystemid") online;
CREATE INDEX mview_lnksharedstorage_i3
   ON mview_lnksharedstorage ("applid") online;



CREATE or REPLACE VIEW lnksharedstorage_acl AS
   SELECT DISTINCT "storageassetid" id
   FROM mview_lnksharedstorage
      JOIN system 
         ON mview_lnksharedstorage."lcomputerid"=system."lcomputerid";

CREATE or REPLACE VIEW lnksharedstorage AS
   SELECT mview_lnksharedstorage.*
   FROM mview_lnksharedstorage
   JOIN lnksharedstorage_acl
      ON lnksharedstorage_acl.id=mview_lnksharedstorage."storageassetid";

grant select on lnksharedstorage to public;

-- --------------------------------------------------------------------------
-- --------------------- tsacinv::system ------------------------------------
-- --------------------------------------------------------------------------
CREATE or REPLACE VIEW system_acl AS
   select distinct * from (
      select amportfolio.assettag id
      from AM2107.amportfolio,system_acl_level0
      where amportfolio.assettag=system_acl_level0.id
      union 
      select amportfolio.assettag id
      from AM2107.amportfolio,lnksharednet
      where amportfolio.assettag=lnksharednet."netsystemid"
   )
-- test: DEMD1XCP0002 (S20148097)  QDE8HV (S21938047)


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
      decode(tbsm.ordered,'XMBSM', 1, 0)             AS "tbsm_ordered",
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
      LEFT OUTER JOIN (
         SELECT DISTINCT amtsiservicetype.identifier ordered, amtsiservice.lportfolioid
         FROM AM2107.amtsiservice, AM2107.amtsiservicetype
         WHERE
            amtsiservice.lservicetypeid = amtsiservicetype.ltsiservicetypeid
            AND amtsiservicetype.identifier = 'XMBSM'
            AND amtsiservice.bdelete = 0 ) tbsm 
         ON amportfolio.lportfolioitemid = tbsm.lportfolioid
      LEFT OUTER JOIN AM2107.amcomment 
         ON amcomputer.lcommentid = amcomment.lcommentid
      LEFT OUTER JOIN AM2107.amtsiautodiscovery 
         ON amportfolio.assettag = amtsiautodiscovery.assettag
   WHERE amcomputer.bgroup = 0 AND ammodel.name = 'LOGICAL SYSTEM';

grant select on system to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::group ------------------------------------
-- --------------------------------------------------------------------------
CREATE VIEW grp_acl AS
   select DISTINCT amemplgroup.barcode id
   from AM2107.amemplgroup
   where amemplgroup.lgroupid <> 0
   

CREATE VIEW grp AS
   SELECT
      DISTINCT amemplgroup.barcode                   AS "code",
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
      JOIN group_acl
         ON amemplgroup.barcode=group_acl.id

grant select on grp to public;


-- --------------------------------------------------------------------------
-- --------------------- tsacinv::group ------------------------------------
-- --------------------------------------------------------------------------
CREATE or REPLACE VIEW usr_acl AS
   select distinct amempldept.lempldeptid id
   FROM AM2107.amempldept
   where amempldept.lempldeptid<>0;

CREATE or REPLACE VIEW usr AS
SELECT
   DISTINCT amempldept.lempldeptid                AS "lempldeptid",
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
   amempldept.webpassword                         AS "webpassword",
   amempldept.idno                                AS "idno",
   amempldept.externalsystem                      AS "srcsys",
   amempldept.externalid                          AS "srcid"
FROM AM2107.amempldept
   JOIN usr_acl 
      on amempldept.lempldeptid=usr_acl.id;

grant select on usr to public;



-- --------------------------------------------------------------------------
-- --------------------- tsacinv::lnkapplappl ------------------------------
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
-- --------------------- tsacinv::lnkapplsystem -----------------------------
-- --------------------------------------------------------------------------


CREATE or REPLACE VIEW lnkapplappl_acl AS
   select distinct amtsirelportfappl.lrelportfapplid id
   FROM AM2107.amtsirelportfappl
   JOIN appl
      ON amtsirelportfappl.lapplicationid=appl."id";


CREATE or REPLACE VIEW lnkapplsystem AS
SELECT
   DISTINCT amtsirelportfappl.lrelportfapplid     AS "id",
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
   JOIN lnkapplappl_acl
      ON amtsirelportfappl.lrelportfapplid=lnkapplappl_acl.id
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

