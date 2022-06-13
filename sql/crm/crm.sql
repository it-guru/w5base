use w5base;
create table businessprocess (
  id          bigint(20)  NOT NULL,
  fullname        varchar(254) NOT NULL,name varchar(100) not null,
  cistatus    int(2)      NOT NULL,
    mandator    bigint(20)  default NULL,pbusinessprocess bigint(20),
    databoss    bigint(20)  default NULL,
    customer    bigint(20)  default NULL,
    importance  int(2)      NOT NULL,
    indexno     bigint(20)  NOT NULL,
  description longtext     default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(80) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),key(mandator),key(indexno),
  UNIQUE KEY name (name,customer),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE businessprocessacl (
  aclid bigint(20) NOT NULL,
  refid bigint(20) NOT NULL,
  aclparentobj varchar(20) NOT NULL,
  aclmode varchar(10) NOT NULL default 'read',
  acltarget varchar(20) NOT NULL default 'user',
  acltargetid  bigint(20) NOT NULL,
  comments   longtext,
  expiration datetime,
  alertstate varchar(10),
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (aclid),
  KEY faqid (refid),
  unique key aclmode (aclparentobj,refid,acltarget,aclmode,acltargetid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table businessprocess add eventlang  varchar(5) default 'de';
update businessprocess set eventlang='de';
alter table businessprocess add processowner bigint(20)  default NULL;
alter table businessprocess add processowner2 bigint(20)  default NULL;
alter table businessprocess add customerprio int(2) default '2';
set FOREIGN_KEY_CHECKS=0;
alter table businessprocess add FOREIGN KEY fk_businessprocess_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
alter table businessprocess add nature varchar(20) default 'PROCESS';
alter table businessprocess add processmgrrole varchar(20) default NULL;
alter table businessprocess add processmgr2role varchar(20) default NULL;
