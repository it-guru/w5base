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
  fullname varchar(128) NOT NULL,
  cistatusid int NOT NULL,
  W5LastSync timestamp NOT NULL,
  CONSTRAINT base__user UNIQUE(userid)
);
grant all on base__user to w5base;


