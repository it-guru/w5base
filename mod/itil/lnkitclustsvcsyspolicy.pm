package itil::lnkitclustsvcsyspolicy;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                group         =>'default',
                dataobjattr   =>"concat(qlnkitclustsvc.id,'-',qsystem.id)",
                wrdataobjattr =>"refid"),
                                                 
      new kernel::Field::Text(
                name          =>'name',
                label         =>'System',
                readonly      =>1,
                weblinkto     =>'itil::system',
                weblinkon     =>['syssystemid'=>'id'],
                dataobjattr   =>'qsystem.name'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                readonly      =>1,
                translation   =>'itil::system',
                dataobjattr   =>'qsystem.systemid'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'System CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'itclustcistatus',
                htmleditwidth =>'40%',
                label         =>'Cluster CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'base::cistatus',
                vjoinon       =>['itclustcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'shortdesc',
                label         =>'Short Description',
                htmlwidth     =>'40%',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                translation   =>'itil::system',
                dataobjattr   =>'qsystem.shortdesc'),

      new kernel::Field::Text(
                name          =>'itclustsvc',
                label         =>'Cluster Servicename',
                weblinkto     =>'itil::lnkitclustsvc',
                weblinkon     =>['itclustsvcid'=>'id'],
                readonly      =>1,
                htmlwidth     =>'250px',
                readonly      =>1,
                dataobjattr   =>"concat(qitclust.fullname,'.',".
                                "qlnkitclustsvc.itsvcname,".
                                "if (qlnkitclustsvc.subitsvcname<>'',".
                                "concat('.',qlnkitclustsvc.subitsvcname),''))"),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Cluster Servicename',
                readonly      =>1,
                htmlwidth     =>'250px',
                readonly      =>1,
                dataobjattr   =>"concat(qitclust.fullname,'.',".
                                "qlnkitclustsvc.itsvcname,".
                                "if (qlnkitclustsvc.subitsvcname<>'',".
                                "concat('.',qlnkitclustsvc.subitsvcname),''),".
                                "' on ',qsystem.name)"),

      new kernel::Field::Select(
                name          =>'runpolicy',
                htmleditwidth =>'100',
                htmlwidth     =>'100',
                label         =>'Run Policy',
                value         =>['allow','deny','allow DEFAULT'],
                dataobjattr   =>"if (qlnkitclustsvcsyspolicy.runpolicy ".
                                "is null,qitclust.defrunpolicy,".
                                "qlnkitclustsvcsyspolicy.runpolicy)",
                wrdataobjattr =>'runpolicy'),

#      new kernel::Field::Link(
#                name          =>'runpolicylevel',
#                htmleditwidth =>'100',
#                htmlwidth     =>'100',
#                label         =>'Run Policy Level',
#                dataobjattr   =>"case if (qlnkitclustsvcsyspolicy.runpolicy ".
#                                "is null,qitclust.defrunpolicy,".
#                                "qlnkitclustsvcsyspolicy.runpolicy) ".
#                                "when 'allow DEFAULT' then '1' ".
#                                "when 'allow'         then '2' ".
#                                "else '9' end"),

      new kernel::Field::DynWebIcon(
                name          =>'runpolicylevel',
                searchable    =>0,
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   my $e=$current->{runpolicylevel};
                   my $name=$self->Name();
                   my $app=$self->getParent();
                   if ($mode=~m/html/i){
                      return("<img ".
                         "src=\"../../itil/load/runpolicy${e}.gif\" ".
                         "title=\"\" border=0>");
                   }
                   return($e);
                },
                dataobjattr   =>"case if (qlnkitclustsvcsyspolicy.runpolicy ".
                                "is null,qitclust.defrunpolicy,".
                                "qlnkitclustsvcsyspolicy.runpolicy) ".
                                "when 'allow DEFAULT' then '1' ".
                                "when 'allow'         then '2' ".
                                "else '9' end"),



      new kernel::Field::Interface(
                name          =>'clustid',
                label         =>'ClustID',
                selectfix     =>1,
                dataobjattr   =>"qitclust.id"),

      new kernel::Field::Interface(
                name          =>'syssystemid',
                label         =>'SystemID',
                selectfix     =>1,
                dataobjattr   =>"qsystem.id",
                wrdataobjattr =>'system'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                readonly      =>1,
                dataobjattr   =>'qsystem.cistatus'),

      new kernel::Field::Link(
                name          =>'itclustcistatusid',
                label         =>'Cluster CI-StateID',
                readonly      =>1,
                dataobjattr   =>'qitclust.cistatus'),

      new kernel::Field::Interface(
                name          =>'itclustsvcid',
                label         =>'ClusterServiceID',
                selectfix     =>1,
                dataobjattr   =>"qlnkitclustsvc.id",
                wrdataobjattr =>'itclustsvc'),

      new kernel::Field::Link(
                name          =>'ofid',
                readonly      =>1,
                label         =>'Overflow ID',
                dataobjattr   =>'qlnkitclustsvcsyspolicy.refid'),


      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"qlnkitclustsvcsyspolicy.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"md5(concat(concat(".
                                "lpad(qlnkitclustsvc.id,35,'0'),'-'),".
                                "lpad(qsystem.id,35,'0')))"),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                selectfix     =>1,
                label         =>'last Editor',
                dataobjattr   =>'qlnkitclustsvcsyspolicy.modifyuser',
                wrdataobjattr =>'modifyuser'),
                                   
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qlnkitclustsvcsyspolicy.modifydate',
                wrdataobjattr =>'modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'qlnkitclustsvcsyspolicy.editor',
                wrdataobjattr =>'editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'qlnkitclustsvcsyspolicy.realeditor',
                wrdataobjattr =>'realeditor')
   );
   $self->setDefaultView(qw(itclustsvc name runpolicy));
   $self->setWorktable("lnkitclustsvcsyspolicy");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_itclustcistatus"))){
     Query->Param("search_itclustcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}





sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   if (!defined($oldrec->{ofid})){  
      map({$newrec->{$_}=$oldrec->{$_}} qw(id syssystemid itclustsvcid));
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}




sub getSqlFrom
{
   my $self=shift;

   my $join="left outer join";

   if ($W5V2::OperationContext eq "W5Replicate"){
      $join="join";
   }
   my $from="lnkitclustsvc qlnkitclustsvc  ".
            "join itclust qitclust ".
            "on qlnkitclustsvc.itclust=qitclust.id ".
            "join system qsystem ".
            "on qsystem.clusterid=qitclust.id ".
            "${join} lnkitclustsvcsyspolicy qlnkitclustsvcsyspolicy ".
            "on qlnkitclustsvc.id=qlnkitclustsvcsyspolicy.itclustsvc and ".
            "   qsystem.id=qlnkitclustsvcsyspolicy.system";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","source") if ($rec->{owner} eq "");
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $itclustid=effVal($oldrec,$newrec,"clustid");

   return("default") if ($self->isWriteOnClusterValid($itclustid,"services"));
   return(undef);
}




1;
