package itil::systemnfsnas;
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
use NetAddr::IP;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'systemnfsnas.id'),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'NFS/NAS Server',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'systemnfsnas.system'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Export Path',
                dataobjattr   =>'systemnfsnas.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{'id'=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'type',
                htmleditwidth =>'190px',
                label         =>'Export Type',
                value         =>[qw(nfs cifs)],
                dataobjattr   =>'systemnfsnas.exporttype'),

      new kernel::Field::Boolean(
                name          =>'publicexport',
                label         =>'Public Export',
                default       =>'0',
                dataobjattr   =>'systemnfsnas.publicexport'),

      new kernel::Field::Text(
                name          =>'exportname',
                label         =>'Export Name (CIFS)',
                dataobjattr   =>'systemnfsnas.exportname'),

      new kernel::Field::Text(
                name          =>'exportoptions',
                label         =>'Common Export Options',
                dataobjattr   =>'systemnfsnas.exportoptions'),


      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Client Systems',
                group         =>'systems',
                subeditmsk    =>'subedit.systemnfsnas',
                allowcleanup  =>1,
                vjointo       =>'itil::lnksystemnfsnas',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'systemnfsnasid'],
                vjoindisp     =>['system','syssystemid','systemcistatus',
                                 'exportoptions'],
                vjoininhash   =>['system','systemid','systemcistatusid',
                                 'exportoptions']),

      new kernel::Field::SubList(
                name          =>'ipshares',
                label         =>'IP shares',
                group         =>'ipshares',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.systemnfsnas',
                vjointo       =>'itil::lnknfsnasipnet',
                vjoinon       =>['id'=>'systemnfsnasid'],
                vjoindisp     =>['name','exportoptions','comments'],
                vjoininhash   =>['name','exportoptions','networkid']),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'systemnfsnas.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'systemnfsnas.comments'),



      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'systemnfsnas.additional'),

      new kernel::Field::Text(
                name          =>'fullidlist',
                label         =>'all related Systems IDs',
                group         =>'relations',
                readonly      =>1,
                uivisible     =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @d;
                   my $fo=$self->getParent->getField("fullsystemidlist");
                   $current->{fullsystemidlist}=$fo->RawValue($current);
                   if (defined($current->{fullsystemidlist})&&
                       ref($current->{fullsystemidlist}) eq "ARRAY" &&
                       $#{$current->{fullsystemidlist}}!=-1){
                      my $sys=getModuleObject($self->getParent->Config,
                                              "itil::system");
                      $sys->SetFilter({id=>$current->{fullsystemidlist},
                                       cistatusid=>'<=4'});
                      my @l=$sys->getHashList("id");
                      foreach my $sysrec (@l){
                         push(@d,$sysrec->{id});
                      }
                   }
                   return(\@d);
                }),
      new kernel::Field::Text(
                name          =>'fullsystemlist',
                label         =>'all related Systems',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @d;
                   my $fo=$self->getParent->getField("fullsystemidlist");
                   $current->{fullsystemidlist}=$fo->RawValue($current);
                   if (defined($current->{fullsystemidlist})&&
                       ref($current->{fullsystemidlist}) eq "ARRAY" &&
                       $#{$current->{fullsystemidlist}}!=-1){
                      my $sys=getModuleObject($self->getParent->Config,
                                              "itil::system");
                      $sys->SetFilter({id=>$current->{fullsystemidlist},
                                       cistatusid=>'<=4'});
                      my @l=$sys->getHashList("name");
                      foreach my $sysrec (@l){
                         push(@d,$sysrec->{name});
                      }
                   }
                   return(\@d);
                }),
      new kernel::Field::Text(
                name          =>'fulltsmidlist',
                label         =>'all related TSM IDs',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>0,
                loadapplfield =>'tsmid',
                depend        =>['fulltsmidlist'],
                onRawValue    =>\&LoadFromAppl),

      new kernel::Field::Text(
                name          =>'fulltsmlist',
                label         =>'all related TSMs',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>0,
                loadapplfield =>'tsmemail',
                depend        =>['fullsystemidlist'],
                onRawValue    =>\&LoadFromAppl),

      new kernel::Field::Text(
                name          =>'fulltsm2list',
                label         =>'all related deputy TSMs',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>0,
                loadapplfield =>'tsm2email',
                depend        =>['fullsystemidlist'],
                onRawValue    =>\&LoadFromAppl),

      new kernel::Field::Text(
                name          =>'fulltsm2idlist',
                label         =>'all related deputy TSM IDs',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>0,
                loadapplfield =>'tsm2id',
                depend        =>['fullsystemidlist'],
                onRawValue    =>\&LoadFromAppl),

      new kernel::Field::Text(
                name          =>'fullappllist',
                label         =>'all related Applications',
                readonly      =>1,
                group         =>'relations',
                htmldetail    =>0,
                loadapplfield =>'name',
                depend        =>['fullsystemidlist'],
                onRawValue    =>\&LoadFromAppl),

      new kernel::Field::Link(
                name          =>'fullsystemidlist',
                readonly      =>1,
                group         =>'relations',
                htmldetail    =>0,
                onRawValue    =>\&CalcSystemIdRelationList,
                label         =>'full SystemID list'),
                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'systemnfsnas.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'systemnfsnas.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'systemnfsnas.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'systemnfsnas.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'systemnfsnas.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'systemnfsnas.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'systemnfsnas.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'systemnfsnas.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'systemnfsnas.realeditor'),

      new kernel::Field::Link(
                name          =>'secadm',
                selectable    =>0,
                dataobjattr   =>'nfsserver.adm'),

      new kernel::Field::Link(
                name          =>'secadm2',
                selectable    =>0,
                dataobjattr   =>'nfsserver.adm2'),

      new kernel::Field::Link(
                name          =>'secadmteam',
                selectable    =>0,
                dataobjattr   =>'nfsserver.admteam'),

      new kernel::Field::Link(
                name          =>'secroles',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'sectarget',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                selectable    =>0,
                dataobjattr   =>'lnkcontact.targetid'),

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{use_distinct}=1;

   $self->setDefaultView(qw(system name cistatus mdate comments));
   $self->setWorktable("systemnfsnas");
   return($self);
}

