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
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'applgrpid',
                label         =>'ApplicationGroupID',
                dataobjattr   =>'addlnkapplgrpsystem.applgrp'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'addlnkapplgrpsystem.system'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'addlnkapplgrpsystem.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                group         =>'add',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
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

   my $idtoken=$applgrp."-".$system;
 
   my $chk=effVal($oldrec,$newrec,"idtoken");
   if ($idtoken ne $chk){
      $newrec->{idtoken}=$idtoken;
   }
   if (!defined($oldrec) ||
       effChanged($oldrec,$newrec,"applgrpid") ||
       effChanged($oldrec,$newrec,"systemid")){
      if (!$self->checkApplgrpSystemRel($applgrp,$system)){
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






#sub getSqlFrom
#{
#   my $self=shift;
#   my $from=<<EOF;
#( select lnkapplsystem.appl applid,ipaddress.id as ipid
#      from lnkapplsystem,ipaddress
#      where lnkapplsystem.system=ipaddress.system
#   union
#   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
#      from lnkitclustsvcappl,ipaddress 
#      where lnkitclustsvcappl.itclustsvc=ipaddress.lnkitclustsvc
#   union
#   select lnkitclustsvcappl.appl applid,ipaddress.id ipid 
#      from lnkitclustsvcappl
#           join lnkitclustsvc on lnkitclustsvcappl.itclustsvc=lnkitclustsvc.id
#           join itclust on lnkitclustsvc.itclust=itclust.id 
#           join system on system.clusterid=itclust.id 
#           join ipaddress on ipaddress.system=system.id
#           left outer join lnkitclustsvcsyspolicy 
#              on lnkitclustsvc.id=lnkitclustsvcsyspolicy.itclustsvc 
#                 and lnkitclustsvcsyspolicy.system=system.id 
#      where system.cistatus<=4 and itclust.cistatus<=4 
#            and ( (lnkitclustsvcsyspolicy.runpolicy is null and 
#                   itclust.defrunpolicy<>'deny') or 
#                  (lnkitclustsvcsyspolicy.runpolicy is not null and 
#                   lnkitclustsvcsyspolicy.runpolicy<>'deny'))
#
#) as ai,appl,ipaddress 
#
#EOF
#
#   return($from);
#}


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


1;
