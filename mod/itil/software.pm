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
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
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
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'software.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'producer',
                label         =>'Producer',
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
                label         =>'Owner',
                dataobjattr   =>'software.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'software.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'software.realeditor'),
   

   );
   $self->setDefaultView(qw(name id cistatus mdate cdate));
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.itil.software"],
                         uniquesize=>255};
   $self->{history}=[qw(insert modify delete)];
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
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
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
   return(qw(header default doccontrol phonenumbers source));
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
   return("default","doccontrol","phonenumbers") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isCopyValid
{
   my $self=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}




1;
