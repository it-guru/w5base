package tRnAI::lnkinstlic;
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
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_lnkinstlic.id'),
                                                  
#      new kernel::Field::Text(
#                name          =>'name',
#                label         =>'Instance-Name',
#                dataobjattr   =>'tRnAI_lnkinstlic.name'),

      new kernel::Field::TextDrop(
                name          =>'instance',
                label         =>'Instance',
                htmlwidth     =>'140',
                vjointo       =>\'tRnAI::instance',
                vjoinon       =>['instanceid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'instanceid',
                label         =>'InstanceID',
                dataobjattr   =>'tRnAI_lnkinstlic.instance'),

      new kernel::Field::TextDrop(
                name          =>'license',
                label         =>'License',
                htmlwidth     =>'140',
                vjointo       =>\'tRnAI::license',
                vjoinon       =>['licenseid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'licenseid',
                label         =>'LicenseID',
                dataobjattr   =>'tRnAI_lnkinstlic.license'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_lnkinstlic.comments'),

      new kernel::Field::Text(
                name          =>'ponum',
                htmlwidth     =>'150px',
                translation   =>'tRnAI::license',
                label         =>'Purchase Order Number',
                dataobjattr   =>'tRnAI_license.ponum'),

      new kernel::Field::Date(
                name          =>'expdate',
                label         =>'Expiration Date',
                translation   =>'tRnAI::license',
                group         =>'license',
                readonly      =>'1',
                dayonly       =>1,
                dataobjattr   =>'tRnAI_license.expdate'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                group         =>'system',
                translation   =>'tRnAI::system',
                vjointo       =>\'tRnAI::system',
                vjoindisp     =>'name',
                vjoinon       =>['systemid'=>'id']),

      new kernel::Field::Link(
                name          =>'systemid',
                group         =>'system',
                label         =>'SystemID',
                dataobjattr   =>'tRnAI_instance.system'),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_lnkinstlic.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_lnkinstlic.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_lnkinstlic.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_lnkinstlic.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_lnkinstlic.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_lnkinstlic.realeditor'),
   

   );
   $self->setDefaultView(qw(license instance system mdate));
   $self->setWorktable("tRnAI_lnkinstlic");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/swlnkinstlic.jpg?".$cgi->query_string());
#}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ".
            "left outer join tRnAI_license ".
              "on tRnAI_lnkinstlic.license=tRnAI_license.id ".
            "left outer join tRnAI_instance ".
              "on tRnAI_lnkinstlic.instance=tRnAI_instance.id ".
            "left outer join tRnAI_system ".
              "on tRnAI_instance.system=tRnAI_system.id ";
   return($from);
}





sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default instance license system source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

  # if ((!defined($oldrec) || defined($newrec->{name})) &&
  #     (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<3)){
  #    $self->LastMsg(ERROR,"invalid name specified");
  #    return(0);
  # }
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
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   if ($self->IsMemberOf(["w5base.RnAI.inventory.read"],undef,"direct")){
      return("header","default","instance","license","system","source");
   }
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