sub LoadFromAppl
{
   my $self=shift;
   my $current=shift;
   my %d;
   my %applid;
   my $fo=$self->getParent->getField("fullsystemidlist");
   $current->{fullsystemidlist}=$fo->RawValue($current);
   if (defined($current->{fullsystemidlist})&&
       ref($current->{fullsystemidlist}) eq "ARRAY" &&
       $#{$current->{fullsystemidlist}}!=-1){
      my $lnk=getModuleObject($self->getParent->Config,
                              "itil::lnkapplsystem");
      $lnk->SetFilter({systemid=>$current->{fullsystemidlist},
                       applcistatusid=>'<=4',
                       systemcistatusid=>'<=4'});
      my @l=$lnk->getHashList("applid");
      foreach my $lnkrec (@l){
         $applid{$lnkrec->{applid}}++;
      }
   }
   if (keys(%applid)){
      my $appl=getModuleObject($self->getParent->Config,
                              "itil::appl");
      $appl->SetFilter({id=>[keys(%applid)]});
      my @l=$appl->getHashList($self->{loadapplfield});
      foreach my $applrec (@l){
         if ($applrec->{$self->{loadapplfield}} ne ""){
            $d{$applrec->{$self->{loadapplfield}}}++;
         }
      }
      return([sort(keys(%d))]);

   }
   return([]);
}

