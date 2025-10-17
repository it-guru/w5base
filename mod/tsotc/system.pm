package tsotc::system;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'OTC-SystemID',
                dataobjattr   =>"otc4darwin_server_vw.server_uuid"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Systemname',
                dataobjattr   =>"server_name"),

      new kernel::Field::Text(
                name          =>'altname',
                sqlorder      =>'desc',
                label         =>'alternate Systemname',
                depend        =>["name","cdateunixtimstamp"],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $name=$current->{name};
                   $name=TextShorter($name,40);
                   $name=~s/[^a-z0-9_-]/_/g;

                   return(lc($name."__".base36($current->{cdateunixtimstamp})));
                }),

      new kernel::Field::Text(
                name          =>'state',
                sqlorder      =>'desc',
                label         =>'System State',
                dataobjattr   =>"otc4darwin_server_vw.vm_state"),

      new kernel::Field::Email(
                name          =>'contactemail',
                label         =>'Contact email',
                dataobjattr   =>"lower(metadata.asp)"),

      new kernel::Field::Text(
                name          =>'projectname',
                label         =>'Project',
                weblinkto     =>\'tsotc::project',
                weblinkon     =>['projectid'=>'id'],
                dataobjattr   =>"otc4darwin_projects_vw.project_name"),

      new kernel::Field::Text(
                name          =>'availability_zone',
                label         =>'Availability Zone',
                dataobjattr   =>"availability_zone"),

      new kernel::Field::Text(
                name          =>'flavor_name',
                label         =>'Flavor',
                dataobjattr   =>"flavor_name"),

      new kernel::Field::Text(
                name          =>'image_name',
                label         =>'Image',
                dataobjattr   =>"image_name"),

      new kernel::Field::Text(
                name          =>'cpucount',
                label         =>'CPU-Count',
                dataobjattr   =>"vcpus"),

      new kernel::Field::Number(
                name          =>'memory',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'ram'),

      new kernel::Field::Interface(
                name          =>'projectid',
                label         =>'OTC-ProjectID',
                dataobjattr   =>'otc4darwin_server_vw.project_uuid'),

      new kernel::Field::SubList(
                name          =>'iaascontacts',
                label         =>'IaaS Contacts',
                group         =>'iaascontacts',
                vjointo       =>\'tsotc::lnksystemiaascontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'iaccontacts',
                label         =>'IaC Contacts',
                group         =>'iaccontacts',
                vjointo       =>\'tsotc::lnksystemiaccontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Addresses',
                group         =>'ipaddresses',
                vjointo       =>\'tsotc::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['name',"hwaddr"]),

      new kernel::Field::Text(
                name          =>'cdateunixtimstamp',
                group         =>'source',
                label         =>'Creation-Unixtimestamp',
                timezone      =>'CET',
                dataobjattr   =>"extract(epoch from date_created ".
                                "at time zone 'CET')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_created"),

#      new kernel::Field::Text(
#                name          =>'appl',
#                htmlwidth     =>'150px',
#                group         =>'source',
#                label         =>'Application',
#                vjointo       =>\'itil::appl',
#                vjoinon       =>['appw5baseid'=>'id'],
#                vjoindisp     =>'name'),
#
#      new kernel::Field::Text(
#                name          =>'appw5baseid',
#                group         =>'source',
#                label         =>'Application W5BaseID',
#                dataobjattr   =>'metadata.darwin_app_w5baseid'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_updated"),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                timezone      =>'CET',
                dataobjattr   =>"otc4darwin_server_vw.db_timestamp"),

   );
   $self->setDefaultView(qw(name state projectname cpucount memory
                            id availability_zone cdate ));
   $self->setWorktable("otc4darwin_server_vw");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my @view=$self->getCurrentView();

   my $from="$worktable ";
   if (in_array(\@view,["ALL","contactemail"])){
      $from.="left outer join ( ".
             "select distinct ON(server_uuid) server_uuid,asp,".
             "darwin_app_w5baseid,w from (".
               "select * from (".
                 "select distinct server_uuid,asp,darwin_app_w5baseid,".
                    "(case when asp is not null then 1 else 0 end) +".
                    "(case when darwin_app_w5baseid is not null ".
                           "then 1 else 0 end) as w ".
                    "from otc4darwin_ias_srv_metadata_vw ".
                 " union ".
                    "select distinct server_uuid,asp,darwin_app_w5baseid, ".
                    "(case when asp is not null then 1 else 0 end) + ".
                    "(case when darwin_app_w5baseid is not null ".
                           "then 1 else 0 end) as w ".
                    "from otc4darwin_iac_srv_metadata_vw ".
                ") as prepremeta order by server_uuid,w desc ".
              ") as premetadata ".
             ") as metadata on ".
             "otc4darwin_server_vw.server_uuid=metadata.server_uuid ";
   }

   $from.="join (".
            "select distinct project_uuid,project_name ".
             "from otc4darwin_projects_vw ".
          ") as otc4darwin_projects_vw ".
          "on otc4darwin_server_vw.project_uuid=".
          "otc4darwin_projects_vw.project_uuid";
   return($from);
}



