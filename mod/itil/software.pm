package itil::software;
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
                dataobjattr   =>'software.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                uploadable    =>0,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'Fullname',
                dataobjattr   =>"concat(producer.name,
                                 if(producer.name<>'','-',''),software.name)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'software.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'software.cistatus'),

      new kernel::Field::TextURL(
                name          =>'iurl',
                label         =>'Internet-Product-URL',
                dataobjattr   =>'software.iurl'),

      new kernel::Field::TextDrop(
                name          =>'producer',
                label         =>'Producer',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::producer',
                vjoinon       =>['producerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'producerid',
                dataobjattr   =>'software.producer'),

      new kernel::Field::Contact(
                name          =>'compcontact',
                AllowEmpty    =>1,
                group         =>'doccontrol',
                label         =>'competent contact',
                vjoinon       =>'compcontactid'),

      new kernel::Field::Link(
                name          =>'compcontactid',
                group         =>'doccontrol',
                label         =>'competent contact id',
                dataobjattr   =>'software.compcontact'),

      new kernel::Field::Contact(
                name          =>'depcompcontact',
                AllowEmpty    =>1,
                group         =>'doccontrol',
                label         =>'deputy competent contact',
                vjoinon       =>'depcompcontactid'),

      new kernel::Field::Link(
                name          =>'depcompcontactid',
                group         =>'doccontrol',
                label         =>'deputy competent contact id',
                dataobjattr   =>'software.depcompcontact'),

      new kernel::Field::Text(
                name          =>'releaseexp',
                group         =>'doccontrol',
                label         =>'Release Expression',
                dataobjattr   =>'software.releaseexp'),


      new kernel::Field::Boolean(
                name          =>'docsig',
                group         =>'doccontrol',
                label         =>'Documentation significant',
                dataobjattr   =>'software.docsig'),

      new kernel::Field::Select(
                name          =>'rightsmgmt',
                label         =>'rights managed',
                group         =>'doccontrol',
                transprefix   =>'right.',              
                value         =>['OPTIONAL','YES','NO'],
                translation   =>'itil::software',
                htmleditwidth =>'100px',
                dataobjattr   =>'software.rightsmgmt'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjointo       =>'itil::lnksoftwarecontact',
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::software'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Boolean(
                name          =>'releasesam0',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: emty release allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],""));
                }),

      new kernel::Field::Text(
                name          =>'pclass',
                selectfix     =>1,
                group         =>'pclass',
                label         =>'Product Class',
                dataobjattr   =>'software.productclass'),
                                                   
      new kernel::Field::Interface(
                name          =>'parentid',
                group         =>['pclass','default'],
                label         =>'parent product id',
                dataobjattr   =>'software.parent'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'parentproduct',
                group         =>'pclass',
                label         =>'parent product',
                AllowEmpty    =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (!defined($current));
                   return(1) if ($current->{pclass} eq "OPTION");
                   return(0);
                },
                vjointo       =>'itil::software',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'instanceid',
                group         =>'pclass',
                label         =>'Instance idenficator',
                dataobjattr   =>'software.instanceidentify'),
                                                   
      new kernel::Field::Boolean(
                name          =>'is_dbs',
                group         =>'pclass',
                label         =>'is DBS (Databasesystem) software',
                dataobjattr   =>'software.is_dbs'),

      new kernel::Field::Boolean(
                name          =>'is_mw',
                group         =>'pclass',
                label         =>'is MW (Middleware) software',
                dataobjattr   =>'software.is_mw'),

      new kernel::Field::Boolean(
                name          =>'is_dms',
                group         =>'pclass',
                label         =>'is DMS (Documentmanagement) software',
                dataobjattr   =>'software.is_dms'),

      new kernel::Field::Boolean(
                name          =>'releasesam1',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 5 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"5"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam2',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 2.1 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"2.1"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam3',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 3.4.1 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"3.4.1"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam4',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 3.5.1p1 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"3.5.1p1"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam5',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 6.7.1.3 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"6.17.1.3"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam6',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 14.7.1.3.9 allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"14.7.1.3.9"));
                }),

      new kernel::Field::Boolean(
                name          =>'releasesam7',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'doccontrol',
                depend        =>['releaseexp'],
                label         =>'release control: sample 4a allowed',
                onRawValue    =>sub{
                   return(releaseSample($_[0],$_[1],"4a"));
                }),

      new kernel::Field::Number(
                name          =>'lnksystemcount',
                group         =>'relations',
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'System relation count',
                depend        =>'lnkactivesystems',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $n=0;
                   my $fo=$self->getParent->getField("lnkactivesystems");
                   my $d=$fo->RawValue($current);
                   if (ref($d) eq "ARRAY"){
                      foreach my $r (@$d){
                         $n++;
                      }
                   }
                   else{
                      if ($d ne ""){
                         $n++;
                      }
                   }
                   return($n);
                }),

      new kernel::Field::JoinUniqMerge(
                name          =>'lnksystemversions',
                group         =>'relations',
                transprefix   =>'',
                default       =>'',
                master        =>'',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                label         =>'active software versions',
                depend        =>'lnkactivesystems',
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinbase     =>['systemcistatusid'=>'4'],
                vjoinon       =>['id'=>'softwareid'],
                vjoindisp     =>'version'),

      new kernel::Field::Text(
                name          =>'lnksystems',
                group         =>'relations',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                label         =>'system relations',
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinon       =>['id'=>'softwareid'],
                vjoindisp     =>'system'),

      new kernel::Field::Text(
                name          =>'lnkactivesystems',
                group         =>'relations',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                label         =>'active system relations',
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinbase     =>['systemcistatusid'=>'4'],
                vjoinon       =>['id'=>'softwareid'],
                vjoindisp     =>'system'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'software.comments'),

      new kernel::Field::SubList(
                name          =>'options',
                label         =>'Options',
                group         =>'options',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.options',
                vjointo       =>'itil::software',
                vjoinon       =>['id'=>'parentid'],
                vjoinbase     =>[{pclass=>\'OPTION',cistatusid=>"<=5"}],
                vjoindisp     =>['name','cistatus']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   my $d=$rec->{$self->Name()};
                   if (ref($d) eq "HASH" && keys(%$d)){
                      return(1);
                   }
                   return(0);
                },
                dataobjattr   =>'software.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'software.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'software.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'software.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'software.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'software.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"software.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(software.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'software.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'software.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'software.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'software.realeditor'),
   

   );
   $self->setDefaultView(qw(name id cistatus mdate cdate));
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin",
                                     "w5base.softwaremgmt.admin"],
                         uniquesize=>255};
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{PhoneLnkUsage}=\&PhoneUsage;

   $self->setWorktable("software");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ".
            "left outer join producer on software.producer=producer.id";

   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneHot);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}


