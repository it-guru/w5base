package tsacinv::appl;
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'applid',
                label         =>'ApplicationID',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amtsicustappl.code'),
                                    
      new kernel::Field::Link(
                name          =>'id',
                label         =>'ApplID',
                dataobjattr   =>'amtsicustappl.ltsicustapplid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Applicationname',
                uppersearch   =>1,
                dataobjattr   =>'amtsicustappl.name'),
                                    
      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'amtsicustappl.status'),
                                    
      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'amtsicustappl.usage'),
                                    
      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                vjointo       =>'tsacinv::customer',
                vjoinon       =>['lcustomerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lcustomerid',
                dataobjattr   =>'amtsicustappl.lcustomerlinkid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),
                                    
      new kernel::Field::TextDrop(
                name          =>'sem',
                label         =>'Service Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['semid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'amtsicustappl.lservicecontactid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm',
                label         =>'Technical Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsmid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'tsmid',
                dataobjattr   =>'amtsicustappl.ltechnicalcontactid'),
                                    
      new kernel::Field::TextDrop(
                name          =>'tsm2',
                label         =>'Deputy Technical Contact',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['tsm2id'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                dataobjattr   =>'amtsicustappl.ldeputytechnicalcontactid'),
                                    
      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amtsicustappl.lassignmentid'),
                                    
      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostid'=>'id'],
                dataobjattr   =>'amcostcenter.title'),
                                    
      new kernel::Field::TextDrop(
                name          =>'accountno',
                label         =>'Account-Number',
                size          =>'15',
                vjointo       =>'tsacinv::accountno',
                vjoinon       =>['id'=>'lapplicationid'],
                vjoindisp     =>'name'),
                                    
      new kernel::Field::Link(
                name          =>'lcostid',
                label         =>'AC-CostcenterID',
                dataobjattr   =>'amtsicustappl.lcostcenterid'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                size          =>'16',
                dataobjattr   =>'amtsicustappl.version'),
                                    
      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'amtsicustappl.description'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                label         =>'Application Maintenence Window',
                dataobjattr   =>'amtsimaint.memcomment'),

      new kernel::Field::Text(
                name          =>'altbc',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                vjointo       =>'tsacinv::lnkapplappl',
                vjoinon       =>['id'=>'lparentid'],
                vjoindisp     =>['child']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['id'=>'lparentid'],
                vjoindisp     =>['child','systemid']),

      new kernel::Field::Text(
                name          =>'srcsys',
                ignorecase    =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amtsicustappl.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amtsicustappl.externalid'),
   );
   $self->setDefaultView(qw(name applid usage conumber assignmentgroup));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amtsicustappl, ".
      "(select amcostcenter.* from amcostcenter ".
      " where amcostcenter.bdelete=0) amcostcenter,amemplgroup assigrp,".
      "amcomment amtsimaint";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amtsicustappl.bdelete=0 and ".
      "amtsicustappl.lmaintwindowid=amtsimaint.lcommentid(+) ".
      "and amtsicustappl.lcostcenterid=amcostcenter.lcostid(+) ".
      "and amtsicustappl.lassignmentid=assigrp.lgroupid(+) ";
   return($where);
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


sub schain
{
   my $self=shift;
   my $page="schain";

   my $idname=$self->IdField->Name();
   $page.=$self->HtmlPersistentVariables($idname);

   return($page);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(schain),$self->SUPER::getValidWebFunctions());
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPages($p,$rec),"schain"=>"Servicekette");
}

#sub getDefaultHtmlDetailPage
#{
#   my $self=shift;
#
#
#
#
#
#
#   return("schain");
#}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->schain($p,$rec)) if ($p eq "schain");
   return($self->SUPER::getHtmlDetailPageContent($p,$rec));
}





1;
