delete from businessservice where name is null;
delete from businessservice where cistatus>4;
delete businessservice
from businessservice
   join appl on businessservice.appl=appl.id
where appl.cistatus>5;
update businessservice set nature='SVC' 
where nature='IT-S' or nature='ES' or nature='TR';
alter table lnkbscomp add varikey bigint(20)  default NULL;
alter table lnkbscomp drop key lnkpos;
alter table lnkbscomp add unique key (businessservice,objtype,varikey,obj1id);
delete from menu where fullname like 'itservices' or fullname like 'itservices.%';
alter table lnkbprocessbusinessservice add unique key (bprocess,businessservice);

