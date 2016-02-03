package base::useradvice;
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
use kernel::App::Web::Listedit;
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
                dataobjattr   =>'useradvice.id'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'Target User',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Htmlarea(
                name          =>'advicetext',
                label         =>'advice text',
                dataobjattr   =>'useradvice.advicetext'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'userid',
                dataobjattr   =>'useradvice.userid'),

      new kernel::Field::Select(
                name          =>'acknowledged',
                label         =>'acknowledge state',
                value         =>['0','1'],
                transprefix   =>'ACK.',
                dataobjattr   =>'useradvice.acknowledged'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'useradvice.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'useradvice.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'useradvice.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'useradvice.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'useradvice.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'useradvice.realeditor'),

   );
   $self->setDefaultView(qw(advicetext acknowledged cdate));
   $self->setWorktable("useradvice");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
   return();
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}

##sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/useradvice.jpg?".$cgi->query_string());
#}

sub getValidWebFunctions
{
   my $self=shift;
   return("currentAdviceList","countEntries",
          $self->SUPER::getValidWebFunctions());
}


sub currentAdviceList
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','useradvice.css'],
                           body=>1,form=>1,
                           title=>$self->T("user advices"));
   $self->setAdviceFilter();

   my $c=0;

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         printf("<div id='%s' class='advice notacknowledged' ".
                "onMouseOver='console.log(this);'>%s</div>\n",
                $rec->{id},$rec->{advicetext});
         $c++;
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }

   if ($c==0){
      print("No current messages");
   }

   print $self->HtmlBottom(body=>1,form=>1);


}


sub setAdviceFilter
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();

   $self->SetFilter({acknowledged=>0,userid=>\$userid});
   $self->SetCurrentView(qw(acknowledged mdate advicetext id));
}

sub countEntries
{
   my $self=shift;
   print $self->HttpHeader("text/xml");
   $self->setAdviceFilter();

   my $n=$self->CountRecords();

   

   printf("<root><openadvice>%d</openadvice></root>\n",$n);
}


sub isQualityCheckValid
{
   my $self=shift;

   return(0);

}








1;
