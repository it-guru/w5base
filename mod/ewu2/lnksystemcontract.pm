package ewu2::lnksystemcontract;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'devlabsystemid',
                label         =>"DevLabSystemID",
                dataobjattr   =>"\"CONTRACT_COMPUTER_SYSTEMS\".".
                                "\"COMPUTER_SYSTEM_ID\""),

      new kernel::Field::Text(
                name          =>'devlabcontractid',
                label         =>"DevLabContractID",
                dataobjattr   =>"\"CONTRACT_COMPUTER_SYSTEMS\".".
                                "\"CONTRACT_ID\""),
      new kernel::Field::Text(
                name          =>'devlabprojectid',
                label         =>"DevLabProjectID",
                dataobjattr   =>"\"CONTRACTS\".".
                                "\"PROJEKT_ID\""),
      new kernel::Field::TextDrop(
                name          =>'systemname',
                label         =>"Systemname",
                vjointo       =>'ewu2::system',
                vjoinon       =>['devlabsystemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".".
                                "\"UNAME\""),

      new kernel::Field::Text(
                name          =>'systemstatus',
                label         =>"System status",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".".
                                "\"STATUS\""),

      new kernel::Field::Boolean(
                name          =>'systemdeleted',
                label         =>"system marked as delete",
                htmldetail    =>0,
                dataobjattr   =>"decode(\"COMPUTER_SYSTEMS\".".
                                "\"DELETED_AT\",NULL,0,1)"),


      new kernel::Field::TextDrop(
                name          =>'contractname',
                label         =>"Contract name",
                vjointo       =>'ewu2::contract',
                vjoinon       =>['devlabcontractid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>"\"CONTRACTS\".".
                                "\"UNAME\""),
      new kernel::Field::Text(
                name          =>'projectname',
                label         =>"Project name",
                dataobjattr   =>"\"PROJECTS\".".
                                "\"UNAME\""),
   );
   $self->{use_distinct}=1;
   $self->setWorktable("\"CONTRACT_COMPUTER_SYSTEMS\"");
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ".
            "join \"COMPUTER_SYSTEMS\" ".
            "on $worktable.\"COMPUTER_SYSTEM_ID\" ".
            "=\"COMPUTER_SYSTEMS\".COMPUTER_SYSTEM_ID ".
            "join \"CONTRACTS\" ".
            "on $worktable.\"CONTRACT_ID\" ".
            "=\"CONTRACTS\".CONTRACT_ID ".
            "join \"PROJECTS\" ".
            "on \"CONTRACTS\".\"PROJEKT_ID\" ".
            "=\"PROJECTS\".PROJEKT_ID";

   return($from);
}





sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}



sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  ""!".$self->T("CI-Status(6)","base::cistatus").""");
#   }
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


1;

