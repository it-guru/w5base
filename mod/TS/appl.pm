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
                depend        =>['baseaeg'],
                group         =>'technical',
                label         =>'Application Expert Group',
                onRawValue    =>\&calcApplicationExpertGroup),

      new kernel::Field::Container(
                name          =>'baseaeg',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['tsmid','opmid','applmgrid','contacts'],
                group         =>'technical',
                label         =>'base Application Expert Group',
                onRawValue    =>\&calcBaseApplicationExpertGroup),

      new kernel::Field::Container(
                name          =>'technicalaeg',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                uivisible     =>1,
                depend        =>['baseaeg'],
                group         =>'technical',
                label         =>'tec Application Expert Group',
                onRawValue    =>\&calcTecApplicationExpertGroup),

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



   $self->AddFields(
      new kernel::Field::Text(
                name          =>'acapplname',
                label         =>'AM: official AssetManager Applicationname',
                group         =>'external',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['applid','name'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $applid=$self->getParent->getField("applid")
                              ->RawValue($current);
                   if ($applid ne ""){
                      my $a=getModuleObject($self->getParent->Config,
                                            "tsacinv::appl");
                      if (defined($a)){
                         $a->SetFilter({applid=>\$applid});
                         my ($arec,$msg)=$a->getOnlyFirst(qw(fullname));
                         if (defined($arec)){
                            return($arec->{fullname});
                         }
                      }
                   }

                   if ($current->{name} ne "" &&
                       $current->{applid} ne ""){
                      return(uc($current->{name}." (".$current->{applid}.")"));
                   }
                   return(undef);
                }),
      new kernel::Field::Text(
                name          =>'amossprodplan',
                label         =>'AM: Production Planning OSS',
                group         =>'external',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'tsacinv::costcenter',
                vjoinon       =>['conumber'=>'name'],
                vjoindisp     =>'productionplanningoss')
   );





   $self->{workflowlink}->{workflowtyp}=[qw(AL_TCom::workflow::diary
                                            OSY::workflow::diary
                                            itil::workflow::businesreq
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


sub calcTecApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;
   my $aeg=$self->getField("baseaeg")->RawValue($rec);

   my %aeg;
   foreach my $aegtag (sort({$aeg->{$a}->{sindex}<=>$aeg->{$b}->{sindex}}
                       keys(%$aeg))){
      foreach my $v (sort(keys(%{$aeg->{$aegtag}}))){
         my $tt=$aegtag."_".$v;
         next if ($v eq "sindex");
         next if ($v eq "phonename");
         $aeg{$tt}=[] if (!exists($aeg{$tt}));
         if (ref($aeg->{$aegtag}->{$v}) eq "ARRAY"){
            push(@{$aeg{$tt}},@{$aeg->{$aegtag}->{$v}});
         }
         else{
            push(@{$aeg{$tt}},$aeg->{$aegtag}->{$v});
         }
      }
   }



   return(\%aeg);
}

sub calcBaseApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;

   my $user=getModuleObject($self->getParent->Config,"base::user");
   my $index=0;
   my @aeg=('applmgr'=>{
                userid=>[$rec->{applmgrid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("applmgr")->Label(),
                sublabel=>"(System Manager)"
            },
            'tsm'=>{
                userid=>[$rec->{tsmid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("tsm")->Label(),
                sublabel=>"(technisch Verantw. Applikation)"
            },
            'opm'=>{
                userid=>[$rec->{opmid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("opm")->Label(),
                sublabel=>"(Produktions Verantw. Applikation)"
            },
            'dba'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Database Admin"),
                sublabel=>"(Verantwortlicher Datenbank)"
            },
            'developerboss'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Chief Developer",
                                           'itil::ext::lnkcontact'),
                sublabel=>"(Verantwortlicher Entwicklung)"
            },
            'projectmanager'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Projectmanager"),
                         sublabel=>"(Verantwortlicher Projektierung)"
            },
            'sdesign'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Solution Designer",
                                           'itil::ext::lnkcontact'),
            },
            'pmdev'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Projectmanager Development",
                                           'itil::ext::lnkcontact'),
            },
            'AEG'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                label=>"Application Expert Group",
                sublabel=>"(AEG)"
            },
           );
   my %a=@aeg;

   my $contacts=$appl->getField("contacts")->RawValue($rec);

   foreach my $crec (@{$contacts}){
      foreach my $k (qw(developerboss projectmanager sdesign pmdev)){
         if ($crec->{target} eq "base::user" &&
             in_array($crec->{roles},$k)){
            if (!in_array($a{$k}->{userid},$crec->{targetid})){
               push(@{$a{$k}->{userid}},$crec->{targetid});
            }
         }
      }
   }

   #######################################################################
   # 
   # tempoary add I-Network informations
   # 
   my $inaeg=getModuleObject($self->Config,"inetwork::aeg");
   my $tswiw=getModuleObject($self->Config,"tswiw::user");
   if (defined($inaeg)){
      $inaeg->SetFilter({w5baseid=>\$rec->{id}});
      foreach my $inrec ($inaeg->getHashList(qw(smemail pmeemail
                                                sdemail))){
          if ($inrec->{smemail} ne ""){
             my $smuserid=$tswiw->GetW5BaseUserID($inrec->{smemail});
             if ($smuserid ne ""){
                push(@{$a{applmgr}->{userid}},$smuserid);
             }
             else{
                msg(ERROR,"unable to resolv $inrec->{smemail} from I-Network");
             }
          }
          if ($inrec->{pmeemail} ne ""){
             my $pmeuserid=$tswiw->GetW5BaseUserID($inrec->{pmeemail});
             if ($pmeuserid ne ""){
                push(@{$a{pmdev}->{userid}},$pmeuserid);
             }
             else{
                msg(ERROR,"unable to resolv $inrec->{pmeemail} from I-Network");
             }
          }
          if ($inrec->{sdemail} ne ""){
             my $sduserid=$tswiw->GetW5BaseUserID($inrec->{sdemail});
             if ($sduserid ne ""){
                push(@{$a{sdesign}->{userid}},$sduserid);
             }
             else{
                msg(ERROR,"unable to resolv $inrec->{sdemail} from I-Network");
             }
          }
      }
   }
   #######################################################################

   my $swi=getModuleObject($self->getParent->Config,"itil::swinstance");
   $swi->SetFilter({cistatusid=>\'4',applid=>\$rec->{id},
                    swnature=>["Oracle DB Server","MySQL","MSSQL","DB2",
                               "Informix","PostgreSQL"]});
   foreach my $srec ($swi->getHashList(qw(admid))){
      if ($srec->{admid} ne ""){
         if (!in_array($a{dba}->{userid},$srec->{admid})){
            push(@{$a{dba}->{userid}},$srec->{admid});
         }
      }
   }
   foreach my $k (keys(%a)){  # fillup AEG
      next if ($k eq "AEG");
      foreach my $userid (@{$a{$k}->{userid}}){
         if (!in_array($a{AEG}->{userid},$userid)){
            push(@{$a{AEG}->{userid}},$userid);
         }
      }
   }


   my @chkuid;
   foreach my $r (values(%a)){
      @{$r->{userid}}=grep(!/^\s*$/,@{$r->{userid}});
      push(@chkuid,@{$r->{userid}});
   }
   $user->SetFilter({userid=>\@chkuid});
   $user->SetCurrentView(qw(phonename email));
   my $u=$user->getHashIndexed("userid");
   foreach my $k (keys(%a)){
      foreach my $userid (@{$a{$k}->{userid}}){
         push(@{$a{$k}->{email}},$u->{userid}->{$userid}->{email});
      }
      foreach my $userid (@{$a{$k}->{userid}}){
         push(@{$a{$k}->{phonename}},
              $u->{userid}->{$userid}->{phonename});
      }
   }

   return(\%a);
}

