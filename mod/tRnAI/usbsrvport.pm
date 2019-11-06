package tRnAI::usbsrvport;
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
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                readonly      =>1,
                wrdataobjattr =>"tRnAI_usbsrvport.id",
                dataobjattr   =>"concat(tRnAI_usbsrv.id,':',portlist.port)"),

      new kernel::Field::TextDrop(
                name          =>'usbsrv',
                label         =>'USB-Server',
                readonly      =>1,
                vjointo       =>\'tRnAI::usbsrv',
                vjoinon       =>['usbsrvid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                dataobjattr   =>"concat(tRnAI_usbsrv.name,':',portlist.port)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Port',
                readonly      =>1,
                dataobjattr   =>'portlist.port'),

      new kernel::Field::Text(
                name          =>'usbsrvid',
                label         =>'USB-Server ID',
                readonly      =>1,
                dataobjattr   =>'tRnAI_usbsrv.id'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'VDI-System',
                AllowEmpty    =>1,
                vjointo       =>\'tRnAI::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'VDI-System ID',
                dataobjattr   =>'tRnAI_usbsrvport.system'),

      new kernel::Field::Link(
                name          =>'usbsrvportid',
                label         =>'USB-Server Port ID',
                dataobjattr   =>'tRnAI_usbsrvport.id'),

      new kernel::Field::Link(
                name          =>'usbsrvusbsrvid',
                label         =>'USB-Server Port',
                dataobjattr   =>'tRnAI_usbsrvport.usbsrv'),

      new kernel::Field::Link(
                name          =>'usbsrvport',
                label         =>'USB-Server Port',
                dataobjattr   =>'tRnAI_usbsrvport.port'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_usbsrvport.comments'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_usbsrvport.modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_usbsrvport.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_usbsrvport.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_usbsrvport.realeditor'),
   

   );
   $self->setDefaultView(qw(usbsrvid usbsrv name system cdate mdate));
   $self->setWorktable("tRnAI_usbsrvport");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
#}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   my ($usbsrvid,$port)=split(/:/,$oldrec->{id});

   $filter[0]={id=>\$oldrec->{id}};
   $newrec->{usbsrvportid}=$oldrec->{id};  # als Referenz in der Overflow die
   $newrec->{usbsrvusbsrvid}=$usbsrvid;
   $newrec->{usbsrvport}=$port;
   if (!defined($oldrec->{usbsrvportid})){    
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}



sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my @pl=();
   for(my $p=1;$p<=40;$p++){
      push(@pl,"select '".sprintf("%03d",$p)."' port");
   }
   my $from="tRnAI_usbsrv join ".
            "(".join(" union ",@pl).") portlist ".
            "on portlist.port<=tRnAI_usbsrv.portcount ".
            "left outer join tRnAI_usbsrvport on ".
            "tRnAI_usbsrv.id=tRnAI_usbsrvport.usbsrv and ".
            "portlist.port=tRnAI_usbsrvport.port ";
   return($from);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   #if ((!defined($oldrec) || defined($newrec->{name})) &&
   #    (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<5)){
   #   $self->LastMsg(ERROR,"invalid name specified");
   #   return(0);
   #}
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default);

   return(@wrgrp) if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"],undef,"up"));
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
