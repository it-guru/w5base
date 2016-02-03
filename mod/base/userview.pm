package base::userview;
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
      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                size          =>'10',
                dataobjattr   =>'userview.id'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Viewname',
                size          =>'20',
                dataobjattr   =>'userview.name'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'View User',
                frontreadonly =>\&isNotAdmin,
                AllowEmpty    =>1,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'userid',
                dataobjattr   =>'userview.userid'),

      new kernel::Field::Text(
                name          =>'viewrevision',
                label         =>'View-Revision',
                size          =>'20',
                uivisible     =>0,
                dataobjattr   =>'userview.viewrevision'),

      new kernel::Field::Text(
                name          =>'module',
                label         =>'Modulename',
                frontreadonly =>\&isNotAdmin,
                size          =>'20',
                dataobjattr   =>'userview.module'),

      new kernel::Field::Text(
                name          =>'modulelong',
                depend        =>['module'],
                searchable    =>0,
                readonly      =>1,
                label         =>'Module long name',
                onRawValue    =>\&getLongName),

      new kernel::Field::Textarea(
                name          =>'data',
                label         =>'Viewdata',
                dataobjattr   =>'userview.viewdata'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'userview.mdate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'userview.cdate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'userview.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'userview.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'userview.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'userview.realeditor'),
   );
   $self->setDefaultView(qw(modulelong module name data));
   $self->setWorktable("userview");
   return($self);
}


sub isNotAdmin
{
   my $self=shift;

   return(1) if (!$self->getParent->IsMemberOf("admin"));
   return(0);
}


sub isCopyValid
{
   my $self=shift;

   return(1);
}


sub getLongName
{
   my $self=shift;
   my $current=shift;
   my $module=$current->{module};
   my $mlong;
   if (my ($b,$sub)=$module=~m/^(base::workflow)\((.*)\)$/){
      $mlong=$self->getParent->T($sub,$sub)."->Workflows";
   }
   else{
      $mlong=$self->getParent->T($module,$module);
   }
   return($mlong);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $userid=$self->getCurrentUserId();
   if (my $srcid=Query->Param("isCopyFromId")){
      $self->ResetFilter();
      $self->SetFilter({id=>\$srcid});
      my ($srec,$msg)=$self->getOnlyFirst(qw(module));
      if (defined($srec)){
         $newrec->{module}=$srec->{module};
         $newrec->{viewrevision}="1";
         if (!defined($newrec->{userid}) || $newrec->{userid} eq ""){
            $newrec->{userid}=$userid;
         }
      }
   }

   $newrec->{name}=effVal($oldrec,$newrec,"name");
   trim(\$newrec->{name});
   $newrec->{name}=~s/^\*//;
   if ($newrec->{name} eq "" ||
       !($newrec->{name}=~m/^[a-zA-Z0-9_\.-]+$/)){
      $self->LastMsg(ERROR,"invalid view name specified");
      return(undef);
   }
   if (!defined($oldrec) || defined($newrec->{module})){
      trim(\$newrec->{module});
      if ($newrec->{module} eq ""){
         $self->LastMsg(ERROR,"invalid module name specified");
         return(undef);
      }
   }
   my $u=effVal($oldrec,$newrec,"userid");
   $newrec->{userid}=0 if (defined($u) && $u eq "");
   if ($userid!=$u && !$self->IsMemberOf("admin")){
      $self->LastMsg(ERROR,"you are not authoriezed to modify the ".
                           "requested viewset");
      return(undef);
   }
   my $u=effVal($oldrec,$newrec,"userid");
   if ($u==0){
      my $name=effVal($oldrec,$newrec,"name");
      $newrec->{name}="*".substr($name,0,9);
   }
   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   
   my $userid=$self->getCurrentUserId();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      Query->Param("search_user"=>'"'.
                   $UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname}.'"');
   }
}  


sub InitCopy
{
   my ($self,$copyfrom,$copyinit)=@_;

   delete($copyinit->{Formated_id});

   my $userid=$self->getCurrentUserId();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $copyinit->{Formated_user}=$UserCache->{$ENV{REMOTE_USER}}->
                                 {rec}->{fullname};
   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return("default") if ((defined($rec) && $rec->{userid}==$userid) ||
                         $self->IsMemberOf("admin"));
   return(undef);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/userviews.jpg?".$cgi->query_string());
}


1;
