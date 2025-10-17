package tsrmo::appl;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                dataobjattr   =>"id"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                ignorecase    =>1,
                label         =>'Name',
                dataobjattr   =>"name"),

      new kernel::Field::Text(
                name          =>'archivestamp',
                label         =>'Archive Stamp',
                dataobjattr   =>"archivestamp"),

      new kernel::Field::Text(
                name          =>'mandatorname',
                label         =>'Mandator name',
                dataobjattr   =>"mandatorname"),

      new kernel::Field::Text(
                name          =>'mandatorgrpname',
                label         =>'Mandator name',
                dataobjattr   =>"mandatorgrpname"),

      new kernel::Field::Text(
                name          =>'businessteam',
                label         =>'Business team',
                dataobjattr   =>"businessteam"),

      new kernel::Field::Link(
                name          =>'rawitemsummary',
                dataobjattr   =>"itemsummary"),

      new kernel::Field::XMLInterface(
                name          =>'itemsummary',
                depend        =>['rawitemsummary'],
                label         =>'total Config-Item Summary',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $d=$current->{rawitemsummary};
                   $d.=s#^\s*<struct>\s*<entry>##s;   # remote W5Warehouse 
                   $d.=s#</entry>\s*</struct>\s*$##s; # header/fooder for
                   $d=utf8($d)->latin1();             # xml data and conv to 
                                                      # latin1 for internal use
                   return($d);
                }),
   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(id name archivestamp 
                            mandatorname mandatorgrpname businessteam 
                            itemsummary));
   $self->setWorktable("applarchive");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   if (defined($self->{DB})){
      $self->{DB}->do("alter session set cursor_sharing=force");
   }
   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=1024*1024*15;    #15MB
   }

   return(1) if (defined($self->{DB}));
   return(0);
}




sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default",'contact',"results","source");
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/tssiem/load/qualys_secscan.jpg?".$cgi->query_string());
#}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         
sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL));
   return(undef);
}

         



1;
