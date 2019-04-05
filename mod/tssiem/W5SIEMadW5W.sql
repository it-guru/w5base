-- drop table "W5SIEM_secscan";
create table "W5SIEM_secscan" (
   ref                VARCHAR2(32) not null,
   id                 VARCHAR2(32) not null,
   ictoid             VARCHAR2(20) not null,
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
   rcvdate            DATE,
   constraint W5SIEM_secscan_pk primary key (ref)
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
   ipaddress            VARCHAR2(45) not null,
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

CREATE INDEX "W5SIEM_secent_i2"
   ON "W5SIEM_secent" (launch_datetime) online;

CREATE INDEX "W5SIEM_secent_i3"
   ON "W5SIEM_secent" (id) online;

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





-- drop table "W5SIEM_secscanruntime";
create table "W5SIEM_secscanruntime" (
   lastrun     DATE not null,
   exitcode    INT
);
grant select on "W5SIEM_secscanruntime" to W5I;
grant select,insert,update,delete on "W5SIEM_secscanruntime" to W5SIEM;
create or replace synonym W5SIEM.secscanruntime for "W5SIEM_secscanruntime";
create or replace synonym W5I.W5SIEM_secscanruntime for "W5SIEM_secscanruntime";