sub Initialize
{
   my $self=shift;

   my $errors;
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsotc"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","iaascontacts","iaccontacts","ipaddresses",
          "source");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
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
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}


sub ImportSystem
{
   my $self=shift;

   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"OTC System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   if ($param->{importname} ne ""){
      $importname=$param->{importname};
      $importname=~s/[^a-z0-9_-].*$//i; # prevent wildcard and or filters
      if ($importname ne ""){
         if ($importname=~m/^[0-9a-f]{8}-
                             [0-9a-f]{4}-
                             [0-9a-f]{4}-
                             [0-9a-f]{4}-
                             [0-9a-f]{12}$/xi){
            $flt={id=>$importname};
            #printf STDERR ("use uuid mode\n");
         }
         else{
            $flt={name=>$importname};
         }
      }
      else{
         return(undef);
      }
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }

   my $system=getModuleObject($self->Config,"TS::system");

   ########################################################################
   # Detect Cloud Record
   ########################################################################
   my $itcloud=getModuleObject($self->Config,"itil::itcloud");
   my $cloudrec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({name=>'OTC',cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
      if (defined($crec)){
         $cloudrec=$crec;
      }
   }

   ########################################################################
   # Detect System Record from Remote System
   ########################################################################
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(name altname 
                               cdate id contactemail availability_zone
                               projectid ipaddresses));
   if ($#l==-1){
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"Systemname '%s' not found in OTC",$importname);
      }
      else{
         $self->Log(WARN,"basedata",
                 sprintf("Systemname '%s' not found in OTC",$importname));
      }
      return(undef);
   }
   if ($#l>0){
      {
         #######################################################################
         if (defined($itcloud) && ref($cloudrec) eq "HASH"){  # das solllte
            my %notifyParam=(                                 # in die generic
                mode=>'ERROR',
                emailbcc=>11634953080001 # hartmut
            );
            if ($cloudrec->{supportid} ne ""){
               $notifyParam{emailcc}=$cloudrec->{supportid};
            }
            push(@{$notifyParam{emailcategory}},"SystemImport");
            push(@{$notifyParam{emailcategory}},"ImportFail");
            push(@{$notifyParam{emailcategory}},"OTC");

            $itcloud->NotifyWriteAuthorizedContacts($cloudrec,
                  {},\%notifyParam,
                  {mode=>'ERROR'},sub{
               my ($subject,$ntext);
               my $subject="OTC cloud systemname configuration error";
               my $ntext="the systemname '".$param->{importname}."' is ".
                         "not unique in OTC";
               $ntext.="\n";
               return($subject,$ntext);
            });
         }
         #######################################################################
      }
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"Systemname '%s' not unique in OTC",
                              $param->{importname});
      }
      return(undef);
   }

   my $sysrec=$l[0];

   my %ipaddresses;
   foreach my $iprec (@{$sysrec->{ipaddresses}}){
      $ipaddresses{$iprec->{name}}={
         name=>$iprec->{name}
      };
   }

   # sysimporttempl is needed for 1st generic insert an refind a redeployment
   my $sysimporttempl={
      name=>$sysrec->{name},
      id=>$sysrec->{id},
      srcid=>$sysrec->{id},
      ipaddresses=>[values(%ipaddresses)]
   };


   my $w5carec;

   ########################################################################
   # Detect CloudArea Record and Appl-Record
   ########################################################################
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
   if ($sysrec->{projectid} ne ""){
      $cloudarea->SetFilter({srcsys=>\'tsotc::project',
                             srcid=>\$sysrec->{projectid}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }

   my $ImportRec={
      cloudrec=>$cloudrec,
      cloudarearec=>$w5carec,
      imprec=>$sysimporttempl,
      srcsys=>'OTC',
      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
         my $osys=shift;                # exists in srcobj
         my $srcid=$osys->{srcid};
         return({id=>\$srcid});
      }
   };
   my $ImportObjects={   # Objects are in seperated Structur for better Dumping
      itcloud=>$itcloud,
      itcloudarea=>$cloudarea,
      appl=>$appl,
      system=>$system,
      srcobj=>$self
   };

   #printf STDERR ("ImportRec(imprec):%s\n",Dumper($ImportRec->{imprec}));
   my $ImportResult=$system->genericSystemImport($ImportObjects,$ImportRec);
   #printf STDERR ("ImportResult:%s\n",Dumper($ImportResult));

   return($ImportResult->{IdentifedBy});
}

1;
