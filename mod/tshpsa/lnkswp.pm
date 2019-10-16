package tshpsa::lnkswp;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
use kernel::Field::DataMaintContacts;


@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'SoftwareProcessID',
                htmldetail    =>0,
                dataobjattr   =>"id"),

      new kernel::Field::Text(
                name          =>'systemid',
                group         =>'source',
                label         =>'ObjectID',
                dataobjattr   =>'sysid'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                nowrap        =>1,
                htmlwidth     =>'120',
                htmldetail    =>0,
                label         =>'Process entry fullname',
                dataobjattr   =>'fullname'),

      new kernel::Field::Text(
                name          =>'softwarename',
                ignorecase    =>1,
                nowrap        =>1,
                searchable    =>0,
                htmlwidth     =>'120',
                label         =>'based on Software',
                depend        =>['softwareid','software','class'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $soft=$self->getParent->getField("software");
                   my $s=$soft->RawValue($current);
                   if ($s ne ""){
                      return($s);
                   }
                   return($current->{class});
                }),

      new kernel::Field::Text(
                name          =>'class',
                ignorecase    =>1,
                nowrap        =>1,
                htmlwidth     =>'120',
                label         =>'Software-Key',
                dataobjattr   =>'swclass'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'version',
                dataobjattr   =>'swvers'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Hostname',
                group         =>'rel',
                vjointo       =>\'tshpsa::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                group         =>'rel',
                selectfix     =>1,
                vjointo       =>\'tshpsa::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5appl',
                label         =>'usable from applications',
                group         =>'w5basedata',
                searchable    =>0,
                weblinkto     =>'none',
                vjointo       =>\'itil::system',
                vjoinon       =>['systemsystemid'=>'systemid'],
                vjoindisp     =>['applicationnames']),

      new kernel::Field::Text(
                name          =>'softwareid',
                label         =>'SoftwareID',
                group         =>'w5basedata',
                searchable    =>0,
                depend        =>['class'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id;
                   if ($current->{class} ne ""){
                      if ($current->{class} eq "Oracle DB" ||
                          $current->{class} eq "Oracle_Database"){
                         $id="9";
                      }
                      #elsif ($current->{class} eq "Java"){
                      #   $id="12687513960002";
                      #}
                      else{
                         my ($iid)=$current->{class}=~m/\[(\d+)\]$/;
                         $id=$iid;
                      }
                   }
                   return($id);
                }),

      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                searchable    =>0,
                group         =>'w5basedata',
                vjoineditbase =>{cistatusid=>[3,4]},
                vjointo       =>\'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Boolean(
                name          =>'is_dbs',
                label         =>'is DBS (Databasesystem) software',
                htmldetail    =>0,
                depend        =>[qw(class software)],
                readonly      =>1,
                group         =>'w5basedata',
                vjointo       =>\'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'is_dbs'),

      new kernel::Field::Boolean(
                name          =>'is_mw',
                label         =>'is MW (Middleware) software',
                htmldetail    =>0,
                readonly      =>1,
                depend        =>[qw(class software)],
                group         =>'w5basedata',
                vjointo       =>\'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'is_mw'),

      new kernel::Field::Text(
                name          =>'path',
                label         =>'path',
                dataobjattr   =>'swpath'),

      new kernel::Field::Text(
                name          =>'uname',
                label         =>'ProcessUser',
                dataobjattr   =>'iname'),

      new kernel::Field::Text(
                name          =>'scandate',
                label         =>'Scandate',
                dataobjattr   =>'scandate'),

     new kernel::Field::Text(
                name          =>'softwareset',
                readonly      =>1,
                htmldetail    =>0,
                selectsearch  =>sub{
                   my $self=shift;
                   my $ss=getModuleObject($self->getParent->Config,
                                          "itil::softwareset");
                   $ss->SecureSetFilter({cistatusid=>4});
                   my @l=$ss->getVal("name");
                   unshift(@l,"");
                   return(@l);
                },
                searchable    =>1,
                group         =>'softsetvalidation',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                label         =>'validate against Software Set',
                onPreProcessFilter=>sub{
                   my $self=shift;
                   my $hflt=shift;
                   if (defined($hflt->{$self->{name}})){
                      my $f=$hflt->{$self->{name}};
                      if (ref($f) ne "ARRAY"){
                         $f=~s/^"(.*)"$/$1/;
                         $f=[$f];
                      }
                      $self->getParent->Context->{FilterSet}={
                         $self->{name}=>$f
                      };
                      delete( $hflt->{$self->{name}})
                   }
                   else{
                      delete($self->getParent->Context->{FilterSet} );
                   }
                   return(0);
                },
                onRawValue    =>sub{
                   my $self=shift;
                   my $FilterSet=$self->getParent->Context->{FilterSet};
                   return($FilterSet->{softwareset});
                }),

     new kernel::Field::Text(
                name          =>'softwarerelstate',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>[qw(softwareid softwarename software 
                                    class denyupselect denyupd denyupdvalidto)],
                group         =>'softsetvalidation',
                label         =>'Software release state',
                onRawValue    =>\&calcSoftwareState),

     new kernel::Field::Textarea(
                name          =>'softwarerelmsg',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>[qw(softwareid softwarename software 
                                    class denyupselect denyupd denyupdvalidto)],
                group         =>'softsetvalidation',
                label         =>'Software release message',
                onRawValue    =>\&calcSoftwareState),


      new kernel::Field::Select(
                name          =>'denyupselect',
                label         =>'it is posible to update Software',
                group         =>'upd',
                vjoineditbase =>{id=>"!99"},
                jsonchanged   =>\&itil::lib::Listedit::getupdateDenyHandlingScript,
                jsoninit      =>\&itil::lib::Listedit::getupdateDenyHandlingScript,
                vjointo       =>\'itil::upddeny',
                vjoinon       =>['denyupd'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'denyupd',
                group         =>'upd',
                default       =>'0',
                label         =>'UpdDenyID',
                dataobjattr   =>'denyupd'),

      new kernel::Field::Textarea(
                name          =>'denyupdcomments',
                group         =>'upd',
                label         =>'comments to Update/Refresh posibilities',
                dataobjattr   =>'denyupdcomments'),

      new kernel::Field::Text(
                name          =>'releasekey',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Releasekey',
                depend        =>['version'],
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $version=$current->{version};
                   return(itil::lib::Listedit::Version2Key($version)); 
                }),


     new kernel::Field::Date(
                name          =>'denyupdvalidto',
                group         =>'upd',
                htmldetail    =>sub{
                                   my $self=shift;
                                   my $mode=shift;
                                   my %param=@_;
                                   if (defined($param{current})){
                                      my $d=$param{current}->{$self->{name}};
                                      return(1) if ($d ne "");
                                   }
                                   return(0);
                                },
                label         =>'Update/Upgrade reject valid to',
                dataobjattr   =>'ddenyupdvalidto'),

      new kernel::Field::Link(
                name          =>'w5systemid',
                label         =>'W5BaseID of relevant System',
                group         =>'w5basedata',
                vjointo       =>'itil::system',
                vjoinon       =>['systemsystemid'=>'systemid'],
                vjoindisp     =>'id'),

      new kernel::Field::Text(
                name          =>'w5systemname',
                label         =>'relevant logical System Config-Item',
                group         =>'w5basedata',
                searchable    =>0,
                vjointo       =>\'AL_TCom::system',
                vjoinon       =>['w5systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::DataMaintContacts(
                vjointo       =>\'itil::system',
                vjoinon       =>['w5systemid'=>'id'],
                group         =>'w5basedata'),

      new kernel::Field::Text(
                name          =>'srcsys',
                selectfix     =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"'T03TC_UC128.UC128_1_MW_REPORT\@XAUTOM'"),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'srcload'),

   );
   $self->setWorktable("HPSA_lnkswp_of");
   $self->setDefaultView(qw(systemname class version path iname));
   return($self);
}

