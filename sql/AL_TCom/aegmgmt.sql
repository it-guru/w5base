use w5base;
create table AL_TCom_appl_aegmgmt (
  id         bigint(20) NOT NULL,
  managed    int(1) default '0',
  meetinginterval      char(20)     default NULL,
  meetingstart         datetime     default NULL,
  meetingcomments      longtext     default NULL,
  processcheckdone     int(1)       default NULL,
  processcheckuntil    datetime     default NULL,
  processcheckcomments longtext     default NULL,
  checklistdone        int(1)       default NULL,
  checklistuntil       datetime     default NULL,
  checklistcomments    longtext     default NULL,
  aegsolution          varchar(40)  default NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  FOREIGN KEY fk_appl (id)
              REFERENCES appl (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table AL_TCom_appl_aegmgmt add leadprmmgr bigint(20);
alter table AL_TCom_appl_aegmgmt add leadinmmgr bigint(20);
