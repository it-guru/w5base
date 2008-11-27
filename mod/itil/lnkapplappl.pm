package itil::lnkapplappl;
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
                label         =>'LinkID',
                dataobjattr   =>'lnkapplappl.id'),

      new kernel::Field::TextDrop(
                name          =>'fromappl',
                htmlwidth     =>'250px',
                label         =>'from Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['fromapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'toappl',
                htmlwidth     =>'150px',
                label         =>'to Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['toapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'contype',
                label         =>'Interfacetype',
                htmlwidth     =>'250px',
                transprefix   =>'contype.',
                value         =>[qw(0 1 2 3 4 5)],
                default       =>'0',
                htmleditwidth =>'350px',
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Select(
                name          =>'conmode',
                label         =>'Interfacemode',
                value         =>[qw(online batch manuell)],
                default       =>'online',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conmode'),

      new kernel::Field::Select(
                name          =>'conproto',
                label         =>'Interfaceprotocol',
                value         =>[qw( unknown CAPI Corba dce DSO ftp html http
                                     jdbc ldap Netegrity NFS ODBC papier
                                     RMI rsh rcp rfc sldap ssh sftp smtp
                                     snmp tuxedo xml X.31 openFT pkix-cmp
                                     utm DB-Link BCV MQSeries)],
                default       =>'online',
                htmlwidth     =>'50px',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conprotocol'),

      new kernel::Field::SubList(
                name          =>'interfacescomp',
                label         =>'Interface components',
                group         =>'interfacescomp',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplapplcomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'lnkapplappl'],
                vjoindisp     =>['name','namealt1','namealt2',"comments"]),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplappl.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplappl.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappl.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappl.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappl.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappl.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappl.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplappl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplappl.realeditor'),

      new kernel::Field::Link(
                name          =>'fromapplid',
                label         =>'from ApplID',
                dataobjattr   =>'lnkapplappl.fromappl'),

      new kernel::Field::Link(
                name          =>'lnktoapplid',
                label         =>'to ApplicationID',
                dataobjattr   =>'toappl.applid'),

      new kernel::Field::Link(
                name          =>'toapplid',
                label         =>'to ApplID',
                dataobjattr   =>'lnkapplappl.toappl'),

      new kernel::Field::Link(
                name          =>'toapplcistatus',
                label         =>'to Appl CI-Status',
                dataobjattr   =>'toappl.cistatus'),

   );
   $self->setDefaultView(qw(id fromappl toappl cdate editor));
   $self->setWorktable("lnkapplappl");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplappl ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
   if ($fromapplid==0){
      $self->LastMsg(ERROR,"invalid from application");
      return(0);
   }
   my $toapplid=effVal($oldrec,$newrec,"toapplid");
   if ($toapplid==0){
      $self->LastMsg(ERROR,"invalid to application");
      return(0);
   }
   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $oldrec->{toapplid}!=$toapplid)){
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(cistatusid));
      if (!defined($applrec) || 
          $applrec->{cistatusid}>4 || $applrec->{cistatusid}==0){
         $self->LastMsg(ERROR,"selected application is currently unuseable");
         return(0);
      }
   }

   my $applid=effVal($oldrec,$newrec,"fromapplid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"interfaces")){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applid=effVal($oldrec,$newrec,"fromapplid");
   my @editgroup=("default","interfacescomp");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnApplValid($applid,"interfaces"));
   return(@editgroup) if (!$self->isDataInputFromUserFrontend());

   return(undef);
}





1;
