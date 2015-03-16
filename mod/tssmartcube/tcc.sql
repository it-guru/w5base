Datenstruktur:

Tabellen:
=========
W5REPO.W5SMARTCUBE_TCC_Report_Store  = Datenstore für den Empfang der TCC Daten
W5REPO.W5I_smartcube_tcc_report_of   = Overflow Tabelle für die RiManOS Komment.

Views:
======
W5REPO.W5SMARTCUBE_TCC_Report        = View über die Smartcube die Daten füllt
W5SMARTCUBE.TCC_REPORT               = Synonym auf W5REPO.W5SMARTCUBE_TCC_Report
                                    
W5REPO.W5I_smartcube_tcc_report      = View die die Smartcube Daten und die
                                       Overflow Tabelle miteinander vereint


Zugriffe von W5Base/Darwin auf die TCC Report Daten:
W5I.TCC_REPORT   = Synonym auf W5REPO.W5I_smartcube_tcc_report


-- drop table "W5I_smartcube_tcc_report_of";
create table "W5I_smartcube_tcc_report_of" (
 system_id             VARCHAR2(40),
 denyupd              NUMBER(*,0) default '0',
 denyupdcomments      VARCHAR2(4000),
 ddenyupdvalidto      DATE,
 modifyuser           NUMBER(*,0),
 dmodifydate          DATE,
 constraint "W5I_smartcube_tcc_report_of_pk" primary key (system_id)
);

create or replace view "W5I_smartcube_tcc_report" as
select "W5SMARTCUBE_TCC_Report".*,
       overflow.system_id      of_id,
       overflow.denyupd,
       overflow.denyupdcomments,
       overflow.ddenyupdvalidto,
       overflow.modifyuser,
       overflow.dmodifydate
from "W5SMARTCUBE_TCC_Report"
     left outer join "W5I_smartcube_tcc_report_of" overflow
        on "W5SMARTCUBE_TCC_Report".system_id=overflow.system_id;

grant select on "W5I_smartcube_tcc_report" to W5I;
grant select,insert,update,delete on "W5I_smartcube_tcc_report_of" to W5I;

create or replace synonym W5I.smartcube_tcc_report 
   for "W5I_smartcube_tcc_report";
create or replace synonym W5I.smartcube_tcc_report_of 
   for "W5I_smartcube_tcc_report_of";

