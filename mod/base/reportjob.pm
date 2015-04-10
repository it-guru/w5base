package base::reportjob;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use DateTime::TimeZone;
use Text::ParseWords;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'Report JobID',
                group         =>'source',
                sqlorder      =>'none',
                dataobjattr   =>'reportjob.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Report name',
                dataobjattr   =>'reportjob.reportname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0"},
                vjoindisp     =>'name'),

      new kernel::Field::Textarea(
                name          =>'textdata',
                group         =>'data',
                label         =>'Data',
                dataobjattr   =>'reportjob.comments'),

      new kernel::Field::Number(
                name          =>'textdatalines',
                group         =>'data',
                label         =>'Data Lines',
                depend        =>['textdata'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $tmp=$current->{textdata};
                   my $nr_of_lines = $tmp =~ tr/\n//; 
                   return($nr_of_lines);
                }),

      new kernel::Field::Date(
                name          =>'validto',
                group         =>'data',
                label         =>'Data valid to',
                dataobjattr   =>'reportjob.validto'),

      new kernel::Field::XMLInterface(
                name          =>'deltabuffer',
                label         =>'XML Data',
                dataobjattr   =>'reportjob.deltabuffer'),

      new kernel::Field::Textarea(
                name          =>'errbuffer',
                group         =>'error',
                label         =>'ERRORs',
                dataobjattr   =>'reportjob.errbuffer'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'reportjob.cistatus'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'reportjob.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'reportjob.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'reportjob.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'reportjob.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'reportjob.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'reportjob.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'reportjob.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'reportjob.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'reportjob.realeditor'),


                                  
   );
   $self->setDefaultView(qw(targetfile name cdate));
   $self->setWorktable("reportjob");
   $self->LoadSubObjs("Reporter","Reporter");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","data","error","wffieldsfilter","source");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" || $name=~m/^\s$/){
      $self->LastMsg(ERROR,"invalid report name '\%s' specified",
                     $name);
      return(undef);
   }
   if (!defined($oldrec)){
      $newrec->{cistatusid}=4 if (!exists($newrec->{cistatusid}));
      if (!exists($newrec->{validto})){
         $newrec->{validto}=$self->ExpandTimeExpression("now+7d"); 
      }
   }
   if (exists($newrec->{errbuffer}) && $newrec->{errbuffer} ne ""){
      delete($newrec->{textbuffer});
   }
   return(1);
}


sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   if (defined($oldrec)){
      if (effChanged($oldrec,$newrec,"textdata") &&
          effVal($oldrec,$newrec,"errbuffer") eq ""){ 
         my $name=effVal($oldrec,$newrec,"name");
         my $id=effVal($oldrec,$newrec,"id");
         my $emailto={};
         my $ia=getModuleObject($self->Config,"base::infoabo");
         my $user=getModuleObject($self->Config,"base::user");
         $ia->LoadTargets($emailto,'*::reportjob',\'valuechange',$id);
         my $wa=getModuleObject($self->Config,"base::workflowaction");
         my %msg;
         foreach my $k (keys(%$emailto)){
            my $lang="en";
            $user->ResetFilter();
            $user->SetFilter({allemail=>\$k});
            my ($urec)=$user->getOnlyFirst(qw(lastlang));
            if (defined($urec) && $urec->{lastlang} ne ""){
               $lang=$urec->{lastlang};
            }
            $ENV{HTTP_FORCE_LANGUAGE}=$lang;
            my $reporter=effVal($oldrec,$newrec,"srcsys");
            if (!exists($msg{$lang})){
               $msg{$lang}=
                  $self->{Reporter}->{$reporter}->onChange($oldrec,$newrec);
            }
            my $msg=$msg{$lang};
            if ($msg ne ""){
               $wa->Notify("INFO","ReportChanged: ".$name,$msg,emailto=>$k);
            }
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
      }
   }
   return($bak);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));

   my $viewok=1;
   if ($rec->{srcsys} ne "" &&
       exists($self->{Reporter}->{$rec->{srcsys}})){
      $viewok=$self->{Reporter}->{$rec->{srcsys}}->isViewValid($self,$rec);
   }
   return() if (!$viewok);

   if ($rec->{errbuffer} ne ""){
      return("header","default","data","error","source");
   }
   return("header","default","data","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/reportjob.jpg?".$cgi->query_string());
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);  # only jobs are allowed to write to this table
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}





1;
