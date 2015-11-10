use w5base;
create table projectroom (
  id         bigint(20)  NOT NULL,
  mandator   bigint(20)  NOT NULL,
  name       varchar(40) NOT NULL,
  cistatus   int(2)      NOT NULL,
    prio           int(1)      default '5',
    aclpolicy      int(3)      default '0',
    projectmode    int(3)      default '0',
    databoss       bigint(20)  default NULL,
    projectboss    bigint(20)  default NULL,
    projectboss2   bigint(20)  default NULL,
    responseteam   bigint(20)  default NULL,
    durationstart  datetime NOT NULL default '0000-00-00 00:00:00',
    durationend    datetime    default NULL,
    budgetmtl      float(8,2)  default NULL,
    budgetyear     float(8,2)  default NULL,
    budgetall      float(8,2)  default NULL,
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
  lastqcheck datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY mandator (mandator,name),
  KEY databoss (databoss),key prio(prio),
  KEY projectmode (projectmode),
  KEY aclpolicy (aclpolicy),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkprojectroom (
  id           bigint(20) NOT NULL,
  projectroom  bigint(20) NOT NULL,
  sortkey      bigint(20)  default NULL,
  objtype      varchar(40) default NULL,
  objid        varchar(40)  default NULL,
  importance   int(2)      default 1,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(10) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY obj (objtype,objid),
  KEY projectroom (projectroom),
  UNIQUE KEY `sortkey` (sortkey),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table projectroom add is_commercial  int(1) default '0';
alter table projectroom add conumber       varchar(20) default NULL;
alter table projectroom add is_allowlnkact int(1) default '0';
alter table projectroom add is_isrestirctiv int(1) default '0';
set FOREIGN_KEY_CHECKS=0;
alter table projectroom add FOREIGN KEY fk_projectroom_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
alter table projectroom add fullname  varchar(128) default '';
