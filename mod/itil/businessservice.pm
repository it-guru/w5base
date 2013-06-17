package itil::businessservice;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   $self->{Worktable}="businessservice";
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                sqlorder      =>'desc',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Business-Service Fullname',
                dataobjattr   =>"concat(if (applname is null,'',".
                                "concat(applname,':')),".
                                "if ($worktable.name is null,'[ENTIRE]',".
                                "$worktable.name))"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'Name',
                dataobjattr   =>"$worktable.name"),

      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"applid"),
                                                  
      new kernel::Field::Link(
                name          =>'applid',
                selectfix     =>1,
                label         =>'ApplicationID',
                dataobjattr   =>"$worktable.appl"),

      new kernel::Field::Databoss(
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(0);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if ($current->{applid} ne "");
                   return(0);
                }),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                label         =>'Databoss ID',
                dataobjattr   =>"if ($worktable.appl is null,".
                                "$worktable.databoss,".
                                "appldataboss)",
                wrdataobjattr  =>"$worktable.databoss"),
                                                  
      new kernel::Field::Text(
                name          =>'application',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current) &&
                                 $current->{applid} ne "");
                   return(0);
                },
                uploadable    =>0,
                label         =>'primarily provided by application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'applname'),

      new kernel::Field::TextDrop(
                name          =>'srcapplication',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if (defined($current));
                   return(1);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                uploadable    =>1,
                label         =>'provided by application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Contact(
                name          =>'funcmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'functional manager',
                vjoinon       =>'funcmgrid'),

                                                  
      new kernel::Field::Link(
                name          =>'funcmgrid',
                label         =>'functional mgr id',
                dataobjattr   =>"$worktable.funcmgr"),

      new kernel::Field::Mandator( 
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if ($current->{applid} ne "");
                   return(0);
                },
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                }),

      new kernel::Field::Link(
                name          =>'mandatorid',
                selectfix     =>1,
                label         =>'Databoss ID',
                dataobjattr   =>"if ($worktable.appl is null,".
                                "$worktable.mandator,".
                                "applmandator)",
                wrdataobjattr  =>"$worktable.mandator"),
                                                  
      new kernel::Field::Text(
                name          =>'mgmtitemgroup',
                label         =>'central managed CI groups',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Textarea(
                name          =>'description',
                group         =>'desc',
                label         =>'Business Service Description',
                dataobjattr   =>"$worktable.description"),

      new kernel::Field::SubList(
                name          =>'servicecomp',
                label         =>'service components',
                group         =>'servicecomp',
                searchable    =>0,
                subeditmsk    =>'subedit.businessservice',
                vjointo       =>'itil::lnkbscomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['name','namealt1','namealt2',"comments"]),

      new kernel::Field::SubList(
                name          =>'servicecompappl',
                label         =>'full related application components',
                htmldetail    =>0,
                group         =>'servicecomp',
                vjointo       =>'itil::lnkbsappl',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Link(
                name          =>'servicecompapplid',
                label         =>'full related application components ids',
                group         =>'servicecomp',
                vjointo       =>'itil::lnkbsappl',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['applid']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::businessservice'}],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'businessprocesses',
                label         =>'involved in Businessprocesses',
                group         =>'businessprocesses',
                vjointo       =>'itil::lnkbprocessbservice',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['businessprocess','customer']),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'applbusinessteam'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'applresponseteam'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>"$worktable.createdate"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>"$worktable.createuser"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>"$worktable.realeditor"),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontacttarget'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontacttargetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontactcroles'),

   );
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(fullname application));
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default applinfo desc  servicecomp
             contacts businessprocesses source));
}






sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="QualityCheck";
      $o->BackendSessionName("preProcessReadedRecord"); # prevent sesssion reuse
                                                  # on sql cached_connect
      my ($id)=$o->ValidatedInsertRecord({applid=>$rec->{parentid}});
      $W5V2::OperationContext=$oldcontext;
      $rec->{id}=$id;
   }
   return(undef);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="((select appl.id applid,appl.name applname,".
          "appl.databoss appldataboss,".
          "appl.mandator applmandator,".
          "appl.businessteam applbusinessteam,".
          "appl.responseteam applresponseteam,".
          "lnkcontact.target lnkcontacttarget,".
          "lnkcontact.targetid lnkcontacttargetid,".
          "lnkcontact.croles lnkcontactcroles,".
          "businessservice.* ".
          "from appl left outer join businessservice ".
          "on appl.id=businessservice.appl ".
          "left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::appl' and ".
          "appl.id=lnkcontact.refid ".
          "where appl.cistatus<6) union ".
          "(select null applid,null applname,".
          "null appldataboss,".
          "null applmandator,".
          "null applbusinessteam,".
          "null applresponseteam,".
          "lnkcontact.target lnkcontacttarget,".
          "lnkcontact.targetid lnkcontacttargetid,".
          "lnkcontact.croles lnkcontactcroles,".
          "businessservice.* ".
          "from businessservice left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::businessservice' ".
          "and lnkcontact.refid=businessservice.id ".
          "where businessservice.appl is null)) as businessservice";

   return($from);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $org=shift;

   if (!defined($oldrec)){
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         $newrec->{mandatorid}=$mandators[0] if ($mandators[0] ne "");
      }
   }

   return($self->SUPER::SecureValidate($oldrec,$newrec,$org));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   if (!defined($oldrec) && defined($newrec->{name})
       && ($newrec->{name}=~m/^\s*$/)){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }

   if (effVal($oldrec,$newrec,"name") eq "[ENTIRE]" ||
       effVal($oldrec,$newrec,"name") eq ""){
      $newrec->{name}=undef;
   }
   if (effVal($oldrec,$newrec,"name")=~m/[:\]\[]/){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }
   my $applid=effVal($oldrec,$newrec,"applid");

   if ($applid eq ""){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
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
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         print STDERR Dumper($newrec);
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         print STDERR (Dumper(\@mandators));
      }
   }
   else{
      if (!$self->isParentWriteable($applid)){
         $self->LastMsg(ERROR,"no write access to specified application");
         return(0);
      }
   }
 




   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l;

   return("default") if (!defined($rec));
   if ($rec->{applid} ne ""){
      if ($self->isParentWriteable($rec->{applid})){
         push(@l,"default","desc","servicecomp");
      }
   }
   else{
      my $wr=0;
      my $userid=$self->getCurrentUserId();
      if ($userid==$rec->{databossid}){
         $wr++;
      }
      else{
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
               if (ref($contact->{roles}) eq "ARRAY"){
                  @roles=@{$contact->{roles}};
               }
               if (grep(/^write$/,@roles)){
                  $wr++;
                  last;
               }
            }
         }
         if (!$wr){
            if ($rec->{mandatorid}!=0 &&
               $self->IsMemberOf($rec->{mandatorid},
                                      ["RCFManager","RCFManager2"],"down")){
                    $wr++;
            }
         }
         if (!$wr){
            if ($self->IsMemberOf("admin")){
               $wr++;
            }
         }
      }
      
      if ($wr){
         push(@l,"default","contacts","desc","servicecomp");
      }
   }
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @l=qw(header default history);
   if ($rec->{applid} ne ""){
      push(@l,qw(desc servicecomp));
   }
   else{
      push(@l,qw(contacts desc servicecomp));
   }
   push(@l,qw(businessprocesses source));
   return(@l);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/bussinessservice.jpg?".$cgi->query_string());
}




sub isParentWriteable
{
   my $self=shift;
   my $applid=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"itil::appl");
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$applid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid application reference");
      return(0);
   }
   my @write=$p->isWriteValid($l[0]);
   if (!grep(/^ALL$/,@write) && !grep(/^default$/,@write)){
      return(0);
   }
   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (
      #!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RCFManager RCFManager2 
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>\$userid},
                 {businessteamid=>\@grpids},
                 {responseteamid=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}





1;
