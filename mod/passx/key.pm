package passx::key;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'passxkey.keyid'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'User',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),
                                                  
      new kernel::Field::Link(
                name          =>'userid',
                sqlorder      =>'desc',
                label         =>'UserID',
                dataobjattr   =>'passxkey.userid'),
                                                  
      new kernel::Field::Link(
                name          =>'version',
                dataobjattr   =>'passxkey.version'),

      new kernel::Field::Text(
                name        =>'keylen',
                label       =>'KeyLen (bit)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'n',
                label       =>'Modulus (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'e',
                label       =>'Public exponent (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'d',
                label       =>'Private exponent (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'p',
                label       =>'P (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'q',
                label       =>'Q (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'q',
                label       =>'Q (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'dmp1',
                label       =>'D mod (P-1) (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'dmq1',
                label       =>'D mod (Q-1) (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'coeff',
                label       =>'1/Q mod P (hex)',
                container   =>'additional'),

      new kernel::Field::Textarea(
                name        =>'verify',
                label       =>'Verify',
                container   =>'additional'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>0,
                dataobjattr   =>'passxkey.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'passxkey.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'passxkey.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'passxkey.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'passxkey.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'passxkey.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'passxkey.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'passxkey.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'passxkey.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'passxkey.realeditor'),
   

   );
   $self->setDefaultView(qw(user cdate mdate));
   return($self);
}

sub InitRequest
{
   my $self=shift;
   my $bk=$self->SUPER::InitRequest(@_);

   if ($ENV{REMOTE_USER} eq "" || $ENV{REMOTE_USER} eq "anonymous"){
      print($self->noAccess());
      return(undef);
   }
   return($bk);
}


sub Initialize
{
   my $self=shift;

   $self->setWorktable("passxkey");
   return($self->SUPER::Initialize());
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{userid}=$self->getCurrentUserId();

   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return("ALL") if ($userid==$rec->{userid});
  
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

1;
