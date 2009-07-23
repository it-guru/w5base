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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnksoftwaresystem.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Text(
                name          =>'version',
                htmlwidth     =>'50px',
                label         =>'Version',
                dataobjattr   =>'lnksoftwaresystem.version'),
                                                   
      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                precision     =>2,
                label         =>'Quantity',
                dataobjattr   =>'lnksoftwaresystem.quantity'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'applications',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                group         =>'useableby',
                htmldetail    =>0,
                label         =>'useable by application',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'applicationnamesline'),

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

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'lnksoftwaresystem.comments'),

#     # alt bestand - muß entfernt werden
#      new kernel::Field::SubList(
#                name          =>'instances',
#                label         =>'Instances',
#                group         =>'instances',
#                subeditmsk    =>'subedit.lnksoftwaresystem',
#                allowcleanup  =>1,
#                vjointo       =>'itil::lnkinstance',
#                vjoinon       =>['id'=>'installationid'],
#                vjoindisp     =>['name','comments'],
#                vjoininhash   =>['name']),

      new kernel::Field::Select(
                name          =>'softwarecistatus',
                group         =>'link',
                searchable    =>0,
                readonly      =>1,
                label         =>'Software CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['softwarecistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Mandator(
                label         =>'System Mandator',
                name          =>'systemmandator',
                vjoinon       =>'systemmandatorid',
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'systemmandatorid',
                label         =>'SystemMandatorID',
                group         =>'link',
                dataobjattr   =>'system.mandator'),

      new kernel::Field::Link(
                name          =>'softwarecistatusid',
                label         =>'SoftwareCiStatusID',
                dataobjattr   =>'software.cistatus'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                group         =>'link',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemsystemid',
                label         =>'SystemID',
                dataobjattr   =>'system.systemid'),
                                                   
      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),
                                                   
      new kernel::Field::Mandator(
                label         =>'License Mandator',
                name          =>'liccontractmandator',
                vjoinon       =>'liccontractmandatorid',
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'liccontractmandatorid',
                label         =>'LicenseMandatorID',
                group         =>'link',
                dataobjattr   =>'liccontract.mandator'),

      new kernel::Field::Select(
                name          =>'liccontractcistatus',
                readonly      =>1,
                group         =>'link',
                label         =>'License CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['liccontractcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'liccontractcistatusid',
                label         =>'LiccontractCiStatusID',
                dataobjattr   =>'liccontract.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>'system.asset'),
                                                   
      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwaresystem.software'),
                                                   
      new kernel::Field::Link(
                name          =>'liccontractid',
                label         =>'LicencenseID',
                dataobjattr   =>'lnksoftwaresystem.liccontract'),
                                                   
      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemId',
                dataobjattr   =>'lnksoftwaresystem.system'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksoftwaresystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnksoftwaresystem.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksoftwaresystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnksoftwaresystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnksoftwaresystem.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksoftwaresystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksoftwaresystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnksoftwaresystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnksoftwaresystem.realeditor'),
                                                   
   );
   $self->setDefaultView(qw(software version quantity system cdate));
   $self->setWorktable("lnksoftwaresystem");
   return($self);
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
            "on lnksoftwaresystem.liccontract=liccontract.id";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   if ($softwareid==0){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $version=effVal($oldrec,$newrec,"version");
   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({id=>\$softwareid,cistatusid=>[3,4]});
   my ($rec,$msg)=$sw->getOnlyFirst(qw(releaseexp));
   if (!defined($rec)){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $releaseexp=$rec->{releaseexp};
   if (defined($ENV{SERVER_SOFTWARE})){
      if (!($releaseexp=~m/^\s*$/)){
         my $chk;
         eval("\$chk=\$version=~m$releaseexp;");
         if ($@ ne "" || !($chk)){
            $self->LastMsg(ERROR,"invalid software version specified");
            return(undef);
         }
      }
   }
   my $systemid=effVal($oldrec,$newrec,"systemid");
   if ($systemid==0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(undef);
   }
   else{
      if (!$self->isParentWriteable($systemid)){
         $self->LastMsg(ERROR,"system is not writeable for you");
         return(undef);
      }
   }
   if (exists($newrec->{quantity}) && ! defined($newrec->{quantity})){
      delete($newrec->{quantity});
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   $rw=1 if (!defined($rec));
   $rw=1 if (defined($rec) && $self->isParentWriteable($rec->{systemid}));
   $rw=1 if ((!$rw) && ($self->IsMemberOf("admin")));
   return("default","misc") if ($rw);
   return(undef);
}

sub isParentWriteable  # Eltern Object Schreibzugriff prüfen
{
   my $self=shift;
   my $systemid=shift;

   return(1) if (!defined($ENV{SERVER_SOFTWARE}));
   my $sys=$self->getPersistentModuleObject("W5BaseSystem","itil::system");
   $sys->ResetFilter();
   $sys->SetFilter({id=>\$systemid});
   my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
   if (defined($rec) && $sys->isWriteValid($rec)){
      return(1);
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default useableby misc link source));
}








1;
