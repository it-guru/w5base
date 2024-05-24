package TS::costobjectmap;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::Listedit;
use finance::costcenter;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB );


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);



   $self->{useMenuFullnameAsACL}=$self->Self();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Link(
                name          =>'fullname',
                searchable    =>0,
                reeadonly     =>1,
                dataobjattr   =>"concat(TS_costobjectmap.systemid,'=>'".
                                ",TS_costobjectmap.conumber)"),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                reeadonly     =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'TS_costobjectmap.id'),

      new kernel::Field::Mandator(
                htmldetail    =>'NotEmpty',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                readonly      =>1,
                dataobjattr   =>'system.mandator'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'system.name'),

      new kernel::Field::Select(
                name          =>'systemcistatus',
                label         =>'CI-State',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                readonly      =>1,
                dataobjattr   =>'system.cistatus'),


      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'TS_costobjectmap.systemid'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'cost object number',
                selectfix     =>1,
                dataobjattr   =>'TS_costobjectmap.conumber'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'TS_costobjectmap.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'TS_costobjectmap.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'TS_costobjectmap.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'TS_costobjectmap.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'TS_costobjectmap.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'TS_costobjectmap.realeditor')
   );
   $self->setDefaultView(qw(systemname systemid cistatus conumber));
   $self->setWorktable("TS_costobjectmap");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ));
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();

   if ($mode eq "select"){
      return("$worktable left outer ".
             "join system on $worktable.systemid=system.systemid");
   }
   return($self->SUPER::getSqlFrom($mode,@filter));
}


sub prepUploadRecord
{
   my $self=shift;
   my $newrec=shift;

   if (!exists($newrec->{id}) || $newrec->{id} eq ""){
      if (exists($newrec->{systemid}) && $newrec->{systemid} ne ""){
         my $o=$self->Clone();
         $o->SetFilter({systemid=>\$newrec->{systemid}});
         my ($rec,$msg)=$o->getOnlyFirst(qw(id));
         if (defined($rec)){
            $newrec->{id}=$rec->{id};
         }
      }
   }
   return(1);
}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid($rec);

   if (in_array(@l,"ALL")){
      return("default");
   }
   return(@l);
}











sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   my $systemid=effVal($oldrec,$newrec,"systemid");
   my $newsystemid=uc($systemid);

   if ($newsystemid eq ""){
      $self->LastMsg(ERROR,"invalid SystemID");
      return(0);
   }
   if ($newsystemid ne $systemid && exists($newrec->{systemid})){
      $newrec->{systemid}=$newsystemid;
   }

   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber(
          $self->SelfAsParentObject(),"conumber",$oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "finance::costcenter"),$newrec->{conumber});
         return(0);
      }
   }


   return(1);
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("TS::vou");
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
