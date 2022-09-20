package kernel::App::Web::ItemTag;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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

# Tag-Handling concept implemented in 09/2022 - and is as example implemented
# in itil::tag_appl (on itil::appl) implemented.
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
  
   $self->{tagtable}="tagtable" if (!defined($self->{tagtable})); 
   $self->{use_distinct}=0;
   my $tagtable=$self->{tagtable};

   $self->{control}={
       'internalKeys'=>[],
       'uniqueKeys'=>[],
   };

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'tagid',
                label         =>'TagID',
                htmldetail    =>0,
                dataobjattr   =>$tagtable.'.id'),

      new kernel::Field::Text(
                name          =>'name',
                selectfix     =>1,
                label         =>'Key',
                dataobjattr   =>"if ($tagtable.id is null,qname.qname,".
                                "$tagtable.name)",
                wrdataobjattr  =>$tagtable.'.name'),

      new kernel::Field::Link(
                name          =>'uname',
                label         =>'uName',
                dataobjattr   =>$tagtable.'.uname'),

      new kernel::Field::Text(
                name          =>'value',
                selectfix     =>1,
                label         =>'Value',
                dataobjattr   =>$tagtable.'.value'),

      new kernel::Field::Boolean(           # vorgesehen, damit man per API  
                name          =>'ishidden', # Tags setzen kann, die aber nur
                label         =>'is hidden',# in alltags auftauchen - nicht aber
                dataobjattr   =>$tagtable.'.ishidden'),  # in HtmlDetail

      new kernel::Field::Text(
                name          =>'refid',
                frontreadonly =>1,
                selectfix     =>1,
                label         =>'ReferenceID',
                dataobjattr   =>$tagtable.'.refid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                label         =>'Comments',
                dataobjattr   =>$tagtable.'.comments'),


      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>$tagtable.'.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                dataobjattr   =>$tagtable.'.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor',
                dataobjattr   =>$tagtable.'.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'RealEditor',
                dataobjattr   =>$tagtable.'.realeditor'),
   );
   $self->LoadSubObjs("ext/ItemTag","tagctrl");
   $self->setDefaultView(qw(aclid refid acltargetname));

   foreach my $obj (values(%{$self->{tagctrl}})){
      $obj->Configure($self,$self->{parent},$self->{control});
   }

   my $internalsql="'0'";
   if ($#{$self->{control}->{internalKeys}}!=-1){
      $internalsql="($tagtable.name in (".
                   join(",",map({"'".$_."'"}
                        @{$self->{control}->{internalKeys}}))."))";
   }
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'internal',
                label         =>'isInternal',
                dataobjattr   =>$internalsql)
   );

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable($self->{tagtable});
   return(1);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   my $parenttable=$self->{parenttable};
   my $parentid=$self->{parentid};

   my $qname;

   if ($#flt==0 && ref($flt[0]) eq "HASH"){
      $qname=$flt[0]->{name};
   }

   my $qnamesql="";
   if ($qname){
      $qnamesql=" join (select '$qname' qname) as qname left outer ".
                "join $worktable ".
                "on $parenttable.$parentid=$worktable.refid and ".
                "$worktable.name='$qname'";
   }
   else{
      $qnamesql=" join (select NULL qname) as qname ".
                "join $worktable ".
                "on $parenttable.$parentid=$worktable.refid ";
   }

   $from.="$parenttable $qnamesql ";

   return($from);
}


sub setTag
{
   my $self=shift;
   my $id=shift;
   my $name=shift;
   my $value=shift;

   my @idlist=$self->ValidatedInsertOrUpdateRecord(
      {value=>$value,name=>$name,refid=>$id},
      {refid=>$id,name=>$name}
   );
   return(@idlist);
}

sub getTag
{
   my $self=shift;
   my $id=shift;
   my $name=shift;
   my %flt;

   if (ref($name) eq "HASH"){
      %flt=%{$name};
   }
   else{
      %flt=(name=>$name);
   }
   $flt{refid}=\$id;


   $self->SetFilter(\%flt);
   my @l=$self->getHashList(qw(mdate name value));
   if ($#l==-1){
      return();
   }

   my @v=map({$_->{value}} @l);
   if (wantarray()){
      return(@v);
   } 
   return($v[0]);
}


sub SetTagFilter
{
   my $self=shift;
   my $filter=shift;

   $self->SetFilter($filter);
   $self->SetCurrentView(qw(name value mdate));
}







sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"name");

   if (in_array($self->{control}->{uniqueKeys},$name)){
      $newrec->{uname}=$name;
   }



