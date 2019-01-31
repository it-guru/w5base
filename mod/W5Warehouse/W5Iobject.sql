create table "W5I_objectsnap" (
 snapclass            VARCHAR2(20) not null,
 snapdate             Date,
 id                   VARCHAR2(80),
 name                 VARCHAR2(512),
 dataobj              VARCHAR2(80),
 xmlrec               CLOB
);

grant select,update,insert,delete on "W5I_objectsnap" to W5I;
create or replace synonym W5I.objectsnap for "W5I_objectsnap";


