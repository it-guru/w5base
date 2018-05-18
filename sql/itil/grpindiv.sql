use w5base;
create table grpindivsystem (
  id         varchar(40) NOT NULL,
  grpindivfld bigint(20) NOT NULL,
  dataobjid   bigint(20) NOT NULL,
  fldval      longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),KEY(dataobjid),
  KEY name (dataobjid),unique(dataobjid,grpindivfld),
  FOREIGN KEY (grpindivfld) REFERENCES grpindivfld (id) ON DELETE CASCADE,
  FOREIGN KEY (dataobjid) REFERENCES system (id) ON DELETE CASCADE
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table grpindivappl (
  id         varchar(40) NOT NULL,
  grpindivfld bigint(20) NOT NULL,
  dataobjid   bigint(20) NOT NULL,
  fldval      longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),KEY(dataobjid),
  KEY name (dataobjid),unique(dataobjid,grpindivfld),
  FOREIGN KEY (grpindivfld) REFERENCES grpindivfld (id) ON DELETE CASCADE,
  FOREIGN KEY (dataobjid) REFERENCES appl (id) ON DELETE CASCADE
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