sub calcApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;
   my $aeg=$self->getField("baseaeg")->RawValue($rec);

   my $d="<table>";
   foreach my $aegtag (sort({$aeg->{$a}->{sindex}<=>$aeg->{$b}->{sindex}}
                       keys(%$aeg))){
      next if ($aegtag eq "AEG");
      my $arec=$aeg->{$aegtag};
      $d.="<tr><td valign=top><div><b>".$arec->{label}.":</b></div>\n".
          "<div>".$arec->{sublabel}."</div></td>\n";
      my $c="";
      if ($#{$arec->{userid}}!=-1){
         for(my $uno=0;$uno<=$#{$arec->{userid}};$uno++){
            $c.="<br>--<br>\n" if ($c ne "");
            my @phone=split(/\n/,
                      quoteHtml($arec->{phonename}->[$uno]));
            my $htmlphone;
            for(my $l=0;$l<=$#phone;$l++){
               my $f=$phone[$l];
               if ($l==0){
                  $f="<a href='mailto:".
                     $arec->{email}->[$uno]."'>$f</a>";
                  $f.="<div style='visiblity:hidden;display:none'>\n".
                      $arec->{email}->[$uno]."</div>\n";
               }
               $f="<div>$f</div>\n";
               $htmlphone.=$f;
            }
            $c.=$htmlphone;
         }
      }
      else{
         $c="<b><font color=red>?</font></b>\n";
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
