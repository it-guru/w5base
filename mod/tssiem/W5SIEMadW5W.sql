-- drop table "W5SIEM_secscan";
create table "W5SIEM_secscan" (
   ref                VARCHAR2(32) not null,
   id                 VARCHAR2(32) not null,
   ictoid             VARCHAR2(20) default null,
   w5baseid_appl      NUMBER(*,0) default null,
   type               VARCHAR2(32) not null,
   title              VARCHAR2(128) not null,
   user_login         VARCHAR(32) not null,
   launch_datetime    DATE not null,
   duration           DATE not null,
   target             CLOB not null,
   pdfvfwifull        BLOB,
   pdfvfwifull_level  INT,
   pdfvfwidelta       BLOB,
   pdfvfwidelta_level INT,
   pdfstdfull         BLOB,
   pdfstdfull_level   INT,
   pdfstddelta        BLOB,
   pdfstddelta_level  INT,
   creationdate       DATE not null,
   importdate         DATE,
   networkid          NUMBER(*,0) default null,
   networkname        VARCHAR2(40) default null,
   rcvdate            DATE,
   constraint W5SIEM_secscan_pk primary key (ref),
   constraint "W5SIEM_secscan_CHK" 
      CHECK (NVL2(ictoid,1,0)+NVL2(w5baseid_appl,1,0) >= 1)
);
grant select on "W5SIEM_secscan" to W5I;
grant select,insert,update,delete on "W5SIEM_secscan" to W5SIEM;
create or replace synonym W5SIEM.secscan for "W5SIEM_secscan";
create or replace synonym W5I.W5SIEM_secscan for "W5SIEM_secscan";

CREATE INDEX "W5SIEM_secscan_i0"
   ON "W5SIEM_secscan" (ictoid) online;

CREATE INDEX "W5SIEM_secscan_i2"
   ON "W5SIEM_secscan" (launch_datetime) online;

CREATE INDEX "W5SIEM_secscan_i3"
   ON "W5SIEM_secscan" (id) online;

-- drop table "W5SIEM_secent";
create table "W5SIEM_secent" (
   id                   INTEGER not null,
   ref                  VARCHAR2(32) not null,
   ipaddress            VARCHAR2(3000) not null, -- Eigentlich das "Target"
   tracking_method      VARCHAR2(40),
   osname               VARCHAR2(128),
   dns                  VARCHAR2(256),
   netbios              VARCHAR2(256),
   ipstatus             VARCHAR2(128),
   qid                  NUMBER(20,0) not null,
   title                VARCHAR2(4000) not null,
   vuln_status          VARCHAR2(40),
   ent_type             VARCHAR2(40),
   severity             NUMBER(2,0) not null,
   port                 NUMBER(20,0),
   ssl                  VARCHAR(10),
   cvss_basescore       NUMBER(3,1),
   cvss_scorestr        VARCHAR(20),
   first_detect         DATE,
   last_detect          DATE,
   vendor_reference     VARCHAR2(4000),
   threat               clob,
   results              clob,
   impact               clob,
   exploitability       clob,
   associated_malware   VARCHAR2(4000),
   pci_vuln             VARCHAR2(10),
   category             VARCHAR2(2000),
   protocol             varchar2(40),
   cve_id               varchar2(256),
   bugtraq_id           varchar2(256),
   times_detected       NUMBER(20,0),
   solution             clob,
   constraint W5SIEM_secent_pk foreign key (ref)
   REFERENCES "W5SIEM_secscan" (ref) ON DELETE CASCADE,
   constraint W5SIEM_secent_pk1 PRIMARY KEY (id)
);
grant select on "W5SIEM_secent" to W5I;
grant select,insert,update,delete on "W5SIEM_secent" to W5SIEM;
create or replace synonym W5SIEM.secent for "W5SIEM_secent";
create or replace synonym W5I.W5SIEM_secent for "W5SIEM_secent";

CREATE INDEX "W5SIEM_secent_i0"
   ON "W5SIEM_secent" (ref) online;

CREATE INDEX "W5SIEM_secent_i1"
   ON "W5SIEM_secent" (ipaddress) online;

CREATE INDEX "W5SIEM_secent_i3"
   ON "W5SIEM_secent" (pci_vuln) online;

CREATE INDEX "W5SIEM_secent_i4"
   ON "W5SIEM_secent" (qid) online;

CREATE INDEX "W5SIEM_secent_i5"
   ON "W5SIEM_secent" (last_detect) online;


CREATE SEQUENCE "W5SIEM_secent_seq"
   MINVALUE 1
   START WITH 1
   INCREMENT BY 1
   CACHE 100;
grant select on "W5SIEM_secent_seq" to W5SIEM;
create or replace synonym W5SIEM.secent_seq for "W5SIEM_secent_seq";

