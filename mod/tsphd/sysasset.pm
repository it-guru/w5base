package tsphd::sysasset;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
                group         =>'source',
                label         =>'PHD-AssetID',
                dataobjattr   =>'PHD_PM_JOIN_L1_L_ASSET_IAM_ASS.asset_assetid'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Asset-Name',
                dataobjattr   =>'PHD_PM_JOIN_L1_L_ASSET_IAM_ASS.asset_assetname'),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>"(to_date('19700101','YYYYMMDD')+(".
                                "PHD_PM_JOIN_L1_L_ASSET_IAM_ASS.modified_date".
                                "/86400))"),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'source',
                dataobjattr   =>"(to_date('19700101','YYYYMMDD')+(".
                                "PHD_PM_JOIN_L1_L_ASSET_IAM_ASS.create_date".
                                "/86400))"),

#
#      new kernel::Field::Creator(
#                name          =>'creator',
#                group         =>'source',
#                label         =>'Creator',
#                dataobjattr   =>'isocountry.createuser'),
#
#      new kernel::Field::Owner(
#                name          =>'owner',
#                group         =>'source',
#                label         =>'last Editor',
#                dataobjattr   =>'isocountry.modifyuser'),
#
#      new kernel::Field::Editor(
#                name          =>'editor',
#                group         =>'source',
#                label         =>'Editor Account',
#                dataobjattr   =>'isocountry.editor'),
#
#      new kernel::Field::RealEditor(
#                name          =>'realeditor',
#                group         =>'source',
#                label         =>'real Editor Account',
#                dataobjattr   =>'isocountry.realeditor'),
#
   );
   $self->setDefaultView(qw(name  id cdate));
   $self->setWorktable("PHD_PM_JOIN_L1_L_ASSET_IAM_ASS");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsphd"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}




1;
