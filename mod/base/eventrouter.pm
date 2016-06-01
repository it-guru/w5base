package base::eventrouter;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'eventrouter.id'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'event route',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>'concat(eventrouter.srcmoduleobject,'.
                                'if (eventrouter.srcsubclass<>"",'.
                                    'concat("(",eventrouter.srcsubclass,")")'.
                                ',""),".",eventrouter.srceventtype," - ",'.
                                'eventrouter.dstevent)'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'eventrouter.cistatus'),
                                                  
      new kernel::Field::Text(
                name          =>'srcmoduleobject',
                label         =>'Source Object',
                dataobjattr   =>'eventrouter.srcmoduleobject'),

      new kernel::Field::Text(
                name          =>'srcsubclass',
                label         =>'Source Subclass',
                dataobjattr   =>'eventrouter.srcsubclass'),

      new kernel::Field::Select(
                name          =>'srceventtype',
                label         =>'Source Operation',
                value         =>['ins',  # insert record
                                 'upd',  # update record
                                 'del',  # delete record
                                 'sch',  # state change
                                 'Any'],
                htmleditwidth =>'140px',
                dataobjattr   =>'eventrouter.srceventtype'),

      new kernel::Field::Text(
                name          =>'dstevent',
                label         =>'Destination Event',
                dataobjattr   =>'eventrouter.dstevent'),

      new kernel::Field::Number(
                name          =>'controldelay',
                precision     =>0,
                unit          =>'sec',
                label         =>'Initial Delay',
                dataobjattr   =>'eventrouter.controldelay'),

      new kernel::Field::Number(
                name          =>'controlretryinterval',
                precision     =>0,
                unit          =>'sec',
                label         =>'Retry interval',
                dataobjattr   =>'eventrouter.controlretryinterval'),

      new kernel::Field::Number(
                name          =>'controlmaxretry',
                precision     =>0,
                unit          =>'n',
                label         =>'Retry count',
                dataobjattr   =>'eventrouter.controlmaxretry'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'eventrouter.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'eventrouter.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'eventrouter.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'eventrouter.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'eventrouter.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'eventrouter.realeditor'),

   );
   $self->setDefaultView(qw(linenumber fullname cistatus cdate mdate));
   $self->setWorktable("eventrouter");
   return($self);
}

sub isCopyValid
{
   my $self=shift;

   return(1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=effVal($oldrec,$newrec,"srcmoduleobject");
   if ($name=~m/\s/i || $name =~m/^\s*$/ || !($name=~m/^\S+::\S+$/)){
      $self->LastMsg(ERROR,"invalid srcmoduleobject"); 
      return(undef);
   }

   my $name=effVal($oldrec,$newrec,"srceventtype");
   if ($name=~m/\s/i || $name =~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid srceventtype"); 
      return(undef);
   }

   my $name=effVal($oldrec,$newrec,"dstevent");
   if ($name=~m/\s/i || $name =~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid dstevent"); 
      return(undef);
   }
   my $controldelay=effVal($oldrec,$newrec,"controldelay");
   if ($controldelay<2){
      $newrec->{controldelay}=2;
   }
   my $controlretryinterval=effVal($oldrec,$newrec,"controlretryinterval");
   if ($controlretryinterval<10){
      $newrec->{controlretryinterval}=10;
   }
   my $controlmaxretry=effVal($oldrec,$newrec,"controlmaxretry");
   if ($controlmaxretry eq ""){
      $newrec->{controlmaxretry}=0;
   }


   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
