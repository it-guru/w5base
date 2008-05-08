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
                label         =>'LinkID',
                dataobjattr   =>"amtsirelportfappl.lrelportfapplid"),

      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parent Application',
                uppersearch   =>1,
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['lparentid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'child',
                label         =>'Child System',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['lsystemid'=>'systemid'],
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::TextDrop(
                name          =>'systemid',
                label         =>'System ID',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['lsystemid'=>'systemid'],
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'amtsirelportfappl.description'),

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
                   return("-only a web useable link-");
                }),

      new kernel::Field::Link(
                name          =>'lsystemid',
                label         =>'lsystemid',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Link(
                name          =>'lparentid',
                label         =>'lparentid',
                dataobjattr   =>'amtsirelportfappl.lapplicationid'),

      new kernel::Field::Link(
                name          =>'lchildid',
                label         =>'lchildid',
                dataobjattr   =>'amtsirelportfappl.lportfolioid'),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amtsirelportfappl.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amtsirelportfappl.externalid'),

      new kernel::Field::Date(
                name          =>'srcload',
                timezone      =>'CET',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'amtsirelportfappl.dtimport'),

   );
   $self->setDefaultView(qw(id parent child));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsirelportfappl,amportfolio,amcomputer";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   return("amtsirelportfappl.bdelete=0 and ".
          "amtsirelportfappl.bactive=1 and amportfolio.bdelete=0 and ".
          "amtsirelportfappl.lportfolioid=amportfolio.lportfolioitemid and ".
          "amportfolio.lportfolioitemid=amcomputer.litemid and ".
          "amcomputer.status<>'out of operation'");
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
