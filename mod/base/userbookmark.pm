package base::userbookmark;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'userbookmark.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Bookmark Name',
                dataobjattr   =>'userbookmark.name'),

      new kernel::Field::Text(
                name          =>'srclink',
                label         =>'Link',
                dataobjattr   =>'userbookmark.src'),

      new kernel::Field::Select(
                name          =>'target',
                label         =>'Target',
                htmleditwidth =>'200px',
                transprefix   =>'target', 
                default       =>'_blank',
                value         =>[qw(_blank _self _top msel)],
                dataobjattr   =>'userbookmark.target'),

      new kernel::Field::Link(
                name          =>'userid',
                selectfix     =>1,
                label         =>'UserID',
                dataobjattr   =>'userbookmark.userid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'userbookmark.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'userbookmark.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'userbookmark.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'userbookmark.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'userbookmark.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'userbookmark.realeditor'),

      new kernel::Field::TextDrop(
                name          =>'user',
                group         =>'source',
                label         =>'attached user',
                vjointo       =>'base::user',
                readonly      =>1,
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),
   );
   $self->setDefaultView(qw(linenumber name user mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("userbookmark");
   return(1);
}

sub SecureSetFilter
{  
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin)],"RMember")){
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {userid=>\$userid},
                ]);
   }
   return($self->SetFilter(@flt));
}  


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   my $srclink=trim(effVal($oldrec,$newrec,"srclink"));
   if ($srclink=~m/\s$/ || !($srclink=~m/^(javascript:|http:|https:|news:|telnet:|..\/)/)){
      $self->LastMsg(ERROR,"invalid web link '%s' specified",$srclink); 
      return(undef);
   }
   if (!defined($oldrec)){
      $newrec->{userid}=$self->getCurrentUserId();
   }
   if (effVal($oldrec,$newrec,"userid") eq ""){
      $self->LastMsg(ERROR,"unable to create bookmark - missing userid"); 
      return(undef);
   }
   
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("header","default") if (!defined($rec));
   return("ALL") if ($rec->{userid} eq $userid || $self->IsMemberOf("admin"));
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return("default") if (!defined($rec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if (defined($rec) && $rec->{userid} eq $userid);
   return(undef);
}


sub WebBookmarkCreate
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           title=>'WebBookmarkCreate');
   my $msg="If you create a bookmark, they will be displayed in MyW5Base.";
   my $bmlink=Query->Param("bmlink");
   if (Query->Param("bmcreate")){
      my $name=Query->Param("bmname");
      my $srclink=Query->Param("bmlink");
      my $target=Query->Param("bmtarget");
      if (($name=~m/^\s*$/) || ($srclink=~m/^\s*$/)){
         $msg="missing informations";
      }
      else{
         $target="_self" if ($target eq "");
         if ($self->SecureValidatedInsertRecord({name=>$name,
                                             srclink=>$srclink,
                                             target=>$target})){
            $self->LastMsg(INFO,"bookmark '$name' is created");
         }
      }
      $msg=$self->findtemplvar({},"LASTMSG");
   }

   print($msg);
   print("</html>");
   return();
}

sub getValidWebFunctions
{
   my $self=shift;
   return("WebBookmarkCreate",$self->SUPER::getValidWebFunctions());
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/userbookmark.jpg?".$cgi->query_string());
}





1;
