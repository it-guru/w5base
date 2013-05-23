use w5base;
create table lnkbprocessappl (
  id           bigint(20) NOT NULL,
  bprocess     bigint(20) NOT NULL,
  appl         bigint(20),
  relevance    int(2)     NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',   
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,       
  PRIMARY KEY  (id),
  KEY bprocess (bprocess),
  KEY appl (appl),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
create table lnkbprocesssystem (
  id           bigint(20) NOT NULL,
  bprocess     bigint(20) NOT NULL,
  system       bigint(20) NOT NULL,
  relevance    int(2)     NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',   
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,       
  PRIMARY KEY  (id),
  KEY bprocess (bprocess),
  KEY system (system),
  UNIQUE KEY `srcsys` (srcsys,srcid)
);
alter table lnkbprocessappl add appfailinfo longtext default NULL;
alter table lnkbprocessappl add autobpnotify int(1) default '0';
drop table lnkbprocesssystem;
rename table lnkbprocessappl to lnkbprocessbusinessservice;
alter table lnkbprocessbusinessservice add businessservice bigint(20) NOT NULL;
set FOREIGN_KEY_CHECKS=0;
alter table lnkbprocessbusinessservice add FOREIGN KEY fk_bs (businessservice) REFERENCES businessservice (id) ON DELETE CASCADE;
set FOREIGN_KEY_CHECKS=1;
alter table businessservice add databoss  bigint(20);
