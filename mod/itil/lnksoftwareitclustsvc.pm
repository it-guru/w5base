package itil::lnksoftwareitclustsvc;
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
use itil::lnksoftware;
use kernel;
@ISA=qw(itil::lnksoftware);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applications',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                group         =>'useableby',
                readonly      =>1,
                label         =>'useable by application',
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['itclustsvcid'=>'itclustsvcid'],
                vjoindisp     =>'appl'),

#      new kernel::Field::Text(
#                name          =>'custcontract',
#                htmlwidth     =>'100px',
#                weblinkto     =>'NONE',
#                group         =>'useableby',
#                searchable    =>0,
#                htmldetail    =>0,
#                label         =>'useable by customer contract',
#                vjointo       =>'itil::itclustsvc',
#                vjoinon       =>['itclustsvcid'=>'id'],
#                vjoindisp     =>'custcontract'),
#
#      new kernel::Field::Text(
#                name          =>'customer',
#                htmlwidth     =>'100px',
#                weblinkto     =>'NONE',
#                searchable    =>0,
#                htmldetail    =>0,
#                group         =>'useableby',
#                label         =>'useable by customer',
#                vjointo       =>'itil::itclustsvc',
#                vjoinon       =>['itclustsvcid'=>'id'],
#                vjoindisp     =>'customer'),

      new kernel::Field::Select(
                name          =>'itclustcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itclustcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'itclustid',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'ClusterID',
                dataobjattr   =>'itclust.id'),

      new kernel::Field::Text(
                name          =>'itclust',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'Cluster',
                dataobjattr   =>'itclust.name'),

      new kernel::Field::Select(
                name          =>'itclustcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itclustcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Link(
                name          =>'itclustcistatusid',
                label         =>'Cluster CI-StatusID',
                dataobjattr   =>'itclust.cistatus'),
                                                   
      new kernel::Field::Text(
                name          =>'itclustsvc',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'Cluster Service',
                dataobjattr   =>'lnkitclustsvc.name'),

      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwareitclustsvc.software')
                                                   
   );
   $self->getField("systemid")->{uivisible}=0;
   $self->getField("system")->{uivisible}=0;
   $self->getField("itclustsvc")->{searchable}=1;
   $self->getField("cicistatusid")->{dataobjattr}='itclust.cistatus';
   $self->getField("mandatorid")->{dataobjattr}='itclust.mandator';
   $self->getField("databossid")->{dataobjattr}='itclust.databoss';
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(software version quantity itclustsvc cdate));
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_itclustcistatus"))){
     Query->Param("search_itclustcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   $self->SUPER::initSearchQuery();
}





sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my $from="lnksoftwaresystem left outer join software ".
            "on lnksoftwaresystem.software=software.id ".
            "left outer join lnkitclustsvc ".
            "on lnksoftwaresystem.lnkitclustsvc=lnkitclustsvc.id ".
            "left outer join itclust ".
            "on lnkitclustsvc.itclust=itclust.id ".
            "left outer join system ".   # dummy relation, to corrct sql
            "on '-99'=system.id ".       # handling of fullname
            "left outer join liccontract ".
            "on lnksoftwaresystem.liccontract=liccontract.id ".
            "left outer join licproduct ".
            "on liccontract.licproduct=licproduct.id ";

   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $bk=$self->SUPER::Validate($oldrec,$newrec,$origrec);
   return($bk) if (!$bk);
   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default instdetail lic swinstances
             useableby misc link releaseinfos 
             upd source));
}








1;
