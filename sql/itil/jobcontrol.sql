use w5base;
create table systemjob (
  id          bigint(20)   NOT NULL,
  name        varchar(128) NOT NULL,
  code        blob         NOT NULL, 
  maxparallel int(10)      NOT NULL,
  logpool     varchar(20)  NOT NULL,
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser  bigint(20) NOT NULL default '0',
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE name (name) 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE systemjobacl (
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
  KEY refid (refid),
  unique key aclmode (aclparentobj,refid,acltarget,aclmode,acltargetid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE lnksystemjobsystem (
  id bigint(20) NOT NULL,
  system      bigint(20) NOT NULL,
  systemjob   bigint(20) NOT NULL,
  additional  longtext   default NULL,
  comments    longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  unique key link (system,systemjob),
  key sj (systemjob),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table systemjob add remoteuser varchar(20) default 'w5base';
alter table systemjob add param blob;
create table systemjobtiming (
  id          bigint(20)   NOT NULL,
  jobid       bigint(20)   NOT NULL,
  systemid    bigint(20)   NOT NULL, 
  tinterval   int(2)       NOT NULL, 
  cistatus    int(2)       NOT NULL,
  plannedyear      int(20), 
  plannedmon       int(20), 
  plannedday       int(20), 
  plannedhour    int(20), 
  plannedmin     int(20), 
  plannedwdmon     int(1), 
  plannedwdtue     int(1), 
  plannedwdwed     int(1), 
  plannedwdthu     int(1), 
  plannedwdfri     int(1), 
  plannedwdsat     int(1), 
  plannedwdsun     int(1), 
  synccontrol    int(2), 
  maxlatency     int(2), 
  lastjobstart     datetime,
  lastjobid        bigint(20), 
  lastexitcode     bigint(20), 
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser  bigint(20) NOT NULL default '0',
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key systemid (systemid,jobid) ,key(tinterval),key(cistatus),
  key(lastjobstart,lastexitcode),unique src (srcid,srcsys)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table systemjobtiming add runcount int(20) default '0';
alter table systemjobacl add comments   longtext;
alter table systemjobacl add expiration datetime;
alter table systemjobacl add alertstate varchar(10);
