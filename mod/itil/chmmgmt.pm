package itil::chmmgmt;
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
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                sqlorder      =>'desc',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                group         =>'appldata',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Contact(
                name          =>'chmgrfmb',
                AllowEmpty    =>1,
                label         =>'Change Management Function Contact',
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>\'function'},
                vjoinon       =>['chmgrfmbid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'chmgrfmbid',
                dataobjattr   =>'appl.chmgrfmb'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'chmgrteam',
                htmlwidth     =>'300px',
                AllowEmpty    =>1,
                label         =>'Change Management Team',
                uivisible     =>0,
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['chmgrteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'chmgrteamid',
                dataobjattr   =>'appl.chmgrteam'),
                                                  
      new kernel::Field::Import( $self,
                vjointo       =>'itil::appl',
                vjoinon       =>['id'=>'id'],
                dontrename    =>1,
                group         =>'appldata',
                readonly      =>1,
                fields        =>[qw(mandator mandatorid
                                    cistatus cistatusid
                                    databoss databossid 
                                    sem semid 
                                    tsm tsmid 
                                    delmgr delmgrid
                                    businessteam businessteamid
                                    customer customerid 
                                    customerprio criticality)]));

   $self->AddGroup("appldata",translation=>'itil::chmmgmt');
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(name mandator cistatus chmgrteam));
   $self->setWorktable("appl");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $chmgrteamid=effVal($oldrec,$newrec,"chmgrteamid");

   my @fld=grep(!/^chmgrteam.*$/,keys(%$newrec));
   if (!defined($oldrec->{chmgrteamid}) && !defined($chmgrteamid) && $#fld!=-1){
      $self->LastMsg(ERROR,"write rejected - please first set chmgmt team");
      return(0);
   }

   return(1);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::chmmgmt");
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return(undef) if (!defined($rec));
   if (!defined($rec->{chmgrteamid})){
      return("default");
   }
   else{
      if ($self->IsMemberOf($rec->{mandatorid},
                            ["RCHManager","RCHManager2",
                             "RCFManager","RCFManager2"],"down")){
         return("default");
      }
      if ($self->IsMemberOf($rec->{chmgrteamid},
                            ["RMember"],"up")){
         return("default");
      }
      if ($self->IsMemberOf("admin")){
         return("default");
      }
   }
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(alldata default));
}






1;
