| directlnktype   | directlnkmode | scworkflowid |
|=================|===============|==============|
| tssc::incident  | w5base2extern | NULL|inmid   | Workflow has been recored
|                 |               |              | and now we are waiting to
|                 |               |              | get an offcial Incident no.
|                 |               |              | from SC.
|                 |               |              |
|------------------------------------------------|
| tssc::incident  | stopped       | any value    | SC has been answered with
|                 |               |              | an unexpected result. In
|                 |               |              | this case all operations
|                 |               |              | are stopped.
|                 |               |              |
|------------------------------------------------|
| tssc::incident  | fixlink       | any value    | No SC conversations needed.
|                 |               |              | 
|                 |               |              | 
|                 |               |              | 
|                 |               |              |
|------------------------------------------------|
| tssc::incident  | extern2w5base | incidentno   | W5Base periodical scans SC
|                 |               |              | to refresh local informations
|                 |               |              |
|                 |               |              |
|                 |               |              |
|------------------------------------------------|
