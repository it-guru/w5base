delete from businessservice where name is null;
delete from businessservice where cistatus>4;
delete businessservice
from businessservice
   join appl on businessservice.appl=appl.id
where appl.cistatus>5;
update businessservice set nature='SVC' 
where nature='IT-S' or nature='ES' or nature='TR';

