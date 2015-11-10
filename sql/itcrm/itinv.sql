use w5base;
create table itcrmappl (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  origname   varchar(40) NOT NULL, 
    customerprio   int(2)      default NULL,
    customer       bigint(20)  default NULL,
    custapplid     varchar(20) default NULL,
    description    longtext    default NULL,
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key(customer),
  KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table itcrmappl add custmgmttool varchar(20) default NULL;
alter table itcrmappl add key(custmgmttool);
alter table itcrmappl add businessowner bigint(20) default NULL;
alter table itcrmappl add itmanager bigint(20) default NULL;
