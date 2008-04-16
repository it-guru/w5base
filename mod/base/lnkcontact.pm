package base::lnkcontact;
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
use Data::Dumper;
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
                label         =>'LinkID',
                dataobjattr   =>'lnkcontact.id'),
                                                 
      new kernel::Field::Text(
                name          =>'parentobj',
                label         =>'Parent-Object',
                dataobjattr   =>'lnkcontact.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                label         =>'RefID',
                dataobjattr   =>'lnkcontact.refid'),

      new kernel::Field::MultiDst (
                name          =>'targetname',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                label         =>'Target-Name',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                vjoineditbase =>[{'cistatusid'=>[3,4]},
                                 {'cistatusid'=>4,
                                  'usertyp'=>['user','extern','function']},
                                ],
                dsttypfield   =>'target',
                dstidfield    =>'targetid'),

      new kernel::Field::DynWebIcon(
                name          =>'targetweblink',
                searchable    =>0,
                depend        =>['target','targetid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $targeto=$self->getParent->getField("target");
                   my $target=$targeto->RawValue($current);

                   my $targetido=$self->getParent->getField("targetid");
                   my $targetid=$targetido->RawValue($current);
                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest;
                   if ($target eq "base::user"){
                      $dest="../../base/user/Detail?userid=$targetid";
                   }
                   if ($target eq "base::grp"){
                      $dest="../../base/grp/Detail?grpid=$targetid";
                   }
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-only a web useable link-");
                }),


      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkcontact.expiration'),
                                                 
      new kernel::Field::Text(
                name          =>'comments',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'lnkcontact.comments'),

      new kernel::Field::Select(
                name          =>'roles',
                label         =>'Roles',
                htmleditwidth =>'100%',
                multisize     =>5,
                container     =>'croles',
                getPostibleValues=>\&getPostibleRoleValues),
                                                 
      new kernel::Field::Container(
                name          =>'croles',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'target',
                label         =>'Target-Typ',
                dataobjattr   =>'target'),
                                                 
      new kernel::Field::Link(
                name          =>'targetid',
                dataobjattr   =>'targetid'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkcontact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkcontact.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkcontact.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkcontact.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkcontact.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkcontact.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkcontact.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkcontact.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkcontact.realeditor'),
   );
   $self->setDefaultView(qw(parentobj targetname cdate editor));
   $self->LoadSubObjs("ext/lnkcontact","lnkcontact");
   return($self);
}

sub getPostibleRoleValues
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   my @opt;
   foreach my $obj (values(%{$app->{lnkcontact}})){
      push(@opt,$obj->getPosibleRoles($self,$current));
   }
   return(@opt);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/lnkcontact.jpg?".$cgi->query_string());
}

sub getRecordHtmlIndex
{ return(); }



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("lnkcontact");
   return(1);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $targetid=effVal($oldrec,$newrec,"targetid");
   my $target=effVal($oldrec,$newrec,"target");
   if ($target eq "" || $targetid eq ""){
      $self->LastMsg(ERROR,"no contact specified");
      return(0);
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $refid=effVal($oldrec,$newrec,"refid");
   if (!defined($parentobj) || $parentobj eq ""){
      $self->LastMsg(ERROR,"empty parent object");
      return(0);
   }
   if (!defined($refid) || $refid eq ""){
      $self->LastMsg(ERROR,"empty refid");
      return(0);
   }
   foreach my $obj (values(%{$self->{lnkcontact}})){
      if ($obj->can("Validate")){
         my $bak=$obj->Validate($oldrec,$newrec,$origrec,$parentobj,$refid);
         if (!$bak){
            if (!$self->LastMsg()){
               $self->LastMsg(ERROR,"unknown error in Validate at $obj");
            }
            return(0);
         }
      }
   }
   #
   # Security check
   #
   my $p=getModuleObject($self->Config,$parentobj);
   if (!defined($p)){ 
      $self->LastMsg(ERROR,"invalid parentobj '$parentobj'");
      return(0);
   }
   return(1) if ($self->IsMemberOf("admin"));
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$refid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid refid '$refid' in parent object '$parentobj'");
      return(0);
   }

   if ($self->isDataInputFromUserFrontend()){
      my @write=$p->isWriteValid($l[0]);
      if ($#write!=-1){
         return(1) if (grep(/^ALL$/,@write));
         foreach my $fo ($p->getFieldObjsByView(["ALL"],current=>$l[0])){
            if ($fo->Type() eq "ContactLnk"){
               my $grp=quotemeta($fo->{group});
               $grp="default" if ($grp eq "");
               return(1) if (grep(/^$grp$/,@write));
            }
         }
      }
   }
   else{
      return(1);
   }
   $self->LastMsg(ERROR,"no write access");
   return(0);
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
#   return("default") if ($self->IsMemberOf("admin"));
   return("default");
}


sub isRoleMultiUsed
{
   my $self=shift;
   my $role=shift;
   my $requestroles=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $parentobj=shift;
   my $refid=shift;
   my $id=effVal($oldrec,$newrec,"id");

   $self->ResetFilter();
   $self->SetFilter({parentobj=>\$parentobj,refid=>\$refid});
   my @l=$self->getHashList(qw(id roles));
   my $alreadyused=0;
   foreach my $rec (@l){
      next if (defined($id) && $id==$rec->{id});
      my $r=$rec->{roles};
      $r=[$r] if (ref($r) ne "ARRAY");
      foreach my $chkrole (keys(%$role)){
         if (grep(/^$chkrole$/,@$r) && grep(/^$chkrole$/,@$requestroles)){
            $self->LastMsg(ERROR,
                           sprintf($self->T("role \"%s\" already assigned at ".
                             "current data record"),$role->{$chkrole}));
            return(1);
         }
      }
   }

   return(0);
}





1;
