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
                label         =>'Disaster Recovery Class (requested)',
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
                label         =>'RTO Recovery Time Objective (current)',
                transprefix   =>'RTO.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4'],
                dataobjattr   =>'appl.rtolevel'),

      new kernel::Field::Select(
                name          =>'rpolevel',
                group         =>'monisla',
                label         =>'RPO Recovery Point Objective (current)',
                transprefix   =>'RPO.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 '5'],
                dataobjattr   =>'appl.rpolevel'),

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
                dataobjattr   =>'appl.rtolevel'),

      new kernel::Field::Text(
                name          =>'rpo',
                group         =>'monisla',
                label         =>'RPO',
                htmldetail    =>0,
                dataobjattr   =>'appl.rpolevel'),

      new kernel::Field::Boolean(
                name          =>'drcok',
                group         =>'monisla',
                label         =>'DR Class - OK',
                htmldetail    =>0,
                dataobjattr   =>
                  "if (appl.disasterrecclass=7, ".
                  "   if (appl.rpolevel<=2 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=1 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=6, ".
                  "   if (appl.rpolevel<=2 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=1 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=5, ".
                  "   if (appl.rpolevel<=2 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=1 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=4, ".
                  "   if (appl.rpolevel<=2 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=1 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=3, ".
                  "   if (appl.rpolevel<=3 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=3 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=2, ".
                  "   if (appl.rpolevel<=3 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=4 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=1, ".
                  "   if (appl.rpolevel<=3 && appl.rpolevel>0 && ".
                  "       appl.rtolevel<=4 && appl.rtolevel>0,1,0),".
                  "if (appl.disasterrecclass=0, ".
                  "   if (appl.rpolevel>=0 && ".
                  "       appl.rtolevel>=0,1,0),".
                  "NULL))))))))"),
   );
 
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applnumber',
                searchable    =>0,
                label         =>'Application number',
                container     =>'additional'),
      insertafter=>['applid'] 
   );
   $self->getField("businessservices")->{vjointo}="AL_TCom::businessservice";
   my $applmgr2=$self->getField("applmgr2");
   if (defined($applmgr2)){
      $applmgr2->{uivisible}=0;
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

   # alle beantworteten Interview-Fragen
   my $o=getModuleObject($self->Config,"itil::lnkapplinteranswer");
   $o->SetFilter({parentid=>\$current->{id}});
   my @l=$o->getHashList(qw(name answer));
   Dumper(\@l);
   $summary->{interviewansers}=\@l;
   return(0) if (!$o->Ping());


   # alle aktiven Interview-Fragen
   my $o=getModuleObject($self->Config,"itil::appl");
   $o->SetFilter({id=>\$current->{id}});
   my ($rec,$msg)=$o->getOnlyFirst(qw(interviewst));
   my @q;
   foreach my $q (@{$rec->{interviewst}->{TotalActiveQuestions}}){
     push(@q,{name=>$q->{name},prio=>$q->{prio}});
   }
   $summary->{interviewstate}={TotalActiveQuestions=>\@q};
   return(0) if (!$o->Ping());

   my $o=getModuleObject($self->Config,"itil::softwareset");
   $o->SetFilter({name=>'"AO Engineering CIT Roadmap*"',
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




   return(1);
}





1;
