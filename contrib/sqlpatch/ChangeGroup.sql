set @oldgrpid=12066790050006;
set @newgrpid=514;
update custcontract set responseteam=@newgrpid 
       where responseteam=@oldgrpid;

update appl set businessteam=@newgrpid 
       where businessteam=@oldgrpid;

update appl set responseteam=@newgrpid 
       where responseteam=@oldgrpid;

update system set admteam=@newgrpid 
       where admteam=@oldgrpid;

update asset set guardianteam=@newgrpid 
       where guardianteam=@oldgrpid;

update lnkcontact set targetid=@newgrpid 
       where target='base::grp' and targetid=@oldgrpid;

update businessprocessacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update faqacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update faqcatacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update fileacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update forumboardacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update menuacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update passxacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

update systemjobacl set acltargetid=@newgrpid 
       where acltarget='base::grp' and acltargetid=@oldgrpid;

