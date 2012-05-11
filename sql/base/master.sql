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
  srcsys     varchar(100) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name), UNIQUE KEY loc (label,location,address1,country),
  UNIQUE KEY `srcsys` (srcsys,srcid),key (refcode1),key(refcode2),key (refcode3)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
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
  srcsys     varchar(100) default 'w5base', 
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
  srcsys     varchar(100) default 'w5base', 
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
  srcsys     varchar(100) default 'w5base', 
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
  key name (name) 
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
  statname   varchar(128) NOT NULL,statval    text,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  srcsys     varchar(100) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload),
  UNIQUE statkey(monthkwday,name,statgroup,statname),key name (statgroup,name)
);
create table eventrouter (
  id         bigint(20)  NOT NULL,
  cistatus   int(2)      NOT NULL,
  srceventtype         varchar(40) NOT NULL,
  srcmoduleobject      varchar(40) NOT NULL,
  srcsubclass          varchar(40) default NULL,
  dstevent             varchar(40) NOT NULL,
  controldelay         int(2) default '0',
  controlmaxretry      int(2) default '0',
  controlretryinterval int(2) default '0',
  comments   blob,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  srcsys     varchar(100) default 'w5base', 
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload)
);
create table interview (
  id         bigint(20)   NOT NULL,
  name       varchar(255) NOT NULL,
  parentobj      varchar(30) NOT NULL,
  interviewcat   bigint(20),
  isrelevant     int(1)       default '1',
  prio           int(2)       default '1',
  comments       blob,
  questtyp       char(20) NOT NULL,
  questenum      varchar(255) NOT NULL,
  interviewstart datetime NOT NULL default '0000-00-00 00:00:00',
  interviewend   datetime NOT NULL default '0000-00-00 00:00:00',
  attadata   blob default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),KEY (parentobj)
);
create table interanswer(
  id         bigint(20)   NOT NULL,
  interviewid  bigint(20)   NOT NULL,
  parentobj    varchar(30) NOT NULL,
  parentid     bigint(20)   NOT NULL,
  answer       varchar(255) NOT NULL,
  prio         int(2)       default '1',
  relevant     int(1)       default '1',
  comments     blob,
  problemdesc  blob,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),KEY (parentid)
);
alter table interview add name_de varchar(255);
alter table interview add questclust varchar(80);
alter table interview add qtag varchar(80) not null, add unique key(qtag);
alter table interanswer add archiv varchar(80) not NULL;
alter table interview add contact bigint(20),add contact2 bigint(20);
alter table interview add restriction blob;
alter table interanswer add unique(parentobj,parentid,archiv,interviewid);
alter table location add additional blob;
alter table location add buildingservgrp bigint(20);
alter table location add databoss bigint(20);
alter table postitnote add parentobj varchar(30) NOT NULL;
alter table postitnote add parentid  varchar(30);
alter table postitnote add grp  bigint(20);
alter table postitnote add key parentg(parentobj,parentid,grp);
alter table postitnote add key parentm(mandator,parentobj,parentid);
CREATE TABLE interviewcat (
  id bigint(20) NOT NULL default '0',
  parentid bigint(20),
  fullname varchar(128) NOT NULL default '',
  name varchar(40) NOT NULL default '',
   comments blob,
   srcsys varchar(100) default NULL,
   srcid varchar(20) default NULL,
   srcload datetime default NULL,
   createdate datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate datetime NOT NULL default '0000-00-00 00:00:00',
   editor varchar(100) NOT NULL default '',
   realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY fullname (fullname),key name (name),key parentid (parentid)
);
alter table interview add cistatus int(2) NOT NULL;
alter table interviewcat add createuser bigint(20) NOT NULL default '0';
alter table interview add effectonmttr int(1) NOT NULL default '0';
alter table interview add effectonmtbf int(1) NOT NULL default '0';
create table mandatordataacl(
  id         bigint(20)   NOT NULL,prio int(5) default '5000',
  mandator   bigint(20)   NOT NULL,aclmode char(10) default 'allow',
  parentobj  varchar(30)  NOT NULL,
  dataname   varchar(40)  NOT NULL,
  target     varchar(30) default NULL,
  targetid   bigint(20) NOT NULL,
  comments   blob,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),KEY m(parentobj,mandator),key (prio)
);
#
alter table interview add boundpviewgroup varchar(40) default NULL;
alter table interview add boundpcontact   varchar(40) default NULL;
alter table interview add addquerydata    varchar(128) default NULL;
create table checklst (
  id          bigint(20)   NOT NULL,
  name        varchar(128) NOT NULL,
  cistatus    int(2)       NOT NULL,
    mandator    bigint(20)  default NULL,
    databoss    bigint(20)  default NULL,
    isprivat    int(2)      default '0',
  description longtext     default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  lastqcheck  datetime default NULL,
  PRIMARY KEY  (id),key(mandator),key(lastqcheck),
  UNIQUE KEY name (name)
);
create table checklstent (
  id          bigint(20)   NOT NULL,
  checklst      bigint(20)   NOT NULL,
  shortdesc     varchar(128) default NULL,
  description   longtext     default NULL,
  comments      longtext     default NULL,
  plannedeffort int(14)      default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  lastqcheck  datetime default NULL,
  PRIMARY KEY  (id),key(lastqcheck),
  KEY checklst (checklst)
);
alter table mandatordataacl add unique(prio,parentobj,dataname,mandator);
create table isocountry (
  id          bigint(20)   NOT NULL,
  cistatus    int(2)       default '4',
  token       char(2)      NOT NULL,
  fullname    varchar(40)  NOT NULL,name varchar(38) NOT NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  PRIMARY KEY (id),unique(token),unique(fullname)
);
insert into isocountry(token,name,fullname) values('DE','Germany','DE-Germany');
set FOREIGN_KEY_CHECKS=0;
create table lnklocationgrp (
  id          bigint(20)   NOT NULL,
    location    bigint(20)  not NULL,
    grp         bigint(20)  not NULL,
    relmode     char(20),
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base', 
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  FOREIGN KEY (grp) REFERENCES grp (grpid) ON DELETE RESTRICT,
  FOREIGN KEY (location) REFERENCES location (id) ON DELETE RESTRICT,
  PRIMARY KEY (id),key(location,relmode),unique(grp,location,relmode),
  UNIQUE KEY `srcsys` (srcsys,srcid),key srcload(srcload)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
alter table location   add lastqcheck datetime default NULL,add key(lastqcheck);
create table itemizedlist (
  id          bigint(20)   NOT NULL,
  cistatus    int(2)       default '4',prio  int(2) default '1000',
  selectlabel char(60) NOT NULL,
  name        char(20) NOT NULL,
  de_fullname varchar(40),labeldata longtext,
  en_fullname varchar(40),
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base', 
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY (id),unique(selectlabel,name)
);
alter table interview add additional  longtext default NULL;
alter table location add mandator bigint(20) default NULL;
create table iomap (
  id          bigint(20)   NOT NULL,
  cistatus    int(2)       default '4', mapprio int(2) default '10000',
  dataobject  varchar(128) NOT NULL,
  queryfrom   varchar(128) default NULL,
  criterion   longtext     default NULL,
  operation   longtext     default NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  PRIMARY KEY (id),key(dataobject),key(createdate),key(cistatus,createdate)
);
alter table iomap add fullname varchar(65), add key(fullname);
alter table isocountry add zipcodeexp varchar(128) default NULL;
alter table location modify zipcode varchar(16) NOT NULL;
set FOREIGN_KEY_CHECKS=0;
alter table location add FOREIGN KEY fk_location_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
alter table isocountry add is_eu int(1) default '0';
alter table isocountry add is_europe int(1) default '0';
alter table isocountry add is_asia int(1) default '0';
alter table isocountry add is_australia int(1) default '0';
alter table isocountry add is_namerica int(1) default '0';
alter table isocountry add is_samerica int(1) default '0';
alter table isocountry add is_africa int(1) default '0';
