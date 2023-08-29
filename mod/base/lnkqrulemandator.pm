package base::lnkqrulemandator;
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
use Class::ISA;
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
                group         =>'source',
                label         =>'Qrule activation LinkID',
                dataobjattr   =>'lnkqrulemandator.lnkqrulemandatorid'),
 
      new kernel::Field::RecordUrl(),

      new kernel::Field::Mandator(allowany=>1,allowall=>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Mandator-ID',
                dataobjattr   =>'lnkqrulemandator.mandator'),
                                                 
      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'confine to data object',
                dataobjattr   =>'lnkqrulemandator.dataobj'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'activation full qualified label',
                htmldetail    =>0,
                readonly      =>1,
                uploadable    =>0,
                dataobjattr   =>"concat(lnkqrulemandator.qrule,'-',".
                           "lnkqrulemandator.dataobj,'-',".
                           "if (lnkqrulemandator.mandator is null ".
                           "or lnkqrulemandator.mandator='0','ANY',".
                           "if (mandator.name is null,'INVALID',".
                           "mandator.name)))"),
                                                 
      new kernel::Field::Text(
                name          =>'dataobjlabel',
                label         =>'data object label',
                depend        =>['dataobj'],
                searchable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                onRawValue    =>sub (){
                   my $self=shift;
                   my $current=shift;
                   my $dataobj=$self->getParent->getField("dataobj",$current)
                                    ->RawValue($current);
                   return($self->getParent->T($dataobj,$dataobj));
                }),
                                                 
      new kernel::Field::Select(
                name          =>'qrule',
                label         =>'Quality Rule',
                vjointo       =>'base::qrule',
                vjoinon       =>['qruleid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>'default',
                label         =>'Rule-State',
                vjoineditbase =>{id=>[qw(4 5)]},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'default',
                label         =>'Rule-StateID',
                dataobjattr   =>'lnkqrulemandator.cistatus'),


      new kernel::Field::Htmlarea(
                name          =>'qruledesc',
                label         =>'Quality Rule Description',
                htmldetail    =>0,
                htmlwidth     =>'500',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'base::qrule',
                vjoinon       =>['qruleid'=>'id'],
                vjoindisp     =>'longdescription'),

      new kernel::Field::Textarea(
                name          =>'qrulecode',
                label         =>'Quality Rule Code',
                htmlwidth     =>'500',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'base::qrule',
                vjoinon       =>['qruleid'=>'id'],
                vjoindisp     =>'code'),

      new kernel::Field::Interface(
                name          =>'qruleid',
                label         =>'QRule-ID',
                dataobjattr   =>'lnkqrulemandator.qrule'),
                                                 
      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkqrulemandator.expiration'),
                                                 
      new kernel::Field::Textarea(
                name          =>'comments',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'lnkqrulemandator.comments'),

      new kernel::Field::SubList(
                name          =>'individualAttr',
                label         =>'individual attributes',
                group         =>'individualAttr',
                allowcleanup  =>1,
                forwardSearch =>1,
                htmldetail    =>'NotEmpty',
                vjointo       =>'base::grpindivlnkqrulemandator',
                vjoinon       =>['id'=>'srcdataobjid'],
                vjoindisp     =>['fieldname','indivfieldvalue']),
                                                 
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkqrulemandator.createuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkqrulemandator.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkqrulemandator.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkqrulemandator.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkqrulemandator.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkqrulemandator.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkqrulemandator.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkqrulemandator.realeditor'),
   );

   $self->{individualAttr}={
      dataobj=>'base::grpindivlnkqrulemandator'
   };

   $self->setDefaultView(qw(mandator qrule cistatus cdate dataobj));
   $self->setWorktable("lnkqrulemandator");
   return($self);
}

