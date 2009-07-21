drop table AL_TCom__appl;
create table AL_TCom__appl (
  id number NOT NULL,
  name varchar(40) NOT NULL,
  cistatusid int NOT NULL,
  tsmid number,
  semid number,
  W5LastSync timestamp NOT NULL,
  CONSTRAINT AL_TCom__appl UNIQUE(id)
);
grant all on AL_TCom__appl to w5base;

drop table base__user;
create table base__user (
  userid number NOT NULL,
  fullname varchar(255) NOT NULL,
  cistatusid int NOT NULL,
  secstateid number NOT NULL,
  usertypid varchar(20) NOT NULL,
  tz varchar(20) NOT NULL,
  lang varchar(20),
  posix varchar(20),
  surname varchar(128),
  givenname varchar(128),
  email varchar(128),
  usertyp varchar(128) NOT NULL,
  W5LastSync timestamp NOT NULL,
  CONSTRAINT base__user UNIQUE(userid)
);
grant all on base__user to w5base;

drop table base__useraccount;
create table base__useraccount (
  userid number,
  account varchar(255) NOT NULL,
  W5LastSync timestamp NOT NULL,
  CONSTRAINT base__useraccount UNIQUE(account)
);
grant all on base__useraccount to w5base;

