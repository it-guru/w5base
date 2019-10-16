package tsacinv::lnkapplsystem;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'"id"'),

      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parent Application',
                htmlwidth     =>'300px',
                uppersearch   =>1,
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['lparentid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'applid',
                readonly      =>1,
                uppersearch   =>1,
                htmlwidth     =>'100',
                label         =>'ApplicationID',
                dataobjattr   =>'"applid"'),

      new kernel::Field::TextDrop(
                name          =>'child',
                label         =>'Child System',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['lsystemid'=>'systemid'],
                dataobjattr   =>'"child"'),

      new kernel::Field::TextDrop(
                name          =>'systemid',
                label         =>'System ID',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['lsystemid'=>'systemid'],
                dataobjattr   =>'"systemid"'),

     new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                label         =>'marked as delete',
                dataobjattr   =>'"deleted"'),

      new kernel::Field::Textarea(
                name          =>'appldescription',
                group         =>'appldata',
                htmldetail    =>0,
                label         =>'Application Description',
                dataobjattr   =>'"appldescription"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                group         =>'appldata',
                htmldetail    =>0,
                translation   =>'tsacinv::appl',
                dataobjattr   =>'"usage"'),

      new kernel::Field::Text(
                name          =>'applconumber',
                label         =>'Costcenter of application',
                size          =>'15',
                group         =>'appldata',
                htmldetail    =>0,
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostid'=>'id'],
                dataobjattr   =>'"applconumber"'),

      new kernel::Field::Text(
                name          =>'applcodescription',
                group         =>'appldata',
                htmldetail    =>0,
                label         =>'Costcenter desc of application',
                dataobjattr   =>'"applcodescription"'),

      new kernel::Field::Text(
                name          =>'altbc',
                htmldetail    =>0,
                readonly      =>1,
                translation   =>'tsacinv::appl',
                label         =>'Alternate BC',
                dataobjattr   =>'"altbc"'),

      new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Customer Business Manager',
                group         =>'appldata',
                translation   =>'tsacinv::appl',
                htmldetail    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'semid',
                group         =>'appldata',
                translation   =>'tsacinv::appl',
                htmldetail    =>0,
                dataobjattr   =>'"semid"'),

      new kernel::Field::TextDrop(
                name          =>'tsm',
                label         =>'Technical Contact',
                group         =>'appldata',
                htmldetail    =>0,
                translation   =>'tsacinv::appl',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'tsmid',
                group         =>'appldata',
                htmldetail    =>0,
                translation   =>'tsacinv::appl',
                dataobjattr   =>'"tsmid"'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'INM Assignment Group',
                group         =>'appldata',
                htmldetail    =>0,
                translation   =>'tsacinv::appl',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                group         =>'appldata',
                htmldetail    =>0,
                translation   =>'tsacinv::appl',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'"lincidentagid"'),



      new kernel::Field::Text(
                name          =>'sysconumber',
                label         =>'Costcenter of system',
                size          =>'15',
                group         =>'sysdata',
                htmldetail    =>0,
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostid'=>'id'],
                dataobjattr   =>'"sysconumber"'),

      new kernel::Field::Text(
                name          =>'syscodescription',
                group         =>'sysdata',
                htmldetail    =>0,
                label         =>'Costcenter desc of system',
                dataobjattr   =>'"syscodescription"'),

      new kernel::Field::TextDrop(
                name          =>'sysiassignmentgroup',
                label         =>'Incident Assignment Group',
                group         =>'sysdata',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                dataobjattr   =>'"lassignmentid"'),

      new kernel::Field::Text(
                name          =>'sysstatus',
                group         =>'sysdata',
                label         =>'Status of system',
                dataobjattr   =>'"sysstatus"'),

      new kernel::Field::Float(
                name          =>'systemcpucount',
                label         =>'System CPU count',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                unit          =>'CPU',
                precision     =>0,
                dataobjattr   =>'"systemcpucount"'),

      new kernel::Field::Float(
                name          =>'systemcpuspeed',
                label         =>'System CPU speed',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                unit          =>'MHz',
                precision     =>0,
                dataobjattr   =>'"systemcpuspeed"'),

      new kernel::Field::Text(
                name          =>'systemcputype',
                label         =>'System CPU type',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                unit          =>'MHz',
                dataobjattr   =>'"systemcputype"'),

      new kernel::Field::Text(
                name          =>'systemtpmc',
                label         =>'System tpmC',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                unit          =>'tpmC',
                dataobjattr   =>'"systemtpmc"'),

      new kernel::Field::Float(
                name          =>'systemmemory',
                label         =>'System Memory',
                group         =>'sysdata',
                htmldetail    =>0,
                translation   =>'tsacinv::system',
                unit          =>'MB',
                precision     =>0,
                dataobjattr   =>'"systemmemory"'),


      new kernel::Field::Text(
                name          =>'systemola',
                label         =>'System OLA',
                dataobjattr   =>'"systemola"'),

      new kernel::Field::Text(
                name          =>'systemstatus',
                label         =>'System Status',
                dataobjattr   =>'"systemstatus"'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'"comments"'),

      new kernel::Field::DynWebIcon(
                name          =>'systemweblink',
                searchable    =>0,
                depend        =>['systemid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $systemido=$self->getParent->getField("systemid");
                   my $systemid=$systemido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../tsacinv/system/Detail?systemid=$systemid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-");
                }),

      new kernel::Field::Link(
                name          =>'lsystemid',
                label         =>'lsystemid',
                dataobjattr   =>'"lsystemid"'),

      new kernel::Field::Link(
                name          =>'lparentid',
                label         =>'lparentid',
                dataobjattr   =>'"lparentid"'),

      new kernel::Field::Link(
                name          =>'lchildid',
                label         =>'lchildid',
                dataobjattr   =>'"lchildid"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),

      new kernel::Field::Date(
                name          =>'srcload',
                timezone      =>'CET',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'"srcload"'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'"replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'"replkeysec"')

   );
   $self->setDefaultView(qw(id parent applid child systemid systemola));
   $self->setWorktable("lnkapplsystem");

   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
}


sub initSqlWhere
{
    my $self=shift;
    return("\"isactive\"='1'");
 }




sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sysdata w5basedata source));
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


1;
