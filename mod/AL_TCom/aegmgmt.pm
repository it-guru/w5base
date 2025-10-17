package AL_TCom::aegmgmt;
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{Worktable}="AL_TCom_appl_aegmgmt";
   $self->{useMenuFullnameAsACL}=$self->Self;

   $self->{history}={
      update=>[
         'local'
      ]
   };

   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                uivisible     =>0,
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"appl.id"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                uploadable    =>1,
                label         =>'Application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'appl.name'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                uploadable    =>0,
                htmleditwidth =>'40%',
                label         =>'Application CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Boolean(
                name          =>'managed',
                selectfix     =>1,
                label         =>'is managed AEG',
                dataobjattr   =>"$worktable.managed"),

      new kernel::Field::Databoss(
                readonly      =>1),

      new kernel::Field::Link(
                readonly      =>1,
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),


                                                  
      new kernel::Field::Interface(
                name          =>'cistatusid',
                readonly      =>1,
                uploadable    =>0,
                label         =>'Application CI-StateID',
                dataobjattr   =>'appl.cistatus'),

#      new kernel::Field::Select(
#                name          =>'aegsolution',
#                value         =>['Customer Solutions',
#                                 'Market & Corporate Solutions',
#                                 'Technologiy Solutions',
#                                 'EU Solutions'],
#                label         =>'Solution',
#                dataobjattr   =>"$worktable.aegsolution"),

      new kernel::Field::Text(
                name          =>'ictoid',
                label         =>'ICTO-ID',
                readonly      =>1,
                dataobjattr   =>"appl.ictono"),

      new kernel::Field::Import($self,
                vjointo       =>'itil::appl',
                vjoinon       =>['id'=>'id'],
                group         =>"default",
                readonly      =>1,
                dontrename    =>1,
                fields        =>['mgmtitemgroup',"mandator","mandatorid"]),

      new kernel::Field::Text(
                name          =>'aegsolution',
                label         =>'Solution',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>"if (mandator.name regexp 'TelekomIT.*',".
                                "replace(replace(mandator.name,'TelekomIT',''),'_',''),".
                                "NULL)"),

      new kernel::Field::Import($self,
                vjointo       =>'itil::appl',
                vjoinon       =>['id'=>'id'],
                group         =>"default",
                readonly      =>1,
                dontrename    =>1,
                fields        =>['responseorgid','responseorg']),

      new kernel::Field::Contact(
                name          =>'leadinmmgr',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'addcontacts',
                label         =>'Lead Incident Manager',
                vjoinon       =>'leadinmmgrid'),

      new kernel::Field::Link(
                name          =>'leadinmmgrid',
                label         =>'Lead Incident Manager ID',
                group         =>'addcontacts',
                dataobjattr   =>"$worktable.leadinmmgr"),

      new kernel::Field::Contact(
                name          =>'leadprmmgr',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'addcontacts',
                label         =>'Lead Problem Manager',
                vjoinon       =>'leadprmmgrid'),

      new kernel::Field::Link(
                name          =>'leadprmmgrid',
                label         =>'Lead Problem Manager ID',
                group         =>'addcontacts',
                dataobjattr   =>"$worktable.leadprmmgr"),

