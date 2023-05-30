package itil::sysiface;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
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
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'sysiface.id'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'150px',
                label         =>'Interface Name',
                dataobjattr   =>'sysiface.name'),

      new kernel::Field::Text(
                name          =>'mac',
                label         =>'MAC-Address',
                dataobjattr   =>'sysiface.macaddr'),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'150px',
                explore       =>500,
                label         =>'System',
                vjoineditbase =>{cistatusid=>">1 AND <6"},
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemID',
                dataobjattr   =>'sysiface.system'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'sysiface.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'sysiface.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'sysiface.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'sysiface.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"sysiface.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(sysiface.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'sysiface.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'sysiface.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'sysiface.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'sysiface.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'sysiface.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'sysiface.realeditor'),
   

   );
   $self->{history}={
      insert=>[
         'local',
         {dataobj=>'itil::system', id=>'systemid',
          field=>'name',as=>'sysiface'},
      ],
      update=>[
         'local',
         {dataobj=>'itil::system', id=>'systemid',
          field=>'name',as=>'sysiface'},
      ],
      delete=>[
         {dataobj=>'itil::system', id=>'systemid',
          field=>'name',as=>'sysiface'},
      ]
   };

   $self->setDefaultView(qw(system name mac mdate));
   $self->setWorktable("sysiface");
   return($self);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}


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


   if (defined($oldrec)){
      if (defined($newrec)){
         delete($newrec->{system});
         delete($newrec->{systemid});
      }
   }
   if ($self->isDataInputFromUserFrontend()){
      if (!$self->itil::lib::Listedit::isWriteOnSystemValid(
              effVal($oldrec,$newrec,"systemid"),"sysiface")){
         $self->LastMsg(ERROR,"no write access to specifed system");
         return(undef);
      }
   }

   if (effVal($oldrec,$newrec,"name") eq "" ||
       (effVal($oldrec,$newrec,"name")=~m/\s/)){
      $self->LastMsg(ERROR,"invalid interface name specified");
      return(undef);
   }
   if (defined($newrec) && exists($newrec->{mac})){
      if ($newrec->{mac}=~m/^[0-9a-f]{12}$/i){
         my @l=($newrec->{mac}=~m/../g);
         $newrec->{mac}=join(":",@l);
      }
   }

   if (defined($newrec) && exists($newrec->{mac})){
      my $mac=effVal($oldrec,$newrec,"mac");
      if ($mac ne ""){
         if (!($mac=~m/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/)){
            $self->LastMsg(ERROR,"invalid MAC address '%s' specified",$mac);
            return(undef);
         }
      }
      $mac=lc($mac);
      if (effVal($oldrec,$newrec,"mac") ne $mac){
         $newrec->{mac}=$mac;
      }
   }


   return(1);
}

sub isParentWriteable
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{systemid} eq "");

   if ($self->itil::lib::Listedit::isWriteOnSystemValid($rec->{systemid},
           "sysiface")){
      return(1);
   }
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
   if (defined($rec)){
      return("default") if ($self->IsMemberOf("admin"));
      if (!$self->isParentWriteable($rec)){
         return(undef);
      }
   }
   return("default");
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default ipaddresses systems itclustsvc source));
}



sub getRecordHtmlIndex
{ return(); }




1;
