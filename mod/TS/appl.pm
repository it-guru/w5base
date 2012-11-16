package TS::appl;
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
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'acapplname',
                label         =>'official AssetManager Applicationname',
                group         =>'source',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['applid','name'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{name} ne "" &&
                       $current->{applid} ne ""){
                      return(uc($current->{name}." (".$current->{applid}.")"));
                   }
                   return(undef);
                }),

      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                group         =>'control',
                label         =>'Incient Assignmentgroup ID',
                container     =>'additional'),

      new kernel::Field::Htmlarea(
                name          =>'applicationexpertgroup',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['tsmid','opmid','applmgrid','contacts'],
                group         =>'technical',
                label         =>'Application Expert Group',
                onRawValue    =>\&calcApplicationExpertGroup),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                group         =>'inmchm',
                async         =>'1',
                searchable    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['acinmassignmentgroupid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'scapprgroupid',
                group         =>'control',
                label         =>'Change Approvergroup ID',
                container     =>'additional'),

      new kernel::Field::TextDrop(
                name          =>'scapprgroup',
                label         =>'Change Approvergroup',
                vjoineditbase =>{isapprover=>\'1'},
                group         =>'inmchm',
                async         =>'1',
                searchable    =>0,
                vjointo       =>'tssc::group',
                vjoinon       =>['scapprgroupid'=>'id'],
                vjoindisp     =>'name'),
   );
 
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applnumber',
                searchable    =>0,
                label         =>'Application number',
                container     =>'additional'),
      insertafter=>['applid'] 
   );
   $self->{workflowlink}->{workflowtyp}=[qw(AL_TCom::workflow::diary
                                            OSY::workflow::diary
                                            itil::workflow::devrequest
                                            AL_TCom::workflow::businesreq
                                            THOMEZMD::workflow::businesreq
                                            base::workflow::DataIssue
                                            base::workflow::mailsend
                                            AL_TCom::workflow::change
                                            AL_TCom::workflow::problem
                                            AL_TCom::workflow::eventnotify
                                            AL_TCom::workflow::P800
                                            AL_TCom::workflow::P800special
                                            AL_TCom::workflow::incident)];
   $self->{workflowlink}->{workflowstart}=\&calcWorkflowStart;

   return($self);
}

sub calcApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;

   my $user=getModuleObject($self->getParent->Config,"base::user");
   my @aeg=('applmgr'=>{userid=>[$rec->{applmgrid}],
                        label=>$appl->getField("applmgr")->Label(),
                        sublabel=>"(System Manager)"},
            'tsm'    =>{userid=>[$rec->{tsmid}],
                        label=>$appl->getField("tsm")->Label(),
                        sublabel=>"(technisch Verantw. Applikation)"},
            'opm'    =>{userid=>[$rec->{opmid}],
                        label=>$appl->getField("opm")->Label(),
                        sublabel=>"(Produktions Verantw. Applikation)"},
            'dba'    =>{userid=>[],
                        label=>$self->getParent->T("Database Admin"),
                        sublabel=>"(Verantwortlicher Datenbank)"},
            'developerboss' =>{userid=>[],
                               label=>$self->getParent->T("Chief Developer",
                                                      'itil::ext::lnkcontact'),
                               sublabel=>"(Verantwortlicher Entwicklung)"},
            'projectmanager'=>{userid=>[],
                               label=>$self->getParent->T("Projectmanager",
                                                     'itil::ext::lnkcontact'),
                               sublabel=>"(Verantwortlicher Projektierung)"},
           );
   my %a=@aeg;

   foreach my $crec (@{$rec->{contacts}}){
      if ($crec->{target} eq "base::user" &&
          in_array($crec->{roles},"developerboss")){
         if (!in_array($a{developerboss}->{userid},$crec->{targetid})){
            push(@{$a{developerboss}->{userid}},$crec->{targetid});
         }
      }
      if ($crec->{target} eq "base::user" &&
          in_array($crec->{roles},"projectmanager")){
         if (!in_array($a{projectmanager}->{userid},$crec->{targetid})){
            push(@{$a{projectmanager}->{userid}},$crec->{targetid});
         }
      }
   }
   my $swi=getModuleObject($self->getParent->Config,"itil::swinstance");
   $swi->SetFilter({cistatusid=>\'4',applid=>\$rec->{id},
                    swnature=>["Oracle DB Server","MySQL","MSSQL","DB2"]});
   foreach my $srec ($swi->getHashList(qw(admid))){
      if (!in_array($a{dba}->{userid},$srec->{admid})){
         push(@{$a{dba}->{userid}},$srec->{admid});
      }
   }


   my @chkuid;
   foreach my $r (values(%a)){
      push(@chkuid,@{$r->{userid}});
   }
   $user->SetFilter({userid=>\@chkuid});
   $user->SetCurrentView(qw(phonename email));
   my $u=$user->getHashIndexed("userid");

   my $d="<table>";
   while(my $aegtag=shift(@aeg)){
      my $arec=shift(@aeg);
      $d.="<tr><td valign=top><div><b>".$arec->{label}.":</b></div>\n".
          "<div>".$arec->{sublabel}."</div></td>\n";
      my $c="";
      @{$arec->{userid}}=grep(!/^\s*$/,@{$arec->{userid}});
      if ($#{$arec->{userid}}!=-1){
         foreach my $userid (@{$arec->{userid}}){
            $c.="<br>--<br>\n" if ($c ne "");
            my @phone=split(/\n/,
                      quoteHtml($u->{userid}->{$userid}->{phonename}));
            my $htmlphone;
            for(my $l=0;$l<=$#phone;$l++){
               my $f=$phone[$l];
               if ($l==0){
                  $f="<a href='mailto:".
                     "$u->{userid}->{$userid}->{email}'>$f</a>";
                  $f.="<div style='visiblity:hidden;display:none'>".
                      $u->{userid}->{$userid}->{email}."</div>\n";
               }
               $f="<div>$f</div>\n";
               $htmlphone.=$f;
             }
            $c.=$htmlphone;
         }
      }
      else{
         $c="?\n";
      }
      $d.="<td valign=top>".$c."</td></tr>\n";
   }
   $d.="</table>";
   return($d);
}

sub calcWorkflowStart
{
   my $self=shift;
   my $r={};

   my %env=('frontendnew'=>'1');
   my $wf=getModuleObject($self->Config,"base::workflow");
   my @l=$wf->getSelectableModules(%env);

   if (grep(/^AL_TCom::workflow::diary$/,@l)){
      $r->{'AL_TCom::workflow::diary'}={
                                          name=>'Formated_appl'
                                       };
   }
   if (grep(/^AL_TCom::workflow::eventnotify$/,@l)){
      $r->{'AL_TCom::workflow::eventnotify'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   return($r);
}

sub getSpecPaths
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::getSpecPaths($rec);
   push(@l,"TS/spec/TS.appl");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^(technical|ALL)$/,@l)){
      push(@l,"inmchm");
   }
   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "technical");
   }
   splice(@l,$inserti,$#l-$inserti,("inmchm",@l[$inserti..($#l+-1)]));
   return(@l);

}  







1;
