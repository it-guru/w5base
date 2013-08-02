use w5base;
set FOREIGN_KEY_CHECKS=0;
CREATE TABLE replicatepartner (
  id   bigint(20)    NOT NULL,
  name varchar(128)  NOT NULL,cistatus   int(2)      NOT NULL,
  comments           longtext  default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) ENGINE=INNODB;
CREATE TABLE replicateobject (
  id   bigint(20)    NOT NULL default '0',
  name varchar(40)   NOT NULL,
  replpartner        bigint(20)    NOT NULL,
  replview           longtext  default NULL,
  allow_phase1       int(1)    default '1',
  allow_phase2       int(1)    default '1',
  allow_phase3       int(1)    default '1',
  entrycount         bigint(20) default '0', latency decimal(8,2),
  comments    longtext  default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY replpartner (replpartner),
  UNIQUE KEY name (name)
) ENGINE=INNODB;
CREATE TABLE replicatestat (
  id   bigint(20)    NOT NULL default '0',
  replobject         bigint(20)    NOT NULL,
  phase              int(1)   NOT NULL,
  startdate          datetime NOT NULL default '0000-00-00 00:00:00',
  enddate            datetime NOT NULL default '0000-00-00 00:00:00',
  duration           int(15)  NOT NULL,
  effentries         bigint(20)    NOT NULL,
  PRIMARY KEY  (id),
  KEY replobject (replobject)
) ENGINE=INNODB;
alter table replicatestat  add FOREIGN KEY fk_replicatestat (replobject)
          REFERENCES replicateobject (id) ON DELETE CASCADE;
alter table replicateobject  add FOREIGN KEY fk_replicateobject (replpartner)
          REFERENCES replicatepartner (id) ON DELETE CASCADE;
set FOREIGN_KEY_CHECKS=1;
