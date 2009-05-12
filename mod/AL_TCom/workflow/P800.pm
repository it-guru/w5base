package AL_TCom::workflow::P800;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

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
   $self->AddGroup("p800_app");
   $self->AddGroup("p800_sys");
   return(1);
   return($self->SUPER::Init(@_));
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   
   return($self->InitFields(
           new kernel::Field::Message(
                name          =>'p800_msg1',
                label         =>'Message',
                group         =>'p800_msg',
                onRawValue    =>sub{return(<<EOF);
Dieser P800 Report bezieht sich <u>IMMER</u> auf ganze Monate. Als 
Monatsgrenze wird dabei die Zeitzone GMT verwendet. Den genauen
Betrachtungszeitraum kann man bei Ereignisbeginn-Ereignisende einsehen.
Den "Stand" des Reportes entnehmen Sie bitte dem Feld "letzer Quellsystem load".
EOF
                }),

           new kernel::Field::Text(
                name          =>'p800_reportmonth',
                label         =>'month of report',
                group         =>'p800_msg',
                depend        =>['srcid'],
                htmldetail    =>0,
                onRawValue    =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   my $m=$current->{srcid};
                                   $m=~s/-.*$//;
                                   return($m);
                                }),

           new kernel::Field::Text(
                name          =>'p800_app_applicationcount',
                label         =>'total count of applications',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_interfacecount',
                label         =>'total count of interfaces',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_changecount',
                label         =>'total count of changes',
                group         =>'p800_app',
                container     =>'headref'),
                                             
           new kernel::Field::Text(
                name          =>'p800_app_changewt',
                label         =>'total worktime of changes',
                dlabelpref    =>'- ',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),
                                             
           new kernel::Field::Text(
                name          =>'p800_app_changecount_customer',
                label         =>'count of changes "special service"',
                dlabelpref    =>'- ',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Interface(
                name          =>'p800_app_changecount_base',
                label         =>'count of changes "base service"',
                dlabelpref    =>'- ',
                onRawValue    =>
                  sub{
                     my $self=shift;
                     my $current=shift;
                     my $d;
                     my $t=$current->{headref}->{p800_app_changecount};
                     my $s=$current->{headref}->{p800_app_changecount_customer};
                     $s=$s->[0] if (defined($s) && ref($s) eq "ARRAY");
                     $t=$t->[0] if (defined($t) && ref($t) eq "ARRAY");
                     if (defined($t) && $t>0){
                        $s=0 if (!defined($s));
                        $d=$t-$s;
                     }
                     return($d);
                  },
                group         =>'p800_app',
                depend        =>['headref']),

           new kernel::Field::Text(
                name          =>'p800_app_change_customerwt',
                label         =>'worktime of "special service" changes',
                dlabelpref    =>'- ',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),
                                             
           new kernel::Field::Text(
                name          =>'p800_app_incidentcount',
                label         =>'total count of incidents',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_incidentwt',
                label         =>'total worktime of incidents',
                dlabelpref    =>'- ',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_specialcount',
                label         =>'total count of specials',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_speicalwt',
                label        =>'total worktime of "special service" (projects)',
                dlabelpref    =>'- ',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_app_customerwt',
                label         =>'total worktime for "special service"',
                unit          =>'min',
                group         =>'p800_app',
                container     =>'headref'),

           new kernel::Field::Text(
                name          =>'p800_sys_count',
                label         =>'count of logical systems',
                group         =>'p800_sys',
                container     =>'headref'),
   ));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef);  # ALL means all groups - else return list of fieldgroups
}

sub IsModuleSelectable
{
   my $self=shift;

   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL)) if (defined($rec));
   return(undef);
}



sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return("p800_msg","p800_app","p800_sys","affected","state","source");
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l=();
   my $wfid=$WfRec->{id};

   if (defined($WfRec) &&
       ref($WfRec->{affectedcontractid}) eq "ARRAY" &&
       $#{$WfRec->{affectedcontractid}}!=-1){
      my @contracts=@{$WfRec->{affectedcontractid}};
      my $contr=$self->getPersistentModuleObject("contrchk",
                                                 "itil::custcontract");
      $contr->SetFilter({id=>\@contracts});
      my @ll=$contr->getHashList(qw(semid sem2id));
      foreach my $r (@ll){
         if ($r->{semid}==$userid || $r->{sem2id}==$userid){
            if ($WfRec->{stateid}==1){
               push(@l,"release");
            }
            if ($WfRec->{stateid}==21){
            #   push(@l,"unrelease");   # zurückziehen ist für User nix
            }
         }
      }
   }
   if ($self->getParent->IsMemberOf("admin","admin.cod")){
      if ($WfRec->{stateid}==1){
         push(@l,"release");
      }
      if ($WfRec->{stateid}==21){
         push(@l,"unrelease");
      }
   }

   return(@l);
}