sub isCopyValid
{
   my $self=shift;

   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join mandator ".
            "on $worktable.mandator=mandator.grpid ";

   return($from);
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   my $dataobj=effVal($oldrec,$newrec,"dataobj");
   if (defined($dataobj)){
      $dataobj=trim($dataobj);
      if ($dataobj eq "" ||
          !($dataobj=~m/^[a-z,0-9,_]+::[a-z,0-9,_]+$/i) &&
          !($dataobj=~m/^[a-z,0-9,_]+::workflow::[a-z,0-9,_]+$/i)){
         $self->LastMsg(ERROR,"invalid dataobject nameing");
         return(undef);  
      }
      $newrec->{dataobj};
   }
   my $qruleid=effVal($oldrec,$newrec,"qruleid");
   if ($qruleid eq ""){
      $self->LastMsg(ERROR,"invalid qruleid");
      return(undef);  
   }
   my $do=getModuleObject($self->Config(),$dataobj);
   if (!defined($do)){
      $self->LastMsg(ERROR,"dataobj not functional");
      return(undef);  
   }
   my @dataobjparent=Class::ISA::self_and_super_path($dataobj);
   my $dataobjparent=$do->SelfAsParentObject();

   my $qr=getModuleObject($self->Config(),"base::qrule");
   my $found=0;
   foreach my $qrulerec (@{$qr->{'data'}}){
      if ($qrulerec->{id} eq $qruleid){
         my $target=$qrulerec->{target};
         $target=[$target] if (ref($target) ne "ARRAY");
         foreach my $t (@$target){
            if ($dataobj=~m/^$t$/){
               $found++;
               last;
            }
            if (in_array(\@dataobjparent,$t)){
               $found++;
               last;
            }
         }
      }
   }
   if (!$found){
      $self->LastMsg(ERROR,"dataobj not allowed for this qrule");
      return(undef);  
   }


   # check if really only one inheritance of dataobject is used
   # for the current mandator
   my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   my $linkid=defined($oldrec)?$oldrec->{id}:'';

   my $m=getModuleObject($self->Config(),'base::mandator');
   $m->SetFilter({grpid=>\$mandatorid});
   my ($mandator,$msg)=$m->getOnlyFirst("name");
   my $mname=$mandator->{name};
   $mname='[any]' if ($mname eq "");

   my $lnkqrm=getModuleObject($self->Config(),$self->Self);
   $lnkqrm->SetFilter({mandatorid=>\$mandatorid,
                       cistatusid=>\'4',
                       id        =>"!$linkid"});
   my $dobjs=$lnkqrm->getHashIndexed("dataobj");
   my %curdobj;
   foreach my $dobj (keys %{$dobjs->{dataobj}}) {
      my $o=getModuleObject($self->Config(),$dobj);
      if ($o->SelfAsParentObject() eq $dataobjparent) {
         $curdobj{$dobj}++;
      }
   }

   my @curdobj=keys(%curdobj);

   if ($#curdobj>0) {
      my @msg=("Mandator '%s' uses several inheritances from '%s'",
               $mname,$dataobjparent);
      if ($cistatusid==4) {
         $self->LastMsg(ERROR,@msg);
         return(undef);
      }

      $self->LastMsg(WARN,@msg);
   }   

   if ($#curdobj==0) {
      my $curdobj=$curdobj[0];

      if ($dataobj ne $curdobj) {
         if (in_array(\@dataobjparent,$curdobj)) {
            my @msg=("All dataobjects '%s' with mandator '%s' ".
                     "have to set to '%s'",$curdobj,$mname,$dataobj);
            if ($cistatusid==4) {
               $self->LastMsg(ERROR,@msg);
               return(undef);
            }

            $self->LastMsg(WARN,@msg);
         }
         else {
            my @msg=("Mandator '%s' uses dataobject '%s', not '%s'",
                     $mname,$curdobj,$dataobj);
            if ($cistatusid==4) {
               $self->LastMsg(ERROR,@msg);
               return(undef);
            }

            $self->LastMsg(WARN,@msg);
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
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/lnkmandatorqmgmt.jpg?".$cgi->query_string());
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub LoadQualityActivationLinks
{     
   my $self=shift;

   my %dataobjtocheck;
   $self->ResetFilter();
   $self->SetFilter({cistatusid=>\'4'});
   $self->SetCurrentView("dataobj","mandatorid","qruleid");
   my ($rec,$msg)=$self->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         #msg(INFO,"dataobject=$rec->{dataobj} mandatorid=$rec->{mandatorid}");
         if ($rec->{dataobj} ne ""){
            my $mandatorid=$rec->{mandatorid};
            my $qruleid=$rec->{qruleid};
            $mandatorid=0 if (!defined($mandatorid));
            if ($rec->{dataobj}=~m/::workflow::/){
               $dataobjtocheck{'base::workflow'}->{$mandatorid}->{$qruleid}++;
            }
            else{
               $dataobjtocheck{$rec->{dataobj}}->{$mandatorid}->{$qruleid}++;
            }
         }
         ($rec,$msg)=$self->getNext();
      }until(!defined($rec));
   }
   return(%dataobjtocheck);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default individualAttr source ));
}






1;
