use w5base;
create table autodiscengine (
  id          bigint(20)  NOT NULL,
  name        varchar(20) NOT NULL, fullname     varchar(128) NOT NULL,
  localdataobj varchar(80) NOT NULL, localkey    varchar(80) NOT NULL ,
  addataobj    varchar(80) NOT NULL, adkey       varchar(80) NOT NULL ,
  cistatus    int(2)      NOT NULL, 
  description longtext     default NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table autodiscvirt (
  id          bigint(20)  NOT NULL,
  engine      varchar(20) NOT NULL,
  elementname varchar(128) NOT NULL,
  quality     int(10) default '0',
  section     varchar(30)  NOT NULL,
  scanname    varchar(128) default NULL,
  scanextra1  varchar(128) default NULL,
  scanextra2  varchar(40)  default NULL,
  scanextra3  varchar(255) default NULL,
  modifydate  datetime    NOT NULL default '0000-00-00 00:00:00',
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(80) default NULL,
  srcload     datetime    default NULL,
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  UNIQUE KEY `srcsys` (srcsys,srcid), KEY `vkey` (engine,elementname)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=0;
create table autodiscent (
  id          bigint(20)  NOT NULL,
  engine      bigint(20)  NOT NULL,
  discon_system       bigint(20),
  discon_swinstance   bigint(20),
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  updatedate  datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id),
  UNIQUE KEY disc_on_system (engine,discon_system),
  UNIQUE KEY disc_on_swinstance (engine,discon_swinstance),
  FOREIGN KEY fk_autodiscengine (engine)
              REFERENCES autodiscengine (id) ON DELETE CASCADE,
  FOREIGN KEY fk_swinstance (discon_swinstance)
              REFERENCES swinstance (id) ON DELETE CASCADE,
  FOREIGN KEY fk_system (discon_system)
              REFERENCES system (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table autodiscrec (
  id          bigint(20)  NOT NULL,
  entryid     bigint(20)  NOT NULL,
  section     varchar(30) NOT NULL,  state int(1) default '1',
  scanname    varchar(128) NOT NULL,
  scandata    varchar(40)  NOT NULL,
  scanextra1  varchar(128),scanextra2 varchar(40),scanextra3 varchar(255),
  lnkto_asset        bigint(20),  assumed_asset        bigint(20),
  lnkto_system       bigint(20),  assumed_system       bigint(20),
  lnkto_swinstance   bigint(20),  assumed_swinstance   bigint(20),
  lnkto_ipaddress    bigint(20),  assumed_ipaddress    bigint(20),
  lnkto_lnksoftware  bigint(20),  assumed_lnksoftware  bigint(20),
  approve_user       bigint(20),
  approve_date       datetime,    misscount int(3) default '0',
  comments    longtext     default NULL, cleartoprocess int(1) default '1',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser  bigint(20) NOT NULL default '0',additional longtext default NULL,
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(80) default NULL,
  srcload    datetime    default NULL, backendload datetime default NULL,
  UNIQUE KEY `srcsys` (srcsys,srcid),
  key(assumed_asset),key(assumed_system),key(assumed_swinstance),
  key(assumed_ipaddress),key(assumed_lnksoftware),
  PRIMARY KEY  (id),key(scanname,entryid),
  FOREIGN KEY fk_autodiscent (entryid)
              REFERENCES autodiscent (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table autodiscmap (
  id          bigint(20)  NOT NULL,
  software    bigint(20),
  osrelease   bigint(20),
  probability int(2) default '9',
  engine      bigint(20)  NOT NULL,
  cistatus    int(2)      NOT NULL,
  scanname    varchar(128) NOT NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(engine,scanname),
  UNIQUE KEY `sname` (software,engine,scanname),
  UNIQUE KEY `osname` (osrelease,engine,scanname),
  UNIQUE KEY `hwname` (hwmodel,engine,scanname),
  FOREIGN KEY fk_autodiscengine (engine)
              REFERENCES autodiscengine (id) ON DELETE CASCADE,
  FOREIGN KEY fk_software (software)
              REFERENCES software (id) ON DELETE CASCADE,
  FOREIGN KEY fk_osrelease (osrelease)
              REFERENCES osrelease (id) ON DELETE CASCADE,
#  FOREIGN KEY fk_hwmodel (hwmodel)
#              REFERENCES hwmodel (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
alter table autodiscrec add forcesysteminst int(0) default '0';
