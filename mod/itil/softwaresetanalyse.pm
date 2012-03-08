package itil::softwaresetanalyse;
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
   $self->{ResultLineClickHandler}="NONE";

   $self->AddFields(
	  new kernel::Field::Htmlarea(
                name          =>'softwareanalysestate',
                readonly      =>1,
                htmlwidth     =>'400px',
                htmlnowrap    =>1,
                label         =>'Software analyse state',
                onRawValue    =>\&calcSoftwareState),
	  new kernel::Field::Htmlarea(
                name          =>'softwareanalysetodo',
                readonly      =>1,
                htmlwidth     =>'500px',
                htmlnowrap    =>1,
                label         =>'Software analyse todo',
                onRawValue    =>\&calcSoftwareState),
   );
   $self->AddFields(
	  new kernel::Field::Text(
                name          =>'softwareset',
                readonly      =>1,
                selectsearch  =>sub{
                   my $self=shift;
                   my $ss=getModuleObject($self->getParent->Config,
                                          "itil::softwareset");
                   $ss->SecureSetFilter({cistatusid=>4});
                   my @l=$ss->getVal("name");
                   return(@l);
                },
                searchable    =>1,
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                label         =>'Software Set'),                
     insertafter=>'name'
   );

   $self->setDefaultView(qw(name softwareanalysestate softwareanalysetodo
                            tsm opm businessteam));

   return($self);
}


sub calcSoftwareState
{
   my $self=shift;
   my $current=shift;

   my $FilterSet=$self->getParent->Context->{FilterSet};
   if ($FilterSet->{Set}->{name} ne $FilterSet->{softwareset}){
      $FilterSet->{Set}={name=>$FilterSet->{softwareset}};
      my $ss=getModuleObject($self->getParent->Config,
                             "itil::softwareset");
      $ss->SecureSetFilter({cistatusid=>4,name=>\$FilterSet->{softwareset}});
      my ($rec)=$ss->getOnlyFirst("name","software");
      $FilterSet->{Set}->{data}=$rec;
      Dumper($FilterSet->{Set}->{data});
   }
   if ($FilterSet->{Analyse}->{id} ne $current->{id}){
      $FilterSet->{Analyse}={id=>$current->{id}};
      my %d=();
      # load interessting softwareids from softwareset
      my %swid;
      foreach my $swrec (@{$FilterSet->{Set}->{data}->{software}}){
         $swid{$swrec->{softwareid}}++;
      }
      $FilterSet->{Analyse}->{softwareid}=[keys(%swid)];
      # load systems
      my $lnk=getModuleObject($self->getParent->Config,
                             "itil::lnkapplsystem");
      $lnk->SetFilter({applid=>\$current->{id},
                       systemcistatusid=>[3,4]}); 
      $FilterSet->{Analyse}->{systems}=[$lnk->getVal("systemid")];

      # load system installed software
      my $lnk=getModuleObject($self->getParent->Config,
                             "itil::lnksoftwaresystem");
      $lnk->SetFilter({systemid=>$FilterSet->{Analyse}->{systems}});
      $lnk->SetCurrentView(qw(systemid system software 
                              releasekey version softwareid));
      $FilterSet->{Analyse}->{ssoftware}=
             $lnk->getHashIndexed(qw(id systemid softwareid));

      # load related software instances
      my $sw=getModuleObject($self->getParent->Config,
                             "itil::swinstance");
      $sw->SetFilter({cistatusid=>[3,4],
                      applid=>\$current->{id}});
      $FilterSet->{Analyse}->{swi}=[
           $sw->getHashList(qw(id lnksoftwaresystemid fullname))];

      # check softwareset against installations
      $FilterSet->{Analyse}->{relevantSoftwareInst}=0;
      $FilterSet->{Analyse}->{todo}=[];
      my $ssoftware=$FilterSet->{Analyse}->{ssoftware}->{softwareid};
      foreach my $swrec (@{$FilterSet->{Set}->{data}->{software}}){
         foreach my $swi (values(%{$FilterSet->{Analyse}->{ssoftware}->{id}})){
            if ($swrec->{softwareid} eq  $swi->{softwareid}){
               $FilterSet->{Analyse}->{relevantSoftwareInst}++;
               if ($swi->{version}=~m/^\s*$/){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- no version specified in software installaton ".
                        "of $swrec->{softwareid} on system $swi->{systemid}");
               }
               if (length($swrec->{releasekey})!=
                   length($swi->{releasekey}) ||
                   ($swi->{releasekey}=~m/^0*$/) ||
                   ($swrec->{releasekey}=~m/^0*$/)){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- releasekey missmatch in  ".
                        "$swi->{software} on $swi->{system} ");
               }
               else{
                  if ($swrec->{comparator}==0){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        push(@{$FilterSet->{Analyse}->{todo}},
                              "- update $swi->{software} on $swi->{system} ".
                              "from $swi->{version} to  $swrec->{version}");
                     }
                  }
               }
            }
           # printf STDERR ("check $swrec->{softwareid} $swrec->{releasekey} against $swi->{softwareid} $swi->{releasekey}\n");
         }
      }

 
      
   }
 #  printf STDERR ("id=$current->{id} d=%s\n",Dumper($FilterSet->{Set}->{data}));
 #  printf STDERR ("sw=%s\n",Dumper($FilterSet->{Analyse}->{ssoftware}));

   my @d;
   { # system count
      my $m=sprintf("analysed system count: %d",
                      $#{$FilterSet->{Analyse}->{systems}}+1);
      if ($#{$FilterSet->{Analyse}->{systems}}==-1){
         push(@d,"<font color=red>"."WARN: ".$m."</font>");
      }
      else{
         push(@d,"INFO: ".$m);
      }
   }
   if ($#{$FilterSet->{Analyse}->{systems}}!=-1){ # softwareinstallation count
      my $m=sprintf("analysed software installations count: %d",
                     keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})+0);
      if (keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})==0){
         push(@d,"<font color=red>"."WARN: ".$m."</font>");
      }
      else{
         push(@d,"INFO: ".$m);
      }
      { # check software instances
         my $m=sprintf("analysed software instance count: %d",
                         $#{$FilterSet->{Analyse}->{swi}}+1);
         if ($#{$FilterSet->{Analyse}->{swi}}!=-1){
            push(@d,"INFO: ".$m);
         }
         else{
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
      }
      my $m=sprintf("found <b>%d</b> relevant software installations for check",
                    $FilterSet->{Analyse}->{relevantSoftwareInst});
      push(@d,"INFO: ".$m);
   }
   if ($self->Name eq "softwareanalysestate"){
      return("<div style='width:300px'>".join("<br>",@d)."</div>");
   }
   if ($self->Name eq "softwareanalysetodo"){
      return("<div style='width:500px'>".
             join("<br>",@{$FilterSet->{Analyse}->{todo}})."</div>");
   }
      
   return(join("<br>",@d));
}

sub SetFilter
{
   my $self=shift;

   if (ref($_[0]) ne "HASH" || !exists($_[0]->{softwareset})){ 
      $self->LastMsg(ERROR,"invalid or undefined analyse softwareset in filter");
      return(0);
   }
   else{
      $self->Context->{FilterSet}={
                                     softwareset=>$_[0]->{softwareset}
                                  };
   }


   return($self->SUPER::SetFilter(@_));

}






1;