sub releaseSample
{
   my $self=shift;
   my $current=shift;
   my $version=shift;

   my $fo=$self->getParent->getField("releaseexp");
   my $releaseexp=$fo->RawValue($current);

   if (!($releaseexp=~m/^\s*$/)){
      my $chk;
      eval("\$chk=\$version=~m$releaseexp;");
      if ($@ ne "" || !($chk)){
         return(0);
      }
   }
   return(1);

}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/software.jpg?".$cgi->query_string());
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (exists($newrec->{name})){
      $newrec->{name}=~s/\s+/_/g;
   }
   if (exists($newrec->{pclass})){
      if ($newrec->{pclass} ne "MAIN" &&
          $newrec->{pclass} ne "OPTION"){
         $self->LastMsg(ERROR,"invalid pclass spezified");
         return(undef);
      }
   }
   if (effVal($oldrec,$newrec,"pclass") ne "OPTION"){
      if (effVal($oldrec,$newrec,"parentid") ne ""){
         $newrec->{parentid}=undef;
      }
   }
   if (effVal($oldrec,$newrec,"pclass") eq "OPTION"){
      if (exists($newrec->{parentid}) && $newrec->{parentid} eq "" &&
          $oldrec->{parentid} ne ""){
         $self->LastMsg(ERROR,"on options, parent could not be deleted");
         return(undef);
      }
      if (exists($newrec->{parentid}) && 
          $oldrec->{parentid} ne "" &&
          $newrec->{parentid} ne $oldrec->{parentid}){
         $self->LastMsg(ERROR,"on options, parent could not be changed");
         return(undef);
      }
   }
   if (!defined($oldrec) ||
       effChanged($oldrec,$newrec,"iurl")){
      if (!$self->IsMemberOf("admin")){
         if (effVal($oldrec,$newrec,"iurl") eq ""){
            $self->LastMsg(ERROR,"specifing of internet product ".
                                 "url is mandatory");
            return(undef);
         }
      }
   }


   if (!defined($oldrec) &&
        $newrec->{pclass} eq "OPTION" &&
        $newrec->{parentid} ne ""){
      my $s=getModuleObject($self->Config,"itil::software");
      $s->SetFilter({id=>\$newrec->{parentid}});
      my ($prec,$msg)=$s->getOnlyFirst(qw(cistatusid producerid));
      if (!defined($prec)){
         $self->LastMsg(ERROR,"invalid parent software product specified");
         return(undef);
      }
      if (!defined($newrec->{producerid})){
         $newrec->{producerid}=$prec->{producerid};
      }
   }
   if (!(trim(effVal($oldrec,$newrec,"producerid"))=~m/^\d+$/)){
      $self->LastMsg(ERROR,"invalid producer specified");
      return(0);
   }
   if (!defined($oldrec) && !exists($newrec->{'releaseexp'})){
      if ($newrec->{'releaseexp'}=~m/^\s*$/){
         $newrec->{'releaseexp'}='/^\d{1,2}(\.\d{1,2}){1,3}$/';
      }
      $newrec->{'releaseexp'}.="/" if (!($newrec->{'releaseexp'}=~m/\/$/));
      if (!($newrec->{'releaseexp'}=~m/^\//)){
         $newrec->{'releaseexp'}="/".$newrec->{'releaseexp'};
      }
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default options doccontrol pclass contacts 
             phonenumbers source));
}




sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   my @l;
   push(@l,"default","doccontrol","phonenumbers","class") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   if (defined($rec) && $rec->{pclass} eq "MAIN"){
      push(@l,"options");
   }
   if ($self->IsMemberOf(["admin","w5base.softwaremgmt.admin"])){
      push(@l,"pclass","contacts");
   }
   return(@l);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->isWriteValid($rec);
   return(1) if (in_array(\@l,"default"));
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   if ($rec->{pclass} ne "MAIN"){
      return("header","default","source","doccontrol","pclass","history");
   }
   return("ALL");
}

sub isCopyValid
{
   my $self=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"SoftwareExpressionValidate");
   return(@l);
}


sub SoftwareExpressionValidate
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            name=>{
               typ=>'STRING',
               path=>0,
               init=>'Apache_WebServer'
            },
            version=>{
               typ=>'STRING',
               path=>1,
               init=>'1.2.3'
            },
            id=>{
               typ=>'STRING'
            },
         },undef,\&doSoftwareExpressionValidate,@_)
   );
}


sub doSoftwareExpressionValidate
{
   my $self=shift;
   my $param=shift;
   my $r={};
   my $limit=50;

   $param->{name}=~s/[\*\s\?,'"]//g;
   $param->{id}=~s/[\*\s\?,'"]//g;

   if (length($param->{name})<2 && length($param->{id})<2){
      return({
         exitcode=>100,
         exitmsg=>"'name' filter not specific enough"
      });
   }

   $self->ResetFilter();

   my %flt=();

   if ($param->{name} ne ""){
      $flt{name}="*".$param->{name}."*";
      $flt{cistatusid}=[3,4,5];
   }
   if ($param->{id} ne ""){
      $flt{id}=\$param->{id};
   }

   $self->SetFilter(\%flt);
   $self->Limit($limit+1);
   my @l=$self->getHashList(qw(name id cistatusid urlofcurrentrec releaseexp));
   
   $r->{data}=\@l;
   if ($#l>=$limit){
      $r->{ResultIncomplete}=1;
      $r->{data}=[@l[0..($limit-1)]];
   }
   if ($param->{version} ne ""){
      $r->{version}=$param->{version};
      foreach my $rec (@{$r->{data}}){
         my $chkrec={
            softwareid=>$rec->{id},
            version=>$param->{version}
         };
         my $chk=$self->validateSoftwareVersion(undef,$chkrec,1);
         $chk="0" if (!$chk);
         $rec->{releaseexp_version_match}=$chk;
      }
   }
  





   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}







1;
