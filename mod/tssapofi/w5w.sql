-- drop table "W5I_OFI_saphier_import";
create table "W5I_OFI_saphier_import" (
 objectid             VARCHAR2(40),
 name                 VARCHAR2(15),
 fullname             VARCHAR2(256),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 dcreatedate          DATE,
 constraint "W5I_OFI_saphier_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_OFI_saphier_import" to W5I;
create or replace synonym W5I.OFI_saphier_import for "W5I_OFI_saphier_import";

-- drop table "W5I_OFI_kost_import";
create table "W5I_OFI_kost_import" (
 objectid             VARCHAR2(40),
 name                 VARCHAR2(15),
 description          VARCHAR2(4000),
 saphierid            VARCHAR2(40),
 deleted              Number(*,0) default '0',
 dmodifydate          DATE,
 dcreatedate          DATE,
 constraint "W5I_OFI_kost_import_pk" primary key (objectid)
);
grant select,insert,update,delete on "W5I_OFI_kost_import" to W5I;
create or replace synonym W5I.OFI_kost_import for "W5I_OFI_kost_import";


