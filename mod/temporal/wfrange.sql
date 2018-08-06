DELIMITER //
CREATE PROCEDURE insinterval(id bigint,s timestamp, e timestamp,c varchar(30))
BEGIN
   declare thisDate timestamp;
   declare nextDate timestamp;
   declare padDate timestamp;
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
      if (ndays=0) THEN
         select concat_ws(' ',date(s), '12:00:00') into padDate;
         insert into wfrange (wfheadid,m,wfclass) values(id,padDate,c);
      END IF;
      if (ndays>0 AND ndays<1000) THEN
         insert into wfrange (wfheadid,m,wfclass) values(id,s,c);
         select concat_ws(' ',date(s), '12:00:00') into padDate;
         if (s<padDate) THEN
            insert into wfrange (wfheadid,m,wfclass) values(id,padDate,c);
         END IF;
         repeat
            select timestampadd(DAY,1,thisDate) into nextDate;
            if (nextDate<e AND nextDate>s) THEN
               select concat_ws(' ',date(nextDate), '12:00:00') into padDate;
               insert into wfrange (wfheadid,m,wfclass) values(id,padDate,c);
            END IF;
            set thisDate = nextDate;
            until thisDate > e
         end repeat;
         insert into wfrange (wfheadid,m,wfclass) values(id,e,c);
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
