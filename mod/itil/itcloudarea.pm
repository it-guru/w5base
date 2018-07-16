package itil::itcloudarea;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'qitcloudarea.id'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full qualified cloud area',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                htmlwidth     =>'280px',
                dataobjattr   =>"concat(itcloud.fullname,'.',".
                                "qitcloudarea.name)"),

      new kernel::Field::TextDrop(
                name          =>'cloud',
                htmlwidth     =>'150px',
                label         =>'Cloud',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::itcloud',
                vjoinon       =>['cloudid'=>'id'],
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      my $itcloudid=$rec->{"cloudid"};
                      if ($self->getParent->isWriteOnITCloudValid($itcloudid,
                           "default")){
                         return(0);
                      }
                   }
                   return(1) if (defined($rec));
                   return(0);
                },
                label         =>'cloud area name',
                dataobjattr   =>'qitcloudarea.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'qitcloudarea.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      my $itcloudid=$rec->{"cloudid"};
                      if ($rec->{cistatusid}!=4){
                         if ($self->getParent->isWriteOnITCloudValid($itcloudid,
                             "default")){
                            return(0);
                         }
                      }
                   }
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::appl',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'applid',
                selectfix     =>1,
                dataobjattr   =>'qitcloudarea.appl'),

      new kernel::Field::Textarea(
                name          =>'description',
                searchable    =>0,
                label         =>'Cloud Area description',
                dataobjattr   =>'qitcloudarea.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'qitcloudarea.comments'),

      new kernel::Field::Text(
                name          =>'conumber',
                translation   =>'itil::appl',
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                group         =>'appl',
                readonly     =>1,
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qitcloudarea.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'qitcloudarea.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'qitcloudarea.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'qitcloudarea.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'qitcloudarea.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"qitcloudarea.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(qitcloudarea.id,35,'0')"),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qitcloudarea.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qitcloudarea.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'qitcloudarea.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'qitcloudarea.realeditor'),

      new kernel::Field::Select(
                name          =>'cloudcistatus',
                readonly      =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                group         =>'cloudinfo',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itcloudcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'itcloudcistatusid',
                label         =>'Cloud CI-State',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.cistatus'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Mandator ID of Cluster',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.mandator'),

      new kernel::Field::Interface(
                name          =>'cloudid',
                selectfix     =>1,
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'W5Base Cloud ID',
                dataobjattr   =>'qitcloudarea.itcloud'),

   );
   $self->setDefaultView(qw(fullname appl conumber  cdate));
   $self->setWorktable("itcloudarea");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/itcloudarea.jpg?".$cgi->query_string());
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



         

sub getSqlFrom
{
   my $self=shift;
   my $from="itcloudarea qitcloudarea  ".
            "left outer join itcloud ".
            "on qitcloudarea.itcloud=itcloud.id ".
            "left outer join appl ".
            "on qitcloudarea.appl=appl.id";
   return($from);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
}

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $itcloudid=effVal($oldrec,$newrec,"cloudid");
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if (!$self->isWriteOnITCloudValid($itcloudid,"areas")){
            $self->LastMsg(ERROR,"no write access to specified cloud");
            return(undef);
         }
      }
   }
   my $applid=effVal($oldrec,$newrec,"applid");
   if ($applid eq ""){
      $self->LastMsg(ERROR,"no valid application specified");
      return(0);
   }
   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" || haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid cloud area name");
      return(0);
   }

   if (!defined($oldrec) || effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}==4){
         my $c=getModuleObject($self->Config,"itil::itcloud");
         $c->SetFilter({id=>$itcloudid});
         my ($crec,$msg)=$c->getOnlyFirst(qw(cistatusid));
         my $itcloudcistatusid;
         if (defined($crec)){
            $itcloudcistatusid=$crec->{cistatusid};
         }
         if ($itcloudcistatusid!=4){
            $self->LastMsg(ERROR,"cloud is not active");
            return(0);
         }
         if (!$self->isWriteOnApplValid($applid,"default")){
            $self->LastMsg(ERROR,"activation of cloudarea only allowed ".
                                 "for application writeables");
            return(0);
         }
      }
   }
   if (effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}==6){
         if (!$self->isWriteOnITCloudValid($itcloudid,"default")){
            $self->LastMsg(ERROR,"mark as wasted only allowed ".
                                 "for cloud writeables");
            return(0);
         }
      }
      if ($newrec->{cistatusid}<3){
         if (!$self->isWriteOnITCloudValid($itcloudid,"default")){
            $self->LastMsg(ERROR,"CI-Status not allowed to set");
            return(0);
         }
      }
   }

   



   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return("default") if (!defined($oldrec));

   my $itcloudid=$oldrec->{"cloudid"};
   my $applid=$oldrec->{"applid"};
   if ($self->isWriteOnITCloudValid($itcloudid,"default") ||
       $self->isWriteOnApplValid($applid,"default")){
      return("default");
   }
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default appl inm 
             misc control source));
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   if ($lock>0 ||
       $#{$rec->{swinstances}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no ".
          "software instance relations");
      return(0);
   }

   return(1);
}









1;