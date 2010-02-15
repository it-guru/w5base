package itil::lnkapplitclust;
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
                dataobjattr   =>'qlnkapplitclust.id'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full qualified Servicename',
                readonly      =>1,
                htmlwidth     =>'250px',
                dataobjattr   =>
             "concat(itclust.fullname,'.',qlnkapplitclust.itsvcname,if (qlnkapplitclust.subitsvcname<>'',concat('.',qlnkapplitclust.subitsvcname),''))"),

      new kernel::Field::TextDrop(
                name          =>'cluster',
                htmlwidth     =>'150px',
                label         =>'Cluster',
                vjointo       =>'itil::itclust',
                vjoinon       =>['clustid'=>'id'],
                vjoineditbase =>{'cistatusid'=>[1,2,3,4]},
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Servicename',
                dataobjattr   =>'qlnkapplitclust.itsvcname'),

      new kernel::Field::Text(
                name          =>'subname',
                htmldetail    =>0,
                htmleditwidth =>'50px',
                label         =>'sub Servicename',
                dataobjattr   =>'qlnkapplitclust.subitsvcname'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'qlnkapplitclust.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qlnkapplitclust.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'qlnkapplitclust.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'qlnkapplitclust.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'qlnkapplitclust.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'qlnkapplitclust.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qlnkapplitclust.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qlnkapplitclust.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'qlnkapplitclust.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'qlnkapplitclust.realeditor'),

      new kernel::Field::Select(
                name          =>'clustcistatus',
                readonly      =>1,
                htmlwidth     =>'100px',
                group         =>'clustinfo',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itclustcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'itclustcistatusid',
                label         =>'Cluster CI-State',
                readonly      =>1,
                group         =>'clustinfo',
                dataobjattr   =>'itclust.cistatus'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'applinfo',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                htmlwidth     =>'100px',
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'applconumber',
                htmlwidth     =>'100px',
                group         =>'applinfo',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Application costcenter',
                dataobjattr   =>'appl.conumber'),
                                                   
      new kernel::Field::Link(
                name          =>'tsmid',
                label         =>'TSM ID',
                readonly      =>1,
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'appldatabossid',
                label         =>'Databosss ID',
                readonly      =>1,
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Contact(
                name          =>'appldataboss',
                group         =>'applinfo',
                label         =>'Databoss',
                translation   =>'itil::appl',
                readonly      =>1,
                vjoinon       =>'appldatabossid'),

      new kernel::Field::Contact(
                name          =>'tsm',
                group         =>'applinfo',
                label         =>'Technical Solution Manager',
                readonly      =>1,
                vjoinon       =>'tsmid'),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'applinfo',
                label         =>'Technical Solution Manager E-Mail',
                htmlwidth     =>'280px',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                label         =>'TSM ID',
                readonly      =>1,
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::TextDrop(
                name          =>'tsm2',
                group         =>'applinfo',
                label         =>'Deputy Technical Solution Manager',
                translation   =>'itil::appl',
                htmlwidth     =>'280px',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'applinfo',
                label         =>'deputy Technical Solution Manager E-Mail',
                htmlwidth     =>'280px',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                label         =>'Businessteam ID',
                readonly      =>1,
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::Group(
                name          =>'businessteam',
                readonly      =>1,
                group         =>'applinfo',
                translation   =>'itil::appl',
                label         =>'Business Team',
                vjoinon       =>'businessteamid'),

      new kernel::Field::Group(
                name          =>'businessdepart',
                label         =>'Business Department',
                readonly      =>1,
                translation   =>'itil::appl',
                group         =>'applinfo',
                vjoinon       =>'businessdepartid'),

      new kernel::Field::Link(
                name          =>'businessdepartid',
                label         =>'Businessdepartment ID',
                readonly      =>1,
                translation   =>'itil::appl',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'businessdepartid'),

      new kernel::Field::Group(
                name          =>'applcustomer',
                label         =>'Application Customer',
                readonly      =>1,
                translation   =>'itil::lnkapplsystem',
                group         =>'applinfo',
                vjoinon       =>'customerid'),

      new kernel::Field::Text(
                name          =>'applcustomerprio',
                label         =>'Customers Application Prioritiy',
                translation   =>'itil::appl',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'applcriticality',
                group         =>'applinfo',
                label         =>'Criticality',
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                readonly      =>1,
                translation   =>'itil::appl',
                dataobjattr   =>'appl.criticality'),


      new kernel::Field::Text(
                name          =>'oncallphones',
                searchable    =>0,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                htmlwidth     =>'150px',
                group         =>'applinfo',
                translation   =>'itil::appl',
                weblinkto     =>'none',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['applid'=>'refid'], 
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>'phonenumber'),


      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Text(
                name          =>'applid',
                htmldetail    =>0,
                label         =>'W5Base Application ID',
                dataobjattr   =>'qlnkapplitclust.appl'),
                                                   
      new kernel::Field::Text(
                name          =>'clustid',
                htmldetail    =>0,
                label         =>'W5Base Cluster ID',
                dataobjattr   =>'qlnkapplitclust.itclust'),
                                                   
      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustsid'],
                vjoindisp     =>['fullname','swnature']),

   );
   $self->setDefaultView(qw(fullname appl  cdate));
   $self->setWorktable("lnkapplitclust");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkapplitclust.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplitclust qlnkapplitclust left outer join appl ".
            "on qlnkapplitclust.appl=appl.id ".
            "left outer join itclust ".
            "on qlnkapplitclust.itclust=itclust.id";
   return($from);
}

# Einbindung von Clustern könnte wie folgt aufgebaut werden:
# select u1.name,user.userid from (select fullname as name from user 
# where fullname like 'Vo%' union select fullname as name from grp 
# where fullname like '%DB') u1 left outer join user on u1.name=user.fullname;

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

printf STDERR ("fifi x00\n");
   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
printf STDERR ("fifi x01\n");
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $itclustid=effVal($oldrec,$newrec,"clustid");
      if (!$self->isWriteOnClusterValid($itclustid)){
         $self->LastMsg(ERROR,"no write access to specified cluster");
         return(undef);
      }
   }
printf STDERR ("fifi x02\n");
   if (effChanged($oldrec,$newrec,"applid")){
      my $applid=$newrec->{'applid'};
      my $id=effVal($oldrec,$newrec,'id');
      if ($id ne ""){
         my $swi=getModuleObject($self->Config,"itil::swinstance");
         $swi->SetFilter({itclustsid=>\$id,cistatusid=>"<=5"});
         foreach my $srec ($swi->getHashList(qw(applid))){
            if ($srec->{applid} ne $applid){
               $self->LastMsg(ERROR,"application does not match all ".
                                    "related software instances");
               return(undef);
            }
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
   my $itclustid=effVal($oldrec,$newrec,"clustid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnClusterValid($itclustid));
   return(undef);
}


sub isWriteOnClusterValid
{
   my $self=shift;
   my $itclustid=shift;

   if ($itclustid ne ""){
      my $c=getModuleObject($self->Config,"itil::itclust");
      $c->SetFilter({id=>\$itclustid});
      my ($cl,$msg)=$c->getOnlyFirst(qw(ALL));
printf STDERR ("fifi 01\n");
      my @g=$c->isWriteValid($cl);
printf STDERR ("fifi 02\n");
      if (grep(/^(ALL|services)$/,@g)){
         return(1);
      }
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default misc clustinfo applinfo swinstances source));
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