sub CalcSystemIdRelationList
{
   my $self=shift;
   my $current=shift;
   my %ids=();
   my $fo=$self->getParent->getField("systems");
   $current->{systems}=$fo->RawValue($current);
   my $fo=$self->getParent->getField("ipshares");
   $current->{ipshares}=$fo->RawValue($current);
   
   #
   # pass 1 : process system shares
   #
   if (defined($current) && defined($current->{systems}) &&
       ref($current->{systems}) eq "ARRAY"){
      foreach my $clirec (@{$current->{systems}}){
         printf STDERR ("d=%s\n",Dumper($clirec));
         my $sysid=$clirec->{systemid};
         if ($sysid ne ""){
            $ids{$sysid}++;
         }
      }
   }
   #
   # pass 2 : process ip shares
   #
   if (defined($current) && defined($current->{ipshares}) &&
       ref($current->{ipshares}) eq "ARRAY"){
      my @ipq=();
      my $ip=getModuleObject($self->getParent->Config,
                             "itil::ipaddress");
      foreach my $iprec (@{$current->{ipshares}}){
         my ($ipaddr,$bits)=split(/\//,$iprec->{name});
         my @ipaddr=split(/\./,$ipaddr);
         my $ipflt=$ipaddr;
         if ($bits<32){
            if ($bits>=24){
               $ipflt=$ipaddr[0].".".$ipaddr[1].".".
                      $ipaddr[2].".*";
            }
            elsif ($bits>=16){
               $ipflt=$ipaddr[0].".".$ipaddr[1].".*";
            }
            else{
               $ipflt=$ipaddr[0].".*";
            }
         }
         my $network=$iprec->{networkid};
         printf STDERR ("ipfilter=%-15s netbits=%-3d ".
                        "netarea=%-12s ".
                        "flt=$ipflt\n",$ipaddr,$bits,$network);
         push(@ipq,{name=>$ipflt,
                    networkid=>\$network});
      }
      if ($#ipq!=-1){
         $ip->SetFilter(\@ipq);
         foreach my $iprec ($ip->getHashList(qw(name 
                                                systemid))){
            my $match=0;
            foreach my $comprec (@{$current->{ipshares}}){
               if (ipCompare($comprec->{name},
                             $iprec->{name})){
                  $match=1;
                  last;
               }
            }
            if ($match){
            printf STDERR ("fifi process=%s\n",Dumper($iprec));
               $ids{$iprec->{systemid}}++;        
            }
         }
      }
   }
   ############################################################
   return([keys(%ids)]);
}

sub ipCompare
{
   my $net=shift;
   my $ip=shift;

   #printf STDERR ("fifi compare ip=$ip net=$net\n");
   my $netobj=new NetAddr::IP($net);
   my $ipobj=new NetAddr::IP($ip."/32");
   #printf STDERR ("fifi netmask=%s\n",$netobj->mask());
   if ($netobj->contains($ipobj)){
      #printf STDERR ("ok\n");
      return(1);
   }
   #printf STDERR ("fail\n");
   return(0);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                        [qw(REmployee RApprentice RFreelancer RBoss)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {secadm=>\$userid},
                 {secadm2=>\$userid},
                 {secadmteam=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}

sub getSqlFrom
{
   my $self=shift;
   my $from="systemnfsnas ".
            " left outer join system as nfsserver ".
            "on systemnfsnas.system=nfsserver.id".
            " left outer join lnkcontact ".
            "on lnkcontact.parentobj='itil::system' ".
            "and systemnfsnas.system=lnkcontact.refid";

   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $name=~s/\s//g;
   if ($name=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid export path specified");
      return(0);
   }

   my $systemid=effVal($oldrec,$newrec,"systemid");
   if ($systemid<=0){
      $self->LastMsg(ERROR,"invalid system specified");
      return(0);
   } 
   return(0) if (!($self->isParentWriteable($systemid)));
   #return(1) if ($self->IsMemberOf("admin"));

   return(1);
}

sub isParentWriteable
{
   my $self=shift;
   my $systemid=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"itil::system");
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$systemid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid system reference");
      return(0);
   }
   my @write=$p->isWriteValid($l[0]);
   if (!grep(/^ALL$/,@write) && !grep(/^default$/,@write)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }
   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default systems ipshares misc source));
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

   if (defined($rec)){
      return(undef) if (!$self->isParentWriteable($rec->{systemid}));
   }

   return("default","misc","systems","ipshares");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/nfsnas.jpg?".$cgi->query_string());
}



1;
