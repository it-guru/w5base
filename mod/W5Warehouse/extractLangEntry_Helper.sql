-- Helper function to extract lang entry

create or replace function extractLangEntry
   (labeldata in varchar2, lang in varchar2)
   return varchar2
as
begin
   if instr(labeldata,chr(10)||'['||lang||':]'||chr(10))=0
   then
      if regexp_instr(labeldata,chr(10)||'\[..:\]')=0
      then
         return(labeldata);
      end if;
      return(
         trim(both chr(10) from trim(
            substr(labeldata,0,regexp_instr(labeldata,chr(10)||'\[..:\]'||chr(10))-1))
      ));
   end if;
   return(
      trim(both chr(10) from trim(
            regexp_replace(
               substr(labeldata,0,instr(labeldata,chr(10)||'['||lang||':]'||chr(10))),
               '\[..:\].*',''
            ))
      )
   );
END;

select * from user_errors;  

select decode(name_label,null,name,extractLangEntry(name_label,'en')) from "base::interviewcat";

