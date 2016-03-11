CREATE TABLE wfhead (
  wfheadid bigint(20) NOT NULL default '0',
  eventstart datetime default NULL,
  eventend datetime default NULL,
  wfclass varchar(30) NOT NULL default '',
  PRIMARY KEY  (wfheadid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE wfrange (
  wfheadid bigint(20) NOT NULL,
  s datetime default NULL,
  m datetime default NULL,
  e datetime default NULL,
  wfclass varchar(30),
  KEY wfheadid (wfheadid),
  key startonly(s),
  key endonly(e),
  key middle(m),
  FOREIGN KEY (wfheadid) REFERENCES wfhead (wfheadid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DELIMITER //
CREATE PROCEDURE insinterval(id bigint,s timestamp, e timestamp,c varchar(30))
BEGIN
   declare thisDate timestamp;
   declare nextDate timestamp;
   declare ndays decimal;
   set thisDate = s;
   delete from wfrange where wfheadid=id;
   IF (s is null AND e is not null) THEN
      insert into wfrange (wfheadid,e) values(id,e);
   END IF;
   IF (e is null AND s is not null) THEN
      insert into wfrange (wfheadid,s) values(id,s);
   END IF;
   IF (e is not null AND s is not null) THEN
      select cast((UNIX_TIMESTAMP(e)-UNIX_TIMESTAMP(s))/60/60/24 as decimal) 
      into ndays; 
      if (ndays>0 AND ndays<1000) THEN
         repeat
            select timestampadd(DAY,1,thisDate) into nextDate;
            insert into wfrange (wfheadid,m,wfclass) values(id,nextDate,c);
            set thisDate = nextDate;
            until thisDate >= e
         end repeat;
      END IF;
   END IF;
END; //
DELIMITER ;


DELIMITER //
CREATE TRIGGER wfrange_ins AFTER  INSERT ON wfhead FOR EACH ROW
BEGIN
   call insinterval(NEW.wfheadid,NEW.eventstart,NEW.eventend,NEW.wfclass);
END //

CREATE TRIGGER wfrange_upd AFTER  UPDATE ON wfhead FOR EACH ROW
BEGIN
   call insinterval(NEW.wfheadid,NEW.eventstart,NEW.eventend,NEW.wfclass);
END //
DELIMITER ;

insert into wfhead (wfheadid,eventstart,eventend,wfclass)
            values (1,'2015-12-23 12:11:01','2016-02-03 12:48:27','aaa');

insert into wfhead (wfheadid,eventstart,eventend,wfclass)
            values (22,'2015-11-23 12:11:01',NULL,'aaa');

insert into wfhead (wfheadid,eventstart,eventend,wfclass)
            values (33,NULL,'2016-01-23 12:11:01','aaa');

insert into wfhead (wfheadid,eventstart,eventend,wfclass)
            values (44,'2115-12-23 12:11:01','2016-02-03 12:48:27','aaa');

insert into wfhead (wfheadid,eventstart,eventend,wfclass)
            values (55,'2015-12-23 12:11:01','2017-02-03 12:48:27','aaa');

select distinct wfhead.wfheadid,wfhead.eventstart,wfhead.eventend 
from wfrange join wfhead on wfrange.wfheadid=wfhead.wfheadid 
where (wfrange.m>'2016-01-01 00:00:00' AND wfrange.m<'2016-01-31 00:00:00') i
      OR (wfrange.e>'2016-01-31 00:00:00') 
      OR (wfrange.s<'2016-01-01 00:00:00');


