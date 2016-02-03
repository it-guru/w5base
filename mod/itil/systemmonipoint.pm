package itil::systemmonipoint;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   $self->{Worktable}="systemmonipoint";
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID - MoniPoint',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"system.id"),
                                                  
      new kernel::Field::Link(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemID',
                dataobjattr   =>"$worktable.system"),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                uploadable    =>1,
                label         =>'fullqualified monitoring point',
                dataobjattr   =>"if ($worktable.name is null,".
                                "concat(system.name,'.','con'),".
                                "concat(system.name,'.',$worktable.name))"),

      new kernel::Field::TextDrop(
                name          =>'systemname',
              #  readonly      =>sub{
              #     my $self=shift;
              #     my $current=shift;
              #     return(1) if (defined($current));
              #     return(0);
              #  },
                uploadable    =>1,
                searchable    =>0,
                label         =>'Systemname',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'name',
                uploadable    =>1,
                label         =>'Monitoring Point',
                dataobjattr   =>"$worktable.name"),

      new kernel::Field::Text(
                name          =>'system',
                readonly      =>1,
                uploadable    =>0,
                group         =>'system',
                label         =>'System',
                weblinkto     =>'itil::system',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'system.name'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                uploadable    =>0,
                group         =>'system',
                htmleditwidth =>'40%',
                label         =>'System CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemcistatusid',
                readonly      =>1,
                uploadable    =>0,
                label         =>'System CI-StateID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>"$worktable.createdate"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>"$worktable.createuser"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>"$worktable.realeditor"),




   );
   $self->setDefaultView(qw(system fullname id));
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



#
# do not create default monitoring points, because there are systems to,
# which have NO monitoring
#
#sub preProcessReadedRecord
#{
#   my $self=shift;
#   my $rec=shift;
#
#   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
#      my $o=$self->Clone();
#      $o->BackendSessionName("preProcessReadedRecord"); # prevent sesssion reuse
#                                                  # on sql cached_connect
#      my ($id)=$o->InsertRecord({systemid=>$rec->{parentid},
#                                          name=>'con'});
#      $rec->{id}=$id;
#      $rec->{name}='con';
#   }
#   return(undef);
#}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="$worktable  left outer join system on system.id=$worktable.system ";

   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->checkWriteValid($oldrec,$newrec)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }

   my $name=effVal($oldrec,$newrec,"name");
   if (!($name=~m/^[a-z0-9_]{1,20}$/i)){
      $self->LastMsg(ERROR,"invalid monitoring service name");
      return(0);
   }

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   if (defined($rec)){
      if (!$self->checkWriteValid($rec)){
         return();
      }
   }

   return("default");
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}

sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $lnkid=effVal($oldrec,$newrec,"systemid");

   return(undef) if ($lnkid eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::system");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$lnkid);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL));
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^default$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default system source));
}




#############################################################################

1;
