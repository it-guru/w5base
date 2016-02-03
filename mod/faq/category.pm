package faq::category;
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
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'faqcatid',
                label         =>'W5BaseID',
                size          =>'10',
                dataobjattr   =>'faqcat.faqcatid'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                size          =>'20',
                dataobjattr   =>'faqcat.name'),

      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parentgroup',
                vjointo       =>'faq::category',
                vjoinon       =>['parentid'=>'faqcatid'],
                vjoindisp     =>'fullname'),


      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                htmlwidth     =>'300px',
                dataobjattr   =>'faqcat.fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'faqcat.comments'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.article',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'faq::catacl',
                vjoinbase     =>[{'aclparentobj'=>\'faq::category'}],
                vjoinon       =>['faqcatid'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'id',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'faqcat.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'id',
                label         =>'Source-Id',
                dataobjattr   =>'faqcat.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'id',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'faqcat.srcload'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'id',
                label         =>'Modification-Date',
                dataobjattr   =>'faqcat.modifydate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'id',
                label         =>'Creation-Date',
                dataobjattr   =>'faqcat.createdate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor Account',
                dataobjattr   =>'faqcat.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'id',
                label         =>'real Editor Account',
                dataobjattr   =>'faqcat.realeditor'),

      new kernel::Field::Link(
                name          =>'parentid',
                label         =>'ParentID',
                dataobjattr   =>'faqcat.parentid'),
   );
   $self->{locktables}="faqcat write, faqcatacl write,  iomap write";
   $self->setDefaultView(qw(fullname faqcatid editor comments));
   $self->setWorktable("faqcat");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (defined($newrec->{name}) || !defined($oldrec)){
      trim(\$newrec->{name});
      if ($newrec->{name} eq "" ||
           !($newrec->{name}=~m/^[a-zA-Z0-9_-]+$/)){
         $self->LastMsg(ERROR,"invalid groupname '%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}



sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if (!grep(/^default$/,$self->isWriteValid($rec)));
   return($self->SUPER::isDeleteValid($rec));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(header default)) if (!defined($rec));
   return(qw(header default id acl));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
  # return("default") if (!defined($rec));  # new record is ok
   return(qw(default acl)) if ($self->IsMemberOf("admin"));
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

 #  my $lnkgrpuser=getModuleObject($self->Config,"base::lnkgrpuser");
 #  if (defined($lnkgrpuser)){
 #     my $idname=$self->IdField->Name();
 #     my $id=$oldrec->{$idname};
 #     $lnkgrpuser->SetFilter({'grpid'=>$id});
 #     $lnkgrpuser->SetCurrentView(qw(ALL));
 #     $lnkgrpuser->ForeachFilteredRecord(sub{
 #                        $lnkgrpuser->ValidatedDeleteRecord($_);
 #                     });
 #  }
   return($bak);
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({faqcatid=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(fullname));
      print($ia->WinHandleInfoAboSubscribe({},
                      "faq::category",$id,$rec->{fullname},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}

sub HandleShowSubscribers
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css'],
                              title=>$self->T("ShowSubscribers"));
      $ia->SetFilter({refid=>\$id,
                      mode=>\'faqchanged',
                      active=>\'1',
                      parentobj=>\'faq::category'});
      my @l=$ia->getHashList(qw(user));
      my $d="<div style=\"padding:5px;\">".
            "<div style=\"margin-bottom:2px\">".
            "<b><u>".$self->T("current active subscribers").":</u></b></div>";
      foreach my $rec (sort({$a->{user} cmp $b->{user}} @l)){
         $d.=$rec->{user}."<br>";
      }
      $d.="</div>";
      print $d;

   }
   else{
      print($self->noAccess());
   }
}

sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $d=$self->SUPER::getDetailFunctionsCode($rec);
   $d.=<<EOF;
function ShowSubscribers()
{
   showPopWin('HandleShowSubscribers?CurrentIdToEdit=$rec->{faqcatid}',450,250,
              null);
}



EOF

   return($d);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f=$self->SUPER::getDetailFunctions($rec);
   unshift(@f,$self->T("ShowSubscribers")=>"ShowSubscribers");

   return(@f);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(HandleShowSubscribers),$self->SUPER::getValidWebFunctions());
}  









1;
