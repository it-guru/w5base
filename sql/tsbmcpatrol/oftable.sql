use w5base;
set FOREIGN_KEY_CHECKS=0;
create table swinstance_bmcpatrol_of(
  of_id           bigint(20)   NOT NULL,
  of_locintserv   varchar(30)  default NULL,
  of_connectstr   longtext     default NULL,
  of_comments     longtext     default NULL,
  of_modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  of_modifyuser bigint(20) default NULL,
  of_editor     varchar(100) NOT NULL default '',
  of_realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (of_id),
  FOREIGN KEY fk_swinstance_of (of_id)
              REFERENCES swinstance (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=1;
