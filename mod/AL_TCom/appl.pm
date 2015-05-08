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

      new kernel::Field::Select(
                name          =>'drclass',
                group         =>'monisla',
                label         =>'Disaster Recovery Class',
                transprefix   =>'DR.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 '5',
                                 '6',
                                 '7',
                                ],
                htmleditwidth =>'280px',
                dataobjattr   =>'appl.disasterrecclass'),

      new kernel::Field::Select(
                name          =>'rtolevel',
                group         =>'monisla',
                label         =>'RTO Recovery Time Objective',
                readonly      =>1,
                transprefix   =>'RTO.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4'],
                dataobjattr   =>'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,4,'.
                                'if (appl.disasterrecclass=2,4,'.
                                'if (appl.disasterrecclass=3,3,'.
                                'if (appl.disasterrecclass=4,1,'.
                                'if (appl.disasterrecclass=5,1,'.
                                'if (appl.disasterrecclass=6,1,'.
                                'if (appl.disasterrecclass=7,1,'.
                                'NULL))))))))'),

      new kernel::Field::Select(
                name          =>'rpolevel',
                group         =>'monisla',
                label         =>'RPO Recovery Point Objective',
                readonly      =>1,
                transprefix   =>'RPO.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 '5'],
                dataobjattr   =>'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,3,'.
                                'if (appl.disasterrecclass=2,3,'.
                                'if (appl.disasterrecclass=3,3,'.
                                'if (appl.disasterrecclass=4,2,'.
                                'if (appl.disasterrecclass=5,2,'.
                                'if (appl.disasterrecclass=6,2,'.
                                'if (appl.disasterrecclass=7,2,'.
                                'NULL))))))))'),

      new kernel::Field::Text(
                name          =>'drc',
                group         =>'monisla',
                label         =>'DR Class',
                htmldetail    =>0,
                dataobjattr   =>'appl.disasterrecclass'),

      new kernel::Field::Text(
                name          =>'rto',
                group         =>'monisla',
                label         =>'RTO',
                htmldetail    =>0,
                dataobjattr   =>'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,4,'.
                                'if (appl.disasterrecclass=2,4,'.
                                'if (appl.disasterrecclass=3,3,'.
                                'if (appl.disasterrecclass=4,1,'.
                                'if (appl.disasterrecclass=5,1,'.
                                'if (appl.disasterrecclass=6,1,'.
                                'if (appl.disasterrecclass=7,1,'.
                                'NULL))))))))'),

      new kernel::Field::Text(
                name          =>'rpo',
                group         =>'monisla',
                label         =>'RPO',
                depend        =>['drc'],
                htmldetail    =>0,
                dataobjattr   =>'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,3,'.
                                'if (appl.disasterrecclass=2,3,'.
                                'if (appl.disasterrecclass=3,3,'.
                                'if (appl.disasterrecclass=4,2,'.
                                'if (appl.disasterrecclass=5,2,'.
                                'if (appl.disasterrecclass=6,2,'.
                                'if (appl.disasterrecclass=7,2,'.
                                'NULL))))))))'),

   );
   #  removed based on 
   #  https://darwin.telekom.de/darwin/auth/base/workflow/ById/14135335110009
   #$self->AddFields(
   #   new kernel::Field::Text(
   #             name          =>'applnumber',
   #             searchable    =>0,
   #             label         =>'Application number',
   #             container     =>'additional'),
   #   insertafter=>['applid'] 
   #);
   $self->getField("businessservices")->{vjointo}="AL_TCom::businessservice";

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
   my @roadmapname=$o->getHashList(qw(id name));

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
      $systemids{$sys->{systemsystemid}}=$sys if ($sys->{systemsystemid} ne "");
   }
   if (keys(%systemids)){
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
      my @swview=qw(fullname denyupd denyupdcomments 
                    softwareinstrelstate is_dbs is_mw
                    urlofcurrentrec);
      $l1->ResetFilter();
      $l1->SetFilter({applications    =>\$current->{name},
                      softwareset     =>$rm->{name},
                      systemcistatusid=>"!6"});
      my @l1=$l1->getHashList(@swview);
      $l2->ResetFilter();
      $l2->SetFilter({applications    =>\$current->{name},
                      softwareset     =>$rm->{name},
                      itclustcistatus =>"!6"});
      my @l2=$l2->getHashList(@swview);
      push(@softstate,{
         roadmap=>$rm->{name},
         i=>[@l1,@l2]
      });
      return(0) if (!$l1->Ping());
      return(0) if (!$l2->Ping());
      Dumper(\@softstate);
      $summary->{software}={record=>\@softstate};      # SET : software fertig
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
                                     urlofcurrentrec));
      return(0) if (!$o->Ping());
      Dumper(\@systems);
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
                                    assetrefreshstate
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
           questionstate=>'FAIL'
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
   if (keys(%systemids)){
      my $o=getModuleObject($self->Config,"tssmartcube::tcc");
      $o->SetFilter({systemid=>[keys(%systemids)]});
      my @osroadmap=$o->getHashList(qw(systemid roadmap osroadmapstate 
                                       urlofcurrentrec 
                                       denyupd denyupdcomments));
      return(0) if (!$o->Ping());
      Dumper(\@osroadmap);
      $summary->{osroadmap}={record=>\@osroadmap};
   }

   #######################################################################
   # HPSA muss unter hpsaswp rein!
   my $rm=$rm[0];
   if (defined($rm)){
      my $softwareset=0;
      my @softstate;

      my %systemids; # nachladen HPSA Scandaten bassierend of SystemIDs
      foreach my $sys (@{$summary->{systems}}){
         if ($sys->{systemsystemid} ne ""){
            $systemids{$sys->{systemsystemid}}=$sys;
         }
      }
      if (keys(%systemids)){
         my $l1=getModuleObject($self->Config,"tshpsa::lnkswp");
         my @swview=qw(fullname denyupd denyupdcomments 
                       softwarerelstate is_mw is_dbs
                       urlofcurrentrec);
         $l1->ResetFilter();
         $l1->SetFilter({systemsystemid        =>[keys(%systemids)],
                         softwareset     =>$rm->{name}});
         my @l1=$l1->getHashList(@swview);
         push(@softstate,{
            roadmap=>$rm->{name},
            i=>[@l1]
         });
         return(0) if (!$l1->Ping());
         my $dump=Dumper(\@softstate);
         $summary->{hpsaswp}={record=>\@softstate};    # SET : hpsaswp fertig
      }
   }


   return(1);
}





1;
