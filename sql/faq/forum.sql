use w5base;
CREATE TABLE forumboard (
  id bigint(20) NOT NULL default '0',
  cistatus   int(2)      NOT NULL,
  faqcat bigint(20),
  name varchar(128) NOT NULL default '',
  boardgroup varchar(128) NOT NULL default '',
  comments blob,
  srcsys varchar(20) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  owner      bigint(20) default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY fullname (name,boardgroup),key (faqcat),key(boardgroup)
);
CREATE TABLE forumtopic (
  id bigint(20) NOT NULL default '0',
  forumboard bigint(20),
  name      varchar(128) NOT NULL default '',
  topicicon int(20) default NULL,
  comments longtext,
  viewcount int(20),
  srcsys varchar(20) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  owner      bigint(20) default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY fullname (forumboard,name),key name(name),fulltext(comments,name)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
CREATE TABLE forumentry (
  id bigint(20) NOT NULL default '0',
  forumtopic bigint(20),
  comments longtext,
  srcsys varchar(20) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  owner      bigint(20) default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  key name (forumtopic),fulltext(comments)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
CREATE TABLE forumboardacl (
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
alter table forumboardacl add comments longtext;
alter table forumboardacl add expiration datetime;
alter table forumboardacl add alertstate varchar(10);
CREATE TABLE forumtopicread (
  id bigint(20) NOT NULL default '0',
  forumtopic bigint(20),
  createdate    datetime NOT NULL default '0000-00-00 00:00:00',
  createuser    bigint(20) default NULL,
  clientipaddr  varchar(100) default NULL,
  PRIMARY KEY  (id),
  KEY forumread(forumtopic),key forumuser(createuser), key cdate(createdate)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table forumboard add boardheader blob;
