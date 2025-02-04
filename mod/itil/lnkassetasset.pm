package itil::lnkassetasset;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit itil::lib::Listedit kernel::DataObj::DB);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

#   $self->{history}={
#      insert=>[
#         {dataobj=>'itil::asset', id=>'passetid',
#          field=>'compassets',as=>'casset'}
#      ],
#      update=>[
#         'local',
#         {dataobj=>'itil::asset', id=>'passetid',
#          field=>'compassets',as=>'casset'}
#      ],
#      delete=>[
#         {dataobj=>'itil::asset', id=>'passetid',
#          field=>'compassets',as=>'casset'}
#      ]
#   };

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Link ID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'lnkassetasset.id'),
      new kernel::Field::RecordUrl(),
                                                 
      new kernel::Field::TextDrop(
                name          =>'passet',
                label         =>'parent asset',
                vjoineditbase =>{'cistatusid'=>"<5",'class'=>'BUNDLE'},
                vjointo       =>'itil::asset',
                vjoinon       =>['passetid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'passet.name'),

      new kernel::Field::Interface(
                name          =>'passetid',
                label         =>'pAssetID',
                readonly      =>1,
                dataobjattr   =>'lnkassetasset.passet'),
                                                   
      new kernel::Field::Interface(
                name          =>'fullname',
                label         =>'fullname',
                readonly      =>1,
                dataobjattr   =>"concat(passet.name,'->',casset.name)"),
                                                   
      new kernel::Field::Interface(
                name          =>'passetcistatusid',
                label         =>'pAssetCiStatusID',
                readonly      =>1,
                dataobjattr   =>'passet.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'casset',
                label         =>'compose asset',
                vjoineditbase =>{'cistatusid'=>"<5",'class'=>'NATIVE'},
                vjointo       =>'itil::asset',
                vjoinon       =>['cassetid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'casset.name'),
                                                   
      new kernel::Field::Text(
                name          =>'cassetlocation',
                label         =>'compose asset location',
                htmldetail    =>0,
                dataobjattr   =>'cassetlocation.name'),
                                                   
      new kernel::Field::Interface(
                name          =>'cassetid',
                label         =>'cAssetID',
                readonly      =>1,
                dataobjattr   =>'lnkassetasset.casset'),
                                                   
      new kernel::Field::Interface(
                name          =>'cassetcistatusid',
                label         =>'cAssetCiStatusID',
                readonly      =>1,
                dataobjattr   =>'casset.cistatus'),

      new kernel::Field::Interface(
                name          =>'cassetlocationid',
                label         =>'cAssetLocationID',
                readonly      =>1,
                dataobjattr   =>'casset.location'),
                                                   

      new kernel::Field::Select(
                name          =>'cassetcistatus',
                label         =>'CI-State',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cassetcistatusid'=>'id'],
                vjoindisp     =>'name'),

                                                  
#      new kernel::Field::Textarea(
#                name          =>'comments',
#                searchable    =>0,
#                label         =>'Comments',
#                dataobjattr   =>'lnkassetasset.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkassetasset.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkassetasset.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkassetasset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkassetasset.srcid'),
                                                   
#      new kernel::Field::Date(
#                name          =>'srcload',
#                group         =>'source',
#                label         =>'Last-Load',
#                dataobjattr   =>'lnkassetasset.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkassetasset.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkassetasset.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkassetasset.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkassetasset.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkassetasset.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkassetasset.realeditor'),

   );
   $self->setDefaultView(qw(passet casset cassetcistatus cassetlocation cdate));
   $self->setWorktable("lnkassetasset");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkassetasset ".
            "left outer join asset as passet ".
            "on lnkassetasset.passet=passet.id ".
            "left outer join asset as casset ".
            "on lnkassetasset.casset=casset.id ".
            "left outer join location as cassetlocation ".
            "on casset.location=cassetlocation.id ";
   return($from);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_applcistatus"))){
#     Query->Param("search_applcistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}



#sub SecureSetFilter
#{
#   my $self=shift;
#   my @flt=@_;
#
#   if (!$self->isDirectFilter(@flt) &&
#       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
#                          "RMember")){
#      my @addflt;
#      $self->itil::appl::addApplicationSecureFilter([''],\@addflt);
#      push(@flt,\@addflt);
#   }
#   return($self->SetFilter(@flt));
#}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (defined($oldrec)){
      if (effChanged($oldrec,$newrec,"passetid")){
         $self->LastMsg(ERROR,"parent asset can not be changed");
         return(undef);
      }
   }

   my $assetid=effVal($oldrec,$newrec,"passetid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteToAssetValid($assetid)){
         $self->LastMsg(ERROR,"no write access to requested parent asset");
         return(undef);
      }
   }


   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default source)
   );
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if (!defined($rec));

   my $assetid=$rec->{passetid};
   if ($self->isWriteToAssetValid($assetid)){
      return("default");
   }
   return(undef);
}


sub isWriteToAssetValid
{
   my $self=shift;
   my $assetid=shift;

   my $userid=$self->getCurrentUserId();
   my $wrok=0;
   $wrok=1 if (!defined($assetid));
   if ($self->itil::lib::Listedit::isWriteOnAssetValid($assetid,"compassets")){
      $wrok=1;
   }
   return($wrok);
}



#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/urlci.jpg?".$cgi->query_string());
#}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}















1;
