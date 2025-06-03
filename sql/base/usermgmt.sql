use w5base;
CREATE TABLE grp (
  grpid bigint(20) NOT NULL default '0',
  parentid bigint(20) default NULL,
  fullname varchar(255) NOT NULL default '',
  name varchar(30) NOT NULL default '',
  cistatus int(11) NOT NULL default '0',
  email varchar(128) NOT NULL default '',
  supervisor bigint(20) NOT NULL default '0',
  srcsys varchar(40) default NULL,
  srcid varchar(128) default NULL,
  srcload datetime default NULL,
  comments blob,additional longtext    default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (grpid),unique(srcsys,srcid),
  UNIQUE KEY fullname (fullname),
  KEY parentid (parentid),
  KEY name (name,cistatus),key(cistatus)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
insert into grp (grpid,fullname,name,cistatus) values(2,'support','support',4);
insert into grp (grpid,fullname,name,cistatus) values(1,'admin','admin',4);
insert into grp (grpid,fullname,name,cistatus) values(-1,'valid_user','valid_user',4);
insert into grp (grpid,fullname,name,cistatus) values(-2,'anonymous','anonymous',4);
CREATE TABLE lnkgrpuser (
  lnkgrpuserid bigint(20) NOT NULL default '0',
  grpid bigint(20) NOT NULL default '0',
  userid bigint(20) NOT NULL default '0',
  createuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  deletedate datetime default NULL,
  srcsys varchar(20) default NULL,
  srcid varchar(20) default NULL,
  srcload datetime default NULL,expiration datetime,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (lnkgrpuserid),
  UNIQUE KEY userid_2 (userid,grpid),
  KEY userid (userid,deletedate),
  KEY grpid (grpid)
);
CREATE TABLE lnkgrpuserrole (
  lnkgrpuserroleid bigint(20) NOT NULL default '0',
  lnkgrpuserid bigint(20) NOT NULL default '0',
  nativrole char(20) not null,
  createuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  deletedate datetime default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (lnkgrpuserroleid),
  UNIQUE (lnkgrpuserid,nativrole),
  key nativrole(nativrole)
);
CREATE TABLE usersubst (
  usersubstid bigint(20) NOT NULL default '0',
  userid      bigint(20) NOT NULL default '0',
  account     varchar(100) NOT NULL default '0',
  active      int(1) not null,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (usersubstid),
  UNIQUE (userid,account),key(account)
);
CREATE TABLE usersubstusage (
  usersubstusageid bigint(20) not null,
  userid           bigint(20) NOT NULL default '0',
  account          varchar(100) NOT NULL default '0',
  PRIMARY KEY  (userid,account,usersubstusageid)
);
CREATE TABLE contact (
  userid bigint(20) NOT NULL default '0',
  fullname varchar(255) NOT NULL default '',
  cistatus int(11) NOT NULL default '0',
  givenname varchar(50) NOT NULL default '',
  surname varchar(30) NOT NULL default '',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  email varchar(128),managedby bigint(20) default '1',
  options text NOT NULL,comments blob,
  timezone varchar(40) NOT NULL default 'CET',
  lang varchar(10),usertyp varchar(10) default 'user',
  pagelimit int(4) default '20',
  office_persnum varchar(20) default NULL,
  office_elecfacsimile varchar(80) default NULL,
  office_facsimile varchar(80) default NULL,
  office_mobile varchar(80) default NULL,
  office_phone varchar(80) default NULL,
  office_street varchar(80) default NULL,
  office_location varchar(80) default NULL,
  office_zipcode varchar(10) default NULL,
  private_elecfacsimile varchar(80) default NULL,
  private_facsimile varchar(80) default NULL,
  private_mobile varchar(80) default NULL,
  private_phone varchar(80) default NULL,
  private_street varchar(80) default NULL,
  private_location varchar(80) default NULL,
  private_zipcode varchar(10) default NULL,
  posix_identifier char(8), ds_identifier char(128),
  picture blob,
  PRIMARY KEY  (userid),
  UNIQUE email(email),
  UNIQUE fullname (fullname),
  UNIQUE posix_identifier (posix_identifier), UNIQUE ds_id(ds_identifier),
  KEY surname (surname),KEY managedbygrp(managedby),
  KEY givenname (givenname),key(cistatus),
  KEY office_location (office_location),
  KEY private_location (private_location)
)  ENGINE=INNODB;
CREATE TABLE useraccount (
  account varchar(128) NOT NULL default '',
  userid bigint(20),password varchar(128),
  requestemail char(128),posturi text,requestcode varchar(20),
  requestemailwf bigint(20),apitoken varchar(128),ipacl longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (account),
  KEY userid (userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE userlogon (
  account varchar(128) NOT NULL default '',
  loghour varchar(10) NOT NULL default '',
  logondate datetime default NULL,
  logonbrowser varchar(128) default NULL,
  logonip varchar(100) default NULL,lang varchar(10),site varchar(128),
  PRIMARY KEY  (account,loghour),key(logondate)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
CREATE TABLE userstate (
  userid bigint(20) NOT NULL default '0',
  unused_warncount tinyint(4) default '0',
  unused_warndate datetime default NULL,
  email_checked datetime default NULL,
  ipacl varchar(255) default NULL,
  PRIMARY KEY  (userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE userview (
  id bigint(20) NOT NULL default '0',
  module varchar(128) NOT NULL default '',
  name varchar(10) NOT NULL default '',
  viewrevision int(11) NOT NULL default '0',
  viewdata longtext NOT NULL,
  mdate timestamp NOT NULL,
  cdate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  userid     bigint(20) NOT NULL,
  createuser bigint(20) NOT NULL,
  modifyuser bigint(20) NOT NULL,
  KEY(userid),
  PRIMARY KEY  (id),
  UNIQUE KEY name (name,module,userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table mandator (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL, cistatus int(11) NOT NULL default '0',
  grpid      bigint(20)  default NULL,
  additional longtext    default NULL,
  comments   longtext    default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(10) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,lastqcheck datetime default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY applid (id),
  UNIQUE KEY name (name),key(lastqcheck),
  UNIQUE KEY grpid (grpid),key(cistatus),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE lnkcontact (
  id          bigint(20) NOT NULL,
  refid       bigint(20) NOT NULL,
  parentobj   varchar(30) NOT NULL,
  target      varchar(30) default NULL,
  targetid    bigint(20) NOT NULL,expiration datetime,alertstate varchar(10),
  croles      longtext default NULL,
  comments    longtext default NULL,
  createuser  bigint(20) default NULL,
  modifyuser  bigint(20) default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(80) default 'w5base',
  srcid       varchar(40) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  KEY refid (refid),
  unique key objcontact (refid,parentobj,target,targetid),
  UNIQUE KEY `srcsys` (srcsys,srcid),KEY target(targetid,target)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE infoabo (
  id         bigint(20)  NOT NULL,
  userid     bigint(20)  NOT NULL,
  parentobj  varchar(40) NOT NULL,
  refid      bigint(20)  NOT NULL,
  cistatus   int(2)      NOT NULL,
  active     int(1) default '1',
  mode       varchar(128) NOT NULL default '',
  notifyby   varchar(20)  NOT NULL default 'email',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) default NULL,
  modifyuser  bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys      varchar(10) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,expiration datetime,
  PRIMARY KEY  (id),
  KEY findnotiy (parentobj,refid,mode),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(mode),
  unique key pk (userid,parentobj,refid,mode)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkgrpuser add alertstate varchar(10);
CREATE TABLE phonenumber (
  id         bigint(20)  NOT NULL,
  parentobj  varchar(20) NOT NULL,
  refid      bigint(20)  NOT NULL,
  name       varchar(40)  NOT NULL,
  number     varchar(40)  NOT NULL, comments    longtext default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) default NULL,
  modifyuser  bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys      varchar(10) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  KEY findrefid (parentobj,refid),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  key pk (parentobj,refid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE lnkqrulemandator (
  lnkqrulemandatorid bigint(20) NOT NULL default '0',
  mandator   bigint(20)  NOT NULL default '0',
  qrule      varchar(40) NOT NULL default '0',
  comments   longtext    default NULL,
  createuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys varchar(20) default NULL,
  srcid varchar(20) default NULL, hotusestart datetime,
  srcload datetime default NULL,  expiration  datetime,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (lnkqrulemandatorid),
  UNIQUE KEY mandator (mandator,qrule),
  KEY qrule (qrule),key(expiration)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkgrpuser add comments longtext default NULL;
alter table lnkqrulemandator add dataobj varchar(40) default NULL,add key(dataobj);
alter table lnkqrulemandator add additional blob;
alter table contact add allowifupdate int(2) default 0;
alter table contact add lastqcheck datetime default NULL,add key(lastqcheck);
alter table grp  add lastqcheck datetime default NULL,add key(lastqcheck);
alter table grp  add description varchar(128);
alter table grp  add lastknownbossemail blob;
alter table contact add ssh1publickey blob default NULL;
alter table contact add ssh2publickey blob default NULL;
alter table contact add office_costcenter varchar(20) default NULL,add key(office_costcenter);
alter table contact add office_accarea varchar(20) default NULL,add key(office_accarea);
alter table contact add office_room varchar(20) default NULL;
alter table contact add secstate int(1) default '2';
alter table grp  add is_org      int(1) default '0';
alter table grp  add is_line     int(1) default '0';
alter table grp  add is_depart   int(1) default '0';
alter table grp  add is_resort   int(1) default '0';
alter table grp  add is_team     int(1) default '0';
alter table grp  add is_orggroup int(1) default '0';
alter table contact add formdata    longtext    default NULL;
alter table contact add dialermode  varchar(20) default 'HTML-Dial-Tag';
alter table contact add dialerurl   varchar(128);
alter table contact add dialeripref varchar(5);
alter table mandator add key(grpid);
alter table contact add gtctxt longtext default NULL;
alter table contact add gtcack datetime default NULL;
alter table contact add dateofbirth datetime default NULL;
alter table contact add persidentno varchar(50) default NULL;
alter table contact add driverlicno varchar(50) default NULL;
alter table contact add eurocarno   varchar(20) default NULL;
alter table contact add sixtcarno   varchar(20) default NULL;
alter table contact add dateofdatapriv      datetime     default NULL;
alter table contact add dateofdatapriv_edt  varchar(128) default NULL;
alter table contact add dateofworksafty     datetime     default NULL;
alter table contact add dateofworksafty_edt varchar(128) default NULL;
alter table contact add dateofcorruprot     datetime     default NULL;
alter table contact add dateofcorruprot_edt varchar(128) default NULL;
alter table contact add dateofvsnfd         datetime     default NULL;
alter table contact add dateofvsnfd_edt     varchar(128) default NULL;
alter table contact add dateofsecretpro     datetime     default NULL;
alter table contact add dateofsecretpro_edt varchar(128) default NULL;
alter table contact add killtimeout int(22) default '1000';
alter table contact add is_vsnfdsafe int(1) default '0';
alter table contact add w5mailsig longtext  default NULL;
create table userblacklist (
  id         bigint(20)   NOT NULL,
  email            varchar(128) default NULL,
  posix_identifier varchar(8) default NULL,
  account          varchar(128) default NULL,
  lockorgtransfer       int(1) default '0',
  lockcontactcreate     int(1) default '0',
  lockcreateci          int(1) default '0',
  lockcreateforumentry  int(1) default '0',
  lockcreatefaqentry    int(1) default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE email (email),
  UNIQUE posix_identifier (posix_identifier),
  UNIQUE account (account)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table contact add admcomments longtext default NULL;
alter table contact add ipacl longtext default NULL;
alter table infoabo add comments longtext default NULL;
alter table infoabo add lastqcheck datetime default NULL,add key(lastqcheck),add invalidsince datetime default null;
alter table contact add office_orgname  varchar(128) default NULL;
alter table contact add salutation char(2) default NULL;
alter table contact add country char(4) default NULL;
alter table contact add banalprotect int(1) default '0',add isw5support int(1) default'0',add key(isw5support);
alter table contact add pcontact bigint(20) default NULL, add FOREIGN KEY fk_pcontact (pcontact) REFERENCES contact (userid) ON DELETE CASCADE;
alter table contact add srcsys varchar(100) default 'w5base', add srcid varchar(100) default NULL,add srcload datetime default NULL, add UNIQUE KEY `srcsys` (srcsys,srcid);
alter table grp  add grppresentation longtext default NULL;
alter table lnkqrulemandator add cistatus int(2) default '4';
create table useradvice (
  id         bigint(20)   NOT NULL,
  userid     bigint(20)   NOT NULL,
  reldataobj       varchar(128) default NULL,
  reldataobjid     varchar(128) default NULL,rellabel varchar(128) default NULL,
  acknowledged     int(1) default '0',
  advicetext       longtext NOT NULL,
  comments         longtext default NULL,
  srcsys      varchar(80) default NULL,
  srcid       varchar(80) default NULL,
  srcload     datetime    default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) NOT NULL default '0',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  KEY datarel (reldataobj,reldataobjid,acknowledged),
  KEY userrel (userid,acknowledged)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table grp  add ext_refid1 varchar(40),add key(ext_refid1), add ext_refid2 varchar(80), add key(ext_refid2);
alter table contact add lastknownboss char(128) default NULL;
alter table contact add winhandling char(20) default 'windefault';
alter table contact add lastexternalseen date;
CREATE TABLE uservote (
  id          bigint(20) NOT NULL,
  refid       bigint(20) NOT NULL,
  parentobj   varchar(80) NOT NULL,
  entrymonth  char(7) NOT NULL,
  voteval     int(4) NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY voteinterval (entrymonth,createuser,parentobj,refid),
  KEY uEntry (parentobj,refid,createuser)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE userquerybreak (
  id          bigint(20) NOT NULL,
  userid      bigint(20) NOT NULL,
  dataobj     varchar(80) NOT NULL,
  duration    bigint(20),
  clientip    varchar(80),
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id),key(userid),key(createdate)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE w5plug (
  id         bigint(20) NOT NULL,
  dataobj    varchar(80) NOT NULL,
  plugmode   varchar(80) default 'HtmlDetail',
  name       varchar(80) NOT NULL,
  plugcode   longtext   default NULL,
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  key(createdate)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE lnkuserw5plug (
  id         bigint(20) NOT NULL,
  plugid     bigint(20) NOT NULL,
  userid     bigint(20) NOT NULL,
  active     int(1)     default '1',
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY u (userid,plugid),
  KEY plutg (plugid),
  key(createdate),
  FOREIGN KEY fk_user (userid) REFERENCES contact (userid) ON DELETE CASCADE,
  FOREIGN KEY fk_user (plugid) REFERENCES w5plug (id) ON DELETE CASCADE
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table grpindivfld (
  id         bigint(20) NOT NULL,
  name       varchar(80) NOT NULL,
  dataobject varchar(128) NOT NULL,
  grpview    bigint(20) NOT NULL,
  grpwrite   bigint(20) NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY name (dataobject,grpview),unique(grpview,name),
  FOREIGN KEY (grpview) REFERENCES grp (grpid) ON DELETE CASCADE
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table grpindivfld add directonly int(1) default '0';
alter table grpindivfld add rdonly int(1) default '0',add fldbehavior varchar(20) default 'singleline',add fldextra longtext;
alter table grp  add is_projectgrp  int(1) default '0';
alter table contact add lastknownpboss char(128) default NULL;
alter table phonenumber add showpublic int(1) default '1';
alter table contact add planneddismissaldate datetime default NULL;
alter table contact add notifieddismissaldate datetime default NULL;
alter table contact add office_sisnumber varchar(20) default NULL;
alter table grp add accarea varchar(20) default NULL,add sisnumber varchar(20) default NULL, add nsin varchar(20) default NULL,add isin varchar(20) default NULL, add comregnum varchar(20) default NULL;
alter table grp add srcurl varchar(256) default NULL;
alter table grp add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table contact add lorgchangedt datetime default NULL;