-- ---------------------------------------------------------------
-- Overflow-Handling for secent PRM Ticket numbers

-- drop table "W5SIEM_secent_of";
create table "W5SIEM_secent_of" (
 msghash              VARCHAR2(64),
 id                   INTEGER,     -- dummy id entry
 prmid                VARCHAR2(32),
 firstprmid           VARCHAR2(32),
 firstprmiddate       DATE,
 prmcomment           VARCHAR2(4000),
 rskid                VARCHAR2(32),
 rskcomment           VARCHAR2(4000),
 modifyuser           NUMBER(*,0),
 dmodifydate          DATE,
 constraint "W5SIEM_secent_of_pk" primary key (msghash)
);
grant select,insert,update,delete on "W5SIEM_secent_of" to W5I;
create or replace synonym W5I.W5SIEM_secent_of for "W5SIEM_secent_of";
-- ---------------------------------------------------------------




--- ab hier sind alles nur Tests und versuche!

-- drop table "W5SIEM_secscanruntime";
create table "W5SIEM_secscanruntime" (
   stype       VARCHAR2(128),
   program     VARCHAR2(128),
   lastrun     DATE not null,
   exitcode    INT
);
grant select on "W5SIEM_secscanruntime" to W5I;
grant select,insert,update,delete on "W5SIEM_secscanruntime" to W5SIEM;
create or replace synonym W5SIEM.secscanruntime for "W5SIEM_secscanruntime";
create or replace synonym W5I.W5SIEM_secscanruntime for "W5SIEM_secscanruntime";


-- detect latest secscan on ICTO-ID
create or replace view "W5SIEM_latestsecscan" as
with scanbase as (
  select ref,launch_datetime,ictoid,title,importdate
  from "W5SIEM_secscan"  
  where launch_datetime>SYSDATE-90
)
select scanbase.ref,
       scanbase.ictoid,
       scanbase.title,
       scanbase.launch_datetime,
       scanbase.importdate
from scanbase join (
   select distinct ref,
          max(launch_datetime) over (partition by ictoid) as maxdate 
   from scanbase where title like '%_vFWI_%'
   union
   select distinct ref,
          max(launch_datetime) over (partition by ictoid) as maxdate 
   from scanbase where title not like '%_vFWI_%'
   ) cur on cur.ref=scanbase.ref
order by scanbase.launch_datetime;
grant select on "W5SIEM_latestsecscan" to W5I;
grant select on "W5SIEM_latestsecscan" to W5SIEM;
create or replace synonym W5SIEM.latestsecscan for "W5SIEM_latestsecscan";
create or replace synonym W5I.W5SIEM_latestsecscan for "W5SIEM_latestsecscan";

-- drop materialized view "mview_W5SIEM_finding";
create materialized view "mview_W5SIEM_finding"
   refresh complete start with TRUNC(SYSDATE+1)+((1/24)*6)
   next SYSDATE+(1/24)
   as
with secentcatbase as (
   select
      replace(standard_hash(
         "W5SIEM_secscan".ref||"W5SIEM_secent".ipaddress||'-'||"W5SIEM_secent".category,'SHA256'),' ','') id,
      replace(standard_hash("W5SIEM_secent".ipaddress||'-'||"W5SIEM_secent".category,'SHA256'),' ','') sectoken,
      "W5SIEM_secent".ipaddress,
      "W5SIEM_secent".category,
      "W5SIEM_secent".title||
      case when "W5SIEM_secent".port is not null then ' at Port:'|| "W5SIEM_secent".port end ||
      chr(10) ||
      case when length("W5SIEM_secent".results)>200 then 
                substr( "W5SIEM_secent".results, 0, 200 ) || '...' 
           else "W5SIEM_secent".results 
       end || chr(10) ||
      'https://darwin.telekom.de/darwin/auth/tssiem/secent/ById/'||"W5SIEM_secent".id dsc ,
      "W5SIEM_secent".ref
   from "W5SIEM_secent"
   join "W5SIEM_secscan"
      on "W5SIEM_secent".ref="W5SIEM_secscan".ref
   where "W5SIEM_secent".severity in (4,5) and "W5SIEM_secent".pci_vuln='yes')
select id,decode("W5SIEM_latestsecscan".ref,NULL,1,0) isdel,sectoken,ipaddress,category, 
replace(replace(
                XmlAgg(
                  XmlElement("a", dsc)
                  order by
                  id desc nulls last)
                  .getClobVal(),
              '<a>', ''),
            '</a>',chr(10)||chr(10)) as detaildesc
from secentcatbase 
left outer join "W5SIEM_latestsecscan"
  on "W5SIEM_latestsecscan".ref=secentcatbase.ref
group by id,sectoken,ipaddress,category,decode("W5SIEM_latestsecscan".ref,NULL,1,0);



