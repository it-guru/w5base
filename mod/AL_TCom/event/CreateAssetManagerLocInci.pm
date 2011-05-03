package AL_TCom::event::CreateAssetManagerLocInci;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);

my @fieldset=qw(address1 country zipcode location);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("CreateAssetManagerLocInci",
                        "CreateAssetManagerLocInci");
   return(1);
}

sub CreateAssetManagerLocInci
{
   my $self=shift;
   my $acloc=getModuleObject($self->Config,"tsacinv::location");
   my $w5loc=getModuleObject($self->Config,"base::location");
   my @checkmap=('DE.Muenster.Wolbecker_Strasse_268' =>
                      '/DE_MÜNSTER_WOLBECKERSTR_268/*',
                 'DE.Donauwoerth.Reichsstrasse_24' =>
                      '/DE_DONAUWÖRTH_REICHSTR_24/*',
                 'DE.Bietigheim-Bissingen.Hauptstrasse_30' =>
                      '/DE_BIETIGHEIM_HAUPTSTR_30/*',
                 'DE.Frankfurt_am_Main.Hahnstrasse_43.T-Systems'=>
                      '/DE*FRANKFURT*HAHN*43*',
                 'DE.Duesseldorf.Bonner_Strasse_179'=>
                      '/DE_DÜSSELDORF_BONNERSTR_179/*');

   while(my $w5name=shift(@checkmap)){
      my $acname=shift(@checkmap);
      if ($w5name ne "" && $acname ne ""){
         $w5loc->ResetFilter();
         $w5loc->SetFilter({name=>$w5name});
         foreach my $w5rec ($w5loc->getHashList("name","id",@fieldset)){
            $acloc->ResetFilter();
            $acloc->SetFilter({fullname=>$acname});
            foreach my $acrec ($acloc->getHashList("fullname","code",@fieldset)){
               $self->ProcessLocationCompare($w5rec,$acrec);
            }
         }
      }
   }
   return({exitcode=>0,msg=>'ok'});
}

sub ProcessLocationCompare
{
   my $self=shift;
   my $w5rec=shift;
   my $acrec=shift;
   msg(INFO,"checking:");
   msg(INFO," * $w5rec->{name}");
   msg(INFO,"   -> $acrec->{fullname}");
   my @entxt;
   foreach my $f (@fieldset){
      my $accmp=$acrec->{$f};
      my $w5cmp=$w5rec->{$f};
      my $fname=$f;
      if ($f eq "zipcode"){
         $accmp=~s/D-//;
         $w5cmp=~s/D-//;
      }
      $fname=~s/address1/Address/;
      $fname=~s/zipcode/ZIP/;
      $fname=~s/location/City/;
      #msg(INFO,"cmp $accmp && $w5cmp");
      if (lc($w5cmp) ne lc($accmp) && $w5cmp ne ""){
         push(@entxt,"- Change the value of the field '$fname' from\n".
                     "  '$acrec->{$f}' to '$w5cmp'\n");
      }
   }
   if ($#entxt!=-1){
      my $itxt="The postal address information on ".
               "masterdata of location ...\n\n".
               "    Location code: $acrec->{code}\n".
               "    Location name: $acrec->{fullname}\n\n".
               " ... is incorrect.\n\n\n".
               "Please correct the following field values on data ".
               "block 'postal address':\n\n".
               join("\n",@entxt)."\n".
               "If you have any questions in relation to this correction, ".
               "feel free to contact me by phone!\n";
      my $isub='AssetManager CSS: '.
               'correction of location informations '.
               $acrec->{fullname}.
               " - Location code:".$acrec->{code};
      msg(INFO,"open new connection for incident handling ...");
      sleep(4);
      if (1){
         print "-----------------------------------------".
               "-------------------------------\n".
               $itxt.
               "-----------------------------------------".
               "-------------------------------\n";
         my $sc;
         my $msg;
         my $IncidentNumber;
         eval('use SC::Customer::TSystems;$sc=new SC::Customer::TSystems;');
         if (!defined($sc)){
            msg(ERROR,"can't connect to SC::API");
            exit(1);
         }
         my $SCuri=$self->Config->Param("DATAOBJCONNECT");
         my $SCuser=$self->Config->Param("DATAOBJUSER");
         my $SCpass=$self->Config->Param("DATAOBJPASS");
         $SCpass=$SCpass->{tsscui} if (ref($SCpass) eq "HASH");
         $SCuser=$SCuser->{tsscui} if (ref($SCuser) eq "HASH");
         $SCuri=$SCuri->{tsscui}   if (ref($SCuri) eq "HASH");
         msg(INFO,"user: ".$SCuser);
         msg(INFO,"pass: ".$SCpass);
         msg(INFO,"uri:  ".$SCuri);
         if (!$sc->Connect($SCuri,$SCuser,$SCpass)){
            msg(ERROR,"ServiceCenter Connect failed");
            exit(1);
         }
         else{
            msg(INFO,"ServiceCenter Connect OK");
         }
         if (!$sc->Login()){
            msg(ERROR,"ServiceCenter Login failed");
            exit(1);
         }
         else{
            msg(INFO,"ServiceCenter Login OK");
         }
         my %Incident=(
            'brief.description'      =>$isub,
            'problem.shortname'      =>'TS_DE_BAMBERG_GUTENBERG_13',
            'assignment'             =>'OE.OIM.OSM.F2R.AM-CSS-SK',
            'home.assignment'        =>'CSS.AO.DTAG.W5BASE',
            'category'               =>'SERVICE REQUEST',
            'subcategory1'           =>'ACCESS',
            'subcategory2'           =>'OTHER',
            'subcategory3'           =>'OTHER',
            'category.type'          =>'I_TOOLSUITE-REQUEST',
            'cause.code'             =>'AM.LOC2',
            'urgency'                =>'Medium',
            'reported.lastname'      =>'VOGLER',
            'dsc.restriction.degree' =>'80',
            'current.priority'       =>'3',
            'dsc.service'            =>'ASSETMANAGER_CSS_PROD (APPL008612)',
            'device.name'            =>'ASSETMANAGER_CSS_PROD (APPL008612)',
            'referral.no'            =>"W5Base",
            'contact.lastname'       =>'VOGLER',
            'contact.phone'          =>'+491709215495',
            'contact.name'           =>'HVOGLER',
            'reported.by'            =>'HVOGLER',
            'action'                 =>$itxt);
         if (!defined($IncidentNumber=$sc->IncidentCreate(\%Incident))){
            $msg=$sc->LastMessage();
            printf STDERR ("ERROR: ServiceCenter CreateIncident failed\n".
                           $msg."\n");
            $sc->Logout();
            exit(1);
         }
         $msg=$sc->LastMessage();
         printf("INFO:  CreateIncident is ok\n");
         printf("INFO:  Incident Number=%s\n",$IncidentNumber);
         printf("INFO:  %s\n",$msg);
         if (!$sc->Logout()){
            msg(ERROR,"ServiceCenter Logout failed");
            exit(1);
         }
         else{
            msg(INFO,"ServiceCenter Logout OK");
         }
      }
      else{
         my $act=getModuleObject($self->Config,"base::workflowaction");
         $act->Notify('',$isub,$itxt,
                      emailfrom=>'"ConfigSync" <>',
                      emailto=>['11634953080001'], 
                      xadminbcc=>1,
                     );
      }
   }

}

1;
