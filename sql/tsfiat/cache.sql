use w5base;
create table tsfiat_firewall(
  id              bigint(20)  NOT NULL,
  parentid        bigint(20),
  name            varchar(128)  NOT NULL,
  vendor          varchar(128)  NOT NULL,
  domainid        bigint(20),
  isoffline       tinyint(1) default '0',
  istopology      tinyint(1) default '0',
  domainname      varchar(128),
  contextname     varchar(128),
  latestrevision  varchar(128),
  ipaddress       varchar(128) NOT NULL,
  virtualtype     varchar(64),
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  srcload    datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table tsfiat_firewall add isexcluded tinyint(1) default '0';
