use w5base;
create table custcontrcrono (
  id          bigint(20)  NOT NULL,
  custcontract  bigint(20)  NOT NULL,
  month         char(7)     NOT NULL, 
  name          varchar(40) NOT NULL, 
  fullname      varchar(80) default NULL,
  applications  longtext    default NULL, 
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  KEY(name),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(modifydate),
  FOREIGN KEY fk_custcontract (custcontract)
              REFERENCES custcontract (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
