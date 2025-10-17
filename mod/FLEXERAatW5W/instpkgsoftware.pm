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
use FLEXERAatW5W::lib::Listedit;
use kernel::Field;
@ISA=qw(FLEXERAatW5W::lib::Listedit);


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

      new kernel::Field::RecordUrl(),

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

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>"(systemname||' - '||PUBLISHERNAME||' - '||".
                                "PRODUCTNAME||' - '||VERSIONRAW)"),

      new kernel::Field::Text(
                name          =>'publisher',
                label         =>'Publisher',
                ignorecase    =>1,
                dataobjattr   =>'PUBLISHERNAME'),

      new kernel::Field::Text(
                name          =>'softwarename',
                label         =>'Software-Name',
                ignorecase    =>1,
                dataobjattr   =>'FULLNAME'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'SoftwareTitleVersion',
                ignorecase    =>1,
                dataobjattr   =>'VERSION'),

      new kernel::Field::Text(
                name          =>'fullversion',
                label         =>'full version string',
                ignorecase    =>1,
                dataobjattr   =>"REGEXP_REPLACE(".
                                "REGEXP_REPLACE(".
                                "REGEXP_REPLACE(".
                                "\"VERSIONRAW\",'\\(.*\\)\\s*\$',''),".
                                "'\\s.*\$',''),".
                                "'\\.[0]+([0-9])','.\\1')"),

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
                name          =>'dreleasedate',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'release date',
                dataobjattr   =>'RELEASEDATE'),

      new kernel::Field::Date(
                name          =>'dstartoflifedate',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'start of life date',
                dataobjattr   =>'STARTOFLIFEDATE'),

      new kernel::Field::Date(
                name          =>'dendoflifedate',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'end of life date',
                dataobjattr   =>'ENDOFLIFEDATE'),

      new kernel::Field::Date(
                name          =>'dendofsalesdate',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'end of sales date',
                dataobjattr   =>'ENDOFSALESDATE'),

      new kernel::Field::Date(
                name          =>'dsupporteduntil',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'supported until',
                dataobjattr   =>'SUPPORTEDUNTIL'),

      new kernel::Field::Date(
                name          =>'dextendedsupportuntil',
                group         =>'support',
                sqlorder      =>'desc',
                dayonly       =>1,
                label         =>'extended support until',
                dataobjattr   =>'EXTENDEDSUPPORTUNTIL'),

      new kernel::Field::SubList(
                name          =>'instpkgsoftware',
                label         =>'installed Packaged-Software',
                group         =>'evidence',
                vjointo       =>'FLEXERAatW5W::softwareevidence',
                htmldetail    =>'NotEmpty',
                vjoinon       =>['id'=>'id'],
                vjoindisp     =>['file_evidence','file_evidence_file_version',
                                 'installer_evidence'],
                vjoininhash   =>['id','file_evidence',
                                 'installer_evidence',]),

      new kernel::Field::Date(
                name          =>'swinstdate',
                group         =>'source',
                sqlorder      =>'desc',
                dayonly       =>1,
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
   $self->setDefaultView(qw(systemname publisher software fullversion 
                            edition classification));
   return($self);
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





sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/software.jpg?".$cgi->query_string());
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
   return(qw(header default software evidence support source));
}  

1;
