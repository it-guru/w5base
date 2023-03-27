package AL_TCom::appl;
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
use TS::appl;
use Storable(qw(dclone));
use kernel::date;
@ISA=qw(TS::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Boolean(
                name          =>'allowoncall',
                group         =>'control',
                htmleditwidth =>'30%',
                searchable    =>0,
                label         =>'allow to send for (Herbeiruf)',
                container     =>'additional'),

      new kernel::Field::Text(
                name          =>'inmbaname',
                label         =>'Incident BusinessArea',
                group         =>'inm',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>"inmbusinessarea.baname")

   );



   $self->addDesasterRecoveryClassFields(); # from TS::appl as field template
   if (my $fobj=$self->getField("applowner")){
      $fobj->{uivisible}=0;
   }

   return($self);
}

sub ItemSummary
{
   my $self=shift;
   my $current=shift;
   my $summary=shift;

   my $bk=$self->SUPER::ItemSummary($current,$summary);

   return($bk) if (!$bk);

   my $f=$self->getField("urlofcurrentrec",$current);
   $summary->{urlofcurrentrec}=$f->RawValue($current);

   # alle beantworteten Interview-Fragen
   my $o=getModuleObject($self->Config,"itil::lnkapplinteranswer");
   $o->SetFilter({parentid=>\$current->{id}});
   my @l=$o->getHashList(qw(id name relevant interviewid answer answerlevel
                            comments));
   Dumper(\@l);
   $summary->{interviewansers}=\@l;
   return(0) if (!$o->Ping());


   # alle aktiven Interview-Fragen
   my $o=getModuleObject($self->Config,"itil::appl");
   $o->SetFilter({id=>\$current->{id}});
   my ($rec,$msg)=$o->getOnlyFirst(qw(interviewst));
   my @q;
   foreach my $q (@{$rec->{interviewst}->{TotalActiveQuestions}}){
     push(@q,{name=>$q->{name},prio=>$q->{prio},id=>$q->{id}});
   }
   $summary->{interviewstate}={TotalActiveQuestions=>\@q};
   return(0) if (!$o->Ping());

   my $o=getModuleObject($self->Config,"itil::softwareset");
   $o->SetFilter({name=>'"TEL-IT Patchmanagement*"',
                  cistatusid=>\'4'});
   my @nativeroadmapname=$o->getHashList(qw(id name));
   my @roadmapname;
   my @mroadmaps;     # Roadmaps on month base
   foreach my $r (@nativeroadmapname){
      if (my ($year,$month)=$r->{name}
          =~m/^TEL-IT Patchmanagement\s*([0-9]{4})[\/-]([0-9]{2})$/){
         push(@mroadmaps,{
            id=>$r->{id},
            name=>$r->{name},
            month=>$month,
            year=>$year,
            k=>sprintf("%04d%02d",$year,$month),
         });
      }
   }
   my ($cy,$cm)=Today_and_Now("GMT");
   my $ckey=sprintf("%04d%02d",$cy,$cm);
   if ($#mroadmaps!=-1){
      @mroadmaps=grep({$_->{k} le $ckey} sort({$a->{k}<=>$b->{k}} @mroadmaps));
      if ($#mroadmaps!=-1){
         @mroadmaps=($mroadmaps[-1]);
      }
   }
   if ($#mroadmaps==-1){
      @roadmapname=grep({$_->{name} eq "TEL-IT Patchmanagement"} 
                        @nativeroadmapname);
   }
   else{
      @roadmapname=@mroadmaps;
   }

   my @rm;
   
   foreach my $rm (@roadmapname){
      my $o=getModuleObject($self->Config,"itil::softwaresetanalyse");
      $o->SetFilter({id=>\$current->{id},
                     softwareset=>$rm->{name}});
      my ($rec,$msg)=$o->getOnlyFirst(qw(rawsoftwareanalysestate));
      push(@rm,{name=>$rm->{name},
                softwaresetid=>$rm->{id},
                result=>$rec->{rawsoftwareanalysestate}->{xmlroot}});
   }
   return(0) if (!$o->Ping());
   $summary->{roadmap}=\@rm;

   my %systemids; # nachladen der Abschreibungsdaten aus AssetManager
   my %assetids;
   foreach my $sys (@{$summary->{systems}}){
      if ($sys->{systemsystemid} ne ""){
         $systemids{$sys->{systemsystemid}}=ObjectRecordCodeResolver($sys);
      }
   }
   if (keys(%systemids) && keys(%systemids)<=250){
      my $o=getModuleObject($self->Config,"tsacinv::system");
      $o->SetFilter({systemid=>[keys(%systemids)]});
      foreach my $acrec ($o->getHashList(qw(systemid assetassetid))){
         $systemids{$acrec->{systemid}}->{assetid}=$acrec->{assetassetid};
         $assetids{$acrec->{assetassetid}}={name=>$acrec->{assetassetid}};
      }
      return(0) if (!$o->Ping());
      my $o=getModuleObject($self->Config,"tsacinv::asset");
      $o->SetFilter({assetid=>[keys(%assetids)]});
      foreach my $acrec ($o->getHashList(qw(assetid deprstart age))){
         $assetids{$acrec->{assetid}}->{amdeprstart}=$acrec->{deprstart};
         $assetids{$acrec->{assetid}}->{amage}=$acrec->{age};
      }
      return(0) if (!$o->Ping());
      $summary->{assets}->{asset}=[values(%assetids)];
   }

   #######################################################################
   # neuer Versuch für RiManOS

   my @dataissues;
   ###########################
   my $rm=$rm[0];
   if (defined($rm)){
      my $softwareset=0;
      my @softstate;
      my $l1=getModuleObject($self->Config,"itil::lnksoftwaresystem");
      my $l2=getModuleObject($self->Config,"itil::lnksoftwareitclustsvc");
      my @swview=qw(fullname denyupd denyupdcomments software version instpath
                    softwareinstrelstate is_dbs is_mw
                    urlofcurrentrec);
      $l1->ResetFilter();
      $l1->SetFilter({applications    =>\$current->{name},
                      softwareset     =>$rm->{name},
                      systemcistatusid=>"!6"});
      my @l1=$l1->getHashList(@swview,"systemsystemid");
      $l2->ResetFilter();
      $l2->SetFilter({applications    =>\$current->{name},
                      softwareset     =>$rm->{name},
                      itclustcistatus =>"!6"});
      my @l2=$l2->getHashList(@swview,"itclustsvc");
      push(@softstate,{
         roadmap=>$rm->{name},
         i=>[@l1,@l2]
      });
      return(0) if (!$l1->Ping());
      return(0) if (!$l2->Ping());
      $summary->{software}={record=>ObjectRecordCodeResolver(\@softstate)};
   }
   ###########################
   {
      my $o=getModuleObject($self->Config,"itil::system");
      $o->SetFilter({applications=>\$current->{name},
                     softwareset     =>$rm->{name},
                     cistatusid=>"!6"});
      my @systems=$o->getHashList(qw(name denyupd denyupdcomments 
                                     dataissuestate
                                     osanalysestate
                                     itfarm
                                     urlofcurrentrec
                                     servicesupport));
      return(0) if (!$o->Ping());
      @systems=@{ObjectRecordCodeResolver(\@systems)};
      for(my $c=0;$c<=$#systems;$c++){
         push(@dataissues,$systems[$c]->{dataissuestate});
         delete($systems[$c]->{dataissuestate});
      }
      $summary->{system}={record=>\@systems};         # SET : system fertig
   }
   ###########################
   {
      my $o=getModuleObject($self->Config,"itil::asset");
      $o->SetFilter({applications=>\$current->{name},
                     cistatusid=>"!6"});
      my @assets=$o->getHashList(qw(name denyupd denyupdcomments refreshpland
                                    dataissuestate age acqumode 
                                    urlofcurrentrec));
      return(0) if (!$o->Ping());
      for(my $c=0;$c<=$#assets;$c++){
         push(@dataissues,$assets[$c]->{dataissuestate});
         delete($assets[$c]->{dataissuestate});
      }
      Dumper(\@assets);
      $summary->{hardware}={record=>\@assets};   # SET : hardware fertig
   }
   ###########################
   {
      my $o=getModuleObject($self->Config,"itil::swinstance");
      $o->SetFilter({appl=>\$current->{name},
                     cistatusid=>"!6"});
      my @swinstances=$o->getHashList(qw(name dataissuestate));
      return(0) if (!$o->Ping());
      Dumper(\@swinstances);
      for(my $c=0;$c<=$#swinstances;$c++){
         push(@dataissues,$swinstances[$c]->{dataissuestate});
         delete($swinstances[$c]->{dataissuestate});
      }
     # $summary->{sinstance}={record=>\@swinstnaces};  # SET : inst fertig
   }
   ###########################
   {
      my $o=getModuleObject($self->Config,"itil::lnkapplinteranswer");
      $o->SetFilter({parentid=>\$current->{id}});
      $o->SetCurrentView(qw(id name relevant interviewid answer answerlevel
                            comments));
      my $ia=$o->getHashIndexed("interviewid");
      return(0) if (!$o->Ping());
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$current->{id}});
      my ($rec,$msg)=$o->getOnlyFirst(qw(interviewst));
      my @q;
      foreach my $q (@{$rec->{interviewst}->{TotalActiveQuestions}}){
        my $h={
           question=>$q->{name},
           questionprio=>$q->{prio},
           questionid=>$q->{id},
           questionstate=>'FAIL',
           urlofcurrentrec=>$summary->{urlofcurrentrec}."/Interview"
        };
        if (exists($ia->{interviewid}->{$q->{id}})){
           my $a=$ia->{interviewid}->{$q->{id}};
           $h->{answer}=$a->{answer};
           $h->{answerrelevant}=$a->{relevant};
           $h->{answercomments}=$a->{comments};
           $h->{answerlevel}=$a->{answerlevel};
           if ($h->{answerlevel}>99){
              $h->{questionstate}='OK';
           }
           elsif ($h->{answerlevel}>=50){
              $h->{questionstate}='WARN';
           }
        }
        if ($h->{questionstate} ne "OK" &&
            $h->{questionstate} ne ""){
           if (length($h->{answercomments})>10){
              $h->{questionstate}.=" but OK"; 
           }
        }
        push(@q,$h);
      }
      return(0) if (!$o->Ping());
      $summary->{interview}={record=>\@q};
   }
   #######################################################################
   {
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$current->{id}});
      my ($rec,$msg)=$o->getOnlyFirst(qw(dataissuestate));
      push(@dataissues,$rec->{dataissuestate});
      $summary->{dataquality}={record=>\@dataissues};
   }

   #######################################################################
   my %systemids; # nachladen TCC osroadmap Daten
   foreach my $sys (@{$summary->{systems}}){
      $systemids{$sys->{systemsystemid}}=$sys if ($sys->{systemsystemid} ne "");
   }
   if (keys(%systemids)>0){
      my $o=getModuleObject($self->Config,"tssmartcube::tcc");
      $o->SetFilter({systemid=>[keys(%systemids)]});
      my @osroadmap=$o->getHashList(qw(systemid systemname 
                                       roadmap osroadmapstate 
                                       urlofcurrentrec os_base_setup
                                       os_base_setup_color
                                       operationcategory
                                       denyupd denyupdcomments));
      return(0) if (!$o->Ping());
      $summary->{osroadmap}={record=>ObjectRecordCodeResolver(\@osroadmap)};
   }

   #######################################################################
   # Daten aus AssetManager CDS "dazuladen" 
   my %systemids; 
   foreach my $sys (@{$summary->{systems}}){
      $systemids{$sys->{systemsystemid}}=$sys if ($sys->{systemsystemid} ne "");
   }
   if (keys(%systemids)>0 && keys(%systemids)<=250){
      my $l1=getModuleObject($self->Config,"tsacinv::system");
      $l1->SetFilter({systemid=>[keys(%systemids)]});
      $l1->SetCurrentView(qw(systemid rawsystemolaclass));
      my $l=$l1->getHashIndexed("systemid");
      if (ref($l->{systemid}) eq "HASH"){
         foreach my $sid (keys(%{$l->{systemid}})){
            if (ref($l->{systemid}->{$sid}) eq "HASH"){
               my $class=$l->{systemid}->{$sid}->{rawsystemolaclass};
               foreach my $sys (@{$summary->{systems}}){
                  if ($sys->{systemsystemid} eq $sid){
                     $sys->{rawsystemolaclass}=$class;
                  }
               }
            }
         }
      }
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec,@_);

   my @remove=qw(custcontracts supcontracts accountnumbers licenses);
   my $rregex="^(".join("|",@remove).")\$";
   @l=grep(!/$rregex/,@l);
   return(@l);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from=$self->SUPER::getSqlFrom($mode,@flt);

   $from.=" left outer join inmbusinessarea ".
          "on appl.id=inmbusinessarea.id";

   return($from);
}







1;
