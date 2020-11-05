package tsAuditSrv::auditfile;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::Field::DataMaintContacts;
use itil::lib::Listedit;
use itil::lib::SecurityRestrictor;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB
        itil::lib::SecurityRestrictor);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                uivisible     =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"(DARWIN_TBL_ASSET_DATA.SYSTEM_NAME||".
                                "' ('||DARWIN_FILES.FILE_NAME||')')"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                weblinkto     =>\'tsAuditSrv::system',
                weblinkon     =>['systemid'=>'systemid'],
                dataobjattr   =>'DARWIN_TBL_ASSET_DATA.SYSTEM_NAME'),

      new kernel::Field::Text(
                name          =>'filename',
                label         =>'Filename',
                ignorecase    =>1,
                dataobjattr   =>'DARWIN_FILES.FILE_NAME'),

     new kernel::Field::File(
                name          =>'filecontent',
                label         =>'File Content',
                types         =>['txt'],
                filename      =>'filename',
                searchable    =>0,
                sqlorder      =>'none',
                uploadable    =>0,
                allowempty    =>0,
                allowdirect   =>1,
                dataobjattr   =>'DARWIN_FILES.FILE_DATA'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"DARWIN_TBL_ASSET_DATA.SYSTEM_ID"),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"DARWIN_TBL_ASSET_DATA.SYSTEM_ID"),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'mod_date'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'FileID',
                group         =>'source',
                dataobjattr   =>"DARWIN_FILES.FILE_ID"),

      new kernel::Field::RecordUrl(),
   );
   $self->{use_distinct}=0;
   $self->BackendSessionName("tsAuditServer_LongRead"); 

   $self->setWorktable("DARWIN_FILES");
   $self->setDefaultView(qw(systemid systemname fullname mdate));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from=
         # "(select ".
         # "FILE_ID,".
         # "decode(rank() over (partition by system_id||'-'||file_name ".
         # "order by mod_date desc),1,1,0) latest ".
         # "from DARWIN_FILES ".
         # ") DF join ".
         # "DARWIN_FILES on DF.FILE_ID=DARWIN_FILES.FILE_ID and DF.latest='1' ".
          "DARWIN_FILES ".
          "JOIN DARWIN_TBL_ASSET_DATA on ".
          "DARWIN_FILES.SYSTEM_ID=DARWIN_TBL_ASSET_DATA.SYSTEM_ID ";
#          "LEFT OUTER JOIN DARWIN_SYSTEM_STATUS on ".
#          "DARWIN_TBL_ASSET_DATA.SYSTEM_ID=DARWIN_SYSTEM_STATUS.SYSTEM_ID";

   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="";

   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin 
                                 w5base.tsAuditSrv.read
                              )],
          "RMember")){
         my @systemid=$self->getSecurityRestrictedAllowedSystemIDs(20);
         if ($#systemid>-1){
            my @secsystemid;
            #needed to fix ora "in" limits
            while (my @sid=splice(@systemid,0,500)){
               push(@secsystemid,"DARWIN_TBL_ASSET_DATA.SYSTEM_ID in (".
                                 join(",",map({"'".$_."'"} @sid)).")");
            }
            $where="(".join(" OR ",@secsystemid).")";
         }
         else{
            $where="(1=0)";
         }
      }
      if ($self->IsMemberOf([qw(w5base.tsAuditSrv.read)])){
         $where.=" AND " if ($where ne "");
         $where.=" (CUSTOMER like 'DTAG.%' ".
                 "or CUSTOMER like 'Deutsche Telekom%')";
      }
   }

   return($where);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   my @l=qw(ALL);

   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   return(undef);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsAuditSrv"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

  if (defined($self->{DB})){
      $self->{DB}->do("alter session set cursor_sharing=force");
   }
   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=1024*1024*15;    #15MB
   }

   return(1) if (defined($self->{DB}));
   return(0);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}




1;
