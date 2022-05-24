package itil::lnkbusinessservicegrp;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkbusinessservicegrp.id'),


      new kernel::Field::TextDrop(
                name          =>'businessservice',
                label         =>'Businesservice',
                vjointo       =>'itil::businessservice',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessserviceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'businessserviceid',
                dataobjattr   =>'lnkbusinessservicegrp.businessservice'),

      new kernel::Field::Group(
                name          =>'grp',
                label         =>'Organisation',
                vjoineditbase =>{'cistatusid'=>[3,4],'is_org'=>1},
                vjoinon       =>'grpid'),

      new kernel::Field::Link(
                name          =>'grpid',
                readonly      =>1,
                group         =>'rel',
                dataobjattr   =>'lnkbusinessservicegrp.grp'),

      new kernel::Field::Text(
                name          =>'fullname',
                uivisible     =>0,
                label         =>'Fullname',
                depend        =>['location','relmode','grp'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $rec=shift;

                   my $l=$self->getParent->getField("businessservice")->
                         FormatedDetail($rec,"AscV01");
                   my $g=$self->getParent->getField("grp")->
                         FormatedDetail($rec,"AscV01");
                   return("$l-$g");
                }),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkbusinessservicegrp.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbusinessservicegrp.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkbusinessservicegrp.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbusinessservicegrp.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbusinessservicegrp.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkbusinessservicegrp.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbusinessservicegrp.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbusinessservicegrp.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkbusinessservicegrp.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkbusinessservicegrp.realeditor')
   );
   $self->setDefaultView(qw(businessservice grp cdate));
   $self->setWorktable("lnkbusinessservicegrp");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkbusinessservicegrp.jpg?".$cgi->query_string());
#}
         

sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default source));
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $grpid=effVal($oldrec,$newrec,"grpid");
   if ($grpid eq ""){
      $self->LastMsg(ERROR,"no group selected with marked as oranisation");
      return(undef);
   }
   my $businessserviceid=effVal($oldrec,$newrec,"businessserviceid");
   if ($businessserviceid eq ""){
      $self->LastMsg(ERROR,"invalid businessservice");
      return(undef);
   }
   if (!$self->isBusinessserviceWriteable($businessserviceid)){
         $self->LastMsg(ERROR,"no write access to requested businessservice");
         return(undef);
   }
   return(1);
}

sub isBusinessserviceWriteable
{
   my $self=shift;
   my $businessserviceid=shift;

   my $bs=getModuleObject($self->Config,"itil::businessservice");

   $bs->SetFilter({id=>\$businessserviceid});
   my ($bsrec,$msg)=$bs->getOnlyFirst(qw(ALL));
   if (!defined($bsrec)){
      $self->LastMsg(ERROR,"businessserviceid does not exists");
      return(undef);
   }
   if ($self->isDataInputFromUserFrontend()){
      my @acl=$bs->isWriteValid($bsrec);
      if (!in_array(\@acl,"grprelations")){
         return(undef);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join businessservice ".
          "on $worktable.businessservice=businessservice.id ");
}





sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));
   if (defined($oldrec)){
      if (!$self->isBusinessserviceWriteable($oldrec->{businessserviceid})){
         return(undef);
      }
   }

   return("default");
}





1;
