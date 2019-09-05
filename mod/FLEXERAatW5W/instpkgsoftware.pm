package FLEXERAatW5W::instpkgsoftware;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->{use_dirtyread}=1;


   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'Installation ID',
                dataobjattr   =>'id'),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Link(
                name          =>'flexerasystemid',
                label         =>'flexerasystemid',
                dataobjattr   =>'FLEXERA_instsoftware.FLEXERASYSTEMID'),

      new kernel::Field::Text(
                name          =>'software',
                label         =>'Product Title',
                ignorecase    =>1,
                dataobjattr   =>'PRODUCTNAME'),

      new kernel::Field::Text(
                name          =>'publisher',
                label         =>'Publisher',
                ignorecase    =>1,
                dataobjattr   =>'PUBLISHERNAME'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'SoftwareTitleVersion',
                ignorecase    =>1,
                dataobjattr   =>'VERSION'),

      new kernel::Field::Text(
                name          =>'classification',
                label         =>'Classification',
                ignorecase    =>1,
                dataobjattr   =>'CLASSIFICATION'),

      new kernel::Field::Text(
                name          =>'edition',
                label         =>'Edition',
                ignorecase    =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'EDITION'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                vjointo       =>'FLEXERAatW5W::system',
                vjoinon       =>['flexerasystemid'=>'id'],
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemdevicestatus',
                label         =>'System Device Status',
                uppersearch   =>1,
                htmldetail    =>0,
                dataobjattr   =>'devicestatus'),

      new kernel::Field::Text(
                name          =>'beaconid',
                group         =>'source',
                label         =>'BeaconID',
                dataobjattr   =>'FLEXERA_system.BEACONID'),

      new kernel::Field::Date(
                name          =>'swinstdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Inst-Date',
                dataobjattr   =>'INSTDATE'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'First-Scan-Date',
                dataobjattr   =>'DISCDATE'),

      new kernel::Field::Date(
                name          =>'lastscandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Last-Scan-Date',
                dataobjattr   =>'FLEXERA_instsoftware.INVENTORYDATE')

   );
   $self->setWorktable("FLEXERA_instsoftware");
   $self->setDefaultView(qw(systemname publisher software version 
                            edition classification));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="$worktable  ".
          "join FLEXERA_system ".
          "on $worktable.FLEXERASYSTEMID=FLEXERA_system.FLEXERASYSTEMID ";

   return($from);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemdevicestatus"))){
     Query->Param("search_systemdevicestatus"=>"!IGNORED");
   }
}







#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}
         



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software 
             source));
}  

1;
