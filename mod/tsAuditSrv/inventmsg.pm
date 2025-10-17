package tsAuditSrv::inventmsg;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
   $param{noHtmlTableSort}=1;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"DARWIN_INVENTORY_DATA.SYSTEM_ID"),

      new kernel::Field::Text(
                name          =>'nodeid',
                label         =>'NodeID',
                group         =>'default',
                dataobjattr   =>'DARWIN_INVENTORY_DATA.NODE_ID'),

      new kernel::Field::Text(
                name          =>'messagetext',
                label         =>'Message Text',
                htmlwidth     =>'220px',
                sqlorder      =>'none',
                dataobjattr   =>'DARWIN_INVENTORY_DATA.MESSAGE_TEXT_EN'),

      new kernel::Field::Text(
                name          =>'resultreturned',
                label         =>'Result Returned',
                sqlorder      =>'none',
                dataobjattr   =>'DARWIN_INVENTORY_DATA.RESULT_RETURNED'),

   );
   $self->setWorktable("DARWIN_INVENTORY_DATA");
   $self->setDefaultView(qw(systemid messagetext resultreturned ));
   return($self);
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
               push(@secsystemid,"DARWIN_INVENTORY_DATA.SYSTEM_ID in (".
                                 join(",",map({"'".$_."'"} @sid)).")");
            }
            $where="(".join(" OR ",@secsystemid).")";
         }
         else{
            $where="(1=0)";
         }
      }
   }

   return($where);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_status"))){
#     Query->Param("search_status"=>"\"!out of operation\"");
#   }
#   if (!defined(Query->Param("search_registered"))){
#     Query->Param("search_registered"=>$self->T("yes"));
#   }
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
   my $rec=shift;  # if $rec is not defined, insert is validated

   my @l=qw(default source);
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
