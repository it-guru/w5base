package tsacinv::license;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                name          =>'licenseid',
                label         =>'LicenseID',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'"licenseid"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"status"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Licensetyp',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'label',
                label         =>'Label',
                size          =>'15',
                dataobjattr   =>'"label"'),

      new kernel::Field::TextDrop(
                name          =>'responsible',
                searchable    =>0,
                label         =>'Responsible',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'supervid',
                dataobjattr   =>'"supervid"'),



      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'"lcostcenterid"'),

      new kernel::Field::Text(
                name          =>'cocustomeroffice',
                label         =>'CO-Number/Customer Office',
                size          =>'20',
                dataobjattr   =>'"cocustomeroffice"'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                dataobjattr   =>'"bc"'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'"lassignmentid"'),

      new kernel::Field::Text(
                name          =>'lassetid',
                label         =>'AC-AssetID',
                htmldetail    =>0,
                dataobjattr   =>'"lassetid"'),

      new kernel::Field::Text(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                htmldetail    =>0,
                dataobjattr   =>'"lportfolioitemid"'),

      new kernel::Field::Text(
                name          =>'lastid',
                label         =>'lastid',
                htmldetail    =>0,
                dataobjattr   =>'"lastid"'),

      new kernel::Field::Link(
                name          =>'altbc',
                htmldetail    =>0,
                label         =>'Alternate BC',
                dataobjattr   =>'"altbc"'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software installations on',
                group         =>'software',
                vjointo       =>'tsacinv::lnksystemsoftware',
                vjoinon       =>['lastid'=>'llicense'],
                vjoindisp     =>[qw(system name version quantity)]),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                sqlorder      =>'none',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'"comments"'),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),


   );
   $self->{use_distinct}=0;
   $self->setWorktable("license");
   $self->setDefaultView(qw(licenseid name assignmentgroup));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsacinv/load/license.jpg?".$cgi->query_string());
}
         

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");

   my $MandatorCache=$self->Cache->{Mandator}->{Cache};
   my %altbc=();
   foreach my $grpid (@mandators){
      if (defined($MandatorCache->{grpid}->{$grpid})){
         my $mc=$MandatorCache->{grpid}->{$grpid};
         if (defined($mc->{additional}) &&
             ref($mc->{additional}->{acaltbc}) eq "ARRAY"){
            map({if ($_ ne ""){$altbc{$_}=1;}} @{$mc->{additional}->{acaltbc}});
         }
      }
   }
   my @altbc=keys(%altbc);

   if (!$self->IsMemberOf("admin")){
      my @wild;
      my @fix;
      if ($#altbc!=-1){
         @wild=("\"\"");
         @fix=(undef);
         foreach my $altbc (@altbc){
            if ($altbc=~m/\*/ || $altbc=~m/"/){
               push(@wild,$altbc);
            }
            else{
               push(@fix,$altbc);
            }
         }
      }
      if ($#wild==-1 && $#fix==-1){
         @fix=("NONE");
      }
      my @addflt=();
      if ($#fix!=-1){
         push(@addflt,{altbc=>\@fix});
      }
      if ($#wild!=-1){
         foreach my $wild (@wild){
            push(@addflt,{altbc=>$wild});
         }
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
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


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default software misc source));
}  


1;
