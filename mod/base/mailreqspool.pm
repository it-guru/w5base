package base::mailreqspool;
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
use Digest::MD5 qw(md5_base64);
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
                dataobjattr   =>'mailreqspool.id'),
                                                  
      new kernel::Field::Email(
                name          =>'fromemail',
                label         =>'From',
                dataobjattr   =>'mailreqspool.fromemail'),

      new kernel::Field::Text(
                name          =>'account',
                label         =>'Account',
                dataobjattr   =>'mailreqspool.usedaccount'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserID',
                dataobjattr   =>'mailreqspool.userid'),

      new kernel::Field::Select(
                name          =>'state',
                htmlwidth     =>'100px',
                label         =>'Request-State',
                htmleditwidth =>'50%',
                translation   =>'base::workflow',
                transprefix   =>'wfstate.',
                value         =>[qw(6 23 21)],
                readonly      =>1,
                dataobjattr   =>'mailreqspool.wfstate'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Subject',
                dataobjattr   =>'mailreqspool.subject'),

      new kernel::Field::Textarea(
                name          =>'textdata',
                label         =>'Mailtext',
                dataobjattr   =>'mailreqspool.textdata'),

      new kernel::Field::Link(
                name          =>'attachment',
                label         =>'Attachment',
                dataobjattr   =>'mailreqspool.attadata'),

      new kernel::Field::Text(
                name          =>'mailmode',
                group         =>'source',
                label         =>'Mode',
                dataobjattr   =>'mailreqspool.mailmode'),
                                                  
      new kernel::Field::Text(
                name          =>'md5sechash',
                group         =>'source',
                label         =>'MD5 Sec Hash',
                dataobjattr   =>'mailreqspool.md5sechash'),
                                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'mailreqspool.createdate'),
                                                  
      new kernel::Field::Date(
                name          =>'procdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Prozess-Date',
                dataobjattr   =>'mailreqspool.procdate'),

   );
   $self->setDefaultView(qw(linenumber cdate procdate fromemail state name));
   $self->setWorktable("mailreqspool");
   $self->LoadSubObjs("ext/MailGate","MailGate");
   return($self);
}

sub Process
{
   my $self=shift;
   my $rec=shift;
   my $answer=shift;

   foreach my $obj (values(%{$self->{MailGate}})){
      my $res=$obj->Process($self,$rec,$answer);
      return($res) if (defined($res));
   }
   $self->LastMsg(ERROR,"unknown mail request - please contact the admin");
   return(undef);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $md5sechash=trim(effVal($oldrec,$newrec,"md5sechash"));
   if ($md5sechash eq ""){
      my $s=NowStamp().$self.$$.".".int(rand(10000));
      $newrec->{md5sechash}=md5_base64($s);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(undef);
}

#sub isWriteValid
#{
#   my $self=shift;
#   my $rec=shift;
#   return("default") if ($self->IsMemberOf("admin"));
#   return(undef);
#}





1;
