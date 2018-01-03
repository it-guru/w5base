use w5base;
create table custcontrcrono (
  id          bigint(20)  NOT NULL,
  custcontract  bigint(20)  NOT NULL,
  month         char(7)     NOT NULL, 
  name          varchar(40) NOT NULL, 
  fullname      varchar(80) default NULL,
  applications  longtext    default NULL, 
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  KEY(name),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(modifydate),
  FOREIGN KEY fk_custcontract (custcontract)
              REFERENCES custcontract (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table mgmtitemgroup (
  id         bigint(20)   NOT NULL,
  name       varchar(40)  NOT NULL,cistatus    int(2)      NOT NULL,
  databoss   bigint(20)   default NULL,
  additional longtext     default NULL,
  comments   longtext     default NULL,
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
  KEY(name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=0;
create table lnkmgmtitemgroup(
  id         bigint(20)   NOT NULL,
  mgmtitemgroup   bigint(20)   NOT NULL,
  appl             bigint(20)   default NULL,
  businessservice  bigint(20)   default NULL,
  businessprocess  bigint(20)   default NULL,
  location         bigint(20)   default NULL,
  comments   longtext     default NULL, 
  lnkfrom datetime NOT NULL,lnkto datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),key(lnkfrom),key(lnkto),
  KEY (mgmtitemgroup),
  UNIQUE (appl,mgmtitemgroup),
  UNIQUE (businessprocess,mgmtitemgroup),
  UNIQUE (businessservice,mgmtitemgroup),
  UNIQUE (location,mgmtitemgroup),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY fk_mgmtitemgroup (mgmtitemgroup)
              REFERENCES mgmtitemgroup (id) ON DELETE CASCADE,
  FOREIGN KEY fk_appl (appl)
              REFERENCES appl (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_businessprocess (businessprocess)
              REFERENCES businessprocess (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_businessservice (businessservice)
              REFERENCES businessservice (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_location (location)
              REFERENCES location (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
alter table mgmtitemgroup add grouptype char(20) default NULL;
alter table mgmtitemgroup add lastqcheck datetime default NULL,add key(lastqcheck);
alter table lnkmgmtitemgroup add notify1on datetime default NULL;
alter table lnkmgmtitemgroup add notify1off datetime default NULL;
alter table mgmtitemgroup add rundowncomment longtext, add rundowndate datetime,add rundownrequestor bigint(20);
alter table lnkmgmtitemgroup add rlnkto datetime default NULL;
