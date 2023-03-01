use w5base;
create table itcloud (
  id          bigint(20)  NOT NULL,
  name        varchar(40)  NOT NULL,
  cloudid     varchar(40)  NOT NULL,
  fullname    varchar(80) NOT NULL,
  cistatus    int(2)      NOT NULL,
    mandator    bigint(20)  default NULL,
    databoss    bigint(20)  default NULL,
    clusttyp    varchar(20) default NULL,
  description longtext     default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(512) default NULL,
  srcload     datetime    default NULL,
  lastqcheck  datetime default NULL,
  PRIMARY KEY  (id),key(mandator),key(lastqcheck),
  UNIQUE KEY name (fullname),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table itcloudarea   (
  id           bigint(20) NOT NULL,
  name         varchar(80) default NULL,
  itcloud      bigint(20) NOT NULL,
  cistatus     int(2)      NOT NULL,
  appl         bigint(20) NOT NULL,
  description longtext     default NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(512) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE applcl(itcloud,name),
  KEY clust(itcloud),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY fk_itcloud (itcloud)
          REFERENCES itcloud (id) ON DELETE CASCADE,
  FOREIGN KEY fk_appl (appl)
          REFERENCES appl (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table itcloud add can_saas   bool default '0';
alter table itcloud add can_paas   bool default '0';
alter table itcloud add can_iaas   bool default '0';
alter table itcloud add support    bigint(20);
alter table itcloudarea add lastqcheck  datetime default NULL,add key(lastqcheck);
alter table itcloud add platformresp bigint(20),add securityresp bigint(20);
alter table itcloud add notifysupport int(1) default '1',add allowuncleanseq int(1) default '0',add ca_allowdirectactivate int(1) default '0',add ca_activate_triggerurl varchar(128),add ca_deactivate_triggerurl varchar(128),add ca_order_triggerurl varchar(128);
alter table itcloudarea add deplnotify int(1) default '1';
alter table itcloudarea add cifirstactivation datetime default NULL;
alter table itcloudarea add requestoraccount  varchar(128) default NULL;
alter table itcloudarea add ipobjectexport int(1) default '1';
alter table itcloud add ordersupport int(1) default '0',add deconssupport int(1) default '0',add allowinactsysimport int(1) default '0';
alter table itcloud add appl bigint(20) default NULL;
alter table itcloud add shortname varchar(20) default NULL;
alter table itcloudarea add previousappl bigint(20);
