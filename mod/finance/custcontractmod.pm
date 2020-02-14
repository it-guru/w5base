package finance::custcontractmod;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'custcontractmod.id'),
                                                  
      new kernel::Field::Link(
                name          =>'contractid',
                label         =>'ID of related contract',
                selectfix     =>1,
                dataobjattr   =>'custcontractmod.contractid'),
                                                  
      new kernel::Field::Interface(
                name          =>'rawname',
                label         =>'raw Modulename',
                dataobjattr   =>'custcontractmod.name'),

      new kernel::Field::Select(
                name          =>'name',
                label         =>'Modulename',
                getPostibleValues=>sub{
                   $self=shift;
                   my @l=$self->getParent->getPosibleModuleValues();
                   my @d;
                   foreach my $l (@l){
                      push(@d,$l->{rawname},$l->{name});
                   }
                   return(@d);
                },
                dataobjattr   =>'custcontractmod.name'),



      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'custcontractmod.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'custcontractmod.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'custcontractmod.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'custcontractmod.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'custcontractmod.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'custcontractmod.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'custcontractmod.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'custcontractmod.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'custcontractmod.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'custcontractmod.realeditor')
   );
   $self->setDefaultView(qw(linenumber name cistatus mandator mdate fullname));
   $self->LoadSubObjs("ext/custcontractmod","custcontractmod");
   $self->setWorktable("custcontractmod");
   return($self);
}


sub getPosibleModuleValues
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;
   my $app=$self;
   my @opt;
   my $parentobj;
   if (defined($current)){
      $parentobj=$current->{parentobj};
   }
   else{
      $parentobj=$newrec->{parentobj};
   }
   my @l=();


   foreach my $obj (values(%{$app->{custcontractmod}})){
      $obj->collectModules($self,\@l,$current,$newrec);
   }
   return(@l);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sem delmgmt contacts control misc attachments));
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/contract.jpg?".$cgi->query_string());
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));

   if ($self->isParentReadable($rec->{contractid})){
      return(qw(ALL));
   }
   return();
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("ALL");
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("finance::custcontractmod");
}




sub isParentWriteable
{
   my $self=shift;
   my $parentid=shift;

   return($self->isParentOPvalid("write",$parentid));

}

sub isParentReadable
{
   my $self=shift;
   my $parentid=shift;

   return($self->isParentOPvalid("read",$parentid));

}

sub isParentOPvalid
{
   my $self=shift;
   my $mode=shift;
   my $parentid=shift;

   if ($parentid ne ""){
      my $p=$self->getPersistentModuleObject("finance::custcontract");
      my $idname=$p->IdField->Name();
      my %flt=($idname=>\$parentid);
      $p->ResetFilter();
      $p->SecureSetFilter(\%flt,\%flt);  # verhindert idDirectFilter true
      my @l=$p->getHashList(qw(ALL));
      if ($#l!=0){
         $self->LastMsg(ERROR,"invalid parent reference") if ($mode eq "write");
         return(0);
      }
      my @blkl;
      if ($mode eq "write"){ 
         @blkl=$p->isWriteValid($l[0]);
      }
      if ($mode eq "read"){ 
         @blkl=$p->isViewValid($l[0]);
      }
      if ($self->isDataInputFromUserFrontend()){
         if (!grep(/^ALL$/,@blkl) && !grep(/^modules$/,@blkl)){
            $self->LastMsg(ERROR,"no access") if ($mode eq "write");
            return(0);
         }
      }
   }
   return(1);
}




1;
