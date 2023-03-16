use w5base;
CREATE TABLE passxkey (
  keyid      bigint(20) NOT NULL default '0',
  userid     bigint(20) NOT NULL default '0',
  version    varchar(40) default NULL,
  additional longtext default NULL,
  srcsys     varchar(40) default NULL,
  srcid      varchar(20) default NULL,
  srcload    datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (keyid),
  UNIQUE (userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE passxpassword (
  passwordid bigint(20) NOT NULL default '0',
  userid     bigint(20) NOT NULL default '0',
  entryid    bigint(20) NOT NULL default '0',
  cryptdata  longtext NOT NULL,
  comments   longtext NOT NULL,
  srcsys     varchar(40) default NULL,
  srcid      varchar(20) default NULL,
  srcload    datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY (passwordid),
  KEY userid (userid),
  UNIQUE t (entryid,userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE passxentry (
  entryid    bigint(20) NOT NULL default '0',
  systemname varchar(80) NOT NULL default '',
  username   varchar(80) NOT NULL default '',
  scriptkey  varchar(128) default NULL, uniqueflag int(1) default '1',
  additional longtext default NULL, entrytype int(2) default '1',
  srcsys     varchar(40) default NULL,
  srcid      varchar(20) default NULL,
  srcload    datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY (entryid),
  KEY (modifyuser),key (entrytype),
  UNIQUE t (systemname,username,uniqueflag)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE passxacl (
  aclid bigint(20) NOT NULL,
  refid bigint(20) NOT NULL,
  aclparentobj varchar(20) NOT NULL,
  aclmode varchar(10) NOT NULL default 'read',
  acltarget varchar(20) NOT NULL default 'user',
  acltargetid  bigint(20) NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (aclid),
  KEY id (refid),
  unique key aclmode (aclparentobj,refid,acltarget,aclmode,acltargetid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table passxentry add comments longtext;
CREATE TABLE passxlog (
  logid bigint(20) NOT NULL,
  entryid bigint(20) NOT NULL,
  name varchar(80) NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (logid),
  KEY id (createuser),key (entryid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table passxacl add comments   longtext;
alter table passxacl add expiration datetime;
alter table passxacl add alertstate varchar(10);
alter table passxentry add quickpath text;
