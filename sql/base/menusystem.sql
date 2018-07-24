use w5base;
CREATE TABLE menu (
  menuid bigint(20) NOT NULL default '0',
  parentid bigint(20),
  fullname varchar(50) NOT NULL default '',
  target varchar(128) NOT NULL default '',
  func varchar(40) NOT NULL default '',
  config varchar(40) NOT NULL default '',
  prio int(22) NOT NULL default '0',
  translation varchar(80) NOT NULL default '',
  useobjacl int(1) NOT NULL default '0',
  param longtext NOT NULL default '',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (menuid),
  UNIQUE KEY name (config,fullname)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE menuacl (
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
  KEY faqid (refid),
  unique key aclmode (aclparentobj,refid,acltarget,aclmode,acltargetid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table menuacl add comments longtext;
alter table menuacl add expiration datetime;
alter table menuacl add alertstate varchar(10);
alter table menu add datamodel varchar(40);
