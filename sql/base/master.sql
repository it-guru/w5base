use w5base;
create table location (
  id         bigint(20) NOT NULL,
  name       varchar(255) NOT NULL,
  cistatus   int(2)      NOT NULL, comments blob,
    label          varchar(40)  NOT NULL,
    address1       varchar(40)  NOT NULL,
    address2       varchar(40)  default NULL,
    country        varchar(3)   NOT NULL,
    zipcode        varchar(6)   NOT NULL,
    location       varchar(40)  NOT NULL,
    roomexpr       varchar(255) default NULL,
    refcode1       varchar(255) default NULL,
    refcode2       varchar(255) default NULL,
    refcode3       varchar(255) default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name), UNIQUE KEY loc (label,location,address1,country),
  UNIQUE KEY `srcsys` (srcsys,srcid),key (refcode1),key(refcode2),key (refcode3)
);
create table history (
  id         bigint(20)   NOT NULL,
  name       varchar(128) NOT NULL,
    dataobject   varchar(128) NOT NULL,
    dataobjectid varchar(128) NOT NULL,
    operation    varchar(10)  NOT NULL,
    oldstate     blob,
    newstate     blob,comments blob,
    uivisible    int(2)   NOT NULL default '1',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  KEY name (name), KEY dataobject (dataobject,dataobjectid),
  UNIQUE KEY `srcsys` (srcsys,srcid),key (operation),key(createdate)
);
create table eventspool (
  id         bigint(20)   NOT NULL,
  spooltag   varchar(80)  NOT NULL,
  eventname  varchar(128) NOT NULL,
  param          blob,
  retryinterval  int(11),
  maxretry       int(11),
  failcount      int(11) NOT NULL default '0',
  firstcalldelay bigint(11) NOT NULL,
  unixcalltime   bigint(11) NOT NULL,
  lasttrytime    bigint(11) NOT NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE spooltag (spooltag) 
);
create table googlekeys (
  id         bigint(20)   NOT NULL,
  name       varchar(128) NOT NULL,
  googlekey  varchar(128) NOT NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE name (name) 
);
alter table location add gpslongitude varchar(40);
alter table location add gpslatitude varchar(40);
create table userdefault (
  id         bigint(20)   NOT NULL,
  userid     bigint(20)   NOT NULL,
  name       varchar(80)  NOT NULL,
  val        blob,
  ishidden   int(1)  default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE name (userid,name) 
);
create table userbookmark (
  id         bigint(20)   NOT NULL,
  userid     bigint(20)   default NULL,
  name       varchar(128) NOT NULL,
  src        blob,
  booktype   varchar(20),
  target     varchar(20),
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE userid(userid,name) ,key name (name),key modifiydate(modifydate)
);
create table w5stat (
  id         bigint(20)   NOT NULL,
  statgroup  varchar(40)  NOT NULL,
  name       varchar(128) NOT NULL, nameid bigint(20),
  month      char(6)      NOT NULL,
  stats      mediumblob,comments blob,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys     varchar(10) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload),
  UNIQUE userid(month,name,statgroup),key name (statgroup,name),key (nameid)
);
create table mailsignatur (
  id         bigint(20)   NOT NULL,
  name       varchar(128) NOT NULL,
  userid     bigint(20)   NOT NULL,
  replyto    varchar(128),
  htmlsig    blob,
  textsig    blob,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload),
  UNIQUE  nameuid(userid,name),key name (name)
);
create table postitnote (
  id         bigint(20)   NOT NULL,
  name           varchar(20) NOT NULL,
  mandator       bigint(20)  default NULL,
  comments       blob        NOT NULL,
  publicstate    int(2)      default '0', 
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE name (name) 
);
alter table location add response bigint(20) default NULL;
alter table location add response2 bigint(20) default NULL;
alter table mailsignatur add fromaddress varchar(128) default NULL;
alter table userbookmark add comments blob;
alter table w5stat change month monthkwday varchar(8) not NULL;
create table w5statmaster (
  id         bigint(20)   NOT NULL,
  statgroup  varchar(40)  NOT NULL,
  name       varchar(128) NOT NULL,
  monthkwday char(8)      NOT NULL,
  statval    text,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  srcsys     varchar(10) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload),
  UNIQUE userid(monthkwday,name,statgroup),key name (statgroup,name)
);
