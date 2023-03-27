use w5base;
create table inmbusinessarea (
  id              bigint(20) NOT NULL,
  baname          varchar(80) default NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  FOREIGN KEY fk_applid (id) REFERENCES appl (id) ON DELETE CASCADE
) ENGINE=INNODB;
