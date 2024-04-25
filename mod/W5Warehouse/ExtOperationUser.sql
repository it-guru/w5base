create or replace view "W5I_ExtOperationUser" as
select 'itil::system'     dataobj,
       ID                 dataobjid,
       SYSTEMID           configitemid,
       name,
       "EMAIL","DSID","POSIX","ACCESSLEVEL"
from "mview_W5I_SystemExtOperationUser"
union
select 'itil::swinstance' dataobj,
       ID                 dataobjid,
       SWINSTANCEID       configitemid,
       name,
       "EMAIL","DSID","POSIX","ACCESSLEVEL"
from "mview_W5I_SWInstanceExtOperationUser"
union
select 'itil::appl'       dataobj,
       ID                 dataobjid,
       APPLID             configitemid,
       name,
       "EMAIL","DSID","POSIX","ACCESSLEVEL"
from "mview_W5I_ApplExtOperationUser";

grant select on "W5I_ExtOperationUser" to W5I;
grant select on "W5I_ExtOperationUser" to W5I;
create or replace synonym W5I.ExtOperationUser
for "W5I_ExtOperationUser";

