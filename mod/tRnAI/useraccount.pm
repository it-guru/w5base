package tRnAI::useraccount;
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

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_useraccount.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'AD-Account',
                htmlwidth     =>'120px',
                dataobjattr   =>'tRnAI_useraccount.name'),

      new kernel::Field::Text(
                name          =>'domain',
                label         =>'AD-Domain',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'120px',
                dataobjattr   =>'tRnAI_useraccount.domain'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                dataobjattr   =>'tRnAI_useraccount.email'),

      new kernel::Field::Date(
                name          =>'expdate',
                label         =>'SC Expireing Date',
                dataobjattr   =>'tRnAI_useraccount.expdate'),

      new kernel::Field::Date(
                name          =>'expnotify1',
                label         =>'Expiration Notify',
                htmldetail    =>0,
                selectfix     =>1,
                dataobjattr   =>'tRnAI_useraccount.expnotify1'),

      new kernel::Field::Date(
                name          =>'exitdate',
                label         =>'Exit Date',
                dataobjattr   =>'tRnAI_useraccount.exitdate'),

      new kernel::Field::Date(
                name          =>'exitnotify1',
                label         =>'Exit Notify',
                htmldetail    =>0,
                selectfix     =>1,
                dataobjattr   =>'tRnAI_useraccount.exitnotify1'),

      new kernel::Field::Date(
                name          =>'birthdate',
                label         =>'date of birth',
                dayonly       =>1, 
                dataobjattr   =>'tRnAI_useraccount.bdate'),

      new kernel::Field::Text(
                name          =>'sappersno',
                label         =>'SAP personal number',
                dataobjattr   =>'tRnAI_useraccount.sappersno'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_useraccount.comments'),

      #new kernel::Field::TextDrop(
      #          name          =>'system',
      #          label         =>'VDI-Systemname',
      #          vjointo       =>\'tRnAI::system',
      #          vjoinon       =>['systemid'=>'id'],
      #          vjoindisp     =>'name'),
      #
      #new kernel::Field::Link(
      #          name          =>'systemid',
      #          label         =>'systemid',
      #          dataobjattr   =>'tRnAI_useraccount.system'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                subeditmsk    =>'subedit.systems',
                vjointo       =>\'tRnAI::lnkuseraccountsystem',
                vjoinon       =>['id'=>'useraccountid'],
                vjoindisp     =>['system','reltyp']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_useraccount.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_useraccount.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_useraccount.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_useraccount.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_useraccount.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_useraccount.realeditor'),
   

   );
   $self->setDefaultView(qw(name email system expdate mdate));
   $self->setWorktable("tRnAI_useraccount");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/useraccount.jpg?".$cgi->query_string());
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my ($worktable,$workdb)=$self->getWorktable();
#   my $from="$worktable ".
#            "left outer join xxx on yyy=zzz";
#   return($from);
#}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<3)){
      $self->LastMsg(ERROR,"invalid AD-Account specified");
      return(0);
   }
   if (exists($newrec->{name})){
      my $n=uc($newrec->{name});
      if (my ($d,$n)=$n=~m/^(\S+)[\/\\](\S+)$/){
         my $full=$d."/".$n;
         if ($full ne $newrec->{name}){
            $newrec->{name}=$full;
         }
         $newrec->{domain}=$d;
      }
      else{
         $newrec->{domain}=undef;
      }

   }

   if (effChanged($oldrec,$newrec,"expdate")){
      if (defined($oldrec) && $oldrec->{expnotify1} ne ""){
         $newrec->{expnotify1}=undef;
      }
   }

   if (effChanged($oldrec,$newrec,"exitdate")){
      if (defined($oldrec) && $oldrec->{exitnotify1} ne ""){
         $newrec->{exitnotify1}=undef;
      }
   }

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default systems);

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



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default systems source));
}





sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
