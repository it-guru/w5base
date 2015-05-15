package AL_TCom::businessservice;
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
use kernel::Field;
use itil::businessservice;
@ISA=qw(itil::businessservice);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->getField("application")->{weblinkto}="AL_TCom::appl";
   $self->getField("srcapplication")->{vjointo}="AL_TCom::appl";
   my $naturelist=$self->getField("nature")->{value};
   @$naturelist=grep(!/^$/,@$naturelist);

   $self->AddFields(
      new kernel::Field::Contact(
                name          =>'requestor',
                group         =>'contactpersons',
                label         =>'Requestor',
                readonly      =>1,
                vjoinon       =>'requestorid'),
      new kernel::Field::Link(
                name          =>'requestorid',
                group         =>'contactpersons',
                label         =>'Requestor',
                readonly      =>1,
                dataobjattr   =>"(select targetid from lnkcontact where ".
                   " lnkcontact.refid=businessservice.id and ".
                   " lnkcontact.target='base::user' and ".
                   " lnkcontact.parentobj='itil::businessservice' and ".
                   " croles like '%roles=\\'requestor\\'=roles%'".
                   " limit 1)"),
      new kernel::Field::Contact(
                name          =>'itsowner',
                group         =>'contactpersons',
                label         =>'IT-Service Owner',
                readonly      =>1,
                vjoinon       =>'funcmgrid'),
      new kernel::Field::Contact(
                name          =>'procmgr',
                group         =>'contactpersons',
                label         =>'process designer',
                readonly      =>1,
                vjoinon       =>'procmgrid'),
      new kernel::Field::Link(
                name          =>'procmgrid',
                group         =>'contactpersons',
                label         =>'process designer id',
                readonly      =>1,
                dataobjattr   =>"(select targetid from lnkcontact where ".
                   " lnkcontact.refid=businessservice.id and ".
                   " lnkcontact.target='base::user' and ".
                   " lnkcontact.parentobj='itil::businessservice' and ".
                   " croles like '%roles=\\'procmgr\\'=roles%'".
                   " limit 1)"),
      new kernel::Field::Contact(
                name          =>'slmgr',
                group         =>'contactpersons',
                label         =>'service level manager',
                readonly      =>1,
                vjoinon       =>'slmgrid'),
      new kernel::Field::Link(
                name          =>'slmgrid',
                group         =>'contactpersons',
                label         =>'service level manager id',
                readonly      =>1,
                dataobjattr   =>"(select targetid from lnkcontact where ".
                   " lnkcontact.refid=businessservice.id and ".
                   " lnkcontact.target='base::user' and ".
                   " lnkcontact.parentobj='itil::businessservice' and ".
                   " croles like '%roles=\\'slmgr\\'=roles%'".
                   " limit 1)"),
      new kernel::Field::Contact(
                name          =>'evmgr',
                group         =>'contactpersons',
                label         =>'event manager',
                readonly      =>1,
                vjoinon       =>'evmgrid'),
      new kernel::Field::Link(
                name          =>'evmgrid',
                group         =>'contactpersons',
                label         =>'event manager id',
                readonly      =>1,
                dataobjattr   =>"(select targetid from lnkcontact where ".
                   " lnkcontact.refid=businessservice.id and ".
                   " lnkcontact.target='base::user' and ".
                   " lnkcontact.parentobj='itil::businessservice' and ".
                   " croles like '%roles=\\'evmgr\\'=roles%'".
                   " limit 1)"),

      new kernel::Field::Text(
                name          =>'vsmname',
                precision     =>2,
                readonly      =>1,
                group         =>'VSMmeasurements',
                label         =>'VSM HashTag',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'name',
                vjoinon       =>['id'=>'id']),

      new kernel::Field::Percent(
                name          =>'vsmdavail',
                precision     =>2,
                readonly      =>1,
                weblinkto     =>'NONE',
                group         =>'VSMmeasurements',
                label         =>'VSM daily availibility',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'davail',
                vjoinon       =>['id'=>'id']),

      new kernel::Field::Percent(
                name          =>'vsmdperf',
                precision     =>2,
                readonly      =>1,
                group         =>'VSMmeasurements',
                weblinkto     =>'NONE',
                label         =>'VSM daily performance',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'dperf',
                vjoinon       =>['id'=>'id']),

      new kernel::Field::Percent(
                name          =>'vsmwavail',
                precision     =>2,
                readonly      =>1,
                weblinkto     =>'NONE',
                group         =>'VSMmeasurements',
                label         =>'VSM weekly availibility',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'wavail',
                vjoinon       =>['id'=>'id']),

      new kernel::Field::Percent(
                name          =>'vsmwperf',
                precision     =>2,
                readonly      =>1,
                group         =>'VSMmeasurements',
                weblinkto     =>'NONE',
                label         =>'VSM weekly performance',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'wperf',
                vjoinon       =>['id'=>'id']),

      new kernel::Field::Percent(
                name          =>'vsmquality',
                group         =>'VSMmeasurements',
                readonly      =>1,
                weblinkto     =>'NONE',
                precision     =>2,
                label         =>'VSM quality',
                vjointo       =>'tsvsm::itsperf',
                vjoindisp     =>'quality',
                vjoinon       =>['id'=>'id']),

   );
   $self->AddGroup("contactpersons",translation=>'AL_TCom::businessservice');
   $self->AddGroup("VSMmeasurements",translation=>'AL_TCom::businessservice');

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'sdbid',
                searchable    =>0,
                group         =>'desc',
                htmleditwidth =>'150',
                label         =>'SDB-ID',
                container     =>'additional'),
      insertafter=>['description']
   );
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'contextlist',
                readonly      =>1,
                uivisible     =>0,
                label         =>'Context-List',
                vjointo       =>'AL_TCom::itscontext',
                vjoinon       =>['id'=>'id'],
             #   vjoinon       =>sub{
             #      my $self=shift;
             #      return(undef); 
             #   },
                vjoindisp     =>'scontextcode',
                weblinkto     =>'NONE',
                vjoinconcat  =>"\n"),
      insertafter=>['fullname']
   );
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'contextaliases',
                readonly      =>1,
                uivisible     =>0,
                label         =>'Context-Aliases',
                vjointo       =>'AL_TCom::itscontext',
                vjoinon       =>['id'=>'id'],
             #   vjoinon       =>sub{
             #      my $self=shift;
             #      return(undef); 
             #   },
                vjoindisp     =>'scontextcode',
                weblinkto     =>'NONE',
                vjoinconcat  =>"\n"),
      insertafter=>['fullname']
   );
   $self->setDefaultView(qw(fullname cistatus));

   $self->getField("application")->{uivisible}=0;
   $self->getField("srcapplication")->{uivisible}=0;

   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   if (exists($newrec->{sdbid})){
      if ($newrec->{sdbid} ne ""){
         $newrec->{srcsys}="SDB";
         $newrec->{srcid}=$newrec->{sdbid};
         $newrec->{srcload}=NowStamp("en");
      }
      else{
         $newrec->{srcsys}="w5base";
         $newrec->{srcid}=undef;
         $newrec->{srcload}=undef;
      }
   }
   my $nature=effVal($oldrec,$newrec,"nature");
   if (effVal($oldrec,$newrec,"shortname") ne "" &&
       ($nature eq "TR" || $nature eq "ES")){
      $self->LastMsg(ERROR,"invalid shortname on ES or TR businessservices");
      return(undef);
   }
   if ($self->isDataInputFromUserFrontend() &&
       $nature eq ""){ # in AL_TCom mode, natures mandatory
      $self->LastMsg(ERROR,"invalid nature specified");
      return(undef);
   }
   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));

}



sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "desc");
   }
   splice(@l,$inserti,$#l-$inserti,("contactpersons",@l[$inserti..($#l+-1)]));
   splice(@l,$inserti,$#l-$inserti,("VSMmeasurements",@l[$inserti..($#l+-1)]));
   return(@l);

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,["desc","ALL"])){
      push(@l,"contactpersons");
   }
   if ($rec->{sdbid} ne ""){
      if (in_array(\@l,["desc","ALL"])){
         push(@l,"VSMmeasurements");
      }
   }

   return(@l);
}










1;
