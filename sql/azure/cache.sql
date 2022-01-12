use w5base;
create table azure_skus(
  id              bigint(20)  NOT NULL,
  fullname        varchar(128)  NOT NULL,
  location        varchar(128)  NOT NULL,
  resourcetype    varchar(128)  NOT NULL,
  name            varchar(128)  NOT NULL,
  maxsizegib          int(20),
  minsizegib          int(20),
  memorygb            int(20),
  cpuarchitecturetype varchar(128),
  vcpus        int(20), vcpuspercore   int(20),
  vcpusavailable      int(20),
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  srcload    datetime default NULL,
  PRIMARY KEY  (id),unique(fullname)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
