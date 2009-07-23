create view contact as select 
  base__user.userid     userid,
  base__user.cistatusid cistatus,
  base__user.fullname   fullname,
  base__user.givenname  givenname,
  base__user.surname    surname,
  base__user.email      email,
  base__user.usertypid  usertyp,
  base__user.secstateid secstate,
  base__user.lang       lang,
  base__user.posix      posix_identifier,
  base__user.tz         timezone
  from w5in.base__user;

create view useraccount as select * from w5in.base__useraccount;