sub calcSoftwareState
{
   my $self=shift;
   my $current=shift;

   my $class="tshpsa::lnkswp";
   my $f=$self->getParent->getField("softwarename");
   my $softwarename=$f->RawValue($current);


   return(itil::lib::Listedit::calcSoftwareState($self,$current,$class,$softwarename));
}

sub getAnalyseSoftwareStateRecordsIndexed
{
   my $self=shift;
   my @key=@_;
   my $res={};

   $self->SetCurrentView(qw(systemid class 
                            system software denyupd denyupdvalidto
                            releasekey version softwareid is_dbs is_mw
                            w5basedata));


   $self->doInitialize();
   @key=($self->{'fields'}->[0]) if ($#key==-1);
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
         my $ok=1;
         if ($rec->{class} eq "Oracle_Database"){
            $rec->{softwareid}=9;
         }
         if ($rec->{version} eq ""){
            $ok=0;
         }
         if ($ok){
            foreach my $key (@key){
               my $v=$rec->{$key};
               next if (!defined($v));
               if (exists($res->{$key}->{$v})){
                  if ($key eq "id"){
                     msg(ERROR,"getAnalyseSoftwareStateRecordsIndexed for ".
                               $self->Self." not unique id in record ".
                               "'".$v."'");
                  }
                  else{
                     if (ref($res->{$key}->{$v}) ne "ARRAY"){
                        $res->{$key}->{$v}=[$res->{$key}->{$v}];
                     }
                     push(@{$res->{$key}->{$v}},$rec);
                  }
               }
               else{
                  $res->{$key}->{$v}=$rec;
               }
            }
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   #else{
   #   msg(ERROR,"getHashIndexed returned '%s' on getFirst",$msg);
   #}
   return($res);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="HPSA_lnkswp";

   return($from);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   $newrec->{id}=$oldrec->{id};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->itil::lib::Listedit::updateDenyHandling($oldrec,$newrec)){
      return(0);
   }
   return(1);
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","upd","rel","w5basedata","source");
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemsystemid}=~m/^S.*\d+$/));

   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter({systemid=>\$rec->{systemsystemid}});
   my ($sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my @l=$sys->isWriteValid($sysrec);

   if (in_array(\@l,[qw(upd ALL)]) || $self->IsMemberOf("admin")){
      return("upd");
   }
   return(undef);
}




#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
#}
         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


1;
