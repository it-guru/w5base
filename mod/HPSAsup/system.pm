package HPSAsup::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

=head1

#
# Generierung der Support-Views in der pw5repo Kennung
#

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
                "W5I_HPSAsup__system_of".modifyuser,
                "W5I_HPSAsup__system_of".modifydate
       
from "itil::appl"
 left outer join "base::grp" bteam   
   on "itil::appl".businessteamid=bteam.grpid
 join "W5I_ACT_itil::lnkapplsystem"  
   on "itil::appl".id="W5I_ACT_itil::lnkapplsystem".applid
 join "itil::system"                 
   on "W5I_ACT_itil::lnkapplsystem".systemid="itil::system".id
 join "tsacinv::system"              
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
    and "itil::system".cistatusid=4  
       -- nur Anwendungen der TOP100-TelekomIT CI-Group
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
    and "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107.%'      
    and "itil::system".location not like 'DE.Kiel.Kronshagener_Weg_107'      
       -- nur Systeme mit Betriebsart=Prod
    and "itil::system".isprod=1                   
       -- keine Systeme mit Systemklassifizierung=Infrastrutkur
    and "itil::system".isinfrastruct=0
       -- Embedded Systeme ausklammern (da Scanner nicht möglich)
    and "itil::system".isembedded=0
       -- MU Status "hibernate" ausklammern
    and "tsacinv::system".status not like 'hibernate'
       -- Ausschluss von Mainframe
    and "itil::system".osclass not like 'MAINFRAME';            
            

grant select on "W5I_HPSAsup__system" to W5I;
grant update,insert on "W5I_HPSAsup__system_of" to W5I;
create or replace synonym W5I.HPSAsup__system for "W5I_HPSAsup__system";
create or replace synonym W5I.HPSAsup__system_of for "W5I_HPSAsup__system_of";
grant select on "W5I_HPSAsup__system_of" to W5_BACKUP_D1;
grant select on "W5I_HPSAsup__system_of" to W5_BACKUP_W1;


=cut

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"id",
                wrdataobjattr =>"systemid"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Select(
                name          =>'dscope',
                label         =>'Scope State',
                value         =>['IN','OUT - no MW','OUT - SAP excl','OUT - other'],
                dataobjattr   =>'dscope'),

      new kernel::Field::Text(
                name          =>'chm',
                label         =>'Change triggered',
                weblinkto     =>'tssm::chm',
                weblinkon     =>['chm'=>'changenumber'],
                dataobjattr   =>'chm'),

      new kernel::Field::Boolean(
                name          =>'hpsafound',
                label         =>'HPSA found',
                readonly      =>1,
                dataobjattr   =>'hpsafnd'),

      new kernel::Field::Boolean(
                name          =>'scannerfound',
                label         =>'MW_Scanner found',
                readonly      =>1,
                dataobjattr   =>'scannerfnd'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Text(
                name          =>'applications',
                group         =>'source',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4",applcistatusid=>"4"}],
                vjoindisp     =>'appl', 
                vjoinon       =>['systemid'=>'systemsystemid'],
                label         =>'Applications'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("HPSAsup__system_of");
   $self->setDefaultView(qw(systemname systemid hpsafound scannerfound comments));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="HPSAsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default tad4d w5basedata am source));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $effdscope=effVal($oldrec,$newrec,"dscope");
   if ($effdscope=~m/^OUT /){
      if (length(effVal($oldrec,$newrec,"comments"))<10){
         $self->LastMsg(ERROR,"setting out of scope needs meaningfu comments"); 
         return(undef);
      }
      if (effVal($oldrec,$newrec,"chm") ne ""){
         $newrec->{chm}=undef;
      }
   }
   if (effChanged($oldrec,$newrec,"chm") &&
       effVal($oldrec,$newrec,"chm") ne ""){
      if ((effVal($oldrec,$newrec,"scannerfound")==1)){
         $self->LastMsg(ERROR,"change number makes no sense - scanner exists"); 
         return(undef);
      }
      if (!(effVal($oldrec,$newrec,"chm")=~m/^C\d{5,15}/)){
         $self->LastMsg(ERROR,"change number seems not to be correct"); 
         return(undef);
      }
   }

   return(1);
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{systemid}};
   $newrec->{id}=$oldrec->{systemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_scannerfound"))){
     Query->Param("search_scannerfound"=>"\"".$self->T("boolean.false")."\"");
   }
   if (!defined(Query->Param("search_dscope"))){
     Query->Param("search_dscope"=>"IN");
   }
}


#sub isViewValid
#{
#   my $self=shift;
#   my $rec=shift;
#
#   my @l=$self->SUPER::isViewValid($rec);
#
#   if (in_array(\@l,"ALL")){
#      if ($rec->{cenv} eq "Both"){
#         return(qw(header source am default));
#      }
#   }
#   return(@l);
#}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/));
   my @l=$self->SUPER::isWriteValid($rec,@_);

   return("default") if ($#l!=-1);
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
