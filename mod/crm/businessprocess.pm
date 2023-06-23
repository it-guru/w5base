package crm::businessprocess;
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
use kernel::MandatorDataACL;
use crm::lib::Listedit;
@ISA=qw(crm::lib::Listedit kernel::MandatorDataACL);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'businessprocess.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                selectfix     =>1,
                dataobjattr   =>'businessprocess.mandator'),

     new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Organisation/Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4],'is_org'=>1},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'customerid',
                selectfix     =>1,
                dataobjattr   =>'businessprocess.customer'),
   
      new kernel::Field::Text(
                name          =>'shortname',
                htmlwidth     =>'250px',
                maxlength     =>99,
                htmleditwidth =>'200px',
                label         =>'Shortname',
                dataobjattr   =>'businessprocess.name'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'businessprocess.fullname'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'550px',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'full qualified process name',
                dataobjattr   =>"concat(businessprocess.name,".
                                "if (businessprocess.fullname is not null and ".
                                "businessprocess.fullname<>'',':',''),".
                                "businessprocess.fullname,'\@',".
                                "customer.fullname)"),

      new kernel::Field::Text(
                name          =>'selector',
                htmlwidth     =>'550px',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Selector',
                dataobjattr   =>"concat(businessprocess.name,".
                                "if (businessprocess.fullname is not null and ".
                                "businessprocess.fullname<>'',':',''),".
                                "businessprocess.fullname,'\@',".
                                "customer.fullname)"),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmlwidth     =>'50px',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::Select(
                name          =>'nature',
                sqlorder      =>'desc',
                label         =>'Nature',
                htmleditwidth =>'40%',
                default       =>'PROCESS',
                transprefix   =>'nat.',
                value         =>['DOMAIN','PROCESS','PROCPART','BCASE',
                                 'PROCPARTST','CUSTSEG'],
                dataobjattr   =>"businessprocess.nature"),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'businessprocess.databoss'),

      new kernel::Field::TextDrop(
                name          =>'pbusinessprocess',
                label         =>'parent business process',
                vjointo       =>'crm::businessprocess',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['pbusinessprocessid'=>'id'],
                AllowEmpty    =>1,
                htmldetail    =>'NotEmptyOrEdit',
                vjoindisp     =>'selector'),

      new kernel::Field::Interface(
                name          =>'pbusinessprocessid',
                dataobjattr   =>'businessprocess.pbusinessprocess'),

      new kernel::Field::Textarea(
                name          =>'treeview',
                label         =>'TreeView',
                htmldetail    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my @d;
                   $self->getParent->TreeLoad(\@d,"crm::businessprocess",$id);

                   return(Dumper(\@d));
                }),


      new kernel::Field::Contact(
                name          =>'processowner',
                group         =>'procdesc',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>[qw(user extern)]},
                label         =>'Process Owner',
                vjoinon       =>'processownerid'),

      new kernel::Field::Link(
                name          =>'processownerid',
                dataobjattr   =>'businessprocess.processowner'),

      new kernel::Field::Contact(
                name          =>'processowner2',
                group         =>'procdesc',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>[qw(user extern)]},
                label         =>'Deputy Process Owner',
                vjoinon       =>'processowner2id'),

      new kernel::Field::Link(
                name          =>'processowner2id',
                dataobjattr   =>'businessprocess.processowner2'),

      new kernel::Field::Select(
                name          =>'processmgrrole',
                label         =>'Processmanager',
                group         =>'procroles',
                value         =>['RINManager','RCHManager','RCFManager',
                                 'RPRManager','RODManager','RCAManager',
                                 'RLIManager',
                                ],
                dataobjattr   =>'businessprocess.processmgrrole'),

      new kernel::Field::Select(
                name          =>'processmgr2role',
                label         =>'Processmanager deputy',
                group         =>'procroles',
                value         =>['RINManager2','RCHManager2','RCFManager2',
                                 'RPRManager2','RODManager2','RCAManager2',
                                 'RLIManager2',
                                ],
                dataobjattr   =>'businessprocess.processmgr2role'),

      new kernel::Field::Interface(
                name          =>'nativprocessmgrrole',
                readonly      =>1,
                history       =>0,
                htmldetail    =>0,
                uploadable    =>0,
                dataobjattr   =>'businessprocess.processmgrrole'),

      new kernel::Field::Interface(
                name          =>'nativprocessmgr2role',
                readonly      =>1,
                history       =>0,
                htmldetail    =>0,
                uploadable    =>0,
                dataobjattr   =>'businessprocess.processmgr2role'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'procdesc',
                label         =>'Customers Process Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'businessprocess.customerprio'),

      new kernel::Field::Select(
                name          =>'importance',
                group         =>'procdesc',
                transprefix   =>'im.',
                htmleditwidth =>'30%',
                label         =>'Importance',
                default       =>'3',
                value         =>[1,2,3,4,5],
                dataobjattr   =>'businessprocess.importance'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                group         =>'procdesc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::SubList(
                name          =>'subproc',
                label         =>'subproc',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'subproc',
                vjointo       =>'crm::businessprocess',
                vjoinon       =>['id'=>'pbusinessprocessid'],
                vjoindisp     =>['fullname','nature']),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.businessprocess',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'crm::businessprocessacl',
                vjoinbase     =>[{'aclparentobj'=>\'crm::businessprocess'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Select(
                name          =>'eventlang',
                group         =>'misc',
                htmleditwidth =>'30%',
                value         =>['en','de','en-de','de-en'],
                label         =>'default language for eventinformations',
                dataobjattr   =>'businessprocess.eventlang'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>'misc',
                dataobjattr   =>'businessprocess.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0);
                },
                dataobjattr   =>'businessprocess.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'businessprocess.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'businessprocess.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'businessprocess.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'businessprocess.createdate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"businessprocess.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(businessprocess.id,35,'0')"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'businessprocess.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'businessprocess.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'businessprocess.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'businessprocess.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'businessprocess.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltarget'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.acltargetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'businessprocessacl.aclmode'),

   );
   $self->setDefaultView(qw(linenumber fullname cistatus importance));
   $self->setWorktable("businessprocess");
   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->{workflowlink}={ workflowkey=>[id=>'affectedbusinessprocessid']
                         };
   $self->{use_distinct}=1;
   return($self);
}


sub TreeLoad
{
   my $self=shift;
   my $d=shift;
   my $dataobj=shift;
   my $id=shift;
   my $idx=shift;
   my @l;

   $idx={} if (!defined($idx));

   # load direct records
   my $o=$self->getPersistentModuleObject("TreeBproc".$dataobj,$dataobj);
   my @ofields=qw(name id pbusinessprocessid urlofcurrentrec);

   my $tent;
   $o->SetFilter({id=>\$id,cistatusid=>'<=5'});
   if (my ($r)=$o->getOnlyFirst(@ofields)){
      $tent={
         label=>$r->{name},
         id=>$r->{id},
         url=>$r->{urlofcurrentrec},
         type=>$o->SelfAsParentObject(),
         child=>[]
      };
      if ($r->{pbusinessprocessid} ne ""){
         $tent->{pid}=$r->{pbusinessprocessid};
      }
      $idx->{$r->{id}}=$tent;
      push(@l,$tent);
   }


   # load parent tree
   while(exists($tent->{pid}) && $tent->{pid} ne ""){
      $o->SetFilter({id=>\$tent->{pid},cistatusid=>'<=5'});
      delete($tent->{pid});
      $tent={};
      if (my ($r)=$o->getOnlyFirst(@ofields)){
         if (!exists($idx->{$r->{id}})){
            $tent={
               label=>$r->{name},
               icon=>$o->getRecordImageUrl($r),
               id=>$r->{id},
               url=>$r->{urlofcurrentrec},
               dataobj=>$o->SelfAsParentObject(),
               child=>[@l]
            };
            
            if ($r->{pbusinessprocessid} ne ""){
               $tent->{pid}=$r->{pbusinessprocessid};
            }
            $idx->{$r->{id}}=$tent;
            @l=($tent);
         }
      }
   }

   # load subs (level1)
   $o->SetFilter({pbusinessprocessid=>\$id,cistatusid=>'<=5'});
   my @subsl1;
   foreach my $r ($o->getHashList(@ofields)){
      $tent={
         label=>$r->{name},
         icon=>$o->getRecordImageUrl($r),
         id=>$r->{id},
         url=>$r->{urlofcurrentrec},
         dataobj=>$o->SelfAsParentObject()
      };
      $idx->{$r->{id}}=$tent;
      push(@subsl1,$tent);
   }
   $idx->{$id}->{child}=\@subsl1;


#   if ($level eq "" || $level eq "up"){
#      if ($l[0]->{pid} ne ""){
#         my @newtop;
#         printf STDERR ("fifi load $l[0]->{pid} for $l[0]->{label}\n");
#         $self->TreeLoad(\@newtop,"crm::businessprocess",$l[0]->{pid},"up");
#         printf STDERR ("fifi load new top $newtop[0]->{label}\n");
#       #  if ($#newtop!=-1){
#       #     $newtop[0]->{child}=[@l];
#       #  }
#         @l=(@newtop);
#      }
#   }

   @{$d}=@l;
}


sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(selector));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{fullname},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{shortname})) &&
       $newrec->{shortname}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid shortname specified");
      return(0);
   }

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (effChanged($oldrec,$newrec,"cistatusid")){
         my $newcistatusid=effVal($oldrec,$newrec,"cistatusid");
         if ($newcistatusid==3 ||
             $newcistatusid==4 ){
            my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
            my $isok=0;
            if ($mandatorid!=0 &&
               $self->IsMemberOf($mandatorid,["BPManager"], "down")){
               $isok=1;
            }
            if (!$isok){
               $self->LastMsg(ERROR,"activation not allowed - ".
                                  "please contact a business process manager");
               return(0);
            }
         }
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
   my $customerid=effVal($oldrec,$newrec,"customerid");
   if ($customerid==0){
      $self->LastMsg(ERROR,"invalid or no customer specified");
      return(0);
   }

   #my $name=effVal($oldrec,$newrec,"name");
   #
   #if ($name eq ""){
   #   $newrec->{name}=\undef;
   #}



   my $shortname=effVal($oldrec,$newrec,"shortname");
   if ($shortname eq ""){
      $newrec->{shortname}=\undef;
   }
   else{
      my $n2=$shortname;
      $n2=~s/[^a-z0-9 _-]//gi;
      if ($n2 ne $shortname){
         $newrec->{shortname}=$n2;
      }
   }
   return(0) if (!$self->HandleCIStatusModification(
                             $oldrec,$newrec,"shortname"));

   return(1);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.crm.businessprocess.read 
                              w5base.crm.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
             [qw(REmployee RApprentice RFreelancer RBoss)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>['write','read']},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>['write','read']}
                ]);
   }
   return($self->SetFilter(@flt));
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join businessprocessacl ".
            "on businessprocessacl.aclparentobj='$selfasparent' ".
            "and $worktable.id=businessprocessacl.refid ".
            "left outer join grp as customer on ".
            "customer.grpid=businessprocess.customer ".
            "left outer join businessprocess as p1 on ".
            "businessprocess.pbusinessprocess=p1.id ".
            "left outer join businessprocess as p2 on ".
            "p1.pbusinessprocess=p2.id ".
            "left outer join businessprocess as p3 on ".
            "p2.pbusinessprocess=p3.id ".
            "left outer join businessprocess as p4 on ".
            "p3.pbusinessprocess=p4.id ".
            "left outer join businessprocess as p5 on ".
            "p4.pbusinessprocess=p5.id ";

   return($from);
}  






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/crm/load/businessprocess.jpg?".$cgi->query_string());
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();

   my @admedit;
   @admedit=("procroles") if ($self->IsMemberOf("admin"));

   #return("default","procdesc","misc","acl",@admedit) if (!defined($rec) ||
   #                      ($rec->{cistatusid}<3 && $rec->{creator}==$userid) );

   return("default","procdesc","misc","acl") if (!defined($rec));

   my $customerid=$rec->{customerid};
   my $mandatorid=$rec->{mandatorid};

   my @databossedit=("default","procdesc","misc","acl",@admedit);

   if ($rec->{databossid}==$userid ||
       ($mandatorid!=0 && $self->IsMemberOf($mandatorid,["BPManager",
                                                       "RCFManager",
                                                       "RCFManager2"],"down"))||
       ($customerid!=0 && $self->IsMemberOf($customerid,["BPManager"],"down"))||
       $self->IsMemberOf("admin")){
      return($self->expandByDataACL($rec->{mandatorid},@databossedit));
   }

   if (defined($rec->{acls}) && ref($rec->{acls}) eq "ARRAY"){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["RMember"],"both");
      my @grpids=keys(%grps);
      foreach my $contact (@{$rec->{acls}}){
         if ($contact->{acltarget} eq "base::user" &&
             $contact->{acltargetid} ne $userid){
            next;
         }
         if ($contact->{acltarget} eq "base::grp"){
            my $grpid=$contact->{acltargetid};
            next if (!grep(/^$grpid$/,@grpids));
         }
         if ($contact->{aclmode} eq "write"){
            return($self->expandByDataACL($rec->{mandatorid},@databossedit));
         }
      }
   }
   return($self->expandByDataACL($rec->{mandatorid}),@admedit);
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","procdesc") if (!defined($rec));
   my @l=qw(default procdesc subproc acl misc source history);
   push(@l,"procroles") if ($self->IsMemberOf("admin"));

   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default procdesc subproc acl misc 
             procroles  source));
}

sub SelfAsParentObject
{
   my $self=shift;
   return("crm::businessprocess");
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub prepUploadRecord
{
   my $self=shift;
   my $newrec=shift;

   if (!exists($newrec->{id}) || $newrec->{id} eq ""){
      if (exists($newrec->{customer}) && $newrec->{customer} ne "" &&
          exists($newrec->{shortname}) && $newrec->{shortname} ne ""){
         my $customer=$newrec->{customer};
         my $shortname=$newrec->{shortname};
         my $opobj=$self->Clone();
         $opobj->SetFilter({customer=>[$customer],shortname=>[$shortname]});
         my ($rec,$msg)=$opobj->getOnlyFirst(qw(id));
         if (defined($rec)){
            $newrec->{id}=$rec->{id};
         }
      }
   }


   return(1);
}


sub jsExploreFormatLabelMethod
{
   my $self=shift;
   my $d=<<EOF;
newlabel=wrapText(newlabel,20);
newlabel=newlabel.replaceAll('\@','\\n\@');
newlabel=newlabel.replaceAll(':',':\\n');
EOF
   return($d);
}






1;
