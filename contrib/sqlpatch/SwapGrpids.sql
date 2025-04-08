set @oldgrpid=16096465050017;
set @newgrpid=17435543000004;
set @tmpgrpid=12345678901234;

set autocommit=off;
start transaction;
update grp set grpid=@tmpgrpid    where grpid=@oldgrpid;
update grp set parentid=@tmpgrpid where parentid=@oldgrpid;
update grp set grpid=@oldgrpid    where grpid=@newgrpid;
update grp set parentid=@oldgrpid where parentid=@newgrpid;
update grp set grpid=@newgrpid    where grpid=@tmpgrpid;
update grp set parentid=@newgrpid where parentid=@tmpgrpid;
commit;

