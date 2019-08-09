package itil::liccontract;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'liccontract.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                uivisible     =>0,
                dataobjattr   =>'liccontract.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'liccontract.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'liccontract.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                vjoineditbase =>{id=>">0 AND <7"},
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'liccontract.cistatus'),

#      new kernel::Field::TextDrop(
#                name          =>'software',
#                label         =>'Software',
#                vjointo       =>'itil::software',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['softwareid'=>'id'],
#                vjoindisp     =>'name'),
#
#      new kernel::Field::Link(
#                name          =>'softwareid',
#                label         =>'SoftwareID',
#                dataobjattr   =>'liccontract.software'),

      new kernel::Field::TextDrop(
                name          =>'licproduct',
                label         =>'License product',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      if ($param{current}->{licproductid} eq ""){
                         return(0);
                      }
                   }
                   return(1);
                },
                vjointo       =>'itil::licproduct',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['licproductid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'licproductid',
                selectfix     =>1,
                label         =>'License product ID',
                dataobjattr   =>'liccontract.licproduct'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'liccontract.databoss'),

#      new kernel::Field::TextDrop(
#                name          =>'responseteam',
#                htmlwidth     =>'300px',
#                group         =>'finance',
#                label         =>'CBM Team',
#                vjointo       =>'base::grp',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['responseteamid'=>'grpid'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::Link(
#                name          =>'responseteamid',
#                dataobjattr   =>'liccontract.responseteam'),
#
#
#      new kernel::Field::TextDrop(
#                name          =>'sem',
#                group         =>'finance',
#                label         =>'Customer Business Manager',
#                vjointo       =>'base::user',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['semid'=>'userid'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::Link(
#                name          =>'semid',
#                dataobjattr   =>'liccontract.sem'),
#
#      new kernel::Field::TextDrop(
#                name          =>'sem2',
#                group         =>'finance',
#                label         =>'Deputy Customer Business Manager',
#                vjointo       =>'base::user',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['sem2id'=>'userid'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::Link(
#                name          =>'sem2id',
#                dataobjattr   =>'liccontract.sem2'),


      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'itil::liccontract'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Number(
                name          =>'unitcount',
                group         =>'licdesc',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{licproductid} ne ""){
                      return(1);
                   }
                   return(0);
                },
                htmleditwidth =>'100',
                label         =>'unit count',
                dataobjattr   =>'liccontract.unitcount'),

      new kernel::Field::TextDrop(
                name          =>'unittype',
                group         =>'licdesc',
                label         =>'unit type (license metric)',
                vjointo       =>'itil::licproduct',
                vjoinon       =>['licproductid'=>'id'],
                vjoindisp     =>'metric',
                readonly      =>1),

      new kernel::Field::Date(
                name          =>'durationstart',
                group         =>'licdesc',
                label         =>'Duration start',
                dataobjattr   =>'liccontract.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                group         =>'licdesc',
                label         =>'Duration end',
                dataobjattr   =>'liccontract.durationend'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'licdesc',
                label         =>'Comments',
                dataobjattr   =>'liccontract.comments'),

      new kernel::Field::SubList(
                name          =>'lickeys',
                label         =>'License keys',
                group         =>'privacy_lickeys',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.liccontract',
                vjointo       =>'itil::lnklickey',
                vjoinon       =>['id'=>'liccontractid'],
                vjoindisp     =>['name','comments']),

      new kernel::Field::Number(
                name          =>'licuse',
                group         =>'licuse',
                label         =>'License use count',
                onRawValue    =>sub{
                           my $self=shift;
                           my $current=shift;
                           my $n=0;
                           my $fo=$self->getParent->getField("licusesys"); 
                           my $d=$fo->RawValue($current);
                           if (ref($d) eq "ARRAY"){
                              foreach my $r (@$d){
                                 $n+=$r->{quantity};
                              } 
                           }
                           my $fo=$self->getParent->getField("licuseappl"); 
                           my $d=$fo->RawValue($current);
                           if (ref($d) eq "ARRAY"){
                              foreach my $r (@$d){
                                 $n+=$r->{quantity};
                              } 
                           }
                           my $fo=$self->getParent->getField("licuseitclust"); 
                           my $d=$fo->RawValue($current);
                           if (ref($d) eq "ARRAY"){
                              foreach my $r (@$d){
                                 $n+=$r->{quantity};
                              } 
                           }

                           return($n);
                        },
                depend        =>['licusesys']
                ),

      new kernel::Field::Number(
                name          =>'licfree',
                group         =>'licuse',
                label         =>'License free count',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      if ($param{current}->{units} eq ""){
                         return(0);
                      }
                   }
                   return(1);
                },
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fo=$self->getParent->getField("licuse"); 
                   my $d=$fo->RawValue($current);
                   my $fo=$self->getParent->getField("unitcount");
                   my $max=$fo->RawValue($current);
                   if (defined($max) && $max>0){
                      return($max-$d);
                   }
                   return(undef);
                },
                depend        =>['licuse','unitcount']),

      new kernel::Field::Percent(
                name          =>'licload',
                group         =>'licuse',
                label         =>'License load',
                onRawValue    =>sub{
                           my $self=shift;
                           my $current=shift;
                           if ($current->{units} ne ""){
                              my $fo=$self->getParent->getField("licuse"); 
                              my $d=$fo->RawValue($current);
                              my $fo=$self->getParent->getField("unitcount");
                              my $max=$fo->RawValue($current);
                              if ($max>0){
                                 return($d*100/$max);
                              }
                              return(100);
                           }
                           return(0);
                        },
                depend        =>['licuse','unitcount']
                ),

      new kernel::Field::SubList(
                name          =>'licusesys',
                label         =>'License use by (systems)',
                group         =>'licuse',
                htmldetail    =>0,
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinon       =>['id'=>'liccontractid'],
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoindisp     =>['system','systemcistatus','quantity'],
                vjoininhash   =>['system','systemcistatus','quantity']),

      new kernel::Field::SubList(
                name          =>'licuseappl',
                label         =>'License use by (application)',
                group         =>'licuse',
                htmldetail    =>0,
                vjointo       =>'itil::lnklicappl',
                vjoinon       =>['id'=>'liccontractid'],
                vjoinbase     =>[{applcistatusid=>"<=5"}],
                vjoindisp     =>['appl','applcistatus','quantity'],
                vjoininhash   =>['appl','applcistatus','quantity']),

      new kernel::Field::SubList(
                name          =>'licuseitclust',
                label         =>'License use by (cluster service)',
                group         =>'licuse',
                htmldetail    =>0,
                vjointo       =>'itil::lnklicitclustsvc',
                vjoinon       =>['id'=>'liccontractid'],
                vjoinbase     =>[{itclustcistatusid=>"<=5"}],
                vjoindisp     =>['itclustsvc','itclustcistatus','quantity'],
                vjoininhash   =>['itclustsvc','itclustcistatus','quantity']),

      new kernel::Field::Text(
                name          =>'orderref',
                group         =>'order',
                label         =>'Order ref',
                dataobjattr   =>'liccontract.orderref'),

      new kernel::Field::Date(
                name          =>'orderdate',
                dayonly       =>1,
                group         =>'order',
                label         =>'Order date',
                dataobjattr   =>'liccontract.orderdate'),

      new kernel::Field::Number(
                name          =>'units',
                group         =>'order',
                selectfix     =>1,
                label         =>'units',
                dataobjattr   =>'liccontract.unitcount'),

      new kernel::Field::Currency(
                name          =>'extprice',
                group         =>'order',
                label         =>'price per unit',
                dataobjattr   =>'liccontract.extprice'),


      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'itil::liccontract',
                label         =>'Attachments',
                group         =>'attachments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>'liccontract.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'liccontract.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'liccontract.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'liccontract.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'liccontract.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'liccontract.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"liccontract.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(liccontract.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'liccontract.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'liccontract.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'liccontract.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'liccontract.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber name mandator cistatus software mdate));
   $self->setWorktable("liccontract");
   return($self);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $fo=$self->getField("licuse");
   my $d=$fo->RawValue($rec);
   return(0) if ($d>0);
   
   return($self->SUPER::isDeleteValid($rec));
}  


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::liccontract' ".
          "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{name})){
      $newrec->{name}=~s/\$//g;
   }

   if ((!defined($oldrec) || defined($newrec->{name})) &&
        (($newrec->{name}=~m/[^A-Z,\+\!&,-:0-9. _\[\]()#]/i) ||
         length(trim($newrec->{name}))<3)){
      $self->LastMsg(ERROR,
                     "invalid licensing name '$newrec->{name}' specified");
      return(0);
   }
   if (defined($newrec->{cistatusid}) && $newrec->{cistatusid}>4){
      # validate if subdatastructures have a cistauts <=4 
      # if true, the new cistatus isn't alowed
   }

   my $fullname=effVal($oldrec,$newrec,"name");
   $fullname=~s/\[\d+\]$//;
   my $units=effVal($oldrec,$newrec,"units");
   my $unitcount=effVal($oldrec,$newrec,"unitcount");

   if (effVal($oldrec,$newrec,"licproductid") eq ""){
      $fullname=$fullname." (unspecified License)";
   }
   elsif ($units ne "" || $unitcount ne ""){
      my $u=$units;
      $u=$unitcount if ($u eq "");
      my $l="unit";
      $l="units" if ($u>1);
      $fullname=$fullname." ($u $l License)";
   }
   else{
      $fullname=$fullname." (unlimited License)";
   }
   if (effVal($oldrec,$newrec,"cistatusid") eq "6"){
      $fullname.=" [deleted]";
   }

   if (effVal($oldrec,$newrec,"fullname") ne $fullname){
      $newrec->{fullname}=$fullname;
   }


   if (!defined($oldrec)){
      my $licproductid=effVal($oldrec,$newrec,"licproductid");
      if ($licproductid eq ""){
         if (!$self->IsMemberOf("admin")){
            $self->LastMsg(ERROR,"only admins can create product less entries");
            return(undef);
         }
      }
   }
   my $units=effVal($oldrec,$newrec,"units");
   my $unitcount=effVal($oldrec,$newrec,"unitcount");
   if ($units eq "" || $units<=0 || (defined($oldrec) && $unitcount<=0)){
      if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
         $self->LastMsg(ERROR,"only admins can create entries with no unit binding");
         return(undef);
      }
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/liccontract.jpg?".$cgi->query_string());
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","order") if (!defined($rec));

   my @grplist=qw(header default licuse 
                 contacts misc attachments source);
   my @l=$self->isWriteValid($rec);
   if ($rec->{licproductid} ne ""){
      push(@grplist,"order");
   }
   if ($rec->{units} ne ""){
      push(@grplist,"licdesc","finance");
      if (grep(/^privacy_lickeys$/,@l)){
         push(@grplist,"privacy_lickeys");
      }
      else{
         my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{contacts});
         push(@grplist,"privacy_lickeys") if (grep(/^privread$/,@acl));
      }
   }
   return(@grplist);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default finance licdesc licuse order privacy_lickeys 
             contacts misc attachments));
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default finance privacy_lickeys order
                       contacts licdesc attachments);
   if (!defined($rec)){
      return("default","order");
   }
   else{
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles} eq "ARRAY"));
            return(@databossedit) if (grep(/^write$/,@roles));
         }
      }
   }
   return(undef);
}




1;
