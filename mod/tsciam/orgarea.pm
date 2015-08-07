package tsciam::orgarea;
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
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->setBase("ou=Organisation,o=DTAG");
   $self->AddFields(
      new kernel::Field::Id(       name       =>'toucid',
                                   label      =>'tOuCID',
                                   size       =>'10',
                                   align      =>'left',
                                   dataobjattr=>'tOuCID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Orgarea-Name (tOuLD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'Orgarea-ShortName (tOuSD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuSD'),

      new kernel::Field::Text(   name       =>'sapid',
                                 label      =>'SAP-OrganisationalID (tOuSapID)',
                                 dataobjattr=>'tOuSapID'),

      new kernel::Field::TextDrop( name       =>'bossfullname',
                                   label      =>'Boss',
                                   vjointo    =>'tsciam::user',
                                   depend     =>['toumgr'],
                                   vjoinon    =>['toumgr'=>'tcid'],
                                   vjoindisp  =>'fullname'),

#      new kernel::Field::TextDrop( name       =>'boss',
#                                   label      =>'Boss (tOuMgr)',
#                                   vjointo    =>'tsciam::user',
#                                   depend     =>['toumgr'],
#                                   vjoinon    =>['toumgr'=>'tcid'],
#                                   vjoindisp  =>'id'),

      new kernel::Field::TextDrop( name       =>'bosssurname',
                                   label      =>'Boss (surname)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   vjointo    =>'tsciam::user',
                                   depend     =>['toumgr'],
                                   vjoinon    =>['toumgr'=>'tcid'],
                                   vjoindisp  =>'surname'),

      new kernel::Field::TextDrop( name       =>'bossgivenname',
                                   label      =>'Boss (givenname)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   depend     =>['toumgr'],
                                   vjointo    =>'tsciam::user',
                                   vjoinon    =>['toumgr'=>'tcid'],
                                   vjoindisp  =>'givenname'),

      new kernel::Field::TextDrop( name       =>'bossemail',
                                   label      =>'Boss (email)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   depend     =>['toumgr'],
                                   vjointo    =>'tsciam::user',
                                   vjoinon    =>['toumgr'=>'tcid'],
                                   vjoindisp  =>'email'),



      new kernel::Field::SubList(  name       =>'users',
                                   label      =>'Users',
                                   group      =>'userro',
                                   vjointo    =>'tsciam::user',
                                   vjoinon    =>['toucid'=>'toucid'],
                                   vjoinbase  =>{primary=>'true',
                                                 active=>'true'},
                                   vjoindisp  =>['fullname']),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Parentgroup (tOuSuperior)',
                                   vjointo    =>'tsciam::orgarea',
                                   vjoinon    =>['parentid'=>'toucid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Interface(name       =>'parentid',
                                   label      =>'ParentID (tOuSuperior)',
                                   dataobjattr=>'tOuSuperior'),

      new kernel::Field::Text(     name       =>'toumgr',
                                   htmldetail =>0,
                                   label      =>'tOuMgr CIAMID',
                                   dataobjattr=>'tOuMgr'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
   );
   $self->setDefaultView(qw(touid name users));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tsciam"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{tswiw}));
   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub SetFilterForQualityCheck
{  
   my $self=shift;
   my @view=@_;
   return(undef);
}
   


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportOrgarea 
                                                  doParentFix
                                                  ParentGroupFix));
}


sub ImportOrgarea
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
   #      Query->Delete("importname");
         $self->LastMsg(OK,"orgarea has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"WhoIsWho Import");
   print $self->getParsedTemplate("tmpl/minitool.orgarea.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}

#########################################################################
# minitool ParentGroupFix based on ajax technic to reconnect parent group
#
sub ParentGroupFix
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           js=>['J5Base.js'],body=>1,
                           title=>"WhoIsWho ParentGroupFix");
   print $self->getParsedTemplate("tmpl/minitool.orgarea.parentfix",{});
   print $self->HtmlBottom(body=>1);
}

