package itil::lnkmgmtitemgroup;
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
                label         =>'LinkID',
                group         =>'source',
                dataobjattr   =>'lnkmgmtitemgroup.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'RelationName',
                group         =>'source',
                searchable    =>'0',
                htmldetail    =>'0',
                dataobjattr   =>"concat(mgmtitemgroup.name,' -> ',".
                                "if (location.id is not null,".
                                     "location.name,".
                                "if (appl.id is not null,".
                                     "appl.name,".
                                "if (businessservice.id is not null,".
                                     "businessservice.name,NULL))))"),

      new kernel::Field::TextDrop(
                name          =>'mgmtitemgroup',
                htmlwidth     =>'250px',
                label         =>'managed item group',
                vjoineditbase =>{'cistatusid'=>"<5"},
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                vjointo       =>'itil::mgmtitemgroup',
                vjoinon       =>['mgmtitemgroupid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'mgmtitemgroupcistatus',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'managed group CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['mgmtitemgroupcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'mgmtitemgroupcistatusid',
                label         =>'manged group CI-State ID',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'mgmtitemgroup.cistatus'),

      new kernel::Field::Interface(
                name          =>'grouptype',
                label         =>'Raw Grouptype',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'mgmtitemgroup.grouptype'),

      new kernel::Field::Interface(
                name          =>'mgmtitemgroupid',
                label         =>'managed item group ID',
                dataobjattr   =>'lnkmgmtitemgroup.mgmtitemgroup'),

      new kernel::Field::Date(
                name          =>'lnkfrom',
                label         =>'relation from',
                dataobjattr   =>'lnkmgmtitemgroup.lnkfrom'),

      new kernel::Field::Date(
                name          =>'lnkto',
                label         =>'relation to',
                dataobjattr   =>'lnkmgmtitemgroup.lnkto'),

      new kernel::Field::TextDrop(
                 name          =>'appl',
                 htmlwidth     =>'150px',
                 label         =>'Application',
                 htmldetail    =>'NotEmpty',
                 vjointo       =>'itil::appl',
                 vjoineditbase =>{'cistatusid'=>"4"},
                 SoftValidate  =>1,
                 vjoinon       =>['applid'=>'id'],
                 vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'applid',
                label         =>'Application ID',
                dataobjattr   =>'lnkmgmtitemgroup.appl'),

      new kernel::Field::TextDrop(
                 name          =>'location',
                 htmlwidth     =>'150px',
                 htmldetail    =>'NotEmpty',
                 label         =>'Location',
                 vjointo       =>'base::location',
                 vjoineditbase =>{'cistatusid'=>"4"},
                 SoftValidate  =>1,
                 vjoinon       =>['locationid'=>'id'],
                 vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'locationid',
                label         =>'Location ID',
                dataobjattr   =>'lnkmgmtitemgroup.location'),

      new kernel::Field::TextDrop(
                 name          =>'businessservice',
                 htmlwidth     =>'150px',
                 htmldetail    =>'NotEmpty',
                 label         =>'Businessservice',
                 vjointo       =>'itil::businessservice',
                 vjoineditbase =>{'cistatusid'=>"<=5"},
                 SoftValidate  =>1,
                 vjoinon       =>['businessserviceid'=>'id'],
                 vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'businessserviceid',
                label         =>'Businessservice ID',
                dataobjattr   =>'lnkmgmtitemgroup.businessservice'),

      new kernel::Field::Import($self,
                vjointo       =>'itil::mgmtitemgroup',
                vjoinon       =>['mgmtitemgroupid'=>'id'],
                group         =>"groupdetails",
                readonly      =>1,
                fields        =>['grouptype']),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkmgmtitemgroup.comments'),

      new kernel::Field::Date(
                name          =>'notify1on',
                group         =>'notifications',
                uploadable    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                label         =>'Notification 1 (on)',
                dataobjattr   =>'lnkmgmtitemgroup.notify1on'),

      new kernel::Field::Date(
                name          =>'notify1off',
                group         =>'notifications',
                uploadable    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                label         =>'Notification 1 (off)',
                dataobjattr   =>'lnkmgmtitemgroup.notify1off'),

      new kernel::Field::Date(
                name          =>'rlnkto',
                group         =>'notifications',
                uploadable    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                label         =>'retracted lnkto',
                dataobjattr   =>'lnkmgmtitemgroup.rlnkto'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkmgmtitemgroup.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkmgmtitemgroup.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkmgmtitemgroup.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkmgmtitemgroup.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkmgmtitemgroup.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkmgmtitemgroup.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkmgmtitemgroup.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkmgmtitemgroup.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkmgmtitemgroup.modifydate'),
                                                   
      new kernel::Field::Date(
                name          =>'cimdate',
                group         =>'source',
                selectfix     =>1,
                label         =>'linked CI Modification-Date',
                dataobjattr   =>"if (location.id is not null,".
                                     "location.modifydate,".
                                "if (appl.id is not null,".
                                     "appl.modifydate,".
                                "if (businessservice.id is not null,".
                                     "businessservice.modifydate,NULL)))"),

      new kernel::Field::Select(
                name          =>'cicistatus',
                htmleditwidth =>'40%',
                group         =>'source',
                label         =>'linked CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cicistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cicistatusid',
                label         =>'linked CI-StateID',
                group         =>'source',
                dataobjattr   =>"if (location.id is not null,".
                                     "location.cistatus,".
                                "if (appl.id is not null,".
                                     "appl.cistatus,".
                                "if (businessservice.id is not null,".
                                     "businessservice.cistatus,NULL)))"),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkmgmtitemgroup.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkmgmtitemgroup.realeditor')
   );

   $self->{history}={
      insert=>[
         'local'
      ],
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>'itil::mgmtitemgroup', id=>'mgmtitemgroupid',
          field=>'fullname',as=>'relation'}
      ]
   };

   $self->setDefaultView(qw(mgmtitemgroup from to appl businessservice 
                            businessprocess location cdate));
   $self->setWorktable("lnkmgmtitemgroup");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_lnkfrom"))){
     Query->Param("search_lnkfrom"=>
                  "<now");
   }
   if (!defined(Query->Param("search_lnkto"))){
     Query->Param("search_lnkto"=>
                  ">now OR [LEER]");
   }
   if (!defined(Query->Param("search_mgmtitemgroupcistatus"))){
     Query->Param("search_mgmtitemgroupcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lickey.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkmgmtitemgroup left outer join ".
            "mgmtitemgroup on lnkmgmtitemgroup.mgmtitemgroup=mgmtitemgroup.id ".
            "left outer join appl ".
               "on lnkmgmtitemgroup.appl=appl.id ".
            "left outer join businessservice ".
               "on lnkmgmtitemgroup.businessservice=businessservice.id ".
            "left outer join location ".
               "on lnkmgmtitemgroup.location=location.id";
   return($from);
}

sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default groupdetails notifications source));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $lnkcount=0;
   foreach my $idfield (qw(applid locationid businessserviceid)){
      $lnkcount++ if (effVal($oldrec,$newrec,$idfield) ne "");
   }
   if ($lnkcount==0){
      $self->LastMsg(ERROR,"no relation target specified");
      return(undef);
   }
   if ($lnkcount>1){
      $self->LastMsg(ERROR,"only one relation target allowed");
      return(undef);
   }
   if (effVal($oldrec,$newrec,"lnkfrom") eq ""){
      $newrec->{lnkfrom}=$self->ExpandTimeExpression("now+28d");
   }


   my $timelimit=7;
   my $mgmtitemgroupid=effVal($oldrec,$newrec,"mgmtitemgroupid");

   my $o=getModuleObject($self->Config,"itil::mgmtitemgroup");
   $o->SetFilter({id=>\$mgmtitemgroupid});
   my ($grec)=$o->getOnlyFirst(qw(grouptype));
   if (!defined($grec)){
      $self->LastMsg(ERROR,"invalid mgmtitemgroup id");
      return(undef);
   }
   if ($grec->{grouptype} eq "RLABEL"){
      $timelimit=0;
   }

   my $from=effVal($oldrec,$newrec,"lnkfrom");
   my $to=effVal($oldrec,$newrec,"lnkto");

   

   if ($to ne ""){
      my $d=CalcDateDuration($from,$to);
      if ($d->{totalminutes}<0){
         $self->LastMsg(ERROR,"to must be behind from");
         return(undef);
      }
      if (!$self->IsMemberOf("admin")){
         if (effChanged($oldrec,$newrec,"lnkto")){
            my $d=CalcDateDuration(NowStamp("en"),$to);
            if ($d->{totaldays}<$timelimit){
               $self->LastMsg(ERROR,"to must be at least %d days ".
                                    "in the future",$timelimit);
               return(undef);
            }
         }
      }
   }
   if (!$self->IsMemberOf("admin")){
      if (effChanged($oldrec,$newrec,"lnkfrom")){
         my $d=CalcDateDuration(NowStamp("en"),$from);
         if ($d->{totaldays}<$timelimit){
            $self->LastMsg(ERROR,"from must be at least %d days in the future",
                                 $timelimit);
            return(undef);
         }
      }
   }
   if (effChanged($oldrec,$newrec,"mgmtitemgroupid")){
      if (!$self->isParentWriteable(effVal($oldrec,$newrec,"mgmtitemgroupid"))){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
   }

   if (effChanged($oldrec,$newrec,"lnkfrom")) {
      $newrec->{notify1on}=undef;
   }   
   if (effChanged($oldrec,$newrec,"lnkto")) {
      if (!defined $newrec->{lnkto} &&
           defined $oldrec->{notify1off}) {
         $newrec->{rlnkto}=$oldrec->{lnkto};
      }
      $newrec->{notify1off}=undef;
   }   

   return(1);
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
   my $oldrec=shift;
   my $newrec=shift;


   return("default") if (!defined($oldrec) && !defined($newrec));

   if ($self->isParentWriteable(effVal($oldrec,$newrec,"mgmtitemgroupid"))){
      return("default");
   }
   return(undef);
}

