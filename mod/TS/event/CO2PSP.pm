package TS::event::CO2PSP;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use finance::costcenter;
@ISA=qw(kernel::Event);

our %src;
our %dst;


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub CO2PSP
{
   my $self=shift;
   my $list=shift;

   $ENV{REMOTE_USER}="service/CO2PSP_Migration";
   my $exitcode=$self->ProcessMigration($list);

   return({exitcode=>$exitcode});
}

sub ProcessLineData
{
   my $self=shift;
   my $oldcostcenter=shift;
   my $newcostcenter=shift;
   my $type=shift;
   my $data=[$oldcostcenter,$newcostcenter->{costcenter}];

   my $newrec={};
   msg(INFO,"Searching $data->[0] ...");
   my $logcol=2;

   my $o="costcenter";
   $self->{$o}->ResetFilter();
   $self->{$o}->SetFilter({name=>\$data->[0]});
   my $total=0;
   my %to=();
   my %cc=(
           12762475160001=>1, # anja
           11634953080001=>1, # hv
           11634955470001=>1, # peter
           );
   my $msg="";
   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");
   my @colist=$self->{$o}->getHashList(qw(ALL));
   if ($#colist==-1){
   }
   else{
      foreach my $rec (@colist){
         my $comments=$rec->{comments};
         $comments=~s/\s*authority at AssetManager\s*//ig;
         $comments=~s/\s*authority at AssetCenter\s*//ig;
         if ($self->{$o}->ValidatedUpdateRecord($rec,
                           {
                            name=>$data->[1],
                            comments=>$comments,
                            costcentertype=>$newcostcenter->{costcentertype},
                            srcsys=>$newcostcenter->{srcsys},
                            srcid=>$newcostcenter->{srcid},
                           },{id=>\$rec->{id}})){
            msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self);
            $total++;
            $to{$rec->{databossid}}++ if ($rec->{databossid} ne "");
            my $l=$self->{$o}->T($self->{$o}->Self,$self->{$o}->Self);
            $msg.="\n".$l." : $data->[0]\n".
                  "$EventJobBaseUrl/auth/finance/costcenter/ById/".
                  $rec->{id}."\n";
         }
      }
   }
   $data->[$logcol]="$total replaces in ".$self->{$o}->Self;

   foreach my $o (qw(system asset appl custcontract)){ 
      $self->{$o}->ResetFilter();
      $self->{$o}->SetFilter({conumber=>\$data->[0],
                              cistatusid=>"<=5"});
      my $n=0;
      foreach my $rec ($self->{$o}->getHashList(qw(ALL))){
         if ($self->{$o}->ValidatedUpdateRecord($rec,
                           {conumber=>$data->[1]},{id=>\$rec->{id}})){
            msg(INFO,"... set $data->[0] -> $data->[1] in ".$self->{$o}->Self.
                     " on id ".$rec->{id});
            $n++;
            $total++;
            $cc{$rec->{databossid}}++ if ($rec->{databossid} ne "");
            my $l=$self->{$o}->T($self->{$o}->Self,$self->{$o}->Self);
            my $t=$self->{$o}->Self;
            $t=~s/::/\//g;
            $msg.="\n".$l." : $rec->{name}\n".
                  "$EventJobBaseUrl/auth/$t/ById/".$rec->{id}."\n";
         }
      }
      $data->[$logcol++]="$n replaces in ".$self->{$o}->Self;
   }
   if ($total>0){
      #printf STDERR ("fifi to=%s\n",Dumper(\%to));
      #printf STDERR ("fifi cc=%s\n",Dumper(\%cc));
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      if (keys(%to)!=0){
         $wfa->Notify("INFO",
                      "Umstellung CO-Nummern auf PSP Elemente ".
                      " - ".$data->[0]."->".$data->[1],
                      "Sehr geehrte Damen und Herren,\n\n".
                      "auf SAP Seite wurde Mitte letzten Jahres die ".
                      "Kontierung auf CO-Nummer durch eine Kontierung ".
                      "auf PSP Elemente umgestellt. PSP Elemente stellen ".
                      "eine Erweiterung der bekannten CO-Nummern da und ".
                      "haben i.d.R. die\nNotation \"A-0000000000\" ".
                      "(PSP Top Element) .\n\n".
                      "Diese Umstellung wird nun auch in W5Base/Darwin ".
                      "(SACM - ".
                      "Service Asset and Configuration Management Prozess) ".
                      "dargestellt. ".
                      "Im konkreten Fall wurde das Kontierungsobjekt '<b>".
                      $data->[0]."</b>' auf '<b>".$data->[1].
                      "</b>' umgestellt. ".
                      "Die Korrektur hat Auswirkungen auf die folgenden ".
                      "Config-Items:\n".$msg.
                      "\n\nBitte prüfen Sie im Bedarfsfall, ob diese ".
                      "Umstellungen auch aus Ihrer Sicht korrekt sind. Bei ".
                      "Rückfragen zu dieser Migration wenden Sie sich bitte ".
                      "an den Config-Manager Hr. Merx Hans-Peter bzw. ".
                      "Fr. Gräb Anja.",
                      emailto=>[keys(%to)],
                      emailcc=>[keys(%cc)]);
      }
   }
}


##########################################################################
##########################################################################
##########################################################################
##########################################################################




sub ProcessMigration
{
   my $self=shift;
   my $list=shift;
   $self->{costcenter}=getModuleObject($self->Config,"finance::costcenter");
   $self->{custcontract}=getModuleObject($self->Config,"finance::custcontract");
   $self->{appl}=getModuleObject($self->Config,"itil::appl");
   $self->{system}=getModuleObject($self->Config,"itil::system");
   $self->{asset}=getModuleObject($self->Config,"itil::asset");
   $self->{sappsp}=getModuleObject($self->Config,"tssapp01::psp");

   my %coMig;

   my $cofilter="*";
   $cofilter=[split(/[,;]+/,$list)] if ($list ne "");

   foreach my $o ($self->{appl},$self->{system},$self->{asset},
                  $self->{custcontract}){
      $o->ResetFilter();
      $o->SetFilter({cistatusid=>"<=5",conumber=>$cofilter});
      my $n=0;
      foreach my $arec ($o->getHashList(qw(conumber))){
         if ($arec->{conumber}=~m/^\S+$/){
            if (!exists($coMig{$arec->{conumber}})){
               $coMig{$arec->{conumber}}=undef;
            }
            if (!defined($coMig{$arec->{conumber}})){
               $self->{sappsp}->ResetFilter();
               $self->{sappsp}->SetFilter({name=>"?-".$arec->{conumber}});
               my ($saprec,$msg)=$self->{sappsp}->getOnlyFirst(qw(id name));
               if (defined($saprec)){
                  $coMig{$arec->{conumber}}={costcenter=>$saprec->{name},
                                             srcsys=>$self->{sappsp}->Self(),
                                             srcid=>$saprec->{id},
                                             costcentertype=>'pspelement',
                                            };
                  $n++;
               }
               else{
                  $coMig{$arec->{conumber}}="-";
               }
            }
         }
      }
   }
   my @mis;
   foreach my $co (keys(%coMig)){
      if ($coMig{$co} eq "-"){
         delete($coMig{$co});
         push(@mis,$co);
      }
   }
   #print Dumper(\%coMig);

   foreach my $oldcostcenter (sort(keys(%coMig))){
      $self->ProcessLineData($oldcostcenter,
                             $coMig{$oldcostcenter});
   }

   printf STDERR ("Miss: %s\n",join(", ",@mis));
  
   return(0); 
}





1;
