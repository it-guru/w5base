create table "W5I_HPSAsup__system_of" (
   systemid     varchar2(40) not null,
   dscope       varchar2(20),
   chm          varchar2(20),
   comments     varchar2(4000),
   modifyuser   number(*,0),
   modifydate   date,
   constraint "W5I_HPSAsup__system_of_pk" primary key (systemid)
);

create or replace view "W5I_HPSAsup__system" as
select distinct "itil::system".id                 id,
                "itil::system".name               systemname, 
                "itil::system".systemid           systemid,
                decode("W5I_HPSAsup__system_of".dscope,null,'IN',
                       "W5I_HPSAsup__system_of".dscope)  dscope,
                decode("W5I_HPSA_system".systemid,null,0,1)  hpsafnd,
                decode("W5I_HPSA_lnkswp".server_id,null,0,1) scannerfnd,
                "W5I_HPSAsup__system_of".systemid of_id,
                "W5I_HPSAsup__system_of".comments,
                "W5I_HPSAsup__system_of".chm,
                '-2016'                       scopemode,
                "W5I_HPSAsup__system_of".modifyuser,
                "W5I_HPSAsup__system_of".modifydate
       
from "itil::appl"
 left outer join "base::grp" bteam   
   on "itil::appl".businessteamid=bteam.grpid
 join "W5I_ACT_itil::lnkapplsystem"  
   on "itil::appl".id="W5I_ACT_itil::lnkapplsystem".applid
 join "itil::system"                 
   on "W5I_ACT_itil::lnkapplsystem".systemid="itil::system".id
 left outer join "tsacinv::system"              
   on "itil::system".systemid="tsacinv::system".systemid
 left outer join "W5I_HPSAsup__system_of"
    on "itil::system".systemid="W5I_HPSAsup__system_of".systemid
 left outer join "W5I_HPSA_system" 
    on "itil::system".systemid="W5I_HPSA_system".systemid
 left outer join "W5I_HPSA_lnkswp" 
    on "W5I_HPSA_system".server_id="W5I_HPSA_lnkswp".server_id 
       and ("W5I_HPSA_lnkswp".swclass='HPSA_MW_Scanner_WIN [14356670830001]'
         or "W5I_HPSA_lnkswp".swclass='HPSA_MW_Scanner [14224372530001]')
where 
        -- nur installiert/aktive Anwendungen
       "itil::appl".cistatusid=4 
       -- nur installiert/aktive Systeme
    and "itil::system".cistatusid in (3,4)
       -- nur Anwendungen der TelekomIT Mandaten
    and "itil::appl".mandator like 'TelekomIT%'
       -- alle CI-Group: TOP100-TelekomIT Anwendungen
    and '; '||mgmtitemgroup||';'  like '%; TOP100-TelekomIT;%'
       -- aber NICHT Anwendungen der CI-Group SAP
    and '; '||mgmtitemgroup||';'  not like '%; SAP;%' 
       -- nicht Anwendungen im Mandaten "Extern"
    and "itil::appl".mandator     not like 'Extern'    
       -- nicht Anwendungen mit Betriebsteam "Extern"
    and bteam.fullname     not like 'Extern'               
       -- nicht Anwendungen mit NOR-Lösungsmodel=DE6
    and "itil::appl".itnormodel<>'DE6'         
       -- nicht GDU SAP
    and bteam.fullname not like 'DTAG.TSY.ITDiv.CS.SAPS.%'  
    and bteam.fullname not like 'DTAG.TSY.ITDiv.CS.SAPS'     
    and bteam.fullname not like 'DTAG.GHQ.VTS.TSI.ITDiv.GITO.SAPS'  
    and bteam.fullname not like 'DTAG.GHQ.VTS.TSI.ITDiv.GITO.SAPS.%' 
       -- nicht Systeme mit Betriebssystem WinXP*
    and "itil::system".osrelease  not like 'WinXP%'               
       -- nicht Systeme mit Betriebssystem WinNT*
    and "itil::system".osrelease  not like 'WinNT%'         
       -- nicht AIX VIO Systeme
    and "itil::system".osrelease  not like 'AIX VIO %'   
       -- nicht AXI HMC Systeme
    and "itil::system".osrelease  not like 'AIX HMC %'    
       -- nicht VMWARE Virutalisierungs-Hosts
    and "itil::system".osrelease  not like 'VMWARE %'     
       --  nicht Solaris auf APPCOM
    and not("itil::system".osrelease like 'Solaris%'        
        and "tsacinv::system".systemolaclass='30')     
       -- keine Systeme am Standort Kiel
    and (   "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107.%' 
         or "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107'
         or "itil::system".location is null )
       -- nur Systeme mit Betriebsart=Prod
    and "itil::system".isprod=1                   
       -- keine Systeme mit Systemklassifizierung=Infrastrutkur
    and "itil::system".isinfrastruct=0
       -- Embedded Systeme ausklammern (da Scanner nicht möglich)
    and "itil::system".isembedded=0
       -- Loadbalancer Systeme ausklammern (da Scanner nicht möglich)
    and "itil::system".isloadbalacer=0
       -- MU Status "hibernate" ausklammern
    and ("tsacinv::system".status not like 'hibernate' or 
         "tsacinv::system".status is null)
       -- Ausschluss von Mainframe
    and "itil::system".osclass not like 'MAINFRAME'

