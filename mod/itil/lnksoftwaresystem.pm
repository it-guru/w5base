package itil::lnksoftwaresystem;
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
                htmldetail    =>0,
                label         =>'useable by application',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'applicationnames'),

      new kernel::Field::Text(
                name          =>'custcontract',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                group         =>'useableby',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'useable by customer contract',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'custcontract'),

      new kernel::Field::Text(
                name          =>'customer',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'useableby',
                label         =>'useable by customer',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'customer'),

      new kernel::Field::TextDrop(
                name          =>'liccontract',
                htmlwidth     =>'100px',
                AllowEmpty    =>1,
                label         =>'License contract',
                vjointo       =>'itil::liccontract',
                vjoinon       =>['liccontractid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Mandator(
                label         =>'System Mandator',
                name          =>'systemmandator',
                htmldetail    =>0,
                vjoinon       =>'systemmandatorid',
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'systemmandatorid',
                label         =>'SystemMandatorID',
                group         =>'link',
                dataobjattr   =>'system.mandator'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                group         =>'link',
                readonly      =>'1',
                htmldetail    =>0,
                label         =>'System SystemID',
                dataobjattr   =>'system.systemid'),
                                                   
      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Text(
                name          =>'osrelease',
                group         =>'link',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'OS-Release of logical system',
                weblinkto     =>'NONE',
                vjointo       =>'itil::osrelease',
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'osclass',
                group         =>'link',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'OS-Class of logical system',
                vjointo       =>'itil::osrelease',
                weblinkto     =>'NONE',
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'osclass'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Number(
                name          =>'syscpucount',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                group         =>'link',
                label         =>'CPU-Count of logical system',
                dataobjattr   =>'system.cpucount'),
                                                   
      new kernel::Field::Number(
                name          =>'asscpucount',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                group         =>'link',
                label         =>'CPU-Count of asset',
                dataobjattr   =>'asset.cpucount'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>'system.asset'),
                                                   
      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwaresystem.software')
                                                   
   );
   $self->getField("itclustsvc")->{uivisible}=0;
   $self->getField("itclustsvcid")->{uivisible}=0;
   $self->getField("system")->{searchable}=1;
   $self->getField("cicistatusid")->{dataobjattr}='system.cistatus';
   $self->getField("mandatorid")->{dataobjattr}='system.mandator';
   $self->getField("databossid")->{dataobjattr}='system.databoss';
   $self->{history}={
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>'itil::system', id=>'systemid',
          field=>'fullname',as=>'software'}
      ]
   };
   $self->setDefaultView(qw(software version quantity system cdate));
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
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
            "left outer join system ".
            "on lnksoftwaresystem.system=system.id ".
            "left outer join liccontract ".
            "on lnksoftwaresystem.liccontract=liccontract.id ".
            "left outer join asset ".
            "on system.asset=asset.id ".
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
   return(qw(header 
             default instdetail lic useableby options 
             swinstances misc link releaseinfos 
             upd source));
}








1;
