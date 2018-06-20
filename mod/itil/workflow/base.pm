package itil::workflow::base;
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
   my $parent=$self->getParent();

   $parent->AddFields(
      new kernel::Field::Text( 
                name       =>'involvedresponseteam',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Response Team'),

      new kernel::Field::Text( 
                name       =>'involvedbusinessteam',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Business Team'),

      new kernel::Field::Text( 
                name       =>'involvedcostcenter',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved CostCenter'),

      new kernel::Field::KeyText( 
                name       =>'affectedcontract',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                readonly   =>1,
                vjointo    =>'itil::custcontract',
                vjoinon    =>['affectedcontractid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Customer Contract'),

      new kernel::Field::KeyText( 
                name       =>'affectedcontractid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Customer Contract ID'),

      new kernel::Field::Text( 
                name       =>'customercontractmod',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'active customer contract modules'),

      new kernel::Field::KeyText( 
                name       =>'affectedapplication',
                translation=>'itil::workflow::base',
                xlswidth   =>'30',
                keyhandler =>'kh',
                readonly   =>1,
                vjointo    =>'itil::appl',
                vjoinon    =>['affectedapplicationid'=>'id'],
                vjoineditbase=>{cistatusid=>'<6'},
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Application'),

      new kernel::Field::KeyText(
                name       =>'affectedapplicationid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                readonly   =>1,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Application ID'),

      new kernel::Field::KeyText( 
                name       =>'affectedsystem',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                readonly   =>1,
                vjointo    =>'itil::system',
                vjoinon    =>['affectedsystemid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected System'),

      new kernel::Field::KeyText( 
                name       =>'affectedsystemid',
                translation=>'itil::workflow::base',
                htmldetail =>0,
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected System ID'),

      new kernel::Field::KeyText( 
                name       =>'affectedproject',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                getHtmlImputCode=>sub{
                   my $self=shift;
                   my $d=shift;
                   my $readonly=shift;
                   my %param=(AllowEmpty=>1,selected=>[$d]);
                   my $name=$self->{name};
                   $self->vjoinobj->ResetFilter();
                   $self->vjoinobj->SecureSetFilter({cistatusid=>[4,3],
                                                     isallowlnkact=>\'1'});
                   my ($dropbox,$keylist,$vallist)=
                                 $self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
                   return($dropbox);
                },
                multiple   =>0,
                AllowEmpty =>1,
                vjointo    =>'base::projectroom',
                vjoinon    =>['affectedprojectid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Project'),

      new kernel::Field::KeyText( 
                name       =>'affectedprojectid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Project ID'),

      new kernel::Field::KeyText(
                name          =>'affectedbusinessprocessid',
                htmldetail =>0,
                container     =>'headref',
                keyhandler    =>'kh',
                label         =>'BusinessprocessID'),

   );
   $self->AddGroup("affected",translation=>'itil::workflow::base');

   return(1);
}

sub IsModuleSelectable
{
   my $self=shift;
   return(0);
}


sub DataIssueCompleteWriteRequest
{
   my $self=shift;
   my $oldIssueRec=shift;
   my $newIssueRec=shift;
   my $rec=shift;
   my $applid=$rec->{affectedapplicationid};
   if (!ref($applid) eq "ARRAY"){
      $applid=[$applid];
   }
   if ($#{$applid}!=-1){
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>$applid});
      my ($arec,$msg)=$appl->getOnlyFirst(qw(name tsmid tsm2id));
      if (defined($arec)){
         $newIssueRec->{fwdtarget}="base::user";
         $newIssueRec->{fwdtargetid}=$arec->{tsmid};
         if ($rec->{tsm2id} ne ""){
            $newIssueRec->{fwddebtarget}="base::user";
            $newIssueRec->{fwddebtargetid}=$arec->{tsm2id};
         }
         $newIssueRec->{mandator}=$rec->{mandator};
         $newIssueRec->{mandatorid}=$rec->{mandatorid};
      }
   }
   else{
      return(undef);
   }
   return(1);
}


# global action handler for this workflow type
sub nativProcess    
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;


   if ($action eq "wfforcerevise"){
      my $ownerid=$WfRec->{owner};
      my @applid=@{$WfRec->{affectedapplicationid}};
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>\@applid});
      my @ccids=qw(delmgrid delmgr2id tsmid tsm2id);
      my @l=$appl->getHashList(@ccids);
      my %ccid;
      foreach my $rec (@l){
         foreach my $n (@ccids){
            if ($rec->{$n} ne "" && $rec->{$n}  ne $ownerid){
               $ccid{$rec->{$n}}++;
            }
         }
      }
      my @ccids=sort(keys(%ccid));
      if ($h->{note}=~m/^\s*$/){
         $self->LastMsg(ERROR,"invalid revise note specified for $WfRec->{id}");
         return(0);
      }
      
      my $wf=$self->getParent->Clone();
      $wf->ResetFilter();
      my $newinvoicedate=$WfRec->{invoicedate};
      for(my $c=0;1;$c++){
         my $d=CalcDateDuration($newinvoicedate,NowStamp("en"));
         if ($d->{totaldays}<0){
            last;
         }
         $newinvoicedate=$wf->ExpandTimeExpression("$newinvoicedate+1M");
         if ($c>3){
            $self->LastMsg(ERROR,
                  "alte camellen werden nicht aufgewärmt $WfRec->{id}");
            return(1);
         }
      }
      if ($wf->Action->StoreRecord($WfRec->{id},'ccomplaint',{},$h->{note})){
         my %wfch=(
                   fwdtargetid=>$ownerid,
                   fwdtarget=>'base::user',
                   invoicedate=>$newinvoicedate,
                   stateid=>18,
                  );
            if ($WfRec->{class}=~m/::workflow::diary$/){
               $wfch{step}="base::workflow::diary::main";
            }
            if ($wf->ValidatedUpdateRecord($WfRec,\%wfch,
                                           {id=>\$WfRec->{id}})){
               foreach my $uid (@ccids){
                  $wf->AddToWorkspace($WfRec->{id},"base::user",$uid);
               }
               push(@ccids,11634953080001);
               my %mailopt=(addcctarget=>\@ccids);
               if ($h->{emailfrom} ne ""){
                  $mailopt{emailfrom}=$h->{emailfrom};
               }
               $wf->Action->NotifyForward($WfRec->{id},
                                          'base::user',
                                          $ownerid,
                                          "Reviewer",
                "Es wurde eine kaufmännische Reklamation an diesem ".
                "Workflow durchgeführt. Bitte prüfen Sie im speziellen ".
                "den Block Fakturadaten und führen Sie eine ".
                "entsprechende Nachbearbeitung durch. Gründe für die ".
                "Reklamation finden Sie im Verlauf-Protokoll des ".
                "Workflows.",
                                          %mailopt);
               return(1);
           }
      }
      #printf STDERR ("fifi l=%s\n",Dumper(\@l));
      #printf STDERR ("fifi general action wfforcerevise\n");
      #printf STDERR ("fifi owner=$ownerid\n");
      #printf STDERR ("fifi applid=%s\n",Dumper(\@applid));
      return(1);
   }
   return(0);
}



1;
