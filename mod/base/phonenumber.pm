package base::phonenumber;
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
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'phonenumber.id'),
                                                 
      new kernel::Field::Text(
                name          =>'parentobj',
                htmlwidth     =>'80',
                label         =>'Parent-Object',
                dataobjattr   =>'phonenumber.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                label         =>'RefID',
                htmlwidth     =>'50',
                dataobjattr   =>'phonenumber.refid'),

      new kernel::Field::Phonenumber(
                name          =>'phonenumber',
                htmlwidth     =>'120',
                label         =>'Phonenumber',
                dataobjattr   =>'phonenumber.number'),

      new kernel::Field::Select(
                name          =>'name',
                depend        =>['parentobj'],
                label         =>'Name',
                htmleditwidth =>'100%',
                getPostibleValues=>\&getPostibleUsageValues,
                dataobjattr   =>'phonenumber.name'),
                                                 
      new kernel::Field::Select(
                name          =>'showpublic',
                label         =>'visibility',
                value         =>['1','0'],
                default       =>'1',
                transprefix   =>'VIS.',
                htmleditwidth =>'160px',
                dataobjattr   =>'phonenumber.showpublic'),
                                                 
      new kernel::Field::Link(
                name          =>'rawname',
                label         =>'rawName',
                dataobjattr   =>'phonenumber.name'),
                                                 
      new kernel::Field::Text(
                name          =>'shortedcomments',
                htmlwidth     =>'320',
                htmldetail    =>'0',
                readonly      =>'1',
                label         =>'shorted Comments',
                depend        =>['comments'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $comments=$current->{comments};
                   $comments=~s/\n/ /g;
                   $comments=TextShorter($comments,47,"INDICATED");
                   if (length($comments)>47){
                      $comments=substr($comments,0,45)."...";
                   }
                   return($comments);
                }),

      new kernel::Field::Textarea(
                name          =>'comments',
                htmlwidth     =>'180',
                label         =>'Comments',
                dataobjattr   =>'phonenumber.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'phonenumber.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'phonenumber.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'phonenumber.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'phonenumber.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'phonenumber.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'phonenumber.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'phonenumber.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'phonenumber.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'phonenumber.realeditor'),
   );
   $self->setDefaultView(qw(parentobj refid phonenumber 
                            shortedcomments cdate editor));
   $self->setWorktable("phonenumber");
   $self->LoadSubObjs("ext/phonenumber","phonenumber");
   return($self);
}

sub getPostibleUsageValues
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   my $p=$app->getParent();
   if (defined($current) && $current->{parentobj} ne ""){
      $p=getModuleObject($app->Config,$current->{parentobj});
   }
   if (defined($p)){
      if (ref($p->{PhoneLnkUsage}) eq "CODE"){
         return(&{$p->{PhoneLnkUsage}}($app,$current));
      }
      else{
         if (ref($p->{PhoneLnkUsage}) eq "ARRAY"){
            return(@{$p->{PhoneLnkUsage}});
         }
      }
   }
   return();
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $refid=effVal($oldrec,$newrec,"refid");
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   if ($refid eq "" || $parentobj eq ""){
      $self->LastMsg(ERROR,"no valid link");
      return(0);
   }
   my $phonenumber=effVal($oldrec,$newrec,"phonenumber");
   if (!defined($phonenumber) || $phonenumber eq "" ||
       !($phonenumber=~m/^[+-\/0-9 ]{4,40}$/)){
      $self->LastMsg(ERROR,
             sprintf($self->T("invalid phone number")." '%s'",$phonenumber));
      return(0);
   }
   if ($self->isParentWriteValid($parentobj,$refid)){
      return(1);
   }
   if (!$self->LastMsg()){
      $self->LastMsg(ERROR,"no write access");
   }
   return(0);
}


sub isParentWriteValid
{
   my $self=shift;
   my $parentobj=shift;
   my $refid=shift;

   #
   # Security check
   #
   my $p=getModuleObject($self->Config,$parentobj);
   if (!defined($p)){ 
      $self->LastMsg(ERROR,"invalid parentobj '$parentobj'");
      return(0);
   }
   return(1) if ($self->IsMemberOf("admin"));
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$refid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid refid '$refid'");
      return(0);
   }
   if ($self->isDataInputFromUserFrontend()){
      my @write=$p->isWriteValid($l[0]);
      if ($#write!=-1){
         return(1) if (grep(/^ALL$/,@write));
         foreach my $fo ($p->getFieldObjsByView(["ALL"],current=>$l[0])){
            if ($fo->Type() eq "PhoneLnk"){
               my $grp=quotemeta($fo->{group});
               $grp="default" if ($grp eq "");
               return(1) if (grep(/^$grp$/,@write));
            }
         }
      }
   }
   else{
      return(1);
   }
   return(0);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $refid=$rec->{refid};
   my $parentobj=$rec->{parentobj};

   if ($self->isParentWriteValid($parentobj,$refid)){
      return(1);
   }
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/phonenumber.jpg?".$cgi->query_string());
}

sub getRecordHtmlIndex
{ return(); }





1;
