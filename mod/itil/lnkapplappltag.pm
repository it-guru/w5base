package itil::lnkapplappltag;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{use_distinct}=1;
  
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'InterfaceTagID',
                dataobjattr   =>'lnkapplappltag.id'),

      new kernel::Field::Link(
                name          =>'lnkapplappl',
                label         =>'Interface ID',
                dataobjattr   =>'lnkapplappltag.lnkapplappl'),

      new kernel::Field::Select(
                name          =>'name',
                label         =>'Name',
                allowfree     =>'1',
                dataobjattr   =>'lnkapplappltag.name',
                vjointo       =>\'itil::lnkapplappltag',
                vjoindisp     =>'name',
                vjoinbase     =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @flt;
                   # pre selection list of names in DeailView Edit mode
                   my $id=Query->Param("id");   # id from tag
                   if ($id ne ""){
                      push(@flt,{taglnkapplappltagid=>\$id});
                   }
                   # pre selection list of names in SubList Edit Mode
                   my $lnkapplappl=Query->Param("lnkapplappl"); # id from if
                   if ($lnkapplappl ne ""){
                      push(@flt,{taglnkapplappl=>\$lnkapplappl});
                   }
                   return(\@flt);
                },
                vjoinon       =>['name'=>'name']),


      new kernel::Field::Text(
                name          =>'value',
                label         =>'Value',
                dataobjattr   =>'lnkapplappltag.value'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>'ifdata',
                label         =>'Interface-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>[3,4,5,6]},
                default       =>'4',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'ifdata',
                label         =>'CI-StateID',
                dataobjattr   =>'lnkapplappl.cistatus'),

      new kernel::Field::Text(
                name          =>'fromappl',
                group         =>'ifdata',
                label         =>'from Application',
                dataobjattr   =>'fromappl.name'),

      new kernel::Field::Link(
                name          =>'fromapplid',
                selectfix     =>1,
                dataobjattr   =>'fromappl.id'),

      new kernel::Field::Text(
                name          =>'toappl',
                group         =>'ifdata',
                label         =>'to Application',
                dataobjattr   =>'toappl.name'),

      #######################################################################
      # needed for tag name distinct selction dropdown box
      new kernel::Field::Link(
                name          =>'taglnkapplappl',
                label         =>'tag filter Interface ID',
                noselect      =>'1',
                dataobjattr   =>'taglnkapplappl.id'),

      new kernel::Field::Link(
                name          =>'taglnkapplappltagid',
                label         =>'tag filter Interface ID',
                noselect      =>'1',
                dataobjattr   =>'taglnkapplappltag.id'),
      #######################################################################

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappltag.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplappltag.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappltag.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappltag.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappltag.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappltag.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappltag.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplappltag.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplappltag.realeditor'),
   );
   $self->setDefaultView(qw(id fromappl toappl name value mdate));
   $self->setWorktable("lnkapplappltag");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->checkWriteValid($oldrec,$newrec)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #return(undef);
   return("default") if (!defined($rec));
   return("default") if ($self->checkWriteValid($rec));
   return(undef);
}

sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $lnkapplappl=effVal($oldrec,$newrec,"lnkapplappl");

   return(undef) if ($lnkapplappl eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$lnkapplappl);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^interfacetag$/,@grplist) ||
             grep(/^tags$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;

   my $from="lnkapplappltag ".
            "join lnkapplappl ".
            "on lnkapplappltag.lnkapplappl=lnkapplappl.id ".
            "left outer join appl as fromappl ".
            "on lnkapplappl.fromappl=fromappl.id ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id ".
            "left outer join appl as tagfromappl ".
            "on lnkapplappl.fromappl=tagfromappl.id ".
            "left outer join lnkapplappl as taglnkapplappl ".
            "on taglnkapplappl.fromappl=tagfromappl.id ".
            "left outer join lnkapplappltag as taglnkapplappltag ".
            "on taglnkapplappltag.lnkapplappl=taglnkapplappl.id";
   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ifdata control source));
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
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}









1;
