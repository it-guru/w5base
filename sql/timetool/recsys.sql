# not used!        # erster Versuch
drop table if exists recsystspan;
create table recsystspan (
  id         bigint(20) NOT NULL,
     timeplan      bigint(20)   NOT NULL,
     entrytyp      int(2)   NOT NULL,
     tfrom         datetime NOT NULL default '0000-00-00 00:00:00',
     tto           datetime    default NULL,
     userid        bigint(20)  default NULL,
     recsubsys     varchar(20) default NULL,
     comments      longtext    default NULL,
     additional    longtext    default NULL,
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
  KEY search (tfrom,tto,recsubsys,timeplan),
  UNIQUE KEY tfrom (tfrom),
  UNIQUE KEY span  (tfrom,tto,userid,recsubsys),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
