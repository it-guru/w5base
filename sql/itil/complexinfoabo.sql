use w5base;
create table itil_infoabo (
  id           bigint(20)   NOT NULL,
  contact      bigint(20)   NOT NULL,
  infoabomode  char(20)     NOT NULL,
  prio         int(20),
  orgarea      bigint(20),
  customer     bigint(20),
  comments     longtext,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  modifydate   datetime     NOT NULL default '0000-00-00 00:00:00',
  modifyuser   bigint(20)   NOT NULL default '0',
  createdate   datetime     NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20)   NOT NULL default '0',
  PRIMARY KEY  (id),key (contact), key(infoabomode)
);
