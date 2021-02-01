package itil::lnkapplgrpapplgrp;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'qlnkapplgrpapplgrp.id'),

      new kernel::Field::TextDrop(
                name          =>'fromapplgrp',
                htmlwidth     =>'250px',
                label         =>'from Applicationgroup',
                vjointo       =>'itil::applgrp',
                vjoinon       =>['fromapplgrpid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'fromapplgrp.fullname'),

      new kernel::Field::Text(
                name          =>'fromapplgrpid',
                label         =>'from ApplGrpID',
                dataobjattr   =>'qlnkapplgrpapplgrp.fromapplgrp'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'toapplgrp',
                htmlwidth     =>'350px',
                label         =>'to Applicationgroup',
                vjointo       =>'itil::applgrp',
                vjoinon       =>['toapplgrpid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'toapplgrp.fullname'),

      new kernel::Field::Text(
                name          =>'toapplgrpid',
                label         =>'to ApplGrpID',
                dataobjattr   =>'qlnkapplgrpapplgrp.toapplgrp'),

      new kernel::Field::Select(
                name          =>'relstatus',
                label         =>'rel. State',
                transprefix   =>'relstate.',
                value         =>['1',
                                 '2',
                                ],  # see also opmode at system
                htmleditwidth =>'200px',
                dataobjattr   =>'relstatus'),
                                                 
      new kernel::Field::Text(
                name          =>'relstatusid',
                label         =>'rel. State ID',
                dataobjattr   =>'qlnkapplgrpapplgrp.relstatus'),
                                                 
 #     new kernel::Field::Text(
 #               name          =>'fullname',
 #               htmlwidth     =>'250px',
 #               label         =>'relation name',
 #               searchable    =>0,
 #               htmldetail    =>0,
 #               dataobjattr   =>"concat(appl.name,' : ',system.name)"),
                                                   
      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'qlnkapplgrpapplgrp.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qlnkapplgrpapplgrp.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'qlnkapplgrpapplgrp.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'qlnkapplgrpapplgrp.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'qlnkapplgrpapplgrp.srcid'),
                                                   
      new kernel::Field::Text(
                name          =>'relstatus',
                group         =>'source',
                htmlwidth     =>'20px',
                readonly      =>1,
                label         =>'Rel.Status',
                dataobjattr   =>'qlnkapplgrpapplgrp.relstatus'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'qlnkapplgrpapplgrp.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qlnkapplgrpapplgrp.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qlnkapplgrpapplgrp.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'qlnkapplgrpapplgrp.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'qlnkapplgrpapplgrp.realeditor'),
   );

 #  $self->{history}={
 #     insert=>[
 #        'local'
 #     ],
 #     update=>[
 #        'local'
 #     ],
 #     delete=>[
 #        {dataobj=>'itil::appl', id=>'applid',
 #         field=>'system',as=>'systems'},
 #        {dataobj=>'itil::system', id=>'systemid',
 #         field=>'appl',as=>'applications'}
 #     ]
 #  };

   $self->setDefaultView(qw(fromapplgrpid fromapplgrp toapplgrpid toapplgrp relstatus cdate));
   $self->setWorktable("lnkapplgrpapplgrp");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkapplgrpapplgrp.jpg?".$cgi->query_string());
#}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_systemcistatus"))){
#     Query->Param("search_systemcistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#   if (!defined(Query->Param("search_applcistatus"))){
#     Query->Param("search_applcistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;


   #
   # creating pre selection for subselect
   #
   my $datasourcerest1="1";
   my $datasourcerest2="lnkapplappl.cistatus<5";
   if ($mode eq "select"){
      foreach my $f (@filter){
         if (ref($f) eq "HASH"){

            if (exists($f->{applid}) && $f->{applid}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplgrpapplgrp.appl='$f->{applid}'";
               $datasourcerest2.=" and lnkitclustsvcappl.appl='$f->{applid}'";
            }
            if (exists($f->{applid}) && ref($f->{applid}) eq "SCALAR"){
               $f->{applid}=[${$f->{applid}}];
            }
            if (exists($f->{applid}) && ref($f->{applid}) eq "ARRAY"){
               $datasourcerest1.=" and lnkapplgrpapplgrp.appl in (".
                             join(",",map({"'".$_."'"} @{$f->{applid}})).")";
               $datasourcerest2.=" and lnkitclustsvcappl.appl in (".
                             join(",",map({"'".$_."'"} @{$f->{applid}})).")";
            }
            if (exists($f->{id}) && $f->{id}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplgrpapplgrp.id='$f->{id}'";
               $datasourcerest2.=" and 1=0";
            }

            if (exists($f->{id}) && ref($f->{id}) eq "ARRAY" &&
                $#{$f->{id}}==0 && $f->{id}->[0]=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplgrpapplgrp.id='$f->{id}->[0]'";
               $datasourcerest2.=" and 1=0";
            }
            if (exists($f->{id}) && ref($f->{id}) eq "SCALAR" &&
                ${$f->{id}}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplgrpapplgrp.id='${$f->{id}}'";
               $datasourcerest2.=" and 1=0";
            }
         }
      }
   }


   $datasourcerest1=" where $datasourcerest1" if ($datasourcerest1 ne ""); 
   $datasourcerest2=" where $datasourcerest2" if ($datasourcerest2 ne ""); 


   my $datasource=
     "select ".
        "lnkapplgrpapplgrp.id, ".
        "lnkapplgrpapplgrp.fromapplgrp, ".
        "lnkapplgrpapplgrp.toapplgrp, ".
        "lnkapplgrpapplgrp.relstatus, ".
        "lnkapplgrpapplgrp.comments, ".
        "lnkapplgrpapplgrp.additional, ".
        "lnkapplgrpapplgrp.createdate, ".
        "lnkapplgrpapplgrp.modifydate, ".
        "lnkapplgrpapplgrp.createuser, ".
        "lnkapplgrpapplgrp.modifyuser, ".
        "lnkapplgrpapplgrp.editor, ".
        "lnkapplgrpapplgrp.realeditor, ".
        "lnkapplgrpapplgrp.srcsys, ".
        "lnkapplgrpapplgrp.srcid, ".
        "lnkapplgrpapplgrp.srcload  ".
     "from lnkapplgrpapplgrp $datasourcerest1 ".
     "union ".
     "select ".
           "id, ".
           "fromapplgrp, ".
           "toapplgrp, ".
           "max(relstatus) relstatus, ".
           "comments,".
           "additional, ".
           "createdate, ".
           "modifydate, ".
           "createuser, ".
           "modifyuser, ".
           "editor, ".
           "realeditor, ".
           "srcsys, ".
           "srcid, ".
           "srcload  ".
        "from (".
        "select ".
           "null id, ".
           "Flnkapplgrpappl.applgrp fromapplgrp, ".
           "Tlnkapplgrpappl.applgrp toapplgrp, ".
           "lnkapplappl.cistatus relstatus, ".
           "null comments,".
           "null additional, ".
           "null createdate, ".
           "null modifydate, ".
           "null createuser, ".
           "null modifyuser, ".
           "null editor, ".
           "null realeditor, ".
           "null srcsys, ".
           "null srcid, ".
           "null srcload  ".
        "from lnkapplgrpappl Flnkapplgrpappl ".
            "join appl Fappl ".
            "on Fappl.id=Flnkapplgrpappl.appl ".
            "join lnkapplappl ".
            "on Fappl.id=lnkapplappl.fromappl ".
            "join appl Tappl ".
            "on lnkapplappl.toappl=Tappl.id ".
            "join lnkapplgrpappl Tlnkapplgrpappl ".
            "on Tlnkapplgrpappl.appl=Tappl.id ".
           $datasourcerest2." ".
        "group by Flnkapplgrpappl.applgrp,Tlnkapplgrpappl.applgrp ".
        "union ".
        "select ".
           "null id, ".
           "Flnkapplgrpappl.applgrp fromapplgrp, ".
           "Tlnkapplgrpappl.applgrp toapplgrp, ".
           "lnkapplappl.cistatus relstatus, ".
           "null comments,".
           "null additional, ".
           "null createdate, ".
           "null modifydate, ".
           "null createuser, ".
           "null modifyuser, ".
           "null editor, ".
           "null realeditor, ".
           "null srcsys, ".
           "null srcid, ".
           "null srcload  ".
        "from lnkapplgrpappl Tlnkapplgrpappl ".
            "join appl Tappl ".
            "on Tappl.id=Tlnkapplgrpappl.appl ".
            "join lnkapplappl ".
            "on Tappl.id=lnkapplappl.fromappl ".
            "join appl Fappl ".
            "on lnkapplappl.toappl=Fappl.id ".
            "join lnkapplgrpappl Flnkapplgrpappl ".
            "on Flnkapplgrpappl.appl=Fappl.id ".
           $datasourcerest2." ".
        ") as r ".
        "group by fromapplgrp,toapplgrp ";

   my $from="($datasource) qlnkapplgrpapplgrp ".
            "left outer join applgrp fromapplgrp ".
            "on qlnkapplgrpapplgrp.fromapplgrp=fromapplgrp.id ".
            "left outer join applgrp toapplgrp ".
            "on qlnkapplgrpapplgrp.toapplgrp=toapplgrp.id ";
   return($from);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkapplgrpapplgrp");
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applgrpid=effVal($oldrec,$newrec,"fromapplgrpid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnApplGrpValid($applgrpid,
                         "applgrpinterfaces"));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc applinfo systeminfo assetinfo));
}







1;