#      new kernel::Field::Select(
#                name          =>'meetinginterval',
#                group         =>'meetings',
#                value         =>['none',
#                                 'weekly',
#                                 'monthly'],
#                label         =>'meeting interval',
#                dataobjattr   =>"$worktable.meetinginterval"),
#                                                  
#      new kernel::Field::Date(
#                name          =>'meetingstart',
#                group         =>'meetings',
#                label         =>'meetings startet at',
#                dataobjattr   =>"$worktable.meetingstart"),
#                                                  
#      new kernel::Field::Textarea(
#                name          =>'meetingcomments',
#                group         =>'meetings',
#                label         =>'meetings - comments',
#                dataobjattr   =>"$worktable.meetingcomments"),
#                                                  
#
#      new kernel::Field::Boolean(
#                name          =>'processcheckdone',
#                group         =>'processcheck',
#                label         =>'process check done',
#                dataobjattr   =>"$worktable.processcheckdone"),
#                                                  
#      new kernel::Field::Date(
#                name          =>'processcheckuntil',
#                group         =>'processcheck',
#                label         =>'process check finished at',
#                dataobjattr   =>"$worktable.processcheckuntil"),
#                                                  
#      new kernel::Field::Textarea(
#                name          =>'processcheckcomments',
#                group         =>'processcheck',
#                label         =>'process check - comments',
#                dataobjattr   =>"$worktable.processcheckcomments"),
#                                                  
#
#      new kernel::Field::Boolean(
#                name          =>'checklistdone',
#                group         =>'checklist',
#                label         =>'checklists created',
#                dataobjattr   =>"$worktable.checklistdone"),
#                                                  
#      new kernel::Field::Date(
#                name          =>'checklistuntil',
#                group         =>'checklist',
#                label         =>'checklist createfinished at',
#                dataobjattr   =>"$worktable.checklistuntil"),
#                                                  
#      new kernel::Field::Textarea(
#                name          =>'checklistcomments',
#                group         =>'checklist',
#                label         =>'checklist - comments',
#                dataobjattr   =>"$worktable.checklistcomments"),
#
      new kernel::Field::Htmlarea(
                name          =>'applicationexpertgroup',
                readonly      =>1,
                group         =>'aeg',
                searchable    =>0,
                label         =>'Application Expert Group',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $o=getModuleObject($self->getParent->Config,"TS::appl");
                   $o->SetFilter({id=>\$id});
                   my ($arec,$msg)=$o->getOnlyFirst($self->Name);
                   return($arec->{$self->Name});
                }),

      new kernel::Field::Link(
                name          =>'technicalaeg',
                readonly      =>1,
                group         =>'aeg',
                searchable    =>0,
                vjointo       =>'TS::appl',
                vjoinon       =>['id'=>'id'],
                vjoindisp     =>'technicalaeg'),

      new kernel::Field::MDate(
                name          =>'mdate',
                readonly      =>1,
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(appl.id,35,'0')"),

      new kernel::Field::Owner(
                name          =>'owner',
                readonly      =>1,
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                readonly      =>1,
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                readonly      =>1,
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>"$worktable.realeditor"),

      new kernel::Field::Text(
                name          =>'w5bid',
                sqlorder      =>'desc',
                readonly      =>1,
                label         =>'W5BaseID',
                dataobjattr   =>"appl.id"),
   );
   $self->setDefaultView(qw(name applcistatus managed aegsolution));
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_managed"))){
     Query->Param("search_managed"=>$self->T("yes"));
   }
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}







sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      $o->BackendSessionName("preProcessReadedRecord");
      my ($id)=$o->ValidatedInsertRecord({id=>$rec->{parentid}});
      $rec->{id}=$id;
      $rec->{replkeypri}="1970-01-01 00:00:00";
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

   $from.="appl left outer join $worktable on appl.id=$worktable.id ".
          "left outer join mandator on appl.mandator=mandator.grpid";

   return($from);
}

#sub initSqlWhere
#{
#   my $self=shift;
#   my $mode=shift;
#   my $where="(asset.cpucount is not null AND asset.cpucount>0)";
#   return($where);
#}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $viewgroups=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist=$self->SUPER::getRecordHtmlIndex($rec,$id,$viewgroups,
                                                  $grouplist,$grouplabel);

   my $email;
   my $o=getModuleObject($self->Config,"TS::appl");
   $o->SetFilter({id=>\$rec->{id}});
   my ($arec,$msg)=$o->getOnlyFirst(qw(technicalaeg));

   my $technicalaeg=$arec->{technicalaeg};
   if (ref($technicalaeg) eq "HASH" &&
       ref($technicalaeg->{AEG_email}) eq "ARRAY"){
      $email=join(";",@{$technicalaeg->{AEG_email}});
   }
   
   if ($email ne ""){
      push(@indexlist,{label=>$self->T('AEG Distibutionlist'),
              href=>"mailto:".$email,
              target=>"_self"
             });
   }

   return(@indexlist);
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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
   my @l=$self->SUPER::isWriteValid($rec);
   return("default","meetings","processcheck","addcontacts",
          "checklist") if (in_array(\@l,"ALL"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default aeg addcontacts 
             meetings processcheck checklist source));
}




1;
