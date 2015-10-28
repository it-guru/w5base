package tshpsa::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'ItemID',
                dataobjattr   =>"item_id"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                lowersearch   =>1,
                label         =>'Hostname',
                dataobjattr   =>'hostname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'primaryip',
                label         =>'primary IP',
                dataobjattr   =>'pip'),

      new kernel::Field::SubList(
                name          =>'swps',
                label         =>'running Software-Processes',
                group         =>'swps',
                vjointo       =>'tshpsa::lnkswp',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>[qw(softwarename version uname path)]),

      new kernel::Field::Text(
                name          =>'w5appl',
                label         =>'W5Base Applications',
                group         =>'w5basedata',
                searchable    =>0,
                weblinkto     =>'none',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['applicationnames']),

      new kernel::Field::Link(
                name          =>'w5systemid',
                label         =>'W5BaseID of relevant System',
                group         =>'w5basedata',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'id'),

      new kernel::Field::Text(
                name          =>'w5systemname',
                label         =>'relevant logical System Config-Item',
                group         =>'w5basedata',
                searchable    =>0,
                vjointo       =>'AL_TCom::system',
                vjoinon       =>['w5systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'curdate'),

#      new kernel::Field::Textarea(
#                name          =>'rawscan',
#                group         =>'source',
#                htmldetail    =>0,
#                sqlorder      =>'NONE',
#                label         =>'raw Scan-Data',
#                dataobjattr   =>"rawscan")
   );
   $self->setWorktable("HPSA_system");
   $self->setDefaultView(qw(name systemid primaryip mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","swps","sysgrps","w5basedata","source");
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(name systemid primaryip swps));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
#         my %e=(
#            section=>'SYSTEMNAME',
#            scanname=>$rec->{name}, 
#            quality=>-50     # relativ schlecht verlässlich
#         );
#         push(@res,\%e);
         foreach my $swp (@{$rec->{swps}}){
            my %e=(
               section=>'SOFTWARE',
               scanname=>$swp->{softwarename},
               scanextra1=>$swp->{path},
               scanextra2=>$swp->{version},
               quality=>10,    # relativ gut verlässlich
               processable=>1
            );
            push(@res,\%e);
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}
         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
