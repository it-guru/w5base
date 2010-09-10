use w5base;
set FOREIGN_KEY_CHECKS=0;
create table lnkapplinvoicestorage (
  id           bigint(20) NOT NULL,
  appl           bigint(20) NOT NULL,
  parentobj      char(20)   default 'itil::system',
  system         bigint(20),
  lnkapplitclust bigint(20),
  storagetype    bigint(20) NOT NULL,
  storageclass   bigint(20) NOT NULL,
  comments       longtext    default NULL,
  capacity       double(8,2) default '0.00',
  durationstart  datetime NOT NULL default '0000-00-00 00:00:00',
  durationend    datetime    default NULL,
  ordernumber    varchar(20) default NULL,
  storageusage   varchar(20) NOT NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(10) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id), 
  FOREIGN KEY fk_system (system) 
              REFERENCES system (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_applitclust (lnkapplitclust) 
              REFERENCES lnkapplitclust (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_appl (appl)     
              REFERENCES appl (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_storagetype  (storagetype) 
              REFERENCES storagetype (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_storageclass (storageclass)     
              REFERENCES storageclass (id) ON DELETE RESTRICT,
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
