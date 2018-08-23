package itil::lnknetinterconipnet;
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
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                group         =>'source',
                searchable    =>0,
                dataobjattr   =>'lnknetinterconipnet.id'),
                                                 

      new kernel::Field::Select(
                name          =>'endpoint',
                label         =>'endpoint',
                value         =>['A',
                                 'B'
                                 ],  # see also opmode at system
                dataobjattr   =>'lnknetinterconipnet.endpoint'),

      new kernel::Field::Link(
                name          =>'netinterconid',
                label         =>'NetInterconID',
                dataobjattr   =>'lnknetinterconipnet.netintercon'),

      new kernel::Field::Link(
                name          =>'ipnetid',
                label         =>'IP-NetID',
                dataobjattr   =>'lnknetinterconipnet.ipnet'),

      new kernel::Field::TextDrop(
                name          =>'netinterconname',
                label         =>'Interconnect',
                vjointo       =>'itil::netintercon',
                vjoinon       =>['netinterconid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'ipnetname',
                label         =>'Network Name',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['ipnetid'=>'id'],
                vjoindisp     =>'fullname'),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnknetinterconipnet.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnknetinterconipnet.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnknetinterconipnet.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnknetinterconipnet.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnknetinterconipnet.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnknetinterconipnet.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnknetinterconipnet.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnknetinterconipnet.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnknetinterconipnet.realeditor'),
                                                   
   );
   $self->setDefaultView(qw(netinterconname endpoint ipnetname));

   $self->setWorktable("lnknetinterconipnet");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnknetinterconipnet left outer join ipnet ".
            "on lnknetinterconipnet.ipnet=ipnet.id ".
            "left outer join netintercon ".
            "on lnknetinterconipnet.netintercon=netintercon.id";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $ipnetid=effVal($oldrec,$newrec,"ipnetid");
   if ($ipnetid==0){
      $self->LastMsg(ERROR,"invalid ip-net specified");
      return(undef);
   }
   my $netinterconid=effVal($oldrec,$newrec,"netinterconid");
   if ($netinterconid==0){
      $self->LastMsg(ERROR,"invalid interconnect specified");
      return(undef);
   }
   else{
      if (!$self->isParentWriteable($netinterconid)){
         $self->LastMsg(ERROR,"internconect is not writeable for you");
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

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   $rw=1 if (!defined($rec));
   $rw=1 if (defined($rec) && $self->isParentWriteable($rec->{netinterconid}));
   $rw=1 if ((!$rw) && ($self->IsMemberOf("admin")));
   return("default","misc") if ($rw);
   return(undef);
}

sub isParentWriteable  # Eltern Object Schreibzugriff prüfen
{
   my $self=shift;
   my $netinterconid=shift;

   return(1) if (!defined($ENV{SERVER_SOFTWARE}));
   my $neti=$self->getPersistentModuleObject("W5BaseNetIco",
                                             "itil::netintercon");
   $neti->ResetFilter();
   $neti->SetFilter({id=>\$netinterconid});
   my ($rec,$msg)=$neti->getOnlyFirst(qw(ALL));
   if (defined($rec) && $neti->isWriteValid($rec)){
      return(1);
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default misc link source));
}








1;