#######################################################################
package AL_TCom::workflow::P800::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $msg=$self->T("P800 Report");
   if ($WfRec->{stateid}==21){
      $msg.=" - ".$self->T("the report is now visible to b:flexx");
   }
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my @b=();
   if (grep(/^release$/,@{$actions})){
      push(@b,release=>$self->T("release"));
   }
   if (grep(/^unrelease$/,@{$actions})){
      push(@b,unrelease=>$self->T("unrelease"));
   }

   return(@b);
}


sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;

   return(0) if ($#{$actions}==-1);
   return(100);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $note=Query->Param("note");
   
   if ($action eq "release"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"release"));
      my $err=0;
      my $bf=getModuleObject($self->getParent->Config,"tsbflexx::p800iface");
      my ($mon,$year)=$WfRec->{srcid}=~m/^(\d+)\/(\d+)-\d+$/;
      if (defined($bf)){
         msg(INFO,"d=%s\n",Dumper($WfRec));
         if (ref($WfRec->{headref}) eq "HASH" &&
             ref($WfRec->{headref}->{affectedcontract}) eq "ARRAY" &&
             $#{$WfRec->{headref}->{affectedcontract}}==0 &&
             defined($mon) && $mon>0 &&
             defined($year) && $year>0){

            my $contract=$WfRec->{headref}->{affectedcontract}->[0];
            my %newrec=(billno        =>sprintf("%04d%02d",$year,$mon),
                        contractnumber=>$contract);
            ################################################################
            #   
            # cleanup
            #   
            my @delrec;
            $bf->SetFilter({billno        =>\$newrec{billno},
                            contractnumber=>\$newrec{contractnumber}});
            $bf->ForeachFilteredRecord(sub{push(@delrec,$_)});
            foreach my $delrec (@delrec){
               if (!$bf->ValidatedDeleteRecord($delrec)){
                  $err=1;
               }
            }
            if ($err==1){
               $self->LastMsg(ERROR,"error while cleanup bflexx");
            }
            ################################################################
            #   
            # send interfaces
            #   
            if (defined($WfRec->{p800_app_interfacecount}) &&
                $WfRec->{p800_app_interfacecount}>0){
               $newrec{measurand}=1;
               $newrec{amount}=$WfRec->{p800_app_interfacecount};
               if (!($bf->ValidatedInsertRecord(\%newrec))){
                  $err=1;
               }
            }
            ################################################################
            #   
            # send standard changes
            #   
            my $basechanges=$WfRec->{p800_app_changecount}-
                            $WfRec->{p800_app_changecount_customer};
            if ($basechanges>0){
               $newrec{measurand}=2;
               $newrec{amount}=$basechanges;
               if (!($bf->ValidatedInsertRecord(\%newrec))){
                  $err=1;
               }
            }
            ################################################################
            #   
            # send incidetns
            #   
            if (defined($WfRec->{p800_app_incidentcount}) &&
                $WfRec->{p800_app_incidentcount}>0){
               $newrec{measurand}=3;
               $newrec{amount}=$WfRec->{p800_app_incidentcount};
               if (!($bf->ValidatedInsertRecord(\%newrec))){
                  $err=1;
               }
            }
            ################################################################
         }
         else{
            $self->LastMsg(ERROR,"invalid data structur");
         }
      }
      else{
         $self->LastMsg(ERROR,"can't create bflexx interface object");
         $err=1;
      }
      if (!$err){
         if ($self->StoreRecord($WfRec,{stateid=>21})){
            Query->Delete("WorkflowStep");
            return(1);
         }
      }
      $self->LastMsg(ERROR,"noch nicht fertig");
      return(0);
   }
   if ($action eq "unrelease"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"unrelease"));
      if ($self->StoreRecord($WfRec,{stateid=>1})){
         Query->Delete("WorkflowStep");
         return(1);
      }
      return(0);
   }
   return($self->SUPER::Process($action,$WfRec));
}


sub Validate
{
   my $self=shift;

   return(1);
}











1;
