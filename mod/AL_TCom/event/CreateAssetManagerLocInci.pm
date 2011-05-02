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
   my @checkmap=('DE.Bietigheim-Bissingen.Hauptstrasse_30' =>
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
   my @entxt="";
   foreach my $f (@fieldset){
      if ($w5rec->{$f} ne $acrec->{$f} && $w5rec->{$f} ne ""){
         push(@entxt,"- Change the value of the field '$f' from\n".
                     "  '$acrec->{$f}' to '$w5rec->{$f}'\n");
      }
   }
   if ($#entxt!=-1){
      my $itxt="The information on masterdata of location ".
               "(Code:$acrec->{code})\n".
               "$acrec->{fullname}\n".
               "is incorrect.\n".
               "Please correct the following field values on data\n".
               "block 'postal address':\n".
               join("\n",@entxt)."\n".
               "If you have any questions in relation to this correction,\n".
               "feel free to contact me by phone!\n";
      print "-----------------------------------------".
            "-------------------------------\n".
            $itxt.
            "-----------------------------------------".
            "-------------------------------\n";
      my $sc;
      my $msg;
      my $IncidentNumber;
      eval('use SC::API;$sc=new SC::API;');
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
      my %Incident=('brief.description'  =>'Correction of location '.
                                           'informations '.$acrec->{fullname},
                    'problem.shortname'  =>'TS_DE_BAMBERG_GUTENBERG_13',
                    'assignment'         =>'CSS.TCOM.ST.DB',
                    'category'           =>'SOFTWARE','subcategory1'=>'OTHER',
                    'reported.lastname'  =>'VOGLER',
                    'contact.lastname'   =>'VOGLER',
                    'contact.name'       =>'HVOGLER',
                    'reported.by'        =>'HVOGLER',
                    'action'             =>$itxt);
      if (!defined($IncidentNumber=$sc->IncidentCreate(\%Incident))){
         $msg=$sc->LastMessage();
         printf STDERR ("ERROR: ServiceCenter CreateIncident failed\n$msg\n");
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

      exit(0);

   }

}

1;
