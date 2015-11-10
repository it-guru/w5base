use w5base;
CREATE TABLE faqcat (
  faqcatid bigint(20) NOT NULL default '0',
  parentid bigint(20),
  fullname varchar(128) NOT NULL default '',
  name varchar(30) NOT NULL default '',
   comments blob,
   srcsys varchar(20) default NULL,
   srcid varchar(20) default NULL,
   srcload datetime default NULL,
   createdate datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate datetime NOT NULL default '0000-00-00 00:00:00',
   editor varchar(100) NOT NULL default '',
   realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (faqcatid),
  UNIQUE KEY fullname (fullname),key name (name),key parentid (parentid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE faqcatacl (
  aclid bigint(20) NOT NULL,
  refid bigint(20) NOT NULL,
  aclparentobj varchar(20) NOT NULL,
  aclmode varchar(10) NOT NULL default 'add',
  acltarget varchar(20) NOT NULL default 'user',
  acltargetid  bigint(20) NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (aclid),
  KEY faqid (refid),
  unique key aclmode (aclparentobj,refid,acltarget,aclmode,acltargetid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table faqcatacl add comments longtext;
alter table faqcatacl add expiration datetime;
alter table faqcatacl add alertstate varchar(10);
