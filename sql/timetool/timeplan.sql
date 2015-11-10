use w5base;
create table timeplan (
  id         bigint(20) NOT NULL,
  name       varchar(60) NOT NULL,
  cistatus   int(2)      NOT NULL,
  mandator   bigint(20)  default NULL,
    adm            bigint(20)  default NULL,
    adm2           bigint(20)  default NULL,
    tmode          varchar(80) default NULL, visiblemode int(1) default '0',
    description    longtext    default NULL,
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY applid (id),key(tmode),
  UNIQUE KEY name (name),KEY(mandator),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table tspanentry (
  id         bigint(20) NOT NULL,
     tfrom         datetime    NOT NULL default '0000-00-00 00:00:00',
     tto           datetime    default NULL,
     timeplanref   bigint(20)  NOT NULL     comment 'id of timeplan',
     useridref     bigint(20)  default NULL comment 'id of user, if personplan',
     dataref       varchar(20) default NULL comment 'data name, if resurceplan',
     subsys        varchar(40) default NULL comment 'calendar module',
     entrytyp      char(20)    default NULL comment 'usage depend on subsys',
     cistatus      int(2)      NOT NULL     comment 'usage depend on subsys',
     comments      longtext    default NULL,
     additional    longtext    default NULL comment 'usage depend on subsys',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  KEY s1 (tfrom),key userid (useridref), key s2 (tto),
  UNIQUE KEY tfrom (tfrom,entrytyp,useridref,timeplanref,subsys),
  UNIQUE KEY span  (tfrom,tto,dataref,useridref,timeplanref,subsys),
  UNIQUE KEY `srcsys` (srcsys,srcid),key (useridref)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table tspanentry add name varchar(40) default NULL,add key(name);
alter table timeplan   add data longtext default NULL;
alter table timeplan   add defstarthour int(2) default '0';
alter table timeplan   add prnapprovedline varchar(128) default NULL;
alter table timeplan   add lineheight varchar(10) default 'auto';
alter table timeplan   add vbarcolor  varchar(20) default 'blue';
create table timeplanworkgroup (
  id         bigint(20) NOT NULL,
  name       varchar(128) NOT NULL,
  cistatus   int(2)      NOT NULL,
  mandator   bigint(20)  default NULL,
    adm            bigint(20)  default NULL,
    adm2           bigint(20)  default NULL,
    mincomposition int(12)     default '0',
    restrictive    int(1)      default '0',
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY applid (id),
  UNIQUE KEY name (name),KEY(mandator),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
