package base::lnkgrpuser;
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
use Data::Dumper;
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
   

   $self->{userview}=getModuleObject($self->Config,"base::userview");
   $self->{lnkgrpuserrole}=getModuleObject($self->Config,
                           "base::lnkgrpuserrole");
   my $role=$self->{lnkgrpuserrole}->getField("role");


   my $roles=new kernel::Field::Select(name       =>'roles',
                                       label      =>'Roles',
                                       translation=>$role->{translation},
                                       value      =>$role->{value});
   {
      $roles->{userrole}=$self->{lnkgrpuserrole};
      $roles->{multisize}=6;
      $roles->{searchable}=0;
      $roles->{onRawValue}=
         sub {
            my $self=shift;
            my $current=shift;
            my $idname=$self->getParent->IdField->Name();
            #printf STDERR ("fifi onRawValue:%s\n",$self->Name());
            #printf STDERR ("fifi onRawValue:id=%s\n",$current->{$idname});
            if (defined($current)){
               $self->{userrole}->SetFilter({$idname=>\$current->{$idname}});
               my @l=$self->{userrole}->getHashList(qw(role));
              
               #printf STDERR ("fifi onRawValue:dump=%s\n",Dumper(\@l));
               my @l=map({$_->{role}} @l);
               return(\@l);
            }
            return([]);
         };
      $roles->{onFinishWrite}=
         sub {
            my $self=shift;
            my $oldrec=shift;
            my $newrec=shift;
            my $oldval=shift;
            my $newval=shift;
            my @addlist=();
            my @dellist=();
            my $idname=$self->getParent->IdField->Name();
            my $relationrec=$oldrec;
            $relationrec=$newrec if (!defined($oldrec));
            $newval=[$newval] if (ref($newval) ne "ARRAY");
            
            foreach my $new (@{$newval}){
               push(@addlist,$new) if (!grep(/^$new$/,@{$oldval}));
            }
            foreach my $old (@{$oldval}){
               push(@dellist,$old) if (!grep(/^$old$/,@{$newval}));
            }
            foreach my $add (@addlist){
               my $newrec={$idname=>\$relationrec->{$idname},
                           role=>$add};
               $self->{userrole}->ValidatedInsertRecord($newrec);
            }
            foreach my $del (@dellist){
               $self->{userrole}->SetFilter(
                                {$idname=>\$relationrec->{$idname},
                                 role=>$del});
               $self->{userrole}->SetCurrentView(qw(ALL));
               $self->{userrole}->ForeachFilteredRecord(sub{
                               $self->{userrole}->ValidatedDeleteRecord($_);
                               });
            }
            #printf STDERR ("fifi onFinishWrite in %s\n",$self->Name());
            #printf STDERR ("fifi oldval=%s\n",join(",",@{$oldval}));
            #printf STDERR ("fifi newval=%s\n",join(",",@{$newval}));
            #printf STDERR ("fifi addlist=%s\n",join(",",@addlist));
            #printf STDERR ("fifi dellist=%s\n",join(",",@dellist));
            return(undef);
         };
   }

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'lnkgrpuserid',
                label         =>'LinkID',
                size          =>'10',
                dataobjattr   =>'lnkgrpuser.lnkgrpuserid'),

      new kernel::Field::TextDrop(
                name          =>'user',
                htmlwidth     =>'380px',
                label         =>'User',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'email',
                readonly      =>1,
                htmlwidth     =>'380px',
                label         =>'E-Mail',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'office_phone',
                readonly      =>1,
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Office Phone',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'group',
                htmlwidth     =>'280px',
                label         =>'Group',
                vjointo       =>'base::grp',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkgrpuser.expiration'),

      new kernel::Field::Select(
                name          =>'alertstate',
                value         =>['','yellow','orange',
                                 'red'],
                uivisible     =>sub{
                    my $self=shift;
                    my $mode=shift;
                    my $app=$self->getParent;
                    my %param=@_;
                    return(1) if (!defined($param{current}));
                    return(1) if (
                       $param{current}->{alertstate} ne "");
                    return(0);
                },
                readonly      =>1,
                label         =>'Alert-State',
                dataobjattr   =>'lnkgrpuser.alertstate'),

      $roles,

      new kernel::Field::SubList(
                name          =>'lineroles',
                label         =>'LineRoles',
                htmldetail    =>'0',
                readonly      =>'1',
                vjointo       =>'base::lnkgrpuserrole',
                vjoinon       =>['lnkgrpuserid'=>'lnkgrpuserid'],
                vjoindisp     =>['role'],
                vjoininhash   =>['role']),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkgrpuser.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkgrpuser.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkgrpuser.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkgrpuser.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkgrpuser.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkgrpuser.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor',
                dataobjattr   =>'lnkgrpuser.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'RealEditor',
                dataobjattr   =>'lnkgrpuser.realeditor'),

      new kernel::Field::Link(
                name          =>'grpid',
                label         =>'GrpID',
                dataobjattr   =>'lnkgrpuser.grpid'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserId',
                dataobjattr   =>'lnkgrpuser.userid'),
   );
   $self->setDefaultView(qw(lnkgrpuserid user group editor));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("lnkgrpuser");
   return(1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (effVal($oldrec,$newrec,"grpid")==0){
      $self->LastMsg(ERROR,"invalid group specified");
      return(undef);
   }
   if (effVal($oldrec,$newrec,"userid")==0){
      $self->LastMsg(ERROR,"invalid user specified");
      return(undef);
   }
   my $grpid=effVal($oldrec,$newrec,"grpid");
   return(1) if (!$self->isDataInputFromUserFrontend());
   return(1) if ($self->IsMemberOf("admin")); 
   my $destuserid=effVal($oldrec,$newrec,"userid");
   my $userid=$self->getCurrentUserId();
   if ($userid==$destuserid && !$self->IsMemberOf("admin")){
      $self->LastMsg(ERROR,"you are not authorized to modify your own account");
      return(0);
   }
   return(1) if ($self->IsMemberOf([$grpid],"RAdmin","down"));
   $self->LastMsg(ERROR,"you are not authorized to admin this group");
   return(0);
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
   if (defined($rec)){
      my $grpid=$rec->{grpid};
      return(undef) if (!$self->IsMemberOf("admin") &&
                        !$self->IsMemberOf([$grpid],"RAdmin","down"));
      my $destuserid=$rec->{userid};
      my $userid=$self->getCurrentUserId();
      return(undef) if ($userid==$destuserid &&
                        !$self->IsMemberOf("admin"));
   }
   return("default");
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateUserCache();
   return($bak);
}

sub FinishDelete
{  
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->InvalidateUserCache();
   {  # cleanup lnkgrpuserrole 
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $self->{lnkgrpuserrole}->SetFilter({'lnkgrpuserid'=>$id});
      $self->{lnkgrpuserrole}->SetCurrentView(qw(ALL));
      $self->{lnkgrpuserrole}->ForeachFilteredRecord(sub{
                         $self->{lnkgrpuserrole}->ValidatedDeleteRecord($_);
                      });
   }
   return($bak);
}

sub getRecordImageUrl
{
   my $self=shift;
   return("../../../public/base/load/gnome-user-group.jpg");
}

   


1;
