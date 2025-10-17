use w5base;
create table TS_costobjectmap (
  id         bigint(20) not null,
  systemid   varchar(40),
  conumber   varchar(40),
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  realeditor varchar(100) NOT NULL default '',
  editor varchar(100) NOT NULL default '',
  unique(systemid)
);
