| directlnktype   | directlnkmode | directlnkid |
|=================|===============|=============|
| tssc::incident  | w5base2extern | NULL        | Workflow has been recored
|                 |               |             | and now we are waiting to
|                 |               |             | get an offcial Incident no.
|                 |               |             | from SC.
|                 |               |             |
|-----------------------------------------------|
| tssc::incident  | externinit    | incidentno  | SC has been answered OK and
|                 |               |             | we have an offical Incident
|                 |               |             | number.
|                 |               |             |
|                 |               |             |
|-----------------------------------------------|
| tssc::incident  | stopped       | any value   | SC has been answered with
|                 |               |             | an unexpected result. In
|                 |               |             | this case all operations
|                 |               |             | are stopped.
|                 |               |             |
|-----------------------------------------------|
| tssc::incident  | extern2w5base | incidentno  | W5Base periodical scans SC
|                 |               |             | to refresh local informations
|                 |               |             |
|                 |               |             |
|                 |               |             |
|-----------------------------------------------|