union all
            
select distinct "itil::system".id                 id,
                "itil::system".name               systemname, 
                "itil::system".systemid           systemid,
                decode("W5I_HPSAsup__system_of".dscope,null,'IN',
                       "W5I_HPSAsup__system_of".dscope)  dscope,
                decode("W5I_HPSA_system".systemid,null,0,1)  hpsafnd,
                decode("W5I_HPSA_lnkswp".server_id,null,0,1) scannerfnd,
                "W5I_HPSAsup__system_of".systemid of_id,
                "W5I_HPSAsup__system_of".comments,
                "W5I_HPSAsup__system_of".chm,
                '2017-'                  scopemode,
                "W5I_HPSAsup__system_of".modifyuser,
                "W5I_HPSAsup__system_of".modifydate
       
from "itil::appl"
 left outer join "base::grp" bteam   
   on "itil::appl".businessteamid=bteam.grpid
 join "W5I_ALL_itil::lnkapplsystem"  
   on "itil::appl".id="W5I_ALL_itil::lnkapplsystem".applid
 join "itil::system"                 
   on "W5I_ALL_itil::lnkapplsystem".systemid="itil::system".id
 left outer join "tsacinv::system"              
   on "itil::system".systemid="tsacinv::system".systemid
 left outer join "W5I_HPSAsup__system_of"
    on "itil::system".systemid="W5I_HPSAsup__system_of".systemid
 left outer join "W5I_HPSA_system" 
    on "itil::system".systemid="W5I_HPSA_system".systemid
 left outer join "W5I_HPSA_lnkswp" 
    on "W5I_HPSA_system".server_id="W5I_HPSA_lnkswp".server_id 
       and ("W5I_HPSA_lnkswp".swclass='HPSA_MW_Scanner_WIN [14356670830001]'
         or "W5I_HPSA_lnkswp".swclass='HPSA_MW_Scanner [14224372530001]')
where 
        -- nur installiert/aktive Anwendungen
       "itil::appl".cistatusid=4 
       -- nur installiert/aktive Systeme
    and "itil::system".cistatusid in (3,4)
       -- nur Anwendungen der TelekomIT Mandaten
    and "itil::appl".mandator like 'TelekomIT%'
       -- nur Anwendungen mit der Prio 1
    and "itil::appl".customerprio=1
       -- nicht Anwendungen im Mandaten "Extern"
    and "itil::appl".mandator     not like 'Extern'    
       -- nicht Anwendungen mit Betriebsteam "Extern"
    and bteam.fullname     not like 'Extern'               
       -- keine Systeme am Standort Kiel
    and (   "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107.%' 
         or "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107'
         or "itil::system".location is null )
       -- nur Systeme mit Betriebsart=Prod
    and "itil::system".isprod=1                   
       -- keine Systeme mit Systemklassifizierung=Infrastrutkur
    and "itil::system".isinfrastruct=0
       -- keine Systeme mit Systemklassifizierung=Backupserver
    and "itil::system".isbackupsrv=0
       -- keine Systeme mit Systemklassifizierung=Printer/Printserver
    and "itil::system".isprinter=0
       -- keine Systeme mit Systemklassifizierung=Switch / Networkswitch
    and "itil::system".isnetswitch=0
       -- keine Systeme mit Systemklassifizierung=Router
    and "itil::system".isrouter=0
       -- Embedded Systeme ausklammern (da Scanner nicht möglich)
    and "itil::system".isembedded=0
       -- Loadbalancer Systeme ausklammern (da Scanner nicht möglich)
    and "itil::system".isloadbalacer=0
       -- MU Status "hibernate" ausklammern
    and ("tsacinv::system".status not like 'hibernate' or 
         "tsacinv::system".status is null)
       -- Ausschluss von Mainframe
    and "itil::system".osclass not like 'MAINFRAME';

grant select on "W5I_HPSAsup__system" to W5I;
grant update,insert on "W5I_HPSAsup__system_of" to W5I;
create or replace synonym W5I.HPSAsup__system for "W5I_HPSAsup__system";
create or replace synonym W5I.HPSAsup__system_of for "W5I_HPSAsup__system_of";
grant select on "W5I_HPSAsup__system_of" to W5_BACKUP_D1;
grant select on "W5I_HPSAsup__system_of" to W5_BACKUP_W1;


