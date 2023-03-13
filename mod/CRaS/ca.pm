package CRaS::ca;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'CRaSca.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'150px',
                label         =>'Name',
                dataobjattr   =>'CRaSca.name'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'150px',
                label         =>'Name',
                dataobjattr   =>'CRaSca.name'),

      new kernel::Field::Select(
                name          =>'sprocess',
                htmlwidth     =>'150px',
                label         =>'sign process',
                value         =>['STEAM','INTERNAL'],
                transprefix   =>'SP.', 
                dataobjattr   =>'CRaSca.signprocess'),

      new kernel::Field::Boolean(
                name          =>'isdefault',
                htmlwidth     =>'150px',
                label         =>'Default',
                dataobjattr   =>'CRaSca.isdefault'),

      new kernel::Field::Text(
                name          =>'valid_cn',
                htmlwidth     =>'150px',
                label         =>'CN regex',
                dataobjattr   =>'CRaSca.valid_cn'),

      new kernel::Field::Text(
                name          =>'valid_c',
                htmlwidth     =>'150px',
                label         =>'C regex',
                dataobjattr   =>'CRaSca.valid_c'),

      new kernel::Field::Text(
                name          =>'valid_o',
                htmlwidth     =>'150px',
                label         =>'O regex',
                dataobjattr   =>'CRaSca.valid_o'),

      new kernel::Field::Text(
                name          =>'valid_st',
                htmlwidth     =>'150px',
                label         =>'ST regex',
                dataobjattr   =>'CRaSca.valid_st'),

      new kernel::Field::Text(
                name          =>'valid_l',
                htmlwidth     =>'150px',
                label         =>'L regex',
                dataobjattr   =>'CRaSca.valid_l'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'CRaSca.comments'),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'CRaSca.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'CRaSca.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"CRaSca.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(CRaSca.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'CRaSca.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'CRaSca.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'CRaSca.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'CRaSca.realeditor'),
   

   );
   $self->setDefaultView(qw(name id cdate mdate));
   $self->setWorktable("CRaSca");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
#}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }

   if (effVal($oldrec,$newrec,"isdefault") ne "1"){
      $newrec->{isdefault}=undef;
      if (defined($oldrec) && !$oldrec->{isdefault}){
         delete($newrec->{isdefault});
      }
   }
   return(1);
}



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
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




1;
