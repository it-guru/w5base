package itil::lnkswinstanceparam;
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
                dataobjattr   =>'lnkswinstanceparam.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'swinstance',
                htmlwidth     =>'100px',
                group         =>'link',
                label         =>'Software-Instance',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'swnature',
                htmlwidth     =>'150px',
                htmldetail    =>0,
                group         =>'link',
                label         =>'Instance type',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'swnature'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                htmldetail    =>0,
                group         =>'link',
                label         =>'Instance CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'link',
                label         =>'Instance CI-StateID',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'cistatusid'),

      new kernel::Field::TextDrop(
                name          =>'application',
                htmlwidth     =>'150px',
                htmldetail    =>0,
                group         =>'link',
                label         =>'Application',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'appl'),

      new kernel::Field::TextDrop(
                name          =>'instanceid',
                htmldetail    =>0,
                group         =>'link',
                translation   =>'itil::swinstance',
                label         =>'Instance ID',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'swinstanceid'),

      new kernel::Field::TextDrop(
                name          =>'swteam',
                htmldetail    =>0,
                group         =>'link',
                translation   =>'itil::swinstance',
                label         =>'Instance guardian team',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'swteam'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'120px',
                label         =>'parameter name',
                dataobjattr   =>'lnkswinstanceparam.name'),
                                                   
      new kernel::Field::Text(
                name          =>'namegrp',
                htmlwidth     =>'120px',
                label         =>'group',
                dataobjattr   =>'lnkswinstanceparam.namegrp'),
                                                   
      new kernel::Field::Text(
                name          =>'val',
                label         =>'parameter value',
                dataobjattr   =>'lnkswinstanceparam.val'),
                                                   
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkswinstanceparam.mdate'),

      new kernel::Field::Boolean(
                name          =>'islatest',
                sqlorder      =>'NONE',
                group         =>'source',
                label         =>'is latest',
                dataobjattr   =>'lnkswinstanceparam.islatest'),
                                                   
      new kernel::Field::Interface(
                name          =>'swinstanceid',
                sqlorder      =>'NONE',
                label         =>'swinstanceID',
                dataobjattr   =>'lnkswinstanceparam.swinstance'),
                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-System',
                dataobjattr   =>'lnkswinstanceparam.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-Id',
                dataobjattr   =>'lnkswinstanceparam.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkswinstanceparam.srcload')
                                                   
   );
   $self->setDefaultView(qw(swinstance namegrp name val swinstance mdate));

   $self->setWorktable("lnkswinstanceparam");
   return($self);
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my $from="lnkswinstanceparam left outer join appl ".
#            "on lnkswinstanceparam.appl=appl.id ".
#            "left outer join liccontract ".
#            "on lnkswinstanceparam.liccontract=liccontract.id";
#   return($from);
#}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($newrec->{islatest}) && !defined($oldrec)){
      $newrec->{islatest}=1;
   }
   if ($newrec->{islatest} eq "" || $newrec->{islatest} eq "0"){
      $newrec->{islatest}=undef;
   }

   my $name=effVal($oldrec,$newrec,"name");
   if (($name=~m/^\s*$/) || !($name=~m/^[a-z_,0-9]+$/)){
      $self->LastMsg(ERROR,"invalid parameter name specified");
      return(undef);
   }
   my $swinstanceid=effVal($oldrec,$newrec,"swinstanceid");
   if ($swinstanceid==0){
      $self->LastMsg(ERROR,"invalid swinstance specified");
      return(undef);
   }
   else{
      if (!$self->isParentWriteable($swinstanceid)){
         $self->LastMsg(ERROR,"instance is not writeable for you");
         return(undef);
      }
   }

   return(1);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.swinstance.read 
                              w5base.itil.read)],
                          "RMember")){
       my $base={};
       if ($#flt==0 && ref($flt[0]) eq "HASH"){
          if (exists($flt[0]->{swinstance})){
             $base->{'fullname'}=$flt[0]->{'swinstance'};
          }
          if (exists($flt[0]->{cistatus})){
             $base->{'cistatus'}=$flt[0]->{'cistatus'};
          }
          if (exists($flt[0]->{application})){
             $base->{'appl'}=$flt[0]->{'application'};
          }
          if (exists($flt[0]->{swteam})){
             $base->{'swteam'}=$flt[0]->{'swteam'};
          }
       } 
       my $swi=$self->getPersistentModuleObject("W5swi","itil::swinstance");
       $swi->SecureSetFilter($base);
       my @swiid=();
       foreach my $s ($swi->getHashList(qw(id))){
          push(@swiid,$s->{id});
       }
       push(@flt,[{swinstanceid=>\@swiid}]);
       
   }
   return($self->SetFilter(@flt));
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("link","default","header") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   $rw=1 if (!defined($rec));
   $rw=1 if (defined($rec) && $self->isParentWriteable($rec->{systemid}));
   $rw=1 if ((!$rw) && ($self->IsMemberOf("admin")));
   return("default","link") if ($rw);
   return(undef);
}

sub isParentWriteable  # Eltern Object Schreibzugriff prüfen
{
   my $self=shift;
   my $swinstance=shift;

   return(1) if (!defined($ENV{SERVER_SOFTWARE}));
   my $swi=$self->getPersistentModuleObject("W5BaseAppl","itil::swinstance");
   $swi->ResetFilter();
   $swi->SetFilter({id=>\$swinstance});
   my ($rec,$msg)=$swi->getOnlyFirst(qw(ALL));
   if (defined($rec) && $swi->isWriteValid($rec)){
      return(1);
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header link default source));
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_islatest"))){
     Query->Param("search_islatest"=>$self->T("yes"));
   }
   if (!defined(Query->Param("search_mdate"))){
     Query->Param("search_mdate"=>'>now-28d');
   }
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }

}









1;
