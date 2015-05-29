CREATE OR REPLACE PROCEDURE syncronizeTable(
   tabname in varchar2,
   uniqueid in varchar2
) AUTHID CURRENT_USER IS  
  TYPE cur_typ IS REF CURSOR;
  temptablename varchar2(40);
  updst   varchar2(4000);
  insst   varchar2(4000);
  valst   varchar2(4000);
  fld     cur_typ;
  fldname varchar2(40);
BEGIN
  temptablename:='import_'|| tabname;
  -- Step 0.2 : ensure exist of cached_ table 
  begin 
      execute IMMEDIATE 'create TABLE "cached_'|| tabname || '" as ' ||
                        'select * from "remote_'|| tabname || '" ' ||
                        'where rownum<0'; 
      execute IMMEDIATE 'create INDEX "Cached_'|| tabname || '" on ' ||
                        '"cached_'|| tabname || '"(' || uniqueid || ') '||
                        'online';
  EXCEPTION 
     WHEN others THEN null; 
  end; 
  begin 
      execute IMMEDIATE 'truncate table "'|| temptablename || '"';
  EXCEPTION 
     WHEN others THEN null; 
  end; 
  begin 
      execute IMMEDIATE 'drop table "'|| temptablename || '"';
  EXCEPTION 
     WHEN others THEN null; 
  end; 
  -- Step 1: create temp Table with import Data
  execute IMMEDIATE 'create global TEMPORARY TABLE "'|| temptablename || '" '||
                    'on commit preserve rows as '||
                    'select * from "remote_' || tabname || '"';
  -- Step 2: Update or Insert Changed records
  updst:=' ';
  insst:=' ';
  valst:=' ';
  open fld for 'SELECT column_name FROM user_tab_cols WHERE table_name = :name'
           using 'remote_'||tabname;
  loop
     fetch fld into fldname;
     exit when fld%NOTFOUND;
     if (updst!=' ') then
        updst:=updst||',';
     end if;
     if (valst!=' ') then
        valst:=valst||',';
     end if;
     if (insst!=' ') then
        insst:=insst||',';
     end if;
     if (fldname!=uniqueid) then
        updst:=updst||'target.'||fldname||'=source.'||fldname;
     end if;
     insst:=insst||fldname;
     valst:=valst||'source.'||fldname;
  end loop;
  close fld;
  execute IMMEDIATE 'MERGE INTO "cached_' || tabname || '" target ' ||
     'using (' ||
     'select * from "import_' || tabname || '" ' ||
     ' minus ' ||
     'select * from "cached_' || tabname || '" ' ||
     ') source ' ||
     'on (target.' || uniqueid || '=source.' || uniqueid || ') '||
     'WHEN MATCHED THEN ' ||
     'update set ' || updst || ' ' ||
     'WHEN NOT MATCHED THEN ' ||
     'insert ('|| insst || ') values(' || valst || ')';
                    
  -- Step 3: Remove deleted records
  execute IMMEDIATE 'delete from "cached_'|| tabname ||'" ' || 
                    'where '|| uniqueid || ' in (' ||
                    'select '|| uniqueid ||' from "cached_'||tabname||'"' ||
                    ' minus ' ||
                    'select '||uniqueid ||' from "'|| temptablename||'"'||
                    ')';
  begin 
      execute IMMEDIATE 'truncate table "'|| temptablename || '"';
  EXCEPTION 
     WHEN others THEN null; 
  end; 
  begin 
      execute IMMEDIATE 'drop table "'|| temptablename || '"';
  EXCEPTION 
     WHEN others THEN null; 
  end; 
END syncronizeTable;
