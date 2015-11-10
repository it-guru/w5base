use w5base;
CREATE TABLE faqkey (
  id bigint(20) NOT NULL,
  name varchar(30) NOT NULL default '',
  fval varchar(128) NOT NULL default '',
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  UNIQUE KEY nameval (fval,name,id),
  KEY name (name,id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
