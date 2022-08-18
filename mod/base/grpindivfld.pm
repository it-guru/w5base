package base::grpindivfld;
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
                label         =>'W5BaseID',
                group         =>'source',
                dataobjattr   =>'grpindivfld.id'),
                                  
      new kernel::Field::Select(
                name          =>'dataobj',
                label         =>'link attribut to Data-Object',
                size          =>'25',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if (!defined($rec));
                   return(1);
                },
                getPostibleValues=>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   my @l;
                   push(@l,"","");
                   push(@l,"itil::appl",
                           $app->T("itil::appl","itil::appl"));
                   push(@l,"itil::system",
                           $app->T("itil::system","itil::system"));
                   push(@l,"base::workflow",
                           $app->T("base::workflow","base::workflow"));
                   push(@l,"base::lnkqrulemandator",
                           $app->T("base::lnkqrulemandator",
                          "base::lnkqrulemandator"));
                   return(@l);
                }, 
                dataobjattr   =>'grpindivfld.dataobject'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Attribut label',
                dataobjattr   =>'grpindivfld.name'),

      new kernel::Field::Group(
                name          =>'groupname',
                label         =>'Groupname',
                vjoinon       =>['grpidview'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Boolean(
                name          =>'directonly',
                label         =>'only direct members',
                dataobjattr   =>'grpindivfld.directonly'),

      new kernel::Field::Boolean(
                name          =>'readonly',
                label         =>'existing values readonly (archived)',
                dataobjattr   =>'grpindivfld.rdonly'),

      new kernel::Field::Select(
                name          =>'behavior',
                label         =>'attribut fldbehavior',
                jsonchanged   =>\&getOnChangedTypeScript,
                jsoninit      =>\&getOnChangedTypeScript,
                value         =>['singleline',
                                 'smallmulti',
                                 'hugemulti',
                                 'select'],
                dataobjattr   =>'grpindivfld.fldbehavior'),

      new kernel::Field::Textarea(
                name          =>'extra',
                label         =>'attribut fldbehavior extra data',
                dataobjattr   =>'grpindivfld.fldextra'),

      new kernel::Field::Interface(
                name          =>'grpidview',
                dataobjattr   =>'grpindivfld.grpview'),

      new kernel::Field::Interface(
                name          =>'grpidwrite',
                dataobjattr   =>'grpindivfld.grpwrite'),


      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'grpindivfld.modifydate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'grpindivfld.createdate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'grpindivfld.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'grpindivfld.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'grpindivfld.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'grpindivfld.realeditor'),
   );
   $self->setDefaultView(qw(name dataobj groupname directonly readonly behavior));
   $self->setWorktable("grpindivfld");
   return($self);
}


sub getOnChangedTypeScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var b=document.forms[0].elements['Formated_behavior'];
var e=document.forms[0].elements['Formated_extra'];

if (b && e){
   var v=b.options[b.selectedIndex].value;
   if (v=="select"){
      e.disabled=false;
   }
   else{
      e.value="";
      e.disabled=true;
   }
}

EOF
   return($d);
}



sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   $self->LastMsg(WARN,
       "delete of field also deletes all existing field values irrevocably");

   return(1);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin)],
                          "RMember")){
      my @addflt;
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},
                 ['RBoss','RBoss2','RMember'],'both');

      my @grpids=keys(%groups);
      @grpids=(-99) if ($#grpids==-1);

      push(@addflt,{grpidview=>\@grpids});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub InitNew
{
   my $self=shift;

   my $initteam=$self->getInitiatorGroupsOf($self->getCurrentUserId());
   Query->Param("Formated_groupname"=>$initteam);
}




sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub isWriteOnGroupValid
{
   my $self=shift;
   my $grpid=shift;

   return(1) if ($self->IsMemberOf("admin"));
   my $userid=$self->getCurrentUserId();
   my %a=$self->getGroupsOf($userid, [qw(RBoss RBoss2)], 'down');
   my %b=$self->getGroupsOf($userid, [qw(RAdmin)], 'direct');
   if (in_array([keys(%a),keys(%b)],$grpid)){
      return(1);
   }

   return(0);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

 
   $newrec->{name}=effVal($oldrec,$newrec,"name");
   trim(\$newrec->{name});
   $newrec->{name}=~s/^\*//;
   if ($newrec->{name} eq "" ||
       !($newrec->{name}=~m/^[a-zA-Z 0-9_\.-]+$/)){
      $self->LastMsg(ERROR,"invalid field name specified");
      return(undef);
   }

   my $extra=effVal($oldrec,$newrec,"extra");
   $extra=trim($extra);
   $extra=~s/["']//g;
   if ($extra ne effVal($oldrec,$newrec,"extra")){
      $newrec->{extra}=$extra;
   }


   my $grpidview=effVal($oldrec,$newrec,"grpidview");
   if ($grpidview eq ""){
      $self->LastMsg(ERROR,"no group specified");
      return(undef);
   }
   if (!$self->isWriteOnGroupValid($grpidview)){
      $self->LastMsg(ERROR,
        "you have no right, to edit individual fields in selected group");
      return(undef);
   }
   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   
   my $userid=$self->getCurrentUserId();
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      Query->Param("search_user"=>'"'.
                   $UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname}.'"');
   }
}  



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   my $grpidview=$rec->{"grpidview"};
   if ($self->isWriteOnGroupValid($grpidview)){
      return("default");
   }
   return(undef);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/grpindivflds.jpg?".$cgi->query_string());
#}


1;
