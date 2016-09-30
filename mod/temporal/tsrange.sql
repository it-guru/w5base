DELIMITER //
CREATE PROCEDURE instsinterval(id bigint,s timestamp, e timestamp,tref bigint)
BEGIN
   declare thisDate timestamp;
   declare nextDate timestamp;
   declare padDate timestamp;
   declare ndays decimal;
   declare msg varchar(128);
   set thisDate = s;
   delete from tsrange where tspanentryid=id;
   IF (s is null AND e is not null) THEN
      insert into tsrange (tspanentryid,timeplanref,e) values(id,tref,e);
   END IF;
   IF (e is null AND s is not null) THEN
      insert into tsrange (tspanentryid,timeplanref,s) values(id,tref,s);
   END IF;
   IF (e is not null AND s is not null) THEN
      select cast((UNIX_TIMESTAMP(e)-UNIX_TIMESTAMP(s))/60/60/24 as decimal) 
      into ndays; 
      if (ndays>0 AND ndays<1000) THEN
         insert into tsrange (tspanentryid,m,timeplanref) values(id,s,tref);
         select concat_ws(' ',date(s), '12:00:00') into padDate;
         if (s<padDate) THEN
            insert into tsrange (tspanentryid,m,timeplanref) 
                          values(id,padDate,tref);
         END IF;
         repeat
            select timestampadd(DAY,1,thisDate) into nextDate;
            if (nextDate<e AND nextDate>s) THEN
               select concat_ws(' ',date(nextDate), '12:00:00') into padDate;
               insert into tsrange (tspanentryid,m,timeplanref) 
                           values(id,padDate,tref);
            END IF;
            set thisDate = nextDate;
            until thisDate > e
         end repeat;
         insert into tsrange (tspanentryid,m,timeplanref) values(id,e,tref);
      END IF;
      if (ndays=0) THEN
         insert into tsrange (tspanentryid,timeplanref,e,s) values(id,tref,e,s);
      END IF;
      if (ndays<0) THEN
         set msg = concat('MyTriggerError: tfrom tto not in sequence');
        # signal just works from mysql 5.5
        #signal sqlstate '45000' set message_text = msg;
        call tfrom_tto_not_in_sequence;
      END IF;
   END IF;
END; //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tsrange_ins AFTER  INSERT ON tspanentry FOR EACH ROW
BEGIN
   call instsinterval(NEW.id,NEW.tfrom,NEW.tto,NEW.timeplanref);
END //

CREATE TRIGGER tsrange_upd AFTER  UPDATE ON tspanentry FOR EACH ROW
BEGIN
   call instsinterval(NEW.id,NEW.tfrom,NEW.tto,NEW.timeplanref);
END //
DELIMITER ;
