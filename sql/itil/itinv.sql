use w5base;
create table appl (
  id         bigint(20) NOT NULL,
  name       varchar(45) NOT NULL,
  cistatus   int(2)      NOT NULL,
    applid         varchar(20) default NULL,
    conumber       varchar(40) default NULL,
    applgroup      varchar(20) default NULL,
    databoss       bigint(20)  default NULL,
    tsm            bigint(20)  default NULL,tsm2       bigint(20) default NULL, 
    sem            bigint(20)  default NULL,
    sem2           bigint(20)  default NULL,
    chmcontact   varchar(128) default NULL,inmcontact varchar(128) default NULL,
    customer       bigint(20)  default NULL,
    businessteam   bigint(20)  default NULL,
    responseteam   bigint(20)  default NULL,
    mandator       bigint(20)  default NULL,
    desiredsla     float(5,2)  default NULL,
    is_licenseapp  bool        default '0',
    customerprio   int(2)      default '2',
    avgusercount   int(11),namedusercount int(11),
    currentvers    text        default NULL,
    maintwindow    text        default NULL,
    description    longtext    default NULL,
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(512) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY applid (applid),
  UNIQUE KEY name (name),KEY(mandator),key(conumber),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnkapplcustcontract (
  id           bigint(20) NOT NULL,
  appl         bigint(20) NOT NULL,
  custcontract bigint(20) NOT NULL,
  fraction     double(8,2) default '100.00',
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY appl (appl),
  KEY custcontract (custcontract),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table system (
  id         bigint(20) NOT NULL,
  name       varchar(68) NOT NULL,
    adm            bigint(20)  default NULL,itcloudarea bigint(20) default NULL,
    adm2           bigint(20)  default NULL,admteam   bigint(20)  default NULL,
    relperson      bigint(20)  default NULL,relperson2 bigint(20)  default NULL,
    systemid       varchar(20)  default NULL,
    inventoryno    varchar(20)  default NULL,
    conumber       varchar(40) default NULL,
    mandator       bigint(20)  default NULL,
    is_prod        bool default '0',relmodel varchar(20) default 'APPL',
    is_test        bool default '0',defonlinestate varchar(20) default 'ONLINE',
    is_devel       bool default '0', is_education   bool default '0',
    is_approvtest  bool default '0',
    is_reference   bool default '0',
    chmcontact   varchar(128) default NULL,inmcontact varchar(128) default NULL,
    asset          bigint(20)  default NULL,
    partofasset    float(5,2)  default NULL,
    is_virtual     bool default '0',
    is_custdriven  bool default '0',
    osrelease      bigint(20)  default NULL,
    cpucount       int(20)     default NULL,
    memory         int(20)     default NULL,
    is_router      bool default '0',
    is_workstation bool default '0',
    is_netswitch   bool default '0',
    is_printer     bool default '0',
    is_backupsrv   bool default '0',
    is_mailserver  bool default '0',
    is_applserver  bool default '0',
    is_adminsystem bool default '0',
    is_databasesrv bool default '0',
    is_webserver   bool default '0',
    is_terminalsrv bool default '0',
    shortdesc      varchar(80)  default NULL,
    description    longtext     default NULL,
    additional     longtext     default NULL,
  comments    longtext     default NULL,
  cistatus   int(2)      NOT NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(512) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY systemid (systemid),key itcloudarea(itcloudarea),
  KEY adm (adm),KEY adm2 (adm2), KEY admteam (admteam),
  UNIQUE KEY name (name),KEY(mandator),key assetid(asset),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table asset (
  id         bigint(20) NOT NULL,
  name       varchar(40) default NULL,
  cistatus   int(2)      NOT NULL,class varchar(20) default 'NATIVE',
    mandator       bigint(20)  default NULL,classagg varchar(40),
    guardian       bigint(20)  default NULL,
    guardian2      bigint(20)  default NULL,
    guardianteam   bigint(20)  default NULL,
    assetid        varchar(20)  default NULL,
    serialnumber   varchar(20)  default NULL,
    hwmodel        bigint(20)  default NULL,
    location       bigint(20)  default NULL,
    cpucount       int(20)     default NULL,
    corecount      int(20)     default NULL,
    cpuspeed       int(20)     default NULL,
    memory         int(20)     default NULL,
    description    longtext     default NULL,
    additional     longtext     default NULL,
    deprstart      datetime default NULL,
    deprend        datetime default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(512) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY assetid (assetid),
  UNIQUE KEY name (name),KEY(mandator),
  KEY guardian (guardian),KEY guardian2 (guardian2), 
  KEY guardianteam (guardianteam),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(location),key(hwmodel)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table platform (
  id         bigint(20) NOT NULL,
  name       varchar(20) NOT NULL,
  cistatus   int(2)      NOT NULL,
    hwbits         varchar(20) default NULL,
    mandator       bigint(20)  default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table osrelease (
  id         bigint(20) NOT NULL,
  name       varchar(45) NOT NULL,
  cistatus   int(2)      NOT NULL,
    mandator       bigint(20)  default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table producer (
  id          bigint(20)  NOT NULL,
  name        varchar(40) NOT NULL,
  cistatus    int(2)      NOT NULL,
    mandator       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table software (
  id          bigint(20)  NOT NULL,
  name        varchar(80) NOT NULL,
  cistatus    int(2)      NOT NULL,
    producer       bigint(20)  default NULL,
    releaseexp     varchar(128) default NULL,
    mandator       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table network (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  cistatus   int(2)      NOT NULL,
    uniquearea     int(20)     default NULL,
    mandator       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table ipaddress (
  id         bigint(20) NOT NULL,
  name       varchar(45) NOT NULL, binnamekey char(128),
  cistatus   int(2)      NOT NULL,
    dnsname        varchar(128) default NULL,
    addresstyp     int(10)     default NULL,
    is_foundindns  bool default '0',is_controllpartner  bool default '0',
    system         bigint(20)  default NULL,
    uniqueflag     bigint(20)  default NULL,
    network        bigint(20)  default NULL,
    description    longtext     default NULL,
    additional     longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(512) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key name(network,name),key dnsname(dnsname),key(binnamekey),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table liccontract (
  id          bigint(20)  NOT NULL,
  name        varchar(300) NOT NULL,
  cistatus    int(2)      NOT NULL,
    software       bigint(20)  default NULL,
    sem            bigint(20)  default NULL,
    sem2           bigint(20)  default NULL,
    mandator       bigint(20)  default NULL,
    responseteam   bigint(20)  default NULL,
    producer       bigint(20)  default NULL,
    lictype        varchar(20) default NULL,
    durationstart  datetime NOT NULL default '0000-00-00 00:00:00',
    durationend    datetime    default NULL,
    intprice       double(36,2) default NULL,
    extprice       double(36,2) default NULL,
    intmaintprice  double(36,2) default NULL,
    extmaintprice  double(36,2) default NULL,
    intafadurationstart  datetime NOT NULL default '0000-00-00 00:00:00',
    intafadurationend    datetime    default NULL,
    extafadurationstart  datetime NOT NULL default '0000-00-00 00:00:00',
    extafadurationend    datetime    default NULL,
    ordertyp       varchar(20) default NULL,
    orderdate      datetime    default NULL,
    orderref       varchar(40) default NULL,
    producerpartno varchar(40) default NULL,
    exppriceliftup double(36,2) default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkapplappl (
  id           bigint(20) NOT NULL,
  fromappl     bigint(20) NOT NULL,
  toappl       bigint(20) NOT NULL,
  conmode      varchar(10) default NULL,
  contype      int(1)      default NULL,
  conprotocol  varchar(15) default NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY fromappl (fromappl),
  KEY toappl (toappl),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table hwmodel (
  id          bigint(20)  NOT NULL,
  fullname    varchar(80) NOT NULL,
  cistatus    int(2)      NOT NULL,
    name        varchar(80) NOT NULL,
    mandator    bigint(20)  default NULL,
    producer    bigint(20)  default NULL,
    platform    bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnkapplsystem (
  id           bigint(20) NOT NULL,       cistatus    int(2)     default '4',
  appl         bigint(20) NOT NULL,       system      bigint(20) NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  fraction     double(8,2) default '100.00',
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id), key cistatus (cistatus), 
  FOREIGN KEY fk_system (system) REFERENCES system (id) ON DELETE CASCADE,
  KEY appl (appl),UNIQUE applsys(appl,system),
  KEY system (system),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnksoftwaresystem (
  id           bigint(20) NOT NULL,
  software     bigint(20) NOT NULL,
  system       bigint(20) default NULL,
  liccontract  bigint(20),
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  quantity     double(8,2) NOT NULL default '1.00',
  version      varchar(30),
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY software (software),KEY liccontract (liccontract),
  KEY system (system), FOREIGN KEY (software) REFERENCES software (id) ON DELETE RESTRICT,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkinstance (
  id                bigint(20) NOT NULL,
  lnksoftwaresystem bigint(20) NOT NULL,
  name              varchar(80) NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(10) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE name (name,lnksoftwaresystem),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table appl add is_soxcontroll   bool default '0';
alter table appl add is_applwithnosys bool default '0';
alter table system add systemtype varchar(20) default 'standard',add key(systemtype);
alter table asset add room varchar(20) default '';
alter table ipaddress add unique ipchk(name,uniqueflag,network);
alter table ipaddress add comments     longtext    default NULL;
alter table system add is_clusternode bool default '0';
alter table system add clusterid bigint(20) default NULL;
alter table system add key(clusterid);
alter table appl add key(customer);
alter table system add ccproxy varchar(128) default '';
create table servicesupport (
  id         bigint(20) NOT NULL,
  name       varchar(60) NOT NULL,
  cistatus   int(2)      NOT NULL,
    mandator       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table appl add servicesupport bigint(20) default NULL;
alter table appl add key(servicesupport);
alter table asset  add place varchar(40) default NULL;
alter table asset  add rack  varchar(40) default NULL;
alter table system add servicesupport bigint(20) default NULL;
alter table servicesupport add timezone varchar(40) NOT NULL default 'CET';
create table systemnfsnas (
  id         bigint(20) NOT NULL,
  name       varchar(128) NOT NULL,  
  cistatus   int(2)      NOT NULL,
    system         bigint(20)   default NULL,
    mbquota        bigint(20)   default NULL,
    exportoptions  varchar(128) default NULL,
    exporttype     varchar(20)  default NULL,
    exportname     varchar(40)  default NULL,
    publicexport   int(1)       default '0',
    description    longtext     default NULL,comments longtext default NULL,
    additional     longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),key(exportname),key(cistatus),
  UNIQUE KEY name (name,system),key(system),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnksystemnfsnas (
  id         bigint(20) NOT NULL,
  systemnfsnas    bigint(20) NOT NULL,
  system          bigint(20) NOT NULL,
  exportoptions   varchar(128) default NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE name (system,systemnfsnas),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table system add is_nas bool default '0';
create table swinstance (
  id         bigint(20)   NOT NULL,
  fullname   varchar(128) NOT NULL,
  cistatus   int(2)       NOT NULL,
    mandator       bigint(20)  default NULL,
    name           varchar(40) NOT NULL,
    addname        varchar(40) NOT NULL,
    swnature       varchar(40) NOT NULL,
    swtype         varchar(10) NOT NULL,
    swport         int(10)     default NULL,
    appl           bigint(20)  default NULL,
    system         bigint(20)  default NULL,
    autompartner   varchar(40) default NULL,
    databoss       bigint(20)  default NULL,
    adm            bigint(20)  default NULL,
    adm2           bigint(20)  default NULL,
    swteam         bigint(20)  default NULL,
    servicesupport bigint(20)  default NULL,
    additional     longtext    default NULL,
  comments   longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(512) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),key(appl),
  UNIQUE KEY fullname (fullname),key(system),key(databoss),
  UNIQUE KEY name (fullname),KEY(mandator),key(name),key(servicesupport),
  UNIQUE KEY `srcsys` (srcsys,srcid),key(swteam),key(adm),key(adm2)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table asset add systemhandle varchar(30)   default NULL;
alter table asset add prodmaintlevel bigint(20)  default NULL;
alter table appl  add slacontroltool varchar(20) default NULL;
alter table appl  add slacontravail  double(8,2) default NULL;
alter table appl  add slacontrbase   varchar(20) default NULL;
alter table appl   add kwords  varchar(255) default NULL;
alter table system add kwords  varchar(255) default NULL;
alter table asset  add kwords  varchar(255) default NULL;
create table lnkswinstancesystem (
  id           bigint(20) NOT NULL,
  swinstance   bigint(20) NOT NULL,
  system       bigint(20) NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY swinstance (swinstance),
  KEY system (system),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkaccountingno (
  id           bigint(20)  NOT NULL,
  accountno    varchar(20) NOT NULL,
  refid        bigint(20)  NOT NULL,
  parentobj    varchar(30) NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(30) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE acc (parentobj,accountno,refid),
  KEY accountno (accountno), KEY refid (refid),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnknfsnasipnet (
  id         bigint(20) NOT NULL,
  systemnfsnas    bigint(20) NOT NULL,
  network         bigint(20) NOT NULL,
  ip              varchar(80) NOT NULL,
  exportoptions   varchar(128) default NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE name (ip,network,systemnfsnas),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkapplapplcomp (
  id           bigint(20) NOT NULL,
  lnkapplappl  bigint(20) NOT NULL,
  sortkey      bigint(20)  default NULL,
  objtype      varchar(20) default NULL,
  obj1id       bigint(20)  default NULL,
  obj2id       bigint(20)  default NULL,
  obj3id       bigint(20)  default NULL,
  obj4id       bigint(20)  default NULL,
  importance   int(2)      default 1,
  #
  #
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL, 
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY obj1 (objtype,obj1id),
  KEY obj2 (objtype,obj2id),
  KEY obj3 (objtype,obj3id),
  KEY obj4 (objtype,obj4id),
  KEY lnkapplappl (lnkapplappl),               
  UNIQUE KEY `sortkey` (sortkey),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table system       add allowifupdate int(2) default 0;
alter table appl         add allowifupdate int(2) default 0;
alter table custcontract add allowifupdate int(2) default 0;
alter table swinstance   add allowifupdate int(2) default 0;
alter table liccontract  add allowifupdate int(2) default 0;
alter table appl add criticality char(20) default NULL;
alter table appl   add lastqcheck datetime default NULL,add key(lastqcheck);
alter table system add lastqcheck datetime default NULL,add key(lastqcheck);
alter table asset  add lastqcheck datetime default NULL,add key(lastqcheck);
alter table system add consoleip  varchar(40) default NULL;
alter table ipaddress add accountno varchar(20), add key(accountno);
alter table ipaddress add ifname varchar(45);
alter table swinstance add swinstanceid varchar(20) default NULL;
alter table swinstance add UNIQUE key swinstanceid (swinstanceid);
alter table swinstance add custcostalloc int(2) default 0;
alter table servicesupport add flathourscost float(5,2) default NULL;
alter table appl add is_applwithnoiface bool default '0';
alter table asset  add databoss bigint(20) default NULL,add key(databoss);
alter table system add databoss bigint(20) default NULL,add key(databoss);
alter table lnkapplcustcontract add unique applcontr(appl,custcontract);
alter table asset  add allowifupdate int(2) default 0;
alter table servicesupport add sapservicename varchar(20) default NULL;
alter table servicesupport add sapcompanycode varchar(20) default NULL;
alter table appl       add databoss2 bigint(20)  default NULL;
alter table asset      add databoss2 bigint(20)  default NULL;
alter table system     add databoss2 bigint(20)  default NULL;
alter table swinstance add databoss2 bigint(20)  default NULL;
alter table system     add hostid    varchar(20) default NULL;
alter table system     add vhostsystem bigint(20) default NULL;
alter table appl       add opmode     varchar(20) default NULL;
alter table asset      add conumber   varchar(40) default NULL;
alter table system     add key(conumber);
alter table asset      add key(conumber);
alter table liccontract  add unitcount int(2) default 1;
alter table liccontract  add unittype  varchar(20) default NULL;
alter table liccontract  add databoss bigint(20)  default NULL;
alter table liccontract  add databoss2 bigint(20)  default NULL;
create table lickey (
  id           bigint(20)  NOT NULL,
  liccontract  bigint(20)  NOT NULL,
  name         varchar(128) NOT NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(30) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY liccontract (liccontract),UNIQUE name (name,liccontract),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnksoftwaresystem add key(liccontract);
create table lnklicappl (
  id           bigint(20) NOT NULL,
  appl         bigint(20) NOT NULL,
  liccontract  bigint(20),
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  quantity     double(8,2) NOT NULL default '1.00',
  is_avforfuse bool        default '0',
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY liccontract (liccontract),key(is_avforfuse),
  KEY appl (appl),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table system add is_avforfuse bool default '0', add key(is_avforfuse);
alter table asset  add is_avforfuse bool default '0', add key(is_avforfuse);
alter table appl   add eventlang  varchar(5) default NULL;
update appl set eventlang='de';
#
alter table system add is_infrastruct bool default '0', add key(is_infrastruct);
alter table appl   add secstate  varchar(20) default NULL;
alter table servicesupport add fullname varchar(128) default NULL;
alter table osrelease add osclass varchar(20) default NULL,add key(osclass);
create table lnkitclustsvc   (
  id           bigint(20) NOT NULL,
  itsvcname    varchar(40) default NULL,
  itclust      bigint(20) NOT NULL,swinstance   bigint(20) NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  subitsvcname varchar(5) default '' not null,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE applcl(itsvcname,itclust,subitsvcname),
  KEY clust(itclust),key swi(swinstance),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table swinstance add ssl_url varchar(128) default NULL;
alter table swinstance add ssl_cert_check datetime default NULL;
alter table swinstance add ssl_cert_end datetime default NULL;
alter table swinstance add ssl_cert_begin datetime default NULL;
alter table swinstance add ssl_state varchar(128) default NULL;
alter table swinstance add lastqcheck datetime default NULL,add key(lastqcheck);
alter table appl  add opm bigint(20)  default NULL;
alter table appl  add opm2 bigint(20)  default NULL;
alter table swinstance add no_sox_inherit int(2) default 0;
alter table system     add no_sox_inherit int(2) default 0;
alter table asset      add no_sox_inherit int(2) default 0;
alter table appl add key opm(opm);
create table itclust (
  id          bigint(20)  NOT NULL,
  name        varchar(40)  NOT NULL,
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
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  lastqcheck  datetime default NULL,
  PRIMARY KEY  (id),key(mandator),key(lastqcheck),
  UNIQUE KEY name (fullname),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table swinstance add runonclusts int(2) default '0';
alter table swinstance add itclusts bigint(20) default NULL,add key(itclusts);
alter table servicesupport add iflathourscost float(5,2) default NULL;
alter table servicesupport add databoss bigint(20) default NULL;
alter table servicesupport add databoss2 bigint(20) default NULL;
alter table appl add swdepot varchar(128) default NULL;
alter table lnksoftwaresystem  add instdate datetime default NULL;
update lnksoftwaresystem set instdate=createdate;
alter table appl add sodefinition int(2) default '0';
alter table appl add socomments longtext default NULL;
alter table appl add soslanumdrtests    float(2) default '0.5';
alter table appl add sosladrduration    int(5) default NULL;
alter table appl add solastdrtestwf     bigint(20) default NULL;
#alter table appl add solastdrdate       datetime default NULL;
alter table appl add soslaclustduration int(5) default NULL;
alter table appl add solastclusttestwf  bigint(20) default NULL;
#alter table appl add solastclustswdate  datetime default NULL;
create table dnsalias (
  id         bigint(20) NOT NULL,
  cistatus   int(2)      NOT NULL,
    dnsalias       varchar(40) default NULL,
    dnsname        varchar(40) default NULL,
    is_foundindns  bool default '0',
    network        bigint(20)  default NULL,
    comments       longtext     default NULL,
    additional     longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  key dnsname(dnsname),
  UNIQUE KEY `srcsys` (srcsys,srcid), unique KEY (dnsalias,dnsname)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table appl  add applbasemoni varchar(20) default NULL;
create table storageclass (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  cistatus   int(2)      NOT NULL,
  comments   longtext    default NULL,
  slaavail   double(8,5) default NULL,
  nbratio    double(8,5) default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table storagetype (
  id         bigint(20) NOT NULL,
  name       varchar(20) NOT NULL,
  cistatus   int(2)      NOT NULL,
  comments   longtext    default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table software add docsig tinyint(1) default '0';
alter table software add compcontact bigint(20) default NULL;
alter table software add depcompcontact bigint(20) default NULL;
alter table ipaddress add key(system);
alter table lnksoftwaresystem  add instpath varchar(255) default NULL;
alter table lnksoftwaresystem  add releasekey char(30) default '000000000000000000000000000000',add key(releasekey);
alter table lnksoftwaresystem  add patchkey varchar(30) default '';
alter table lnksoftwaresystem  add majorminorkey varchar(30) default '';
alter table lnkapplappl add description longtext default NULL;
alter table itclust add itclustid char(20) default NULL, add unique(itclustid);
alter table lnkitclustsvc add itservid char(20) default NULL, add unique(itservid);
create table lnkitclustsvcappl   (
  id           bigint(20) NOT NULL,
  itclust      bigint(20) NOT NULL,
  itclustsvc   bigint(20) NOT NULL,
  appl         bigint(20) NOT NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE applcl(itclust,itclustsvc,appl),
  FOREIGN KEY fk_applclustsvc (appl) REFERENCES appl (id) ON DELETE CASCADE,
  FOREIGN KEY fk_itclustsvc (itclustsvc) 
          REFERENCES lnkitclustsvc (id) ON DELETE CASCADE,
  KEY itclustsvc(itclustsvc),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=0;
alter table ipaddress  add FOREIGN KEY fk_sysip (system)
          REFERENCES system (id) ON DELETE CASCADE;
alter table ipaddress  add lnkitclustsvc bigint(20) default NULL;
alter table ipaddress  add FOREIGN KEY fk_itclustsvcip (lnkitclustsvc)
          REFERENCES lnkitclustsvc (id) ON DELETE CASCADE;
set FOREIGN_KEY_CHECKS=1;
alter table system add is_loadbalacer bool default '0', add key(is_loadbalacer);
alter table system add is_housing bool default '0', add key(is_housing);
alter table itclust add allowifupdate int(2) default 0;
set FOREIGN_KEY_CHECKS=0;
alter table lnksoftwaresystem  add FOREIGN KEY fk_sysswi (system)
          REFERENCES system (id) ON DELETE CASCADE;
alter table lnksoftwaresystem  add lnkitclustsvc bigint(20) default NULL;
alter table lnksoftwaresystem  add FOREIGN KEY fk_itclustsvcsw (lnkitclustsvc)
          REFERENCES lnkitclustsvc (id) ON DELETE CASCADE;
set FOREIGN_KEY_CHECKS=1;
alter table swinstance   add lnksoftwaresystem bigint(20) default NULL;
alter table osrelease add comments longtext default NULL;
alter table swinstance add techrelstring longtext default NULL;
create table lnkswinstanceparam (
  id           bigint(20) NOT NULL,
  swinstance   bigint(20) NOT NULL,
  name         varchar(100) NOT NULL,namegrp varchar(20),
  val          varchar(254) NOT NULL,
  mdate        datetime NOT NULL default '0000-00-00 00:00:00',
  islatest     int(1) default NULL,
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY swinstance(swinstance),
  UNIQUE KEY `srcsys` (srcsys,srcid,islatest),
  UNIQUE KEY `latest` (swinstance,name,islatest)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkapplappl add fromurl varchar(128),add tourl varchar(128),add fromservice varchar(80),add toservice varchar(80),add implapplversion varchar(20),add implproject varchar(40);
alter table appl   add chmgrfmb     bigint(20) default NULL;
alter table software add rightsmgmt char(10) default 'OPTIONAL';
alter table swinstance add runtimeusername varchar(40) default NULL;
alter table swinstance add installusername varchar(40) default NULL;
alter table swinstance add configdirpath varchar(80) default NULL;
alter table swinstance add issslinstance varchar(10) default 'UNKNOWN';
alter table swinstance add admcomments longtext default NULL;
create table ipnet (
  id         bigint(20) NOT NULL,
  name       varchar(45) NOT NULL, binnamekey char(128),
  cistatus   int(2)      NOT NULL, label varchar(128),
    netmask        varchar(40) default NULL,
    network        bigint(20)  default NULL,
    description    longtext     default NULL,
    additional     longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),unique(label),
  unique(name,network),key(binnamekey),key(network),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=0;
alter table appl add FOREIGN KEY fk_appl_databoss (databoss)
          REFERENCES contact (userid) ON DELETE SET NULL;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table asset add FOREIGN KEY fk_asset_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table itclust add FOREIGN KEY fk_itclust_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table system add FOREIGN KEY fk_system_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table liccontract add FOREIGN KEY fk_liccontract_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table servicesupport add FOREIGN KEY fk_servicesupport_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
set FOREIGN_KEY_CHECKS=0;
alter table swinstance add FOREIGN KEY fk_swinstance_databoss (databoss)
          REFERENCES contact (userid) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
alter table lnksoftwaresystem add denyupd int(1) default '0';
alter table lnksoftwaresystem add denyupdvalidto datetime default NULL;
alter table lnksoftwaresystem add denyupdcomments longtext default NULL;
alter table system add autodisc_mode varchar(20) default NULL,
add autodisc_rawdata longtext default NULL, add autodisc_mdate datetime default NULL,
add autodisc_srcload datetime default NULL, add autodisc_srcsys varchar(100) default NULL,
add autodisc_srcid varchar(20) default NULL, add autodisc_modifyuser bigint(20) default NULL,
add autodisc_editor varchar(100) default NULL, add autodisc_realeditor varchar(100) default NULL;
create table appladv (
  id           bigint(20) NOT NULL,
  appl         bigint(20) NOT NULL,itnormodel bigint(20) default '0',
  dstate       int(1) default '10',
  isactive     int(1) default NULL,
  docdate      char(7) default NULL,refreshinfo1 datetime,refreshinfo2 datetime,
  comments     longtext default NULL,
  additional   longtext default NULL,
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),key(docdate),
  FOREIGN KEY fk_appl (appl)
              REFERENCES appl (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid), unique(appl,isactive)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table applnor (
  id           bigint(20) NOT NULL,
  appl         bigint(20) NOT NULL,
  dstate       int(1) default '10',
  isactive     int(1) default NULL,
  docdate      char(7) default NULL,refreshinfo1 datetime,refreshinfo2 datetime,
  comments     longtext default NULL,
  additional   longtext default NULL,
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),key(docdate),
  FOREIGN KEY fk_appl (appl)
              REFERENCES appl (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid), unique(appl,isactive)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table itnormodel (
  id           bigint(20) NOT NULL,
  name         char(5) NOT NULL,cistatus int(2)  NOT NULL,
  fullname     varchar(40) not NULL,
  comments     longtext default NULL,mdesc longtext default NULL,
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser   bigint(20) default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),key(name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
insert into itnormodel (id,name,cistatus,fullname) values(0,'S',4,'S - Standard');
#alter table swinstance add autogendiary int(1) default '0';
#update swinstance set autogendiary = custcostalloc;
alter table itnormodel add defcountry varchar(80) default null;
alter table applnor add lastqcheck datetime default NULL,add key(lastqcheck);
alter table appladv add lastqcheck datetime default NULL,add key(lastqcheck);
alter table software add productclass varchar(20) default 'MAIN';
alter table software add parent bigint(20) default null, add key(parent);
alter table software add FOREIGN KEY fk_software (parent)
          REFERENCES software (id) ON DELETE CASCADE;
alter table lnksoftwaresystem add parent bigint(20) default null,add key(parent);
alter table lnksoftwaresystem add FOREIGN KEY fk_lnksoftwaresystem (parent)
          REFERENCES lnksoftwaresystem (id) ON DELETE CASCADE;
create table swinstancerule (
  id         bigint(20) NOT NULL,
  swinstance bigint(20) NOT NULL,
  ruletype   char(10)   NOT NULL,
  refid      bigint(20) default NULL,
  parentobj  varchar(30) default NULL,parentname varchar(80) default NULL,
  cistatus   int(2)      NOT NULL,
  complexity   int(2)   default '5',isprivate int(2) default '0',
  rulelabel    varchar(128) default '',
  varname      longtext default NULL,
  vargroup     longtext default NULL,
  varval       longtext default NULL,
  srcaddr      longtext default NULL,srcport      longtext default NULL,
  dstaddr      longtext default NULL,dstport      longtext default NULL,
  policy       char(20) default 'ALLOW',
  conumber     varchar(40) default NULL,
  comments     longtext default NULL,
  additional   longtext default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY fk_pswinstance (swinstance)
              REFERENCES swinstance (id) ON DELETE CASCADE,
  key(parentobj,refid),
  key(rulelabel),
  key(ruletype),
  key(swinstance),
  UNIQUE KEY `srcsys` (srcsys,srcid)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;
set FOREIGN_KEY_CHECKS=0;
alter table system add FOREIGN KEY fk_vhostsystem (vhostsystem)
          REFERENCES system (id) ON DELETE RESTRICT;
set FOREIGN_KEY_CHECKS=1;
alter table appl add additionalchm longtext default NULL;
alter table appl add additionalinm longtext default NULL;
create table assetphyscore (
  id         bigint(20) NOT NULL,
  coreid     int(4) NOT NULL,
  asset      bigint(20) NOT NULL,
  cpu        bigint(20) default NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY fk_asset (asset)
              REFERENCES asset (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table assetphyscpu (
  id         bigint(20) NOT NULL,
  cpuid      int(4) NOT NULL,
  asset      bigint(20) NOT NULL,
  PRIMARY KEY  (id),
  FOREIGN KEY fk_asset (asset)
              REFERENCES asset (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table businessservice (
  id          bigint(20)  NOT NULL,
  name        varchar(128) default NULL,
  appl        bigint(20),
  cistatus    int(2)      default '4', funcmgr bigint(20) default NULL,
  description longtext     default NULL,version varchar(20),
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(80) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (appl,name),KEY(name),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY fk_appl (appl)
              REFERENCES appl (id) ON DELETE SET NUL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table appl add applmgr bigint(20) default NULL, add applowner bigint(20) default NULL;
alter table lnkapplappl add monitor varchar(20) default NULL;
alter table lnkapplappl add monitortool varchar(20) default NULL;
alter table lnkapplappl add monitorinterval varchar(20) default NULL;
alter table appl add applmgr2 bigint(20) default NULL;
alter table swinstance add techprodstring longtext default NULL;
create table systemmonipoint (
  id         bigint(20) NOT NULL,
  system     bigint(20) NOT NULL,
  name        varchar(20)  NOT NULL,
  description longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),UNIQUE KEY `nameing` (name,system),
  FOREIGN KEY fk_system (system)
              REFERENCES system (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkbscomp (
  id           bigint(20) NOT NULL,
  businessservice  bigint(20) NOT NULL,
  sortkey      bigint(20)  default NULL,
  varikey      bigint(20)  default NULL,
  objtype      varchar(40) default NULL,
  obj1id       bigint(20)  default NULL,
  obj2id       bigint(20)  default NULL,
  obj3id       bigint(20)  default NULL,
  obj4id       bigint(20)  default NULL,
  importance   int(2)      default 1,
  lnkpos       char(2)     default NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL, 
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY obj1 (objtype,obj1id),
  KEY obj2 (objtype,obj2id),
  KEY obj3 (objtype,obj3id),
  KEY obj4 (objtype,obj4id),
  KEY businessservice (businessservice),               
  UNIQUE KEY `sortkey` (sortkey),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY fk_businessservice (businessservice)
              REFERENCES businessservice (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table systemmonipoint 
 add mon1url varchar(128),add mon1date datetime,add mon1mode varchar(10),
 add mon2url varchar(128),add mon2date datetime,add mon2mode varchar(10),
 add mon3url varchar(128),add mon3date datetime,add mon3mode varchar(10);
alter table system 
 add mon1url varchar(128),add mon1date datetime,add mon1mode varchar(10),
 add mon2url varchar(128),add mon2date datetime,add mon2mode varchar(10),
 add mon3url varchar(128),add mon3date datetime,add mon3mode varchar(10);
alter table appl 
 add mon1url varchar(128),add mon1date datetime,add mon1mode varchar(10),
 add mon2url varchar(128),add mon2date datetime,add mon2mode varchar(10),
 add mon3url varchar(128),add mon3date datetime,add mon3mode varchar(10);
alter table businessservice 
 add mon1url varchar(128),add mon1date datetime,add mon1mode varchar(10),
 add mon2url varchar(128),add mon2date datetime,add mon2mode varchar(10),
 add mon3url varchar(128),add mon3date datetime,add mon3mode varchar(10);
alter table businessprocess 
 add mon1url varchar(128),add mon1date datetime,add mon1mode varchar(10),
 add mon2url varchar(128),add mon2date datetime,add mon2mode varchar(10),
 add mon3url varchar(128),add mon3date datetime,add mon3mode varchar(10);
create table accessurl (
  id          bigint(20) NOT NULL,
  appl        bigint(20) NOT NULL,
  fullname    varchar(512) NOT NULL,
  network     bigint(20) NOT NULL,
  is_userfrontend int(1) default '0',scheme   varchar(20) not null,
  is_interface    int(1) default '0',hostname varchar(128),  
  is_internal     int(1) default '0',ipport   int(10),      
  comments    longtext     default NULL,itcloudarea bigint(20) default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(512) default NULL,
  srcload     datetime    default NULL,FOREIGN KEY cloudarea(itcloudarea) REFERENCES itcloudarea(id) ON DELETE CASCADE,
  PRIMARY KEY  (id), FOREIGN KEY appl (appl) REFERENCES appl (id) ON DELETE CASCADE,
  UNIQUE KEY fullname (fullname,network),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
alter table system 
 add perf1url varchar(128),add perf1date datetime,add perf1mode varchar(10),
 add perf2url varchar(128),add perf2date datetime,add perf2mode varchar(10),
 add perf3url varchar(128),add perf3date datetime,add perf3mode varchar(10);
alter table ipaddress add is_notdeleted int(1) default '1', add is_primary int(1) default null;
update ipaddress set is_notdeleted=null where cistatus>=6;
alter table ipaddress add is_monitoring int(1) default null, add unique MonitoringUniqueCheck(is_notdeleted,is_monitoring,system), add unique PrimaryUniqueCheck(is_notdeleted,is_primary,system);
create table lnkswinstanceswinstance (
  id bigint(20) NOT NULL,
  fromswi bigint(20) NOT NULL,
  toswi bigint(20) NOT NULL,
  conmode varchar(10) default NULL,
  comments longtext,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys varchar(100) default 'w5base',
  srcid varchar(20) default NULL,
  srcload datetime default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY srcsys (srcsys,srcid),
  KEY toswi (toswi),unique(conmode,toswi,fromswi),
  KEY fromswi (fromswi),
  FOREIGN KEY fk_swi1 (toswi) REFERENCES swinstance (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_swi2 (fromswi) REFERENCES swinstance (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkapplappl add cistatus int(2) default '4', add exch_personal_data int(2) default '0',add agreements longtext default NULL;
alter table appl add isnotarchrelevant int(1) default '0';
alter table appl add applbasemoniteam bigint(20), add applbasemonistatus char(15);
alter table swinstance add moniteam bigint(20), add monistatus char(15);
alter table system add moniteam bigint(20), add monistatus char(15);
alter table software add is_dms int(1) default '0', add is_dbs int(1) default '0', add is_mw int(1) default '0';
create table applgrp (
  id         bigint(20) NOT NULL,
  name       varchar(40) NOT NULL,
  fullname   varchar(128) default NULL,
  cistatus   int(2)      NOT NULL,
  applgrpid  varchar(20) default NULL,
  databoss   bigint(20)  default NULL,
  mandator   bigint(20)  default NULL,
  description longtext   default NULL,
  additional  longtext   default NULL,
  comments    longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,allowifupdate int(2) default 0,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,lastqcheck datetime default NULL,
  PRIMARY KEY  (id), UNIQUE KEY applgrpid (applgrpid),key(lastqcheck),
  UNIQUE KEY name (name),KEY(mandator), UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnkapplgrpappl (
  id         bigint(20) NOT NULL,
  applgrp    bigint(20) NOT NULL,
  appl       bigint(20) NOT NULL, applversion varchar(20),
  retirement        datetime,
  planed_activation datetime,     planed_retirement datetime,
  description longtext   default NULL,
  additional  longtext   default NULL,
  comments    longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(80) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id), UNIQUE KEY rel (applgrp,appl,applversion),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY (appl) REFERENCES appl (id) ON DELETE CASCADE,
  FOREIGN KEY (applgrp) REFERENCES applgrp (id) ON DELETE CASCADE
) ENGINE=INNODB;
alter table appl add disasterrecclass varchar(20) default NULL;
alter table appl add rtolevel varchar(20) default NULL;
alter table appl add rpolevel varchar(20) default NULL;
alter table asset add denyupd int(1) default '0',add denyupdvalidto datetime default NULL,add denyupdcomments longtext default NULL,add refreshinfo1 datetime default NULL, add refreshinfo2 datetime default NULL, add refreshinfo3 datetime default NULL;
alter table system add denyupd int(1) default '0',add denyupdvalidto datetime default NULL,add denyupdcomments longtext default NULL;
create table licproduct (
  id          bigint(20)  NOT NULL,
  name        varchar(255) NOT NULL,
  pgroup      varchar(128) default NULL,
  cistatus    int(2)      NOT NULL,
    lmetric varchar(40) default 'UNKNOWN', itemno varchar(40),
    producer       bigint(20)  default NULL, 
    mandator       bigint(20)  default NULL,
  comments    longtext     default NULL,
  additional  longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table liccontract add licproduct bigint(20) default null;
alter table liccontract add fullname varchar(512) not null;
alter table lnksoftwaresystem add licsubof bigint(20) default null;
create table lnkapplconumber (
  id          bigint(20)  NOT NULL,
  name        varchar(40) NOT NULL,
  appl        bigint(20)  NOT NULL,
  comments    longtext     default NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  createuser  bigint(20) NOT NULL default '0',
  modifyuser  bigint(20) NOT NULL default '0',
  editor      varchar(100) NOT NULL default '',
  realeditor  varchar(100) NOT NULL default '',
  srcsys      varchar(100) default 'w5base',
  srcid       varchar(20) default NULL,
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (appl,name),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table businessservice add validfrom datetime default NULL, add validto datetime default NULL, add customer bigint(20)  default NULL, add repocycle varchar(20) default NULL;
alter table businessservice add requ_mtbf int(10) default NULL,add impl_mtbf int(10) default NULL,add curr_mtbf int(10) default NULL, add requ_ttr varchar(20) default NULL,add impl_ttr int(10) default NULL,add  curr_ttr int(10) default NULL, add requ_avail_p double(8,2) default NULL,add impl_avail_p double(8,2) default NULL,add  curr_avail_p double(8,2) default NULL, add requ_respti varchar(20) default NULL,add impl_respti int(10) default NULL,add  curr_respti int(10) default NULL,add th_warn_avail double(8,2) default NULL, add th_crit_avail double(8,2) default NULL, add th_warn_respti double(8,2) default NULL, add th_crit_respti double(8,2) default NULL;
alter table businessservice add th_warn_mtbf double(8,2) default NULL, add th_crit_mtbf double(8,2) default NULL,add th_warn_ttr double(8,2) default NULL, add th_crit_ttr double(8,2) default NULL;
alter table appl add controlcenter bigint(20);
alter table system add lastqenrich datetime default NULL,add key(lastqenrich);
alter table appl add lastqenrich datetime default NULL,add key(lastqenrich);
alter table swinstance add lastqenrich datetime default NULL,add key(lastqenrich);
alter table accessurl add lastip longtext, add lastqcheck datetime default NULL,add key(lastqcheck),add lastqenrich datetime default NULL,add key(lastqenrich);
create table accessurllastip (
  id          bigint(20)  NOT NULL,
  accessurl   bigint(20)  NOT NULL,
  name        varchar(40) NOT NULL,
  createdate  datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate  datetime NOT NULL default '0000-00-00 00:00:00',
  srcload     datetime    default NULL,
  PRIMARY KEY  (id),
  KEY name (name),
  FOREIGN KEY accessurl (accessurl)
              REFERENCES accessurl (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table asset add refreshpland datetime default NULL;
alter table businessservice add repoperiod varchar(20) default '', add durationtoav varchar(20) default '', add reproacht bigint(20) default NULL, add mperiod   bigint(20) default NULL, add commentsrm longtext  default NULL, add commentsperf longtext  default NULL;
alter table businessservice add curr_perf int(10) default NULL, add requ_perf varchar(20) default NULL,add impl_perf int(10) default NULL,add th_warn_perf double(8,2) default NULL, add th_crit_perf double(8,2) default NULL;
alter table businessservice add  slacomments longtext default NULL;
alter table businessservice add  reviewperiod varchar(20) default NULL;
alter table businessservice add  servicesupport bigint(20) default NULL;
alter table appl add mainusetime text default NULL;
alter table appl add secusetime  text default NULL;
create table lnkbusinessservicegrp (
  id         bigint(20) NOT NULL,
  businessservice    bigint(20) NOT NULL, 
  grp                bigint(20) NOT NULL,
  comments           longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(80) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id), UNIQUE KEY rel (businessservice,grp),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY (businessservice) 
          REFERENCES businessservice(id) ON DELETE CASCADE,
  FOREIGN KEY (grp) 
          REFERENCES grp (grpid) ON DELETE CASCADE
) ENGINE=INNODB;
alter table asset add acquStart datetime default NULL,add acquMode varchar(10) default 'PURCHASE';
alter table businessservice add occreactiontime bigint(20), add occtotaltime bigint(20);
alter table businessservice add occreactiontimelevel int(20), add occtotaltimelevel int(20);
alter table appl add usetime text default NULL, add tempexeptusetime text default NULL;
alter table swinstance add ssl_cert_exp_notify1 datetime default NULL;
alter table applgrp add responseorg bigint(20) default NULL;
use w5base;
create table lnkbprocessappl (
  id           bigint(20) NOT NULL,
  bprocess     bigint(20) NOT NULL,
  appl         bigint(20),
  relevance    int(2)     NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',   
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,       
  PRIMARY KEY  (id),
  KEY bprocess (bprocess),
  KEY appl (appl),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table lnkbprocesssystem (
  id           bigint(20) NOT NULL,
  bprocess     bigint(20) NOT NULL,
  system       bigint(20) NOT NULL,
  relevance    int(2)     NOT NULL,
  comments     longtext    default NULL,
  additional   longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',   
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,       
  PRIMARY KEY  (id),
  KEY bprocess (bprocess),
  KEY system (system),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkbprocessappl add appfailinfo longtext default NULL;
alter table lnkbprocessappl add autobpnotify int(1) default '0';
drop table lnkbprocesssystem;
rename table lnkbprocessappl to lnkbprocessbusinessservice;
alter table lnkbprocessbusinessservice add businessservice bigint(20) NOT NULL;
set FOREIGN_KEY_CHECKS=0;
alter table lnkbprocessbusinessservice add FOREIGN KEY fk_bs (businessservice) REFERENCES businessservice (id) ON DELETE CASCADE; alter table lnkbprocessbusinessservice add unique key (bprocess,businessservice);
set FOREIGN_KEY_CHECKS=1;
alter table businessservice add databoss  bigint(20);
alter table businessservice add mandator  bigint(20);
alter table businessservice add nature  char(5) default '', add unique fullname(nature,name);
alter table businessservice add contact1 bigint(20),add contact2 bigint(20),add contact3 bigint(20),add contact4 bigint(20),add contact5 bigint(20),add contact6 bigint(20),add contact7 bigint(20),add contact8 bigint(20),add contact9 bigint(20);
alter table businessservice add shortname varchar(10);
alter table businessservice drop key fullname, add unique fullname(nature,name,shortname);
alter table businessservice add implservicesupport  bigint(20);
alter table businessservice add lastqcheck datetime default NULL,add key(lastqcheck);
alter table accessurl add expiration datetime default NULL;
alter table lnkapplappl add ifagreementneeded int(1) default '1',add ifagreementdoc longblob,add ifagreementlang varchar(3),add ifagreementexclreason longtext,add ifagreementdocname varchar(255),add ifagreementdocdate datetime,add ifagreementdoctype varchar(255),add handleconfidential int(1) default '0';
alter table software add iurl varchar(1024);
alter table producer add iurl varchar(1024);
alter table system add is_embedded bool default '0';
create table lnkapplgrpapplgrp (
  id         bigint(20) not null,
   fromapplgrp       bigint(20) not null,
   toapplgrp         bigint(20) not null,
   planed_activation datetime DEFAULT NULL,
   planed_retirement datetime DEFAULT NULL,
   relstatus         int(2)   default '1',
   contype           int(2)   default NULL,
  additional longtext     default NULL,
  comments   longtext     default NULL,
  createdate datetime     NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime     NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20)   NOT NULL default '0',
  modifyuser bigint(20)   NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20)  default NULL,
  srcload    datetime     default NULL,
  PRIMARY KEY  (id),
  KEY fromapplgrp (fromapplgrp),
  KEY toapplgrp (toapplgrp),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table lnkapplappl add iscrypted int(1) default '0';
create table wallet (
   id             bigint(20) NOT NULL,
   name           varchar(255) NOT NULL,
   shortdesc      varchar(128) NOT NULL,
   comments       longtext default NULL,
   sslcert        blob NOT NULL,
   sslcertdocname varchar(255) NOT NULL,
   applid         bigint(20) NOT NULL,
   issuer         varchar(512) NOT NULL,
   subject        varchar(512) NOT NULL,
   serialno       varchar(32) NOT NULL,
   startdate      datetime NOT NULL default '0000-00-00 00:00:00',
   enddate        datetime NOT NULL default '0000-00-00 00:00:00',
   exp_notify1    datetime default NULL,
   createdate     datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate     datetime NOT NULL default '0000-00-00 00:00:00',
   createuser     bigint(20) NOT NULL default '0',
   modifyuser     bigint(20) NOT NULL default '0',
   editor         varchar(100) NOT NULL default '',
   realeditor     varchar(100) NOT NULL default '',
   PRIMARY KEY (id),
   UNIQUE KEY uk_name (name),
   FOREIGN KEY fk_appl (applid) REFERENCES appl (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table itfarm (
  id         bigint(20) NOT NULL,
  fullname   varchar(120) NOT NULL,
  name       varchar(40) NOT NULL,
  combound   varchar(40) NOT NULL,
  cistatus   int(2)      NOT NULL,
    itfarmid       varchar(20) default NULL,
    databoss       bigint(20)  default NULL,
    mandator       bigint(20)  default NULL,
    description    longtext    default NULL,
    itnormodelrest varchar(20) default NULL,
    additional     longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL, lastqcheck datetime default NULL,
  PRIMARY KEY  (id),KEY lastqcheck(lastqcheck),
  UNIQUE KEY itfarmid (itfarmid),
  UNIQUE KEY name (fullname),KEY(mandator),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnkitfarmasset (
  id         bigint(20) NOT NULL,
  itfarm     bigint(20) NOT NULL,
  asset      bigint(20) NOT NULL,
  itnormodelrest varchar(20) default NULL,
  additional longtext   default NULL,
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY asset (asset),
  FOREIGN KEY fk_itfarm (itfarm) REFERENCES itfarm (id) ON DELETE CASCADE,
  FOREIGN KEY fk_asset (asset)   REFERENCES asset (id) ON DELETE RESTRICT,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
create table lnkassetasset (
  id         bigint(20) NOT NULL,
  passet     bigint(20) NOT NULL,
  casset     bigint(20) NOT NULL,
  additional longtext   default NULL,
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY casset (casset),
  FOREIGN KEY fk_casset (casset) REFERENCES asset (id) ON DELETE CASCADE,
  FOREIGN KEY fk_passet (passet) REFERENCES asset (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
alter table swinstance add ssl_cipher varchar(40) default NULL,add ssl_certserial varchar(40) default NULL,add ssl_version varchar(40) default NULL,add ssl_certdump longtext   default NULL,add ssl_certsighash varchar(40) default NULL;
alter table accessurl add lnkapplappl bigint(20),add target_is_fromappl int(1) default '0', add notmultiple int(1) default '1', add from_fullname varchar(512), add from_scheme varchar(20), add from_hostname varchar(128), add from_ipport int(10), change appl appl bigint(20);
alter table accessurl drop key fullname, add UNIQUE KEY fullname (fullname,network,notmultiple),add FOREIGN KEY lnkapplappl (lnkapplappl) REFERENCES lnkapplappl (id) ON DELETE CASCADE;
alter table system add dsid varchar(128);
create table lnkitclustsvcsyspolicy (
  refid  varchar(80) NOT NULL,
  itclustsvc bigint(20) NOT NULL,
  system     bigint(20) NOT NULL,
  runpolicy  varchar(20) default NULL,
  modifyuser bigint(20) default NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  PRIMARY KEY  (refid),
  FOREIGN KEY fk_itclustsvc (itclustsvc) 
  REFERENCES lnkitclustsvc (id) ON DELETE CASCADE,
  FOREIGN KEY fk_system (system) 
  REFERENCES system (id) ON DELETE CASCADE
);
alter table itclust add defrunpolicy varchar(20) default 'allow';
create table asset_tstamp (
  id         bigint(20)  NOT NULL,
  refid      bigint(20)  NOT NULL,
  tstampname varchar(80) NOT NULL,
  tstamp     datetime    NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime    NOT NULL default '0000-00-00 00:00:00',
  comments   longtext    default NULL,
  PRIMARY KEY  (id),
  unique(refid,tstampname),
  FOREIGN KEY fk_tstamp_asset (refid) 
  REFERENCES asset (id) ON DELETE CASCADE
);
alter table appl add soslanumclusttests    float(2) default '0.0';
alter table system add itnormodel bigint(20);
alter table network add probeipurl varchar(128),add probeipproxy varchar(128);
alter table swinstance add ssl_network bigint(20) default NULL;
alter table lnkapplappl add ifagreementstate varchar(20);
create table netintercon (
  id         bigint(20) NOT NULL,
  name       varchar(80) NOT NULL,
  cistatus   int(2)      NOT NULL,
    mandator        bigint(20)  default NULL,
    databoss        bigint(20)  default NULL,
    epa_typ         int(2)      default '1',
    epa_id          varchar(40) default NULL,
    epa_systemid    bigint(20)  default NULL,
    epa_ifacename   varchar(40) default NULL,
    epa__systemname varchar(80) default NULL,epa__incidentgroup varchar(128),
    epa__adm        bigint(20)  default NULL,
    epa__adm2       bigint(20)  default NULL,
    epa__location   varchar(80) default NULL,
    epa__room       varchar(40) default NULL,
    epa__place      varchar(40) default NULL,
    epb_typ         int(2)      default '1',
    epb_id          varchar(40) default NULL,
    epb_systemid    bigint(20)  default NULL,
    epb_ifacename   varchar(40) default NULL,
    epb__systemname varchar(80) default NULL,epb__incidentgroup varchar(128),
    epb__adm        bigint(20)  default NULL,
    epb__adm2       bigint(20)  default NULL,
    epb__location   varchar(80) default NULL,
    epb__room       varchar(40) default NULL,
    epb__place      varchar(40) default NULL,
    lineid          varchar(40) default NULL,
    linetype        varchar(40) default NULL,
    linebandwidth   bigint(20)  default NULL,
    lineipnet       bigint(20)  default NULL,
    additional      longtext    default NULL,
  comments    longtext     default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL, 
  lastqcheck datetime default NULL,
  PRIMARY KEY  (id),KEY lastqcheck(lastqcheck),
  UNIQUE KEY `srcsys` (srcsys,srcid),
  FOREIGN KEY fk_epa (epa_systemid)  REFERENCES system (id) ON DELETE RESTRICT,
  FOREIGN KEY fk_epb (epb_systemid)  REFERENCES system (id) ON DELETE RESTRICT
) ENGINE=INNODB;
alter table wallet add issuerdn varchar(256);
alter table swinstance add ssl_certissuerdn varchar(256);
alter table software add instanceidentify varchar(256);
create table riskmgmtbase (
  id              bigint(20) NOT NULL,
  itrmcriticality int(4) default NULL,
  solutionopt     varchar(30) default NULL,
  ibipoints       int(4) default NULL,
  ibiprice        int(10) default NULL,
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  FOREIGN KEY fk_applid (id) REFERENCES appl (id) ON DELETE CASCADE
) ENGINE=INNODB;
alter table asset add slotno varchar(40) default '';
alter table system add productline varchar(40) default NULL;
create table lnknetinterconipnet (
  id         bigint(20) NOT NULL,
  ipnet       bigint(20) NOT NULL,
  netintercon bigint(20) NOT NULL,
  endpoint    char(1) default 'A',
  additional longtext   default NULL,
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) default NULL,
  modifyuser bigint(20) default NULL,
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY lnkkey (ipnet,netintercon),
  FOREIGN KEY fk_ipnet  (ipnet) REFERENCES ipnet (id) ON DELETE CASCADE,
  FOREIGN KEY fk_netintercon (netintercon) REFERENCES netintercon (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=INNODB;
alter table system add is_cbreakdown bool default '0';
alter table ipaddress add lastqcheck datetime default NULL,add key(lastqcheck);
create table sysiface (
  id         bigint(20) NOT NULL,
  system     bigint(20) NOT NULL,
  asset      bigint(20) NOT NULL,
  name       varchar(45) NOT NULL, 
  macaddr    varchar(45) NOT NULL, 
  additional longtext   default NULL,
  comments   longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  createuser bigint(20) NOT NULL default '0',
  modifyuser bigint(20) NOT NULL default '0',
  editor     varchar(100) NOT NULL default '',
  realeditor varchar(100) NOT NULL default '',
  srcsys     varchar(100) default 'w5base',
  srcid      varchar(20) default NULL,
  srcload    datetime    default NULL,
  PRIMARY KEY  (id),key(system),key(asset),key(name),UNIQUE KEY `mac` (system,macaddr),
  UNIQUE KEY `srcsys` (srcsys,srcid),UNIQUE KEY `ifname` (system,name),
  FOREIGN KEY fk_sys  (system) REFERENCES system (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table wallet add expnotifyleaddays int(22) default '56';
alter table swinstance add ssl_expnotifyleaddays int(22) default '56';
alter table swinstance add techdataupd datetime default NULL;
alter table lnkitclustsvc add lastqcheck datetime default NULL,add key(lastqcheck);
alter table itfarm add shortname varchar(40);
alter table system add fsystemalias varchar(128) default NULL,add unique(fsystemalias);
alter table lnkapplappl add gwappl bigint(20) default NULL,add gwappl2 bigint(20) default NULL,add ifrelation varchar(20) default 'DIRECT';
alter table wallet add altname longtext;
alter table ipaddress  add itcloudarea bigint(20) default NULL,add key(itcloudarea);
alter table swinstance  add itcloudarea bigint(20) default NULL,add key(itcloudarea);
alter table accessurl add isonsharedproxy int(1) default '0',add do_ssl_cert_check int(1) default '0',add ssl_cert_check datetime default NULL,add ssl_cert_end datetime default NULL,add ssl_cert_begin datetime default NULL,add ssl_state varchar(128) default NULL,add ssl_cert_exp_notify1 datetime default NULL,add ssl_cipher varchar(40) default NULL,add ssl_certserial varchar(40) default NULL,add ssl_version varchar(40) default NULL,add ssl_certdump longtext   default NULL,add ssl_certsighash varchar(40) default NULL;
create table addlnkapplgrpsystem (
  id         bigint(20) NOT NULL,
  idtoken    varchar(40) NOT NULL,
  applgrp    bigint(20)  NOT NULL,
  system     bigint(20)  NOT NULL,
  additional  longtext   default NULL,
  comments    longtext   default NULL,
  createdate datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id), UNIQUE KEY idtoken (idtoken),key(applgrp),key(system),
  UNIQUE KEY token (applgrp,system),
  FOREIGN KEY fk_sys  (system) REFERENCES system (id) ON DELETE CASCADE,
  FOREIGN KEY fk_agrp (applgrp) REFERENCES applgrp (id) ON DELETE CASCADE
) ENGINE=INNODB;
alter table appl add respmethod varchar(40) default 'ROLEBASED';
alter table swinstance add software bigint(20) default NULL,add version varchar(30) default NULL,add ipaddress bigint(20) default NULL;
create table lnkadditionalci (
  id           bigint(20) NOT NULL,
  appl         bigint(20),
  system       bigint(20),
  swinstance   bigint(20),
  name         varchar(40), ciusage varchar(40),
  target       varchar(80),
  targetid     varchar(80),
  comments     longtext default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(80) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY appl (appl),
  KEY system (system),
  KEY swinstance (swinstance),
  FOREIGN KEY fk_system (system) REFERENCES system (id) ON DELETE CASCADE,
  FOREIGN KEY fk_appl   (appl)   REFERENCES appl (id) ON DELETE CASCADE,
  FOREIGN KEY fk_swinstace (swinstance) REFERENCES swinstance (id) ON DELETE CASCADE,
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table asset add eohsd datetime default NULL;
alter table lnkadditionalci add accessurl bigint(20),add FOREIGN KEY fk_accessurl (accessurl) REFERENCES accessurl (id) ON DELETE CASCADE;
alter table network add tagname varchar(20) default NULL, add UNIQUE KEY tagname (tagname);
alter table system add autoscalinggroup varchar(128) default NULL;
alter table system add autoscalingsubgroup varchar(128) default NULL;
alter table ipnet add ipnetresp bigint(20) default NULL,add ipnetresp2 bigint(20) default NULL,add techcontact bigint(20) default NULL;
alter table accessurl add ssl_expnotifyleaddays int(22) default '56';
create table lnkapplappltag (
  id           bigint(20) NOT NULL,
  lnkapplappl  bigint(20) NOT NULL,
  name         varchar(40) NOT NULL,
  value        varchar(128) NOT NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL, 
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY name (name),
  FOREIGN KEY lnkapplappl (lnkapplappl) 
  REFERENCES lnkapplappl (id) ON DELETE CASCADE,
  KEY lnkapplappl (lnkapplappl),               
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table asset add plandecons datetime default NULL;
alter table accessurl add ssl_certissuerdn varchar(256) default null;
alter table asset add notifyplandecons1 datetime default NULL,add notifyplandecons2 datetime default NULL;
alter table asset add eohscomments longtext;
alter table system add issoximpl int(2) default NULL;
alter table system add reqitnormodel bigint(20);
alter table system add instdate datetime default NULL,add key(instdate);
alter table system add is_closedosenv bool default '0';
alter table appl add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table system add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table asset add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table itclust add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table swinstance add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table itcloud add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
alter table applgrp add lorgchangedt datetime default NULL,add lrecertreqdt datetime default NULL,add lrecertdt datetime default NULL,add lrecertuser bigint(20) default NULL,add lrecertreqnotify datetime default NULL;
drop table riskmgmtbase;
