use w5base;
set FOREIGN_KEY_CHECKS=0;
create table tsacinv_lnkw5bosrelease (
  id           bigint(20) NOT NULL,
  tsacname     varchar(128) NOT NULL,
  w5bid        bigint(20),
  outgoing     tinyint(1) default NULL,
  comments     longtext   default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  FOREIGN KEY (w5bid) REFERENCES osrelease (id) ON DELETE CASCADE,
  PRIMARY KEY  (id),unique(tsacname,w5bid,outgoing),unique(w5bid,outgoing)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
