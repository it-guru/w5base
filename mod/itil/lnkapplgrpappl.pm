package itil::lnkapplgrpappl;
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
use kernel::Field;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'LinkID',
                dataobjattr   =>'lnkapplgrpappl.id'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'relation fullname',
                dataobjattr   =>'concat(applgrp.name," - ",'.
                     'appl.name,'.
                     "if (lnkapplgrpappl.applversion is not null and ".
                     "lnkapplgrpappl.applversion<>\"\",\"-\",\"\"),".
                     "if (lnkapplgrpappl.applversion is null,\"-any version\",".
                     "lnkapplgrpappl.applversion),\" (ID:\",".
                     'lnkapplgrpappl.id,")")'),

      new kernel::Field::TextDrop(
                name          =>'applgrp',
                htmlwidth     =>'300px',
                label         =>'Applicationgroup',
                vjointo       =>'itil::applgrp',
                vjoinon       =>['applgrpid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'applgrpcistatus',
                htmleditwidth =>'40%',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'relation',
                label         =>'Applicationgroup CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applgrpcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'200px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                htmleditwidth =>'40%',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'relation',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Text(
                name          =>'applversion',
                nowrap        =>'1',
                htmlwidth     =>'140px',
                label         =>'Application Version',
                dataobjattr   =>'lnkapplgrpappl.applversion'),

      new kernel::Field::Date(
                name          =>'planed_activation',
                label         =>'planed activation',
                dayonly       =>1,
                dataobjattr   =>'lnkapplgrpappl.planed_activation'),

      new kernel::Field::Date(
                name          =>'planed_retirement',
                dayonly       =>1,
                label         =>'planed retirement',
                dataobjattr   =>'lnkapplgrpappl.planed_retirement'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplgrpappl.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplgrpappl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplgrpappl.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplgrpappl.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplgrpappl.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplgrpappl.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplgrpappl.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplgrpappl.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplgrpappl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplgrpappl.realeditor'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'applgrpcistatusid',
                label         =>'ApplGroupCiStatusID',
                dataobjattr   =>'applgrp.cistatus'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Interface(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'lnkapplgrpappl.appl'),

      new kernel::Field::Interface(
                name          =>'applgrpid',
                htmlwidth     =>'150px',
                label         =>'ApplicationgroupID',
                dataobjattr   =>'lnkapplgrpappl.applgrp'),
   );
   $self->setDefaultView(qw(applgrp appl applversion 
                            planed_activation planed_retirement));
   $self->setWorktable("lnkapplgrpappl");
   return($self);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applgrpcistatus"))){
     Query->Param("search_applgrpcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplgrpappl left outer join appl ".
            "on lnkapplgrpappl.appl=appl.id ".
            "left outer join applgrp ".
            "on lnkapplgrpappl.applgrp=applgrp.id ";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplgrpappl.jpg?".
          $cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{applgrpid})) ||
       (defined($newrec->{applgrpid}) && $newrec->{applgrpid}==0)){
      $self->LastMsg(ERROR,"invalid applicationgroup specified");
      return(undef);
   }
   if (exists($newrec->{applid})){
      my $o=$self->Clone();
      my $flt={applid=>\$newrec->{applid}};
      if (defined($oldrec)){
         $flt->{id}="!".$oldrec->{id};
      }
      $o->SetFilter($flt);
      $o->SetCurrentView(qw(applgrpid applgrp));
      my $l=$o->getHashIndexed(qw(applgrpid));
      my $curapplgrpid=effVal($oldrec,$newrec,"applgrpid");
      delete($l->{applgrpid}->{$curapplgrpid});
      if (keys(%{$l->{applgrpid}})){
         msg(ERROR,"doublicate applicationgroup request for ".
                   $curapplgrpid." with ".join(",",keys(%{$l->{applgrpid}})));
         $self->LastMsg(ERROR,
              "application already belongs to an other applicationgroup");
         return(0);
      }
   }

   if ($self->isDataInputFromUserFrontend()){
      my $applgrpid=effVal($oldrec,$newrec,"applgrpid");
      if (!defined($applgrpid) ||
          !$self->isWriteOnApplgrpValid($applgrpid,"applications")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
   }


   return(1);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("header","default","source","relation","history");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf("admin"));
   return("default");
}





1;