#   if ((!defined($oldrec) && !defined($newrec->{refid})) ||
#       (defined($newrec->{refid}) && $newrec->{refid}==0)){
#      $self->LastMsg(ERROR,"no '%s' specified",
#                           $self->getField("refid")->Label());
#      return(undef);
#   }
#   if ((!defined($oldrec) && !defined($newrec->{acltargetid})) ||
#       (defined($newrec->{acltargetid}) && $newrec->{acltargetid}==0)){
#      $self->LastMsg(ERROR,"no '%s' specified",
#                           $self->getField("acltargetname")->Label());
#      return(undef);
#   }
#   if (defined($self->getParent)){
#      $newrec->{aclparentobj}=$self->getParent->SelfAsParentObject();
#   }
#   my $parentobj=effVal($oldrec,$newrec,"aclparentobj");
#   if ($parentobj eq ""){
#      $newrec->{aclparentobj}=$self->getParent;
#   }
#   my $parentobj=effVal($oldrec,$newrec,"aclparentobj");
#   my $refid=effVal($oldrec,$newrec,"refid");
#
#   if ($refid ne ""){
#      my $pobj;
#      if ($parentobj ne ""){
#         $pobj=getModuleObject($self->Config,$parentobj);
#      }
#      if (defined($pobj)){
#         if ($self->isDataInputFromUserFrontend()){
#            if (!$self->checkParentWriteAccess($pobj,$refid)){
#               $self->LastMsg(ERROR,"insufficient access to parent object");
#               return(undef);
#            }
#         }
#      }
#      else{
#         $self->LastMsg(ERROR,"no parentobj specified");
#         return(undef);
#      }
#   }
#   else{
#      $self->LastMsg(ERROR,"no refid specified");
#      return(undef);
#   }
   return(1);
}

#sub checkParentWriteAccess
#{
#   my $self=shift;
#   my $pobj=shift;
#   my $refid=shift;
#   my $mode=shift;
#
#   if ($refid eq ""){
#      $self->LastMsg(ERROR,"invalid '%s' specified",
#                        $self->getField("refid")->Label());
#   }
#   $pobj->SetFilter({$pobj->IdField->Name()=>\$refid});
#   my @l=$pobj->getHashList(qw(ALL));
#   if ($#l==-1){
#      # Elternobjekt scheint nicht mehr zu existieren
#      if ($refid ne "" && !($refid=~m/[\*\?]/) &&
#          $pobj->Ping() && $mode eq "delete"){
#         #msg(INFO,"Cleanup on none existing parent record '$pobj' '$refid'");
#         return(1);
#      }
#      $self->LastMsg(ERROR,"invalid refid specified '%s' in %s",
#                     $refid,$pobj->Self);
#      return(0); # parent object id does not exists
#   }
#   if ($#l!=0){
#      $self->LastMsg(ERROR,"invalid '%s' specified '%s'",
#                        $self->getField("refid")->Label(),$refid);
#      return(undef);
#   }
#   my $prec=$l[0];
#   my @grps=$pobj->isWriteValid($prec);
#   if (!grep(/^acls$/,@grps) &&
#       !grep(/^acl$/,@grps) &&
#       !grep(/^ALL$/,@grps)){
#      #msg(INFO,"access only for '%s'\n",join(",",@grps));
#      return(0);
#   }
#
#   return(1);
#}
#
#sub ValidateDelete
#{
#   my $self=shift;
#   my $rec=shift;
#   my $parentobj=$rec->{aclparentobj};
#   my $refid=$rec->{refid};
#   if ($refid ne ""){
#      my $pobj;
#      if ($parentobj ne ""){
#         $pobj=getModuleObject($self->Config,$parentobj);
#      }
#      if (defined($pobj)){
#         if (!$self->checkParentWriteAccess($pobj,$refid,"delete")){
#            $self->LastMsg(ERROR,"insufficient access to parent object");
#            return(undef);
#         }
#         return(1);
#      }
#      else{
#         $self->LastMsg(ERROR,"no parentobj specified");
#         return(undef);
#      }
#   }
#   else{
#      $self->LastMsg(ERROR,"no refid specified");
#      return(undef);
#   }
#   return(0);
#}



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
   return("ALL") if ($self->IsMemberOf("admin"));

   return(undef);
}

#
#   my $refid=$rec->{refid};
#   my $parentobj=$rec->{aclparentobj};
#
#   if ($refid ne ""){
#      my $pobj;
#      if ($parentobj ne ""){
#         $pobj=getModuleObject($self->Config,$parentobj);
#      }
#      if (defined($pobj)){
#         if ($self->checkParentWriteAccess($pobj,$refid)){
#            return("ALL");
#         }
#      }
#   }
#   return(undef);
#}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



   


1;
