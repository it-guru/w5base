package itil::complexinfoabo;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use itil::workflow::eventnotify;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
#                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'itil_infoabo.id'),
                                                  
      new kernel::Field::Text(
                readonly      =>1,
                htmldetail    =>0,
                name          =>'name',
                label         =>'InfoAbo Name',
                dataobjattr   =>'concat(contact.fullname," - ",'.
                                'itil_infoabo.infoabomode)'),

      new kernel::Field::Text(
                readonly      =>1,
                htmldetail    =>0,
                name          =>'email',
                label         =>'Contact Email',
                dataobjattr   =>'contact.email'),

      new kernel::Field::Contact(
                name          =>'contact',
                label         =>'Contact',
                vjoinon       =>'contactid'),

      new kernel::Field::Link(
                name          =>'contactid',
                label         =>'Contact ID',
                dataobjattr   =>'itil_infoabo.contact'),

      new kernel::Field::Select(
                name          =>'cistatus',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Contact CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'name',
                label         =>'Contact CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Boolean(
                name          =>'active',
                label         =>'Active',
                htmleditwidth =>'30%',
                default       =>1,
                dataobjattr   =>'itil_infoabo.active'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'itil_infoabo.expiration'),

      new kernel::Field::Select(
                name          =>'mode',
                label         =>'Mode',
                value         =>['eventinfo'],
                dataobjattr   =>'itil_infoabo.infoabomode'),

      new kernel::Field::Select(
                name          =>'eventmode',
                translation   =>'itil::workflow::eventnotify',
                allowempty    =>1,
                useNullEmpty  =>1,
                label         =>'Eventnotification Mode',
                getPostibleValues=>sub{
                   my $self=shift;
                   my @d=("","");
                   foreach my $k (
                          itil::workflow::eventnotify::getAllowedEventModes()){
                      push(@d,$k,$self->getParent->T($k,$self->{translation}));
                   }
                   return(@d);
                },
                dataobjattr   =>'itil_infoabo.eventmode'),

      new kernel::Field::Select(
                name          =>'eventstatclass',
                allowempty    =>1,
                useNullEmpty  =>1,
                label         =>'Prio of eventinfo',
                value         =>['1','2','3','4','5'],
                dataobjattr   =>'itil_infoabo.eventstatclass'),

      new kernel::Field::Link(
                name          =>'nativeventstatclass',
                label         =>'nativ prio of event',
                dataobjattr   =>'itil_infoabo.eventstatclass'),

      new kernel::Field::Select(
                name          =>'affecteditemprio',
                label         =>'Prio of affected config item',
                allowempty    =>1,
                useNullEmpty  =>1,
                value         =>['1','2','3'],
                dataobjattr   =>'itil_infoabo.affecteditemprio'),

      new kernel::Field::Link(
                name          =>'nativaffecteditemprio',
                label         =>'nativ prio of event',
                dataobjattr   =>'itil_infoabo.affecteditemprio'),

      new kernel::Field::Group(
                name          =>'affectedorgarea',
                AllowEmpty    =>1,
                label         =>'affected orgarea',
                vjoinon       =>'affectedorgareaid'),

      new kernel::Field::Link(
                name          =>'affectedorgareaid',
                label         =>'Orgarea ID',
                dataobjattr   =>'itil_infoabo.affectedorgarea'),

      new kernel::Field::Group(
                name          =>'affectedcustomer',
                AllowEmpty    =>1,
                label         =>'affected customer',
                vjoinon       =>'affectedcustomerid'),

      new kernel::Field::Link(
                name          =>'affectedcustomerid',
                label         =>'Orgarea ID',
                dataobjattr   =>'itil_infoabo.affectedcustomer'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'itil_infoabo.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'itil_infoabo.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'itil_infoabo.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'itil_infoabo.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'itil_infoabo.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'itil_infoabo.realeditor'),

   );
   $self->setDefaultView(qw(name cistatus eventstatclass 
                            affectedcustomer affectedorgarea ));
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setWorktable("itil_infoabo");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join contact ".
          "on $worktable.contact=contact.userid ");
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

#   my $name=trim(effVal($oldrec,$newrec,"name"));
#   if ($name=~m/\s/i){
#      $self->LastMsg(ERROR,"invalid sitename '%s' specified",$name); 
#      return(undef);
#   }
#   $newrec->{'name'}=$name;
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   my $o=getModuleObject($self->Config,"base::infoabo");
   return("ALL") if ($o->isInfoAboAdmin("read"));
   return();
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $o=getModuleObject($self->Config,"base::infoabo");
   return("default") if ($o->isInfoAboAdmin());
   return(undef);
}





1;
