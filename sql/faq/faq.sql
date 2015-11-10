use w5base;
CREATE TABLE faq (
  faqid     bigint(20) NOT NULL default '0',
  name      varchar(128) NOT NULL default '',
  faqcat    bigint(20) NOT NULL,
  viewcount int(11) NOT NULL default '0',
  data longtext NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  owner bigint(20) NOT NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  UNIQUE KEY `srcsys` (srcsys,srcid),
  PRIMARY KEY  (faqid),
  KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table faq add createuser bigint(20) default NULL,add key (createuser);
update faq set createuser=owner where createuser is null;
alter table faq add furtherkeys varchar(128) default NULL;
alter table faq add viewlast  datetime default NULL, add key(viewlast);
alter table faq add viewfreq  int(20)  default NULL;
alter table faq add lang  varchar(10)  default 'multilang';
alter table faq add published boolean  default '0';
update faq set published=1;
alter table faq add viewlastbywriter  datetime default NULL, add key(viewlastbywriter);
alter table faq add viewlastbywriternotify  datetime default NULL;
