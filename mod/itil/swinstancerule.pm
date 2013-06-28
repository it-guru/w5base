package itil::swinstancerule;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=6 if (!defined($param{MainSearchFieldLines}));
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
                dataobjattr   =>'swinstancerule.id'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Rule label',
                htmlwidth     =>'400px',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'swinstancerule.rulelabel'),
       
      new kernel::Field::TextDrop(
                name          =>'swinstance',
                htmlwidth     =>'100px',
                label         =>'Software-Instance',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'ruletype',
                selectfix     =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                jsonchanged   =>\&getOnChangedScript,
                label         =>'Rule Type',
                value         =>['FWAPP','FWSYS','IPCLIACL','CFRULE','FREE'],
                dataobjattr   =>'swinstancerule.ruletype'),

      new kernel::Field::Interface(
                name          =>'rawruletype',
                label         =>'Rule Type (Raw)',
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'swinstancerule.ruletype'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>'default',
                label         =>'Rule-State',
                vjoineditbase =>{id=>[qw(2 4 5 6)]},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'link',
                label         =>'Rule-StateID',
                dataobjattr   =>'swinstancerule.cistatus'),

      new kernel::Field::MultiDst(
                name          =>'boundcomponent',
                htmlwidth     =>'200',
                htmleditwidth =>'200',
                selectivetyp  =>1,
                group         =>'link',
                dst           =>['itil::appl'=>'name',
                                 'itil::system'=>'name'
                ],
                vjoineditbase =>[{'cistatusid'=>"<5"},
                                 {'cistatusid'=>"<5"}
                ],
                label         =>'bound target Component',
                altnamestore  =>'parentname',
                dsttypfield   =>'parentobj',
                dstidfield    =>'refid'),

      new kernel::Field::Select(
                name          =>'policy',
                selectfix     =>1,
                label         =>'Policy',
                group         =>['ipfw'],
                value         =>['ALLOW','DENY'],
                dataobjattr   =>'swinstancerule.policy'),

      new kernel::Field::Text(
                name          =>'fromaddr',
                group         =>'ipfw',
                label         =>'from IP-Address',
                dataobjattr   =>'swinstancerule.srcaddr'),

      new kernel::Field::Text(
                name          =>'fromport',
                group         =>'ipfw',
                htmleditwidth =>'80px',
                label         =>'from IP-Port',
                dataobjattr   =>'swinstancerule.srcport'),

      new kernel::Field::Text(
                name          =>'toaddr',
                group         =>'ipfw',
                label         =>'to IP-Address',
                dataobjattr   =>'swinstancerule.srcaddr'),

      new kernel::Field::Text(
                name          =>'toport',
                group         =>'ipfw',
                htmleditwidth =>'80px',
                label         =>'to IP-Port',
                dataobjattr   =>'swinstancerule.srcport'),

      new kernel::Field::Text(
                name          =>'clifromaddr',
                group         =>'ipcliacl',
                label         =>'Client IP-Address',
                dataobjattr   =>'swinstancerule.srcaddr'),

      new kernel::Field::Text(
                name          =>'clitoport',
                group         =>'ipcliacl',
                htmleditwidth =>'80px',
                label         =>'Instance IP-Port',
                dataobjattr   =>'swinstancerule.dstport'),

      new kernel::Field::Text(
                name          =>'varname',
                group         =>'varval',
                label         =>'Variable-Name',
                dataobjattr   =>'swinstancerule.varname'),

      new kernel::Field::Text(
                name          =>'varval',
                group         =>'varval',
                label         =>'Variable-Value',
                dataobjattr   =>'swinstancerule.varval'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>['ipfw','varval','ipcliacl'],
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'swinstancerule.comments'),

      new kernel::Field::Textarea(
                name          =>'freetext',
                group         =>'free',
                label         =>'Free text',
                searchable    =>0,
                dataobjattr   =>'swinstancerule.comments'),

      new kernel::Field::TextDrop(
                name          =>'system',
                group         =>'system',
                label         =>'System',
                searchable    =>0,
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'application',
                group         =>'appl',
                searchable    =>0,
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'swinstanceid',
                group         =>'link',
                dataobjattr   =>'swinstancerule.swinstance'),

      new kernel::Field::Link(
                name          =>'parentname',
                group         =>'link',
                dataobjattr   =>'swinstancerule.parentname'),

      new kernel::Field::Link(
                name          =>'refid',
                group         =>'link',
                dataobjattr   =>'swinstancerule.refid'),

      new kernel::Field::Link(
                name          =>'parentobj',
                group         =>'link',
                dataobjattr   =>'swinstancerule.parentobj'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'swinstancerule.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'swinstancerule.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'swinstancerule.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'swinstancerule.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'swinstancerule.realeditor'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-System',
                dataobjattr   =>'swinstancerule.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-Id',
                dataobjattr   =>'swinstancerule.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'swinstancerule.srcload')
                                                   
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(swinstance fullname cistatus mdate));

   $self->setWorktable("swinstancerule");
   return($self);
}


sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
if (mode=="onchange"){
   document.forms[0].submit();
}
EOF
   return($d);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $ruletype=effVal($oldrec,$newrec,"ruletype");
   my $fullname;
   if ($ruletype eq "FWAPP"){
      $fullname=sprintf("FW-A:%s:%s:%s -> %s:%s",
                effVal($oldrec,$newrec,"policy"),
                effVal($oldrec,$newrec,"fromaddr"),
                effVal($oldrec,$newrec,"fromport"),
                effVal($oldrec,$newrec,"toaddr"),
                effVal($oldrec,$newrec,"toport"));
      if (effVal($oldrec,$newrec,"parentobj") ne "itil::appl"){
         $newrec->{parentobj}="itil::appl";
      }
   }
   elsif ($ruletype eq "FWSYS"){
      $fullname=sprintf("FW-S:%s:%s:%s -> %s:%s",
                effVal($oldrec,$newrec,"policy"),
                effVal($oldrec,$newrec,"fromaddr"),
                effVal($oldrec,$newrec,"fromport"),
                effVal($oldrec,$newrec,"toaddr"),
                effVal($oldrec,$newrec,"toport"));
      if (effVal($oldrec,$newrec,"parentobj") ne "itil::system"){
         $newrec->{parentobj}="itil::system";
      }
   }
   elsif ($ruletype eq "IPCLIACL"){
      $fullname=sprintf("IPACL:%s:%s",
                effVal($oldrec,$newrec,"clifromaddr"),
                effVal($oldrec,$newrec,"clitoport"));
   }
   elsif ($ruletype eq "CFRULE"){
      $fullname=sprintf("VAR:%s=%s",
                effVal($oldrec,$newrec,"varname"),
                effVal($oldrec,$newrec,"varval"));
   }
   elsif ($ruletype eq "FREE"){
      my $s=effVal($oldrec,$newrec,"freetext");
      $s=~s/[^a-z0-9 ]+/ /gi;
      $s=limitlen($s,70,1);
      $fullname=sprintf("FREE:%s",$s);
   }

   if ($fullname ne effVal($oldrec,$newrec,"fullname")){
      $newrec->{fullname}=$fullname;
   }

   my $swinstanceid=effVal($oldrec,$newrec,"swinstanceid");

   if ($swinstanceid eq ""){
      $self->LastMsg(ERROR,"no valid software instance specified");
      return(0);
   }
   my $writeok=0;
   if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
       $swinstanceid,"swinstancerules")){
      $writeok++;
   }
   if (!$writeok){
      if ((!defined($oldrec) && $newrec->{cistatusid}==2) ||
          (defined($oldrec) && $oldrec->{cistatusid}==2 &&
           $newrec->{cistatusid}==2)){
         # validate access to request a new rule (bound component access)
         if ($ruletype eq "FWSYS"){ 
            # check write access to logical system
            my $sysid=effVal($oldrec,$newrec,"refid");
         }
         elsif ($ruletype eq "FWAPP"){ 
            # check write access to logical system
            my $appid=effVal($oldrec,$newrec,"refid");
         }
      }
   }
   if (!$writeok){
      $self->LastMsg(ERROR,"no necessary write access");
      return(0);
   }



   return(1);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header);
   my $ruletype=Query->Param("Formated_ruletype");
   $ruletype="FWAPP" if ($ruletype eq "" && Query->Param("FUNC") eq "New");


   push(@l,"system","ipfw") if (!defined($rec) && $ruletype eq "FWSYS");
   push(@l,"appl","ipfw")   if (!defined($rec) && $ruletype eq "FWAPP");
   push(@l,"varval")        if (!defined($rec) && $ruletype eq "CFRULE");
   push(@l,"free")          if (!defined($rec) && $ruletype eq "FREE");
   push(@l,"ipcliacl")      if (!defined($rec) && $ruletype eq "IPCLIACL");
  
   return(@l) if (!defined($rec));

   $ruletype=$rec->{ruletype};

   push(@l,"system","ipfw","link") if ($ruletype eq "FWSYS" && defined($rec));
   push(@l,"appl","ipfw","link") if ($ruletype eq "FWAPP" && defined($rec));
   push(@l,"varval")             if ($ruletype eq "CFRULE" && defined($rec));
   push(@l,"free")               if ($ruletype eq "FREE"   && defined($rec));
   push(@l,"ipcliacl")           if ($ruletype eq "IPCLIACL" && defined($rec));
   push(@l,"source") if (defined($rec));
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   if (!defined($rec)){
      $rw++;
   }
   else{
      if ($rec->{cistatusid}==2){  # check access by bound item
      }
      if (!$rw){
         my $swid=$rec->{swinstanceid};
         if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
             $swid,"swinstancerules")){
            $rw++;
         }
      }

   }

   return(qw(default ipfw link appl system varval ipcliacl free)) if ($rw);
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ipfw ipcliacl varval free link system appl source));
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}









1;