sub isParentWriteable
{
   my $self=shift;
   my $parentid=shift;

   if ($parentid ne ""){
      my $o=getModuleObject($self->Config,"itil::mgmtitemgroup");
      $o->SetFilter({id=>\$parentid});
      my ($aclrec,$msg)=$o->getOnlyFirst(qw(ALL));
      my @l=$o->isWriteValid($aclrec);
      if (in_array(\@l,"comments")){
         return(1);
      }
   }
   return(0);

}


sub DailyProcess
{
   my $self=shift;

   msg(INFO,"running Daily Process in itil::lnkmgmtitemgroup");

   $self->ResetFilter();
   $self->SetFilter({
      cicistatusid=>'>5',
      cimdate=>"<now-28d",
      lnkto=>'[EMPTY]'
   });
   foreach my $rec ($self->getHashList(qw(ALL))){
      my $op=$self->Clone();
      my $newlnkto=$self->ExpandTimeExpression("now+90d");
      $op->ValidatedUpdateRecord($rec,{
         lnkto=>$newlnkto,
         mdate=>NowStamp("en")
      },{id=>\$rec->{id}}); 
   }

   $self->ResetFilter();

   $self->SetFilter({
      cicistatusid=>'>5',
      lnkto=>'<now-90d'
   });
   foreach my $rec ($self->getHashList(qw(ALL))){
      my $op=$self->Clone();
      $op->ValidatedDeleteRecord($rec);
   }


   return(1);

}





1;
