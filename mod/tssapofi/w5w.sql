-- drop table "W5I_OFI_saphier_import";
create table "W5I_OFI_saphier_import" (
 objectid             VARCHAR2(40),
 name                 VARCHAR2(15),
 fullname             VARCHAR2(256),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 dsrcload             DATE,
 dcreatedate          DATE,
 constraint "W5I_OFI_saphier_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_OFI_saphier_import" to W5I;
create or replace synonym W5I.OFI_saphier_import for "W5I_OFI_saphier_import";
CREATE INDEX "W5I_OFI_saphier_import_idx0"
   ON "W5I_OFI_saphier_import" (name) online;
CREATE INDEX "W5I_OFI_saphier_import_idx1"
   ON "W5I_OFI_saphier_import" (fullname) online;


-- drop table "W5I_OFI_kost_import";
create table "W5I_OFI_kost_import" (
 objectid             VARCHAR2(40),
 name                 VARCHAR2(15),
 description          VARCHAR2(4000),
 company_code         VARCHAR2(40),
 saphierid            VARCHAR2(40),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 dsrcload             DATE,
 dcreatedate          DATE,
 constraint "W5I_OFI_kost_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_OFI_kost_import" to W5I;
create or replace synonym W5I.OFI_kost_import for "W5I_OFI_kost_import";
CREATE INDEX "W5I_OFI_kost_import_idx0"
   ON "W5I_OFI_kost_import" (name) online;
CREATE INDEX "W5I_OFI_kost_import_idx1"
   ON "W5I_OFI_kost_import" (saphierid) online;

-- drop table "W5I_OFI_wbs_import";
create table "W5I_OFI_wbs_import" (
 objectid             VARCHAR2(40),
 name                 VARCHAR2(40),
 description          VARCHAR2(4000),
 supervisor_ciamid    VARCHAR2(20),
 servicemgr_ciamid    VARCHAR2(20),
 delivermgr_ciamid    VARCHAR2(20),
 company_code         VARCHAR2(40),
 customer_link        VARCHAR2(40),
 saphierid            VARCHAR2(40),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 dsrcload             DATE,
 dcreatedate          DATE,
 constraint "W5I_OFI_wbs_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_OFI_wbs_import" to W5I;
create or replace synonym W5I.OFI_wbs_import for "W5I_OFI_wbs_import";
CREATE INDEX "W5I_OFI_wbs_import_idx0"
   ON "W5I_OFI_wbs_import" (name) online;
CREATE INDEX "W5I_OFI_wbs_import_idx1"
   ON "W5I_OFI_wbs_import" (saphierid) online;