sub doParentFix
{
   my $self=shift;

   print $self->HttpHeader("text/html",charset=>'utf-8');
   my $grpid=$self->Query->Param("grpid");
   if ($grpid eq ""){
      print("ERROR: no grpid sumited");
      return();
   }
   my $wiw=getModuleObject($self->Config,"tswiw::orgarea");
   my $grp=getModuleObject($self->Config,"base::grp");

   #
   # load current grprec vom w5base
   #
   $grp->ResetFilter();
   $grp->SecureSetFilter({grpid=>\$grpid});
   my ($grprec)=$grp->getOnlyFirst(qw(ALL));
   if (!$grprec){
      print("ERROR: grp not found");
      return();
   }
   if ($grprec->{srcid} eq ""){
      print("ERROR: no touid in srcid of grp");
      return();
   }
   #
   # load current parent from wiw
   #
   $wiw->SecureSetFilter({touid=>\$grprec->{srcid}});
   my ($wiwrec)=$wiw->getOnlyFirst(qw(parentid));

   if ($wiwrec->{parentid} eq ""){
      print("ERROR: no parentid found in wiw");
      return();
   }

   #
   # find new parent fullname
   #
   $grp->ResetFilter();
   $grp->SecureSetFilter({srcid=>\$wiwrec->{parentid},srcsys=>\'WhoIsWho'});
   my ($pgrprec)=$grp->getOnlyFirst(qw(fullname));
   if (!defined($pgrprec)){
      $self->Import({importname=>$wiwrec->{parentid}});
      $grp->ResetFilter();
      $grp->SecureSetFilter({srcid=>\$wiwrec->{parentid},srcsys=>\'WhoIsWho'});
      my ($pgrprec)=$grp->getOnlyFirst(qw(fullname));
      if (!defined($pgrprec)){
         if (!$self->LastMsg()){
            $self->LastMsg(ERROR,"can not create new parent group");
         }
         print(latin1(join("<hr>",grep(/ERROR/,$self->LastMsg())))->utf8());
         return();
      }
   }
   if ($pgrprec->{fullname} eq ""){
      print("ERROR: can not find valid parent groupname");
      return();
   }
   
   #
   # write new parent
   #

   if ($grp->SecureValidatedUpdateRecord($grprec,{parent=>$pgrprec->{fullname}},
                                         {grpid=>\$grprec->{grpid}})){

      $grp->ResetFilter();
      $grp->SecureSetFilter({grpid=>\$grpid});
      my ($grprec)=$grp->getOnlyFirst(qw(ALL));
      my $qcokobj=$grp->getField("qcok");
      my $qcok=$qcokobj->RawValue($grprec);
      if ($qcok){
         print("QCheck now OK");
      }
      else{
         print("QCheck still failed");
      }
      return();
   }
   print(join(";".$self->LastMsg()));
}

#########################################################################

sub Import
{
   my $self=shift;
   my $param=shift;

   my $orgid=$param->{importname};
   if (!($orgid=~m/^\S{3,10}$/)){
      $self->LastMsg(ERROR,"invalid name specified");
      return(undef);
   }
   my @idimp;
   my $wiw=getModuleObject($self->Config,"tswiw::orgarea");
   my $grp=getModuleObject($self->Config,"base::grp");

   my $ok=0;
   my $chkid=$orgid;
   while($#idimp<20){
      $wiw->ResetFilter();
      $wiw->SetFilter({touid=>\$chkid});
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         $grp->ResetFilter();
         $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\'WhoIsWho'});
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){ # ok, grp already exists in W5Base
            $self->LastMsg(INFO,"$wiwrec->{touid} = $grprec->{fullname}");
            last;
         }
         else{
            msg(INFO,"wiwid $wiwrec->{touid} not found in W5Base");
            push(@idimp,$wiwrec->{touid});
         }
         $chkid=$wiwrec->{parentid};
         last if ($chkid eq "");
      }
      else{
         $self->LastMsg(ERROR,"invalid orgid $chkid in tree");
         return(undef);
      }
   }
   foreach my $wiwid (reverse(@idimp)){
      $wiw->ResetFilter();
      $wiw->SetFilter({touid=>\$wiwid});
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         my $grprec;
         $grp->ResetFilter();
         if ($wiwrec->{parentid} ne ""){
            $grp->SetFilter({srcid=>\$wiwrec->{parentid},
                             srcsys=>\'WhoIsWho'});
         }
         else{
            $grp->SetFilter({fullname=>\'DTAG.TSI'});
         }
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){

            my $newname=$wiwrec->{shortname};
            if ($newname eq ""){
               $self->LastMsg(ERROR,"no shortname for ".
                                    "id '$wiwrec->{touid}' found");
               return(undef);
            }
            $newname=~s/[\/\s]/_/g;    # rewriting for some shit names
            $newname=~s/&/_u_/g;
            my %newgrp=(name=>$newname,
                        srcsys=>'WhoIsWho',
                        srcid=>$wiwrec->{touid},
                        parentid=>$grprec->{grpid},
                        cistatusid=>4,
                        srcload=>NowStamp(),
                        comments=>"Description from WhoIsWho: ".
                                  $wiwrec->{name});
            msg(DEBUG,"Write=%s",Dumper(\%newgrp));
            if (my $back=$grp->ValidatedInsertRecord(\%newgrp)){
               $ok++;    
               msg(DEBUG,"ValidatedInsertRecord returned=$back");
               $grp->ResetFilter();
               $grp->SetFilter({grpid=>\$back});
               my ($grprec)=$grp->getOnlyFirst(qw(ALL));
               if ($grprec){
                  $self->LastMsg(INFO,"$grprec->{srcid} = $grprec->{fullname}");
               }
           
            }
           # printf STDERR ("wiwrec=%s\n",Dumper($wiwrec));
           # printf STDERR ("grprec=%s\n",Dumper($grprec));
           # printf STDERR ("fifi importing $wiwid\n");
         }
         else{
            printf STDERR ("fifi parentid $wiwrec->{parentid} not found\n");
         }
      }
   }
   if ($ok==$#idimp+1){
      return(1);
   }
   $self->LastMsg(ERROR,"one or more operations failed");
   return(undef);
}

1;
