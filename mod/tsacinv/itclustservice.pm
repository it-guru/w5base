package tsacinv::itclustservice;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Clusterservice fullname',
                searchable    =>1,
                uppersearch   =>1,
                htmldetail    =>0,
                htmlwidth     =>'250px',
                align         =>'left',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Clusterservice name',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Clusterservice type',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"type"'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'"description"'),

      new kernel::Field::Id(
                name          =>'serviceid',
                label         =>'ClusterserviceID',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'"serviceid"'),

      new kernel::Field::Id(
                name          =>'clusterid',
                label         =>'ClusterID',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                weblinkto     =>'tsacinv::itclust',
                weblinkon     =>['clusterid'=>'clusterid'],
                align         =>'left',
                dataobjattr   =>'"clusterid"'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisor',
                label         =>'Assignment Group Supervisor',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisor'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisoremail',
                label         =>'Assignment Group Supervisor E-Mail',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisoremail'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'"lassignmentid"'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'"lincidentagid"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"status"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'"usage"'),

      new kernel::Field::Boolean(
                name          =>'soxrelevant',
                label         =>'SOX relevant',
                dataobjattr   =>'"soxrelevant"'),

      new kernel::Field::Link(
                name          =>'lclusterid',
                label         =>'AC-PortfolioID',
                dataobjattr   =>'"lclusterid"'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'ComputerID',
                dataobjattr   =>'"lcomputerid"'),

      new kernel::Field::SubList(
                name          =>'backups',
                label         =>'ordered backup jobs',
                group         =>'backups',
                forwardSearch =>1,
                vjointo       =>'tsacinv::backup',
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>[qw(backupid stype subtype name
                                    dbinstance policy tfrom tto isactive)]),

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
   $self->setWorktable("itclustservice");
   $self->setDefaultView(qw(fullname clusterid status assignmentgroup));
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default systems backups source));
}  


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportSystem));
}  

sub ImportSystem
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"AssetManager System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


   

sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   if ($param->{importname} ne ""){
      $flt={clusterid=>[$param->{importname}]};
   }
   else{
      return(undef);
   }
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(clusterid name lassignmentid assetid));
   if ($#l==-1){
      $self->LastMsg(ERROR,"ClusterID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"ClusterID not unique in AssetManager");
      return(undef);
   }

   my $sysrec=$l[0];
   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter($flt);
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5sysrec)){
      if ($w5sysrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"ClusterID already exists in W5Base");
         return(undef);
      }
      $identifyby=$sys->ValidatedUpdateRecord($w5sysrec,{cistatusid=>4},
                                              {id=>\$w5sysrec->{id}});
   }
   else{
      # check 1: Assigmenen Group registered
      if ($sysrec->{lassignmentid} eq ""){
         $self->LastMsg(ERROR,"ClusterID has no Assignment Group");
         return(undef);
      }
      #printf STDERR Dumper($sysrec);
      # check 2: Assignment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      # check 3: Supervisor registered
      if ($acgrouprec->{supervisorldapid} eq "" &&
          $acgrouprec->{supervisoremail} eq ""){
         $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
         return(undef);
      }
      my $importname=$acgrouprec->{supervisorldapid};
      $importname=$acgrouprec->{supervisoremail} if ($importname eq "");
      # check 4: load Supervisor ID in W5Base
      my $user=getModuleObject($self->Config,"base::user");
      my $databossid=$user->GetW5BaseUserID($importname,"email");
      if (!defined($databossid)){
         $self->LastMsg(ERROR,"Can't import Supervisor as Databoss");
         return(undef);
      }
      # check 5: find id of mandator "extern"
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->SetFilter({name=>"extern"});
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (!defined($mandrec)){
         $self->LastMsg(ERROR,"Can't find mandator extern");
         return(undef);
      }
      my $mandatorid=$mandrec->{grpid};
      # final: do the insert operation
      my $newrec={name=>$sysrec->{clustername},
                  clusterid=>$sysrec->{clusterid},
                  admid=>$databossid,
                  allowifupdate=>1,
                  mandatorid=>$mandatorid,
                  cistatusid=>4};
      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $sys->ResetFilter();
      $sys->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($sys);
         $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}





1;
