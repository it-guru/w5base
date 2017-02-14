
-- drop materialized view "mview_FLEXERA_system";
create materialized view "mview_FLEXERA_system"
   refresh complete start with sysdate
   next sysdate+(1/24)*3
   as
select * from w5base.system@flexerap;

CREATE INDEX "FLEXERA_system_id1"
   ON "mview_FLEXERA_system"(id) online;
CREATE INDEX "FLEXERA_system_id2"
   ON "mview_FLEXERA_system"(systemname) online;

-- drop view "W5I_FLEXERA_system";
create view "W5I_FLEXERA_system" as
select "mview_FLEXERA_system".*,
       "W5I_FLEXERAsup__system_of".systemid
from "mview_FLEXERA_system"
   left outer join "W5I_FLEXERAsup__system_of"
        on "mview_FLEXERA_system".flexerasystemid=
           "W5I_FLEXERAsup__system_of".flexerasystemid;

grant select on "W5I_FLEXERA_system" to W5I;
create or replace synonym W5I.FLEXERA_system for "W5I_FLEXERA_system";

