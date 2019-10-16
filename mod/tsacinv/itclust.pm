package tsacinv::itclust;
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
                label         =>'Cluster fullname',
                searchable    =>1,
                uppersearch   =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                align         =>'left',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Clustername',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"name"'),

      new kernel::Field::Id(
                name          =>'clusterid',
                label         =>'ClusterID',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'"clusterid"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"status"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'"usage"'),

      new kernel::Field::Text(
                name          =>'clustertype',
                label         =>'Clustertype',
                uppersearch   =>1,
                dataobjattr   =>'"clustertype"'),

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
                searchable    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisor'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisoremail',
                label         =>'Assignment Group Supervisor E-Mail',
                htmldetail    =>0,
                searchable    =>0,
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

#      new kernel::Field::Text(
#                name          =>'type',
#                label         =>'Type',
#                dataobjattr   =>'amcomputer.computertype'),

      new kernel::Field::Boolean(
                name          =>'soxrelevant',
                label         =>'SOX relevant',
                dataobjattr   =>'"soxrelevant"'),

      new kernel::Field::Text(
                name          =>'lclusterid',
                label         =>'AC-ClusterID',
                dataobjattr   =>'"lclusterid"'),

      new kernel::Field::Link(
                name          =>'lportfolio',
                label         =>'AC-PortfolioID',
                dataobjattr   =>'"lportfolio"'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lclusterid'=>'lclusterid'],
                vjoindisp     =>[qw(systemname systemid status)]),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Services',
                group         =>'services',
                vjointo       =>'tsacinv::itclustservice',
                vjoinon       =>['lclusterid'=>'lclusterid'],
                vjoindisp     =>[qw(fullname type)],
                vjoininhash   =>[qw(serviceid status name description)]),

      new kernel::Field::SubList(
                name          =>'notassignedbackups',
                label         =>'not assignable backup jobs',
                group         =>'notassignedbackups',
                forwardSearch =>1,
                vjointo       =>'tsacinv::backup',
                vjoinon       =>['lclusterid'=>'lcomputerid'],
                vjoindisp     =>[qw(backupid stype subtype name
                                    dbinstance policy tfrom tto isactive)]),

      new kernel::Field::Link(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                dataobjattr   =>'"lportfolioitemid"'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'LocationID',
                dataobjattr   =>'"locationid"'),

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
   $self->setWorktable("itclust");
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

sub initSearchQuery
{
   my $self=shift;
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
   return('ALL');
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
   return(qw(header default services systems notassignedbackups source));
}  


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportCluster));
}  

sub ImportCluster
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"cluster has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"AssetManager Cluster Import");
   print $self->getParsedTemplate("tmpl/minitool.cluster.import",{});
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
   my @l=$self->getHashList(qw(ALL));
   if ($#l==-1){
      $self->LastMsg(ERROR,"ClusterID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"ClusterID not unique in AssetManager");
      return(undef);
   }

   my $clustrec=$l[0];

   my $itclust=getModuleObject($self->Config,"itil::itclust");
   $itclust->SetFilter($flt);
   my ($w5clustrec,$msg)=$itclust->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5clustrec)){
      if ($w5clustrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"ClusterID already exists in W5Base");
         return(undef);
      }

      my %newrec=(cistatusid=>4);
      my $userid;

      if ($self->isDataInputFromUserFrontend() &&
          !$self->IsMemberOf("admin")) {
         $userid=$self->getCurrentUserId();
         $newrec{databossid}=$userid;
      }

      if ($itclust->ValidatedUpdateRecord($w5clustrec,\%newrec,
                                      {id=>\$w5clustrec->{id}})) {
         $identifyby=$w5clustrec->{id};
      }
   }
   else{


      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->SetFilter({cistatusid=>\'4',name=>"extern"});
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (!defined($mandrec)){
         $self->LastMsg(ERROR,"Can't find mandator extern");
         return(undef);
      }
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
      my $mandatorid=$mandrec->{grpid};
      if ($#mandators!=-1){
         $mand->ResetFilter();
         $mand->SetFilter({cistatusid=>\'4',grpid=>\@mandators});
         my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
         if (defined($mandrec)){
            $mandatorid=$mandrec->{grpid};
         }
      }
      my $newrec={name=>$clustrec->{name},
                  clusterid=>$clustrec->{clusterid},
                  clusttyp=>"OS",
                  comments=>$clustrec->{usage},
                  allowifupdate=>1,
                  mandatorid=>$mandatorid,
                  cistatusid=>4};
      $identifyby=$itclust->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $itclust->ResetFilter();
      $itclust->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$itclust->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($itclust);
         $qc->nativQualityCheck($itclust->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}





1;
