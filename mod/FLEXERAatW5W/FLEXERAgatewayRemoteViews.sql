
-- drop materialized view "mview_FLEXERA_system";
create materialized view "mview_FLEXERA_system"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select * from w5base.system@flexerap;

CREATE INDEX "FLEXERA_system_id1"
   ON "mview_FLEXERA_system"(flexerasystemid) online;
CREATE INDEX "FLEXERA_system_id2"
   ON "mview_FLEXERA_system"(systemname) online;


create or replace view "W5I_FLEXERA_system" as
select "mview_FLEXERA_system".*,
       "W5I_FLEXERA__systemidmap_of".systemid
from "mview_FLEXERA_system"
   left outer join "W5I_FLEXERA__systemidmap_of"
        on "mview_FLEXERA_system".flexerasystemid=
           "W5I_FLEXERA__systemidmap_of".flexerasystemid;

grant select on "W5I_FLEXERA_system" to W5I;
create or replace synonym W5I.FLEXERA_system for "W5I_FLEXERA_system";

-- drop materialized view "mview_FLEXERA_instpkgsoftware";
create materialized view "mview_FLEXERA_instpkgsoftware"
   refresh complete start with sysdate
   next sysdate+(1/24)*18
   as
select * from w5base.instpkgsoftware@flexerap;

CREATE INDEX "FLEXERA_instpkgsoftware_id1"
   ON "mview_FLEXERA_instpkgsoftware"(id) online;
CREATE INDEX "FLEXERA_instpkgsoftware_id2"
   ON "mview_FLEXERA_instpkgsoftware"(flexerasystemid) online;

create or replace view "W5I_FLEXERA_instpkgsoftware" as
select "mview_FLEXERA_instpkgsoftware".*
from "mview_FLEXERA_instpkgsoftware";

grant select on "W5I_FLEXERA_instpkgsoftware" to W5I;
create or replace synonym W5I.FLEXERA_instpkgsoftware for "W5I_FLEXERA_instpkgsoftware";


