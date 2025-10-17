package tbonedb::bupstat;
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
use kernel::Field;
use tbonedb::lib::Listedit;
@ISA=qw(tbonedb::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'CheckID',
                searchable    =>0,
                dataobjattr   =>"POSCHECK_RESDETAILID"),

      new kernel::Field::Text(
                name          =>'bupid',
                label         =>'BUP',
                weblinkto     =>\'tbonedb::bupjob',
                weblinkon     =>['bupid'=>'bupid'],
                uppersearch   =>1,
                dataobjattr   =>'POSCHECK_BUPID'),

      new kernel::Field::Text(
                name          =>'systemid',
                uppersearch   =>1,
                label         =>'SystemID',
                dataobjattr   =>'SYSTEMID'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                dataobjattr   =>'HOSTNAME'),

      new kernel::Field::Boolean(
                name          =>'latestbackup',
                label         =>'is latest',
                sqlorder      =>'none',
                htmldetail    =>0,
                dataobjattr   =>'decode(O,1,1,0)'),

      new kernel::Field::Date(
                name          =>'checkdate',
                label         =>'Check Date',
                sqlorder      =>'DESC',
                timezone      =>'CET',
                dataobjattr   =>'POSCHECK_DATE'),

      new kernel::Field::Number(
                name          =>'checkexitcode',
                label         =>'Check Exitcode',
                dataobjattr   =>'POSCHECK_RESULTID'),

      new kernel::Field::Text(
                name          =>'exitstate',
                label         =>'Exit State',
                dataobjattr   =>"decode(POSCHECK_RESULTID,0,'ok','failed')"),

      new kernel::Field::Text(
                name          =>'w5applications',
                label         =>'W5Base/Application',
                group         =>'w5basedata',
                vjointo       =>\'itil::lnkapplsystem',
                vjoinslimit   =>'1000',
                vjoinon       =>['systemid'=>'systemsystemid'],
                weblinkto     =>'none',
                vjoindisp     =>'appl'),


      new kernel::Field::Text(
                name          =>'exittext',
                label         =>'Exit Text',
                dataobjattr   =>"RESULT_DESCRIPTION"),

   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(systemname systemid bupid checkdate 
                            exitstate exittext));
   $self->setWorktable("BUPSTAT");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="";

   $from.="(select ".
          "v_bupdetails_31d.*,".
          "rank() over (partition by POSCHECK_BUPID ".
          "order by POSCHECK_DATE desc) O ".
          "from v_bupdetails_31d".
          ") BUPSTAT";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_latestbackup"))){
     Query->Param("search_latestbackup"=>$self->T("yes"));
   }
}









sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
#}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
