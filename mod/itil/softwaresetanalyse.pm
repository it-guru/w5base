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
use itil::lib::Listedit;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{ResultLineClickHandler}="NONE";

   $self->AddFields(
	  new kernel::Field::XMLInterface(
                name          =>'rawsoftwareanalysestate',
                readonly      =>1,
                searchable    =>0,
                htmlwidth     =>'400px',
                group         =>'softsetvalidation',
                htmlnowrap    =>1,
                label         =>'SoftwareSet analysed raw state',
                onRawValue    =>\&itil::lib::Listedit::calcSoftwareState),
	  new kernel::Field::Htmlarea(
                name          =>'softwareanalysestate',
                readonly      =>1,
                searchable    =>0,
                htmlwidth     =>'400px',
                group         =>'softsetvalidation',
                htmlnowrap    =>1,
                label         =>'SoftwareSet analysed state',
                onRawValue    =>\&itil::lib::Listedit::calcSoftwareState),
	  new kernel::Field::Htmlarea(
                name          =>'softwareanalysetodo',
                readonly      =>1,
                searchable    =>0,
                group         =>'softsetvalidation',
                htmlwidth     =>'500px',
                htmlnowrap    =>1,
                label         =>'SoftwareSet analysed todo',
                onRawValue    =>\&itil::lib::Listedit::calcSoftwareState),
   );
   $self->AddFields(
	  new kernel::Field::Text(
                name          =>'softwareset',
                readonly      =>1,
                group         =>'softsetvalidation',
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
                label         =>'validate against Software Set',     
                onPreProcessFilter=>sub{
                   my $self=shift;
                   my $hflt=shift;
                   if (defined($hflt->{$self->{name}})){
                      if ($hflt->{$self->{name}}=~m/^".*"$/ ||
                          ref($hflt->{$self->{name}})){
                         $self->getParent->Context->{FilterSet}=
                             {$self->{name}=>$hflt->{$self->{name}}};
                      }
                      else{
                         $self->getParent->Context->{FilterSet}=
                             {$self->{name}=>[$hflt->{$self->{name}}]};
                      }
                      delete( $hflt->{$self->{name}})
                   }
                   else{
                      delete($self->getParent->Context->{FilterSet} );
                   }
                   return(0);
                },
                onRawValue    =>sub{
                   my $self=shift;
                   my $FilterSet=$self->getParent->Context->{FilterSet};
                   return($FilterSet->{softwareset});
                }),

     insertafter=>'name'
   );

   $self->setDefaultView(qw(name softwareset 
                            softwareanalysestate softwareanalysetodo
                            tsm opm businessteam));

   return($self);
}



sub isViewValid
{
   my $self=shift;
   my @l=$self->SUPER::isViewValid(@_);
   push(@l,"softsetvalidation");
   return(@l);
}








1;
