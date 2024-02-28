package itil::lnkapplsystem;
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
use itil::lib::Listedit;
use itil::appl;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);
   my $sys=getModuleObject($self->Config,"itil::system");

   my $vmifexp="if (".join(' or ',
                map({"system.systemtype='$_'"} @{$sys->needVMHost()}));
   if ($#{$sys->needVMHost()}==-1){
      $vmifexp="if (0";
   }


   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'qlnkapplsystem.id'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'250px',
                label         =>'relation name',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"concat(appl.name,' : ',system.name)"),
                                                   
      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
                                                   
      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                htmlwidth     =>'80px',
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),
                                                   
      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::Text(
                name          =>'systemsrcsys',
                label         =>'System Source-System',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.srcsys'),

      new kernel::Field::Text(
                name          =>'systemsrcid',
                label         =>'System Source-Id',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.srcid'),

      new kernel::Field::TextDrop(
                name          =>'systemconumber',
                htmlwidth     =>'100px',
                htmdetail     =>0,
                readonly      =>1,
                label         =>'System costcenter',
                dataobjattr   =>'system.conumber'),
                                                   
      new kernel::Field::Text(
                name          =>'shortdesc',
                label         =>'Short Description',
                readonly      =>1,
                group         =>'systeminfo',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::Text(
                name          =>'assetassetname',
                readonly      =>1,
                group         =>'assetinfo',
                label         =>'Asset-Name',
                dataobjattr   =>"$vmifexp,vasset.name,asset.name)"),

      new kernel::Field::TextDrop(
                name          =>'assetlocation',
                group         =>'assetinfo',
                readonly      =>1,
                label         =>'Asset Location',
                vjointo       =>'base::location',
                vjoinon       =>['assetlocationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'itfarm',
                group         =>'assetinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Serverfarm',
                vjointo       =>'itil::lnkitfarmasset',
                vjoinon       =>['assetid'=>'assetid'],
                vjoindisp     =>'itfarm'),

      new kernel::Field::Select(
                name          =>'osrelease',
                group         =>'systeminfo',
                readonly      =>1,
                translation   =>'itil::system',
                htmleditwidth =>'40%',
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Number(
                name          =>'logicalcpucount',
                group         =>'systeminfo',
                readonly      =>1,
                label         =>'log. CPU count',
                dataobjattr   =>'system.cpucount'),

      new kernel::Field::Number(
                name          =>'relphysicalcpucount',
                group         =>'systeminfo',
                label         =>'relative phys. CPU count',
                readonly      =>1,
                searchable    =>0,
                precision     =>2,
                weblinkto     =>"NONE",
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'relphysicalcpucount'),

      new kernel::Field::Number(
                name          =>'logicalmemory',
                group         =>'systeminfo',
                label         =>'log. Memory',
                unit          =>'MB',
                dataobjattr   =>'system.memory'),

      new kernel::Field::Select(
                name          =>'osclass',
                group         =>'systeminfo',
                readonly      =>1,
                translation   =>'itil::system',
                htmleditwidth =>'40%',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'OS-Class',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'osclass'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Link(
                name          =>'systemdenyupd',
                label         =>'System denyupd',
                dataobjattr   =>'system.denyupd'),

      new kernel::Field::Link(
                name          =>'systemdenyupdvalidto',
                label         =>'System denyupdvalidto',
                dataobjattr   =>'system.denyupdvalidto'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Boolean(
                name          =>'isprod',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Productionsystem',
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Boolean(
                name          =>'istest',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Testsystem',
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                searchable    =>0,
                htmlwidth     =>'60px',
                dataobjattr   =>'qlnkapplsystem.fraction'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'qlnkapplsystem.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   my $d=$rec->{$self->Name()};
                   if (ref($d) eq "HASH" && keys(%$d)){
                      return(1);
                   }
                   return(0);
                },
                dataobjattr   =>'qlnkapplsystem.additional'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qlnkapplsystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'qlnkapplsystem.modifyuser'),

      new kernel::Field::Select(
                name          =>'cistatus',
                label         =>'Relation CI-State',
                group         =>'source',
                selectsearch  =>sub{
                   my $self=shift;
                   my @l;
                   push(@l,$self->getParent->T("CI-Status(4)","base::cistatus"),
                           $self->getParent->T("CI-Status(6)","base::cistatus")
                   );
                   return(@l);
                },
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                wrdataobjattr =>'lnkapplsystem.cistatus',
                dataobjattr   =>'qlnkapplsystem.cistatus'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'qlnkapplsystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'qlnkapplsystem.srcid'),
                                                   
      new kernel::Field::Text(
                name          =>'reltyp',
                group         =>'source',
                htmlwidth     =>'20px',
                readonly      =>1,
                label         =>'Rel.Typ',
                dataobjattr   =>"if (qlnkapplsystem.numreltyp='20','cluster',".
                                "if (qlnkapplsystem.numreltyp='30','instance',".
                                "'direct'))"),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'qlnkapplsystem.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"qlnkapplsystem.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(qlnkapplsystem.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qlnkapplsystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qlnkapplsystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'qlnkapplsystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'qlnkapplsystem.realeditor'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                label         =>'Application Mandator',
                readonly      =>1),

      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'applconumber',
                htmlwidth     =>'100px',
                group         =>'applinfo',
                htmdetail     =>0,
                readonly      =>1,
                label         =>'Application costcenter',
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::appl',
                dontrename    =>1,
                readonly      =>1,
                group         =>'applinfo',
                uploadable    =>0,
                fields        =>[qw(opmode)]),
                                                   
      new kernel::Field::Link(
                name          =>'tsmid',
                label         =>'TSM ID',
                readonly      =>1,
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'appldatabossid',
                label         =>'Databosss ID',
                readonly      =>1,
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Contact(
                name          =>'appldataboss',
                group         =>'applinfo',
                label         =>'Databoss',
                translation   =>'itil::appl',
                readonly      =>1,
                vjoinon       =>'appldatabossid'),

      new kernel::Field::Contact(
                name          =>'tsm',
                group         =>'applinfo',
                label         =>'Technical Solution Manager',
                readonly      =>1,
                vjoinon       =>'tsmid'),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'applinfo',
                label         =>'Technical Solution Manager E-Mail',
                htmlwidth     =>'280px',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                label         =>'TSM ID',
                readonly      =>1,
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::TextDrop(
                name          =>'tsm2',
                group         =>'applinfo',
                label         =>'Deputy Technical Solution Manager',
                translation   =>'itil::appl',
                htmlwidth     =>'280px',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'applinfo',
                label         =>'deputy Technical Solution Manager E-Mail',
                htmlwidth     =>'280px',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                label         =>'Businessteam ID',
                readonly      =>1,
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::Group(
                name          =>'businessteam',
                readonly      =>1,
                group         =>'applinfo',
                label         =>'Business Team',
                vjoinon       =>'businessteamid',
                dataobjattr   =>'businessteam.fullname'),

      new kernel::Field::Group(
                name          =>'businessdepart',
                label         =>'Business Department',
                readonly      =>1,
                translation   =>'itil::appl',
                group         =>'applinfo',
                vjoinon       =>'businessdepartid'),

      new kernel::Field::Link(
                name          =>'businessdepartid',
                label         =>'Businessdepartment ID',
                readonly      =>1,
                translation   =>'itil::appl',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'businessdepartid'),

      new kernel::Field::Group(
                name          =>'applcustomer',
                label         =>'Application Customer',
                readonly      =>1,
                group         =>'applinfo',
                vjoinon       =>'customerid'),

      new kernel::Field::Text(
                name          =>'applcustomerprio',
                label         =>'Customers Application Prioritiy',
                translation   =>'itil::appl',
                readonly      =>1,
                group         =>'applinfo',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'applcriticality',
                group         =>'applinfo',
                label         =>'Criticality',
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                readonly      =>1,
                translation   =>'itil::appl',
                dataobjattr   =>'appl.criticality'),


      new kernel::Field::Text(
                name          =>'oncallphones',
                searchable    =>0,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                htmlwidth     =>'150px',
                group         =>'applinfo',
                translation   =>'itil::appl',
                weblinkto     =>'none',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['applid'=>'refid'], 
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>'phonenumber'),


      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetID W5BaseID',
                dataobjattr   =>"$vmifexp,vsystem.asset,system.asset)"),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Boolean(
                name          =>'isdevel',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Developmentsystem',
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Boolean(
                name          =>'iseducation',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Educationsystem',
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Boolean(
                name          =>'isapprovtest',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Approval Testsystem',
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Boolean(
                name          =>'isreference',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Referencesystem',
                dataobjattr   =>'system.is_reference'),

      new kernel::Field::Boolean(
                name          =>'isapplserver',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Applicationserver',
                dataobjattr   =>'system.is_applserver'),

      new kernel::Field::Boolean(
                name          =>'isbackupsrv',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Backupserver',
                dataobjattr   =>'system.is_backupsrv'),

      new kernel::Field::Boolean(
                name          =>'isdatabasesrv',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'Databaseserver',
                dataobjattr   =>'system.is_databasesrv'),

      new kernel::Field::Boolean(
                name          =>'iswebserver',
                readonly      =>1,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                label         =>'WEB-Server',
                dataobjattr   =>'system.is_webserver'),

      new kernel::Field::Boolean(
                name          =>'isnetswitch',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Switch/Networkswitch',
                dataobjattr   =>'system.is_netswitch'),

      new kernel::Field::Boolean(
                name          =>'isembedded',
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'Embedded System',
                dataobjattr   =>'system.is_embedded'),

      new kernel::Field::Boolean(
                name          =>'systemissox',
                readonly      =>1,
                uivisible     =>0,
                group         =>'systeminfo',
                htmleditwidth =>'30%',
                translation   =>'itil::system',
                label         =>'mangaged by rules of SOX',
                dataobjattr   =>
                'if (system.no_sox_inherit,0,appl.is_soxcontroll)'),

      new kernel::Field::Boolean(
                name          =>'assetissox',
                readonly      =>1,
                group         =>'assetinfo',
                htmleditwidth =>'30%',
                uivisible     =>0,
                translation   =>'itil::system',
                label         =>'mangaged by rules of SOX',
                dataobjattr   =>'if (asset.no_sox_inherit,0,'.
                                'if (system.no_sox_inherit,0,'.
                                'appl.is_soxcontroll))'),

      new kernel::Field::TextDrop(
                name          =>'applgrp',
                htmlwidth     =>'250px',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Applicationgroup',
                vjointo       =>'itil::applgrp',
                vjoinon       =>['applgrpid'=>'id'],
                vjoindisp     =>'fullname',
                group         =>'applgrp',
                dataobjattr   =>'applgrp.fullname'),
                                                   
      new kernel::Field::Select(
                name          =>'applgrpcistatus',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                htmlwidth     =>'80px',
                group         =>'applgrp',
                label         =>'Applicationgroup CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applgrpcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Interface(
                name          =>'applgrpid',
                label         =>'W5Base Applicationgroup ID',
                readonly      =>1,
                group         =>'applgrp',
                dataobjattr   =>'applgrp.id'),


      new kernel::Field::Interface(
                name          =>'applgrpcistatusid',
                label         =>'Applicationgroup CI-State',
                readonly      =>1,
                group         =>'applgrp',
                dataobjattr   =>'applgrp.cistatus'),


      new kernel::Field::Interface(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>"$vmifexp,vsystem.asset,system.asset)"),
                                                   
      new kernel::Field::Text(
                name          =>'applid',
                htmldetail    =>0,
                label         =>'W5Base Application ID',
                dataobjattr   =>'qlnkapplsystem.appl'),
                                                   
      new kernel::Field::Text(
                name          =>'systemid',
                htmldetail    =>0,
                label         =>'W5Base System ID',
                dataobjattr   =>'qlnkapplsystem.system'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Application MandatorID',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Link(
                name          =>'assetlocationid',
                label         =>'AssetLocationID',
                dataobjattr   =>'asset.location'),


      new kernel::Field::Link(
                name          =>'secsystemapplsectarget',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.target'),

      new kernel::Field::Link(
                name          =>'secsystemapplsectargetid',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secsystemapplsecroles',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'secsystemapplmandatorid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.mandator'),

      new kernel::Field::Link(
                name          =>'secsystemapplbusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.businessteam'),

      new kernel::Field::Link(
                name          =>'secsystemappltsmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm'),

      new kernel::Field::Link(
                name          =>'secsystemappltsm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm2'),

      new kernel::Field::Link(
                name          =>'secsystemapplopmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm'),

      new kernel::Field::Link(
                name          =>'secsystemapplopm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm2'),



      new kernel::Field::DynWebIcon(
                name          =>'applweblink',
                searchable    =>0,
                depend        =>['applid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $applido=$self->getParent->getField("applid");
                   my $applid=$applido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../itil/appl/Detail?id=$applid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-");
                }),

      new kernel::Field::DynWebIcon(
                name          =>'systemweblink',
                searchable    =>0,
                depend        =>['systemid'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $systemido=$self->getParent->getField("systemid");
                   my $systemid=$systemido->RawValue($current);

                   my $img="<img ";
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   $img.="title=\"\" border=0>";
                   my $dest="../../itil/system/Detail?id=$systemid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-");
                }),

   );

   $self->{history}={
      insert=>[
         'local'
      ],
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>'itil::appl', id=>'applid',
          field=>'system',as=>'systems'},
         {dataobj=>'itil::system', id=>'systemid',
          field=>'appl',as=>'applications'}
      ]
   };

   $self->setDefaultView(qw(appl system systemsystemid fraction cdate));
   $self->setWorktable("lnkapplsystem");
   return($self);
}


sub calcPhyCpuCount
{
   my $self=shift;
   my $current=shift;

   my $assetid=$current->{assetid};
   my $lcpucount=$current->{logicalcpucount};
   my $sys=getModuleObject($self->getParent->Config,"itil::system");
   my $ass=getModuleObject($self->getParent->Config,"itil::asset");
   $ass->SetFilter({id=>\$assetid});
   my ($arec)=$ass->getOnlyFirst(qw(cpucount corecount));
   if (defined($arec)){
      $sys->SetFilter({assetid=>\$assetid,cistatusid=>[qw(3 4 5)]}); 
      my $syscount;
      my $syscpucount;
      foreach my $subsysrec ($sys->getHashList(qw(cpucount))){
         $syscount++;
         $syscpucount+=$subsysrec->{cpucount}; 
      }
      if ($syscount>1){
      }
      return($arec->{cpucount});
   }

   return(undef);

}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;
   #
   # creating pre selection for subselect
   #
   my $datasourcerest1="1";
   my $datasourcerest2="system.cistatus<=5 and itclust.cistatus<=5 ".
                       "and (".
                       "(lnkitclustsvcsyspolicy.runpolicy is null and ".
                       "itclust.defrunpolicy<>'deny') or ".
                       "(lnkitclustsvcsyspolicy.runpolicy is not null and ".
                       "lnkitclustsvcsyspolicy.runpolicy<>'deny'))";
   my $datasourcerest3="system.cistatus<=5 ".
                       "and swinstance.runonclusts=0 ".
                       "and swinstance.cistatus<=5";
   if ($mode eq "select"){
      foreach my $f (@filter){
         if (ref($f) eq "HASH"){
            if (exists($f->{assetid}) && $f->{assetid}=~m/^\d+$/){
               $f->{assetid}=[$f->{assetid}];
            }
            if (exists($f->{assetid}) && ref($f->{assetid}) eq "SCALAR"){
               $f->{assetid}=[${$f->{assetid}}];
            }
            if (exists($f->{cistatusid}) && ref($f->{cistatusid}) eq "ARRAY"){
               # this is only to allow searches in lnkapplsystem throw the
               # Web-Frontend by users in disposed of wasted relations
               if ($#{$f->{cistatusid}}==0 && $f->{cistatusid}->[0] eq "6"){
                  $datasourcerest1.=" and lnkapplsystem.cistatus in (".
                                join(",",map({"'".$_."'"} 
                                         @{$f->{cistatusid}})).")";
               }
            }
            if (exists($f->{assetid}) && ref($f->{assetid}) eq "ARRAY"){
               my $sys=getModuleObject($self->Config,"itil::system");
               $sys->SetFilter({assetid=>$f->{assetid}});
               my @l=$sys->getHashList("id");
               my @sysid=();
               foreach my $sysrec ($sys->getHashList("id")){
                  push(@sysid,$sysrec->{id});
               }
               push(@sysid,"-99") if ($#sysid==-1);
           #    $datasourcerest1.=" and lnkapplsystem.cistatus='4'";   # assetid handling on only active relations???
               $datasourcerest1.=" and lnkapplsystem.system in (".
                             join(",",map({"'".$_."'"} @sysid)).")";
               $datasourcerest2.=" and system.id in (".
                             join(",",map({"'".$_."'"} @sysid)).")";
               $datasourcerest3.=" and system.id in (".
                             join(",",map({"'".$_."'"} @sysid)).")";
            }
            if (exists($f->{applid}) && $f->{applid}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplsystem.appl='$f->{applid}'";
               $datasourcerest2.=" and lnkitclustsvcappl.appl='$f->{applid}'";
               $datasourcerest3.=" and swinstance.appl='$f->{applid}'";
            }
            if (exists($f->{applid}) && ref($f->{applid}) eq "SCALAR"){
               $f->{applid}=[${$f->{applid}}];
            }
            if (exists($f->{applid}) && ref($f->{applid}) eq "ARRAY"){
               $datasourcerest1.=" and lnkapplsystem.appl in (".
                             join(",",map({"'".$_."'"} @{$f->{applid}})).")";
               $datasourcerest2.=" and lnkitclustsvcappl.appl in (".
                             join(",",map({"'".$_."'"} @{$f->{applid}})).")";
               $datasourcerest3.=" and swinstance.appl in (".
                             join(",",map({"'".$_."'"} @{$f->{applid}})).")";
            }
            if (exists($f->{id}) && $f->{id}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplsystem.id='$f->{id}'";
               $datasourcerest2.=" and 1=0";
               $datasourcerest3.=" and 1=0";
            }
            if (exists($f->{id}) && ref($f->{id}) eq "ARRAY"){
               $datasourcerest2.=" and 1=0";
               $datasourcerest3.=" and 1=0";
               if ($#{$f->{id}}==0 && $f->{id}->[0]=~m/^\d+$/){
                  $datasourcerest1.=" and lnkapplsystem.id='$f->{id}->[0]'";
               }
               if ($#{$f->{id}}>0){
                  $datasourcerest1.=" and lnkapplsystem.id in (".
                  join(",",map({
                         my $id=$_;
                         "'".$id."'";
                      } @{$f->{id}}))
                  .")";
               }
            }
            if (exists($f->{id}) && ref($f->{id}) eq "SCALAR" &&
                ${$f->{id}}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplsystem.id='${$f->{id}}'";
               $datasourcerest2.=" and 1=0";
               $datasourcerest3.=" and 1=0";
            }
            if (exists($f->{systemid}) && $f->{systemid}=~m/^\d+$/){
               $datasourcerest1.=" and lnkapplsystem.system='$f->{systemid}'";
               $datasourcerest2.=" and system.id='$f->{systemid}'";
               $datasourcerest3.=" and swinstance.system='$f->{systemid}'";
            }
            if (exists($f->{systemid}) && ref($f->{systemid}) eq "SCALAR"){
               $f->{systemid}=[${$f->{systemid}}];
            }
            if (exists($f->{systemid}) && ref($f->{systemid}) eq "ARRAY"){
               $datasourcerest1.=" and lnkapplsystem.system in (".
                             join(",",map({"'".$_."'"} @{$f->{systemid}})).")";
               $datasourcerest2.=" and system.id in (".
                             join(",",map({"'".$_."'"} @{$f->{systemid}})).")";
               $datasourcerest3.=" and swinstance.system in (".
                             join(",",map({"'".$_."'"} @{$f->{systemid}})).")";
            }
         }
      }
   }
   if ($datasourcerest1 eq "1"){
      msg(INFO,"lnkapplsystem filter with cistatus=4");
      $datasourcerest1="lnkapplsystem.cistatus='4'";
   }
   else{
      #msg(INFO,"lnkapplsystem filter open $datasourcerest1");
   }

   $datasourcerest1=" where $datasourcerest1" if ($datasourcerest1 ne ""); 
   $datasourcerest2=" where $datasourcerest2" if ($datasourcerest2 ne ""); 
   $datasourcerest3=" where $datasourcerest3" if ($datasourcerest3 ne ""); 


   my $datasource=
     "select ".
        "lnkapplsystem.id, ".
        "lnkapplsystem.appl, ".
        "lnkapplsystem.system, ".
        "lnkapplsystem.comments, ".
        "lnkapplsystem.additional, ".
        "lnkapplsystem.fraction, ".
        "lnkapplsystem.createdate, ".
        "lnkapplsystem.modifydate, ".
        "lnkapplsystem.createuser, ".
        "lnkapplsystem.modifyuser, ".
        "lnkapplsystem.editor, ".
        "lnkapplsystem.realeditor, ".
        "lnkapplsystem.cistatus, ".
        "lnkapplsystem.srcsys, ".
        "lnkapplsystem.srcid, ".
        "lnkapplsystem.srcload, ".
        "'10' numrawreltyp ".
     "from lnkapplsystem $datasourcerest1 ".
     "union all ".
     "select ".
        "null id, ".
        "lnkitclustsvcappl.appl, ".
        "system.id system, ".
        "concat('relation by cluster service ',".
               "lnkitclustsvc.itsvcname) comments, ".
        "null additional, ".
        "100.0 fraction, ".
        "min(lnkitclustsvcappl.createdate) createdate, ".
        "lnkitclustsvcappl.modifydate, ".
        "lnkitclustsvcappl.createuser, ".
        "lnkitclustsvcappl.modifyuser, ".
        "lnkitclustsvcappl.editor, ".
        "lnkitclustsvcappl.realeditor, ".
        "'4' cistatus, ".
        "lnkitclustsvcappl.srcsys, ".
        "lnkitclustsvcappl.srcid, ".
        "lnkitclustsvcappl.srcload, ".
        "'20' numrawreltyp ".
     "from lnkitclustsvcappl ".
        "join lnkitclustsvc on lnkitclustsvc.id=lnkitclustsvcappl.itclustsvc ".
        "join itclust on itclust.id=lnkitclustsvc.itclust ".
        "join system on lnkitclustsvc.itclust=system.clusterid ".
        "left join lnkitclustsvcsyspolicy ".
           "on lnkitclustsvc.id=lnkitclustsvcsyspolicy.itclustsvc ".
           " and lnkitclustsvcsyspolicy.system=system.id ".
        $datasourcerest2." ".
        "group by system.id,lnkitclustsvcappl.appl ".
     "union all ".
     "select ".
        "null id, ".
        "swinstance.appl, ".
        "system.id system, ".
        "concat('relation by software instance ',".
               "swinstance.fullname) comments, ".
        "null additional, ".
        "100.0 fraction, ".
        "swinstance.createdate createdate, ".
        "swinstance.modifydate, ".
        "swinstance.createuser, ".
        "swinstance.modifyuser, ".
        "swinstance.editor, ".
        "swinstance.realeditor, ".
        "'4' cistatus, ".
        "swinstance.srcsys, ".
        "swinstance.srcid, ".
        "swinstance.srcload, ".
        "'30' numrawreltyp ".
     "from swinstance ".
        "join system on swinstance.system=system.id ".
        $datasourcerest3." ".
        "group by system.id";

   my $fields="id,appl,system,comments,additional,fraction,createdate,".
              "createuser,modifyuser,modifydate,".
              "editor,realeditor,cistatus,srcsys,srcid,srcload";

   my $from="(select $fields,min(numrawreltyp) numreltyp ".
            "from ($datasource) qqlnkapplsystem ".
            "group by system,appl) qlnkapplsystem ".
            "left outer join appl ".
            "on qlnkapplsystem.appl=appl.id ".
            "left outer join system ".
            "on qlnkapplsystem.system=system.id ".
            "left outer join asset ".
            "on system.asset=asset.id ".
            "left outer join system as vsystem ".
            "on system.vhostsystem=vsystem.id ".
            "left outer join asset as vasset ".
            "on vsystem.asset=vasset.id ".

            "left outer join appl as secsystemappl ".
            "on qlnkapplsystem.appl=secsystemappl.id and ".
               "secsystemappl.cistatus<6 ".
           
            "left outer join lnkcontact secsystemlnkcontact ".
            "on secsystemlnkcontact.parentobj='itil::appl' ".
            "and qlnkapplsystem.appl=secsystemlnkcontact.refid ".
           
            "left outer join costcenter secsystemcostcenter ".
            "on secsystemappl.conumber=secsystemcostcenter.name ".

            "left outer join lnkapplgrpappl ".
            "on lnkapplgrpappl.appl=qlnkapplsystem.appl ".

            "left outer join applgrp ".
            "on applgrp.id=lnkapplgrpappl.applgrp ";

    $from.="left outer join grp as businessteam ".
           "on appl.businessteam=businessteam.grpid";

    #printf STDERR ("datasourcerest1:\n%s\n\n",$datasourcerest1);
    #printf STDERR ("datasourcerest2:\n%s\n\n",$datasourcerest2);
    #printf STDERR ("datasourcerest3:\n%s\n\n",$datasourcerest3);
    #printf STDERR ("FROM:\n%s\n\n",$from);

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my @addflt;
      push(@addflt,{mandatorid=>\@mandators});
      $self->itil::appl::addApplicationSecureFilter(['secsystemappl'],\@addflt);
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{systemid})) ||
       (defined($newrec->{systemid}) && $newrec->{systemid}==0)){
      $self->LastMsg(ERROR,"invalid systemid specified");
      return(undef);
   }
   return(1);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $applid=effVal($oldrec,$newrec,"applid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"systems")){
         $self->LastMsg(ERROR,
               "no rights to modify this system - application relation");
         return(undef);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkapplsystem");
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applid=effVal($oldrec,$newrec,"applid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnApplValid($applid,"systems"));
   return("default") if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc applgrp applinfo systeminfo assetinfo));
}







1;
