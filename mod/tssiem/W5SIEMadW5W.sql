-- drop table "W5SIEM_secscan";
create table "W5SIEM_secscan" (
 scanid               VARCHAR2(28) not null,
 ictoid               VARCHAR2(20) not null,
 label                VARCHAR2(128) not null,
 pdfsummary           BLOB,
 importdate           DATE not null,
 scandate             DATE not null,
 constraint "W5SIEM_secscan_pk" primary key (scanid)
);

grant select on "W5SIEM_secscan" to W5I;
grant select,insert on "W5SIEM_secscan" to W5SIEM;
create or replace synonym W5SIEM.secscan for "W5SIEM_secscan";
create or replace synonym W5I.W5SIEM_secscan for "W5SIEM_secscan";


-- drop table "W5SIEM_secent";
create table "W5SIEM_secent" (
 scanid               VARCHAR2(28) not null,
 ipaddress            VARCHAR2(45) not null,
 tracking_method      VARCHAR2(40),
 osname               VARCHAR2(128),
 ipstatus             VARCHAR2(128),
 qid                  NUMBER(20,0) not null,
 title                VARCHAR2(4000) not null,
 vuln_status          VARCHAR2(40),
 ent_type             VARCHAR2(40),
 servertiy            NUMBER(2,0) not null,
 port                 NUMBER(20,0),
 ssl                  NUMBER(1,0) default 0,
 first_detect         DATE not null,
 last_detect          DATE not null,
 vendor_reference     VARCHAR2(4000),
 threat               clob,
 impact               clob,
 exploitability       clob,
 associated_malware   VARCHAR2(255),
 pci_vuln             NUMBER(1,0) default 0,
 category             VARCHAR2(255),
 constraint "W5SIEM_secent_pk" foreign key (scanid) 
    REFERENCES "W5SIEM_secscan" (scanid)
);

grant select on "W5SIEM_secent" to W5I;
grant select,insert on "W5SIEM_secent" to W5SIEM;
create or replace synonym W5SIEM.secent for "W5SIEM_secent";
create or replace synonym W5I.W5SIEM_secent for "W5SIEM_secent";


