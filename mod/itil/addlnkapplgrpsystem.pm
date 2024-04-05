package itil::addlnkapplgrpsystem;
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
use vars qw(@ISA $VERSION $DESCRIPTION);
use kernel;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);


$VERSION="1.0";
$DESCRIPTION=<<EOF;
Dataobject to store inforations related to ApplicationGroup-System
Relations. This Object will not be edit by Web-Frontend Users.
EOF




sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));

   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                group         =>'source',
                dataobjattr   =>'addlnkapplgrpsystem.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'applgrp',
                label         =>'ApplicationGroup',
                vjointo       =>'itil::applgrp',
                vjoinon       =>['applgrpid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'applgrp.fullname'),

      new kernel::Field::Select(
                name          =>'applgrpcistatus',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Applicationgroup CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applgrpcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'applgrpcistatusid',
                label         =>'ApplGrpCiStatusID',
                dataobjattr   =>'applgrp.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),

      new kernel::Field::Text(
                name          =>'applgrpid',
                label         =>'ApplicationGroup W5BaseID',
                dataobjattr   =>'addlnkapplgrpsystem.applgrp'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'System W5BaseID',
                dataobjattr   =>'addlnkapplgrpsystem.system'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'addlnkapplgrpsystem.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                group         =>'add',
                htmldetail    =>0,
                searchable    =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(1);
                   }
                    
                   return(0);
                },
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   if ($mode eq "SearchMask" &&
                       $self->getParent->IsMemberOf("admin")){
                      return(1);
                   }
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'addlnkapplgrpsystem.additional'),

      new kernel::Field::Text(
                name          =>'idtoken',
                label         =>'IdToken',
                group         =>'source',
                dataobjattr   =>'addlnkapplgrpsystem.idtoken'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'addlnkapplgrpsystem.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'addlnkapplgrpsystem.modifydate'),



   );
   $self->setWorktable("addlnkapplgrpsystem");
   $self->setDefaultView(qw(applgrp system mdate));
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $applgrp=effVal($oldrec,$newrec,"applgrpid");
   my $system=effVal($oldrec,$newrec,"systemid");

   if ($applgrp eq "" || $system eq ""){
      $self->LastMsg(ERROR,"missing systemid or applgrpid");
      return(undef);
   }

   my $idtoken=$applgrp."-".$system;
 
   my $chk=effVal($oldrec,$newrec,"idtoken");
   if ($idtoken ne $chk){
      $newrec->{idtoken}=$idtoken;
   }
   if (!defined($oldrec) ||
       effChanged($oldrec,$newrec,"applgrpid") ||
       effChanged($oldrec,$newrec,"systemid")){
      if (!$self->checkApplgrpSystemRel($applgrp,$system)){
         msg(ERROR,"relationcheck bettwen applgrp=$applgrp ".
                   "and system=$system failed");
         $self->LastMsg(ERROR,"no existing relation between application group ".
                              "and system");
         return(0);
      }
   }

   return(1);
}


sub checkApplgrpSystemRel
{
   my $self=shift;
   my $applgrp=shift;
   my $system=shift;

   my $o=$self->getPersistentModuleObject("capplrel","itil::lnkapplsystem");

   $o->SetFilter({applgrpid=>\$applgrp,systemid=>\$system});
   my ($chkrec)=$o->getOnlyFirst(qw(id));
   if (!defined($chkrec)){
      return(0);
   }
   return(1);


}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}






sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();

   my $from="$worktable ".
            "join applgrp on $worktable.applgrp=applgrp.id ".
            "join system on ($worktable.system=system.id and ".
                            "system.cistatus<7)";
   return($from);
}


#sub initSqlWhere
#{
#   my $self=shift;
#   my $mode=shift;
#   my $where="ai.applid=appl.id and ai.ipid=ipaddress.id";
#   return($where);
#}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if ($self->IsMemberOf("admin"));

   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("default","header") if (!defined($rec));

   return(qw(ALL));
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applgrpcistatus"))){
     Query->Param("search_applgrpcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




1;
