package itil::lnklicappl;
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
                dataobjattr   =>'lnklicappl.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'100px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                precision     =>2,
                label         =>'Quantity',
                dataobjattr   =>'lnklicappl.quantity'),
                                                   
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
                dataobjattr   =>'lnklicappl.comments'),

      new kernel::Field::Mandator(
                label         =>'Application Mandator',
                name          =>'applmandator',
                vjoinon       =>'applmandatorid',
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'applmandatorid',
                label         =>'SystemMandatorID',
                group         =>'link',
                dataobjattr   =>'appl.mandator'),


      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                group         =>'link',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'applapplid',
                label         =>'ApplicationID',
                dataobjattr   =>'appl.applid'),
                                                   
      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplicationCiStatusID',
                dataobjattr   =>'appl.cistatus'),
                                                   
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
                name          =>'liccontractid',
                label         =>'LicencenseID',
                dataobjattr   =>'lnklicappl.liccontract'),
                                                   
      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplId',
                dataobjattr   =>'lnklicappl.appl'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnklicappl.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnklicappl.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnklicappl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnklicappl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnklicappl.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnklicappl.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnklicappl.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnklicappl.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnklicappl.realeditor'),
                                                   
   );
   $self->setDefaultView(qw(liccontract liccontractcistatus 
                            quantity appl applcistatus));

   $self->setWorktable("lnklicappl");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnklicappl left outer join appl ".
            "on lnklicappl.appl=appl.id ".
            "left outer join liccontract ".
            "on lnklicappl.liccontract=liccontract.id";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $applid=effVal($oldrec,$newrec,"applid");
   if ($applid==0){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   else{
      if (!$self->isParentWriteable($applid)){
         $self->LastMsg(ERROR,"application is not writeable for you");
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
   my $sys=$self->getPersistentModuleObject("W5BaseAppl","itil::appl");
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
   return(qw(header default misc link source));
}








1;
