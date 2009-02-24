package itil::workflow::base;
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;
   my $parent=$self->getParent();

   $parent->AddFields(
      new kernel::Field::Text( 
                name       =>'involvedresponseteam',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Response Team'),

      new kernel::Field::Text( 
                name       =>'involvedbusinessteam',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Business Team'),

      new kernel::Field::Text( 
                name       =>'involvedcustomer',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Customer'),

      new kernel::Field::Text( 
                name       =>'involvedcostcenter',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved CostCenter'),

      new kernel::Field::KeyText( 
                name       =>'affectedcontract',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                readonly   =>1,
                vjointo    =>'itil::custcontract',
                vjoinon    =>['affectedcontractid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Customer Contract'),

      new kernel::Field::KeyText( 
                name       =>'affectedcontractid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Customer Contract ID'),

      new kernel::Field::KeyText( 
                name       =>'affectedapplication',
                translation=>'itil::workflow::base',
                xlswidth   =>'30',
                keyhandler =>'kh',
                readonly   =>1,
                vjointo    =>'itil::appl',
                vjoinon    =>['affectedapplicationid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Application'),

      new kernel::Field::KeyText(
                name       =>'affectedapplicationid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                readonly   =>1,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Application ID'),

      new kernel::Field::KeyText( 
                name       =>'affectedsystem',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                readonly   =>1,
                weblinkto  =>'itil::system',
                weblinkon  =>['affectedsystemid'],
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected System'),

      new kernel::Field::KeyText( 
                name       =>'affectedsystemid',
                translation=>'itil::workflow::base',
                htmldetail =>0,
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected System ID'),

      new kernel::Field::KeyText( 
                name       =>'affectedproject',
                translation=>'itil::workflow::base',
                keyhandler =>'kh',
                getHtmlImputCode=>sub{
                   my $self=shift;
                   my $d=shift;
                   my $readonly=shift;
                   my %param=(AllowEmpty=>1,selected=>[$d]);
                   my $name=$self->{name};
                   $self->vjoinobj->ResetFilter();
                   $self->vjoinobj->SecureSetFilter({cistatusid=>[4,3],
                                                     isallowlnkact=>\'1'});
                   my ($dropbox,$keylist,$vallist)=
                                 $self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
                   return($dropbox);
                },
                vjointo    =>'base::projectroom',
                vjoinon    =>['affectedprojectid'=>'id'],
                vjoindisp  =>'name',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Project'),

      new kernel::Field::KeyText( 
                name       =>'affectedprojectid',
                htmldetail =>0,
                translation=>'itil::workflow::base',
                searchable =>0,
                keyhandler =>'kh',
                container  =>'headref',
                group      =>'affected',
                label      =>'Affected Project ID'),

   );
   $self->AddGroup("affected",translation=>'itil::workflow::base');

   return(0);
}


1;
