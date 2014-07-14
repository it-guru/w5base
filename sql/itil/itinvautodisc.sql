use w5base;
create table autodiscengine (
  id          bigint(20)  NOT NULL,
  name        varchar(20) NOT NULL, fullname     varchar(128) NOT NULL,
  localdataobj varchar(80) NOT NULL, localkey    varchar(80) NOT NULL ,
  addataobj    varchar(80) NOT NULL, adkey       varchar(80) NOT NULL ,
  cistatus    int(2)      NOT NULL, 
  description longtext     default NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table autodiscdata (
  id          bigint(20)  NOT NULL,
  engine      varchar(20)  NOT NULL,
  system      bigint(20)  default NULL,
  swinstance  bigint(20)  default NULL,
  addata      longtext    default NULL,
  createdate  datetime    NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime    NOT NULL default '0000-00-00 00:00:00',
  srcload     datetime    default NULL,
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),unique(swinstance,engine),unique(system,engine),
  FOREIGN KEY fk_engine (engine)
              REFERENCES autodiscengine (name) ON DELETE CASCADE,
  FOREIGN KEY fk_swinstance (swinstance)
              REFERENCES swinstance (id) ON DELETE CASCADE,
  FOREIGN KEY fk_system (system)
              REFERENCES system (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
