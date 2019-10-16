package tsphd::sysasset;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                group         =>'source',
                label         =>'PHD-AssetID',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_assetid"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Asset-Name',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_assetname"),

      new kernel::Field::Text(
                name          =>'typ',
                label         =>'Typ',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_systemtyp"),

      new kernel::Field::Text(
                name          =>'subtyp',
                label         =>'Subtyp',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_systemsubtyp"),

      new kernel::Field::Text(
                name          =>'function',
                label         =>'Function',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_funktion"),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_systemstatus"),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                group         =>'asset',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "modell_bezeichnung"),

      new kernel::Field::Text(
                name          =>'modelprod',
                label         =>'Model Producer',
                group         =>'asset',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "modell_hersteller"),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_os"),

      new kernel::Field::Email(
                name          =>'semail',
                label         =>'SE-EMail',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "se_mail"),

      new kernel::Field::Email(
                name          =>'svmail',
                label         =>'SV-EMail',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "sv_mail"),

      new kernel::Field::Text(
                name          =>'inmassignmentgroup',
                label         =>'Incident-Assignmentgroup',
                dataobjattr   =>"ASSET_SM9_INCIDENTGROUP_Z_B___"),

      new kernel::Field::Text(
                name          =>'chmassignmentgroup',
                label         =>'Change-Assignmentgroup',
                dataobjattr   =>"ASSET_SM9_CHANGEGROUP_Z_B___TI"),

      new kernel::Field::Number(
                name          =>'cpucount',
                group         =>'asset',
                label         =>'CPU-Count (default=1)',
                dataobjattr   =>"'1'"),

      new kernel::Field::Number(
                name          =>'cpuspeed',
                xlswidth      =>10,
                group         =>'asset',
                unit          =>'MHz',
                label         =>'CPU-Speed',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_takt"),

      new kernel::Field::Number(
                name          =>'corecount',
                xlswidth      =>10,
                group         =>'asset',
                label         =>'Core-Count (default=1)',
                dataobjattr   =>"'1'"),

      new kernel::Field::Number(
                name          =>'memory',
                group         =>'asset',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_mb"),

      new kernel::Field::Text(
                name          =>'serialno',
                xlswidth      =>15,
                group         =>'asset',
                label         =>'Serialnumber',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_seriennummer"),

      new kernel::Field::TextDrop(
                name          =>'location',
                group         =>'asset',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                group         =>'asset',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "sto_w5baseid"),

      new kernel::Field::Text(
                name          =>'room',
                group         =>'asset',
                label         =>'Room',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_raum"),
      new kernel::Field::Text(
                name          =>'rack',
                group         =>'asset',
                label         =>'Rack',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_rack"),

      new kernel::Field::Text(
                name          =>'place',
                group         =>'asset',
                label         =>'Place',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_einbauplatz"),

      new kernel::Field::Text(
                name          =>'ifmac',
                group         =>'addr',
                label         =>'Interface MAC',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_mac_adresse_1"),

      new kernel::Field::Text(
                name          =>'ipaddress',
                group         =>'addr',
                label         =>'IP-Address',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_ip_adresse__"),

      new kernel::Field::Text(
                name          =>'dnsname',
                group         =>'addr',
                label         =>'DNS Name (only FQDN useable)',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_dns_name_des_systems__"),

      new kernel::Field::Text(
                name          =>'ipsubnetmask',
                group         =>'addr',
                label         =>'IP-SubNetMask',
                dataobjattr   =>"DARWIN_JOIN_L4_ASSETS_STO_MD_S.".
                                "asset_subnet_mask__"),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>"(to_date('19700101','YYYYMMDD')+(".
                                "IAM_ASSET.SI_ZULETZT_GEAENDERT_AM".
                                "/86400))"),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'source',
                dataobjattr   =>"(to_date('19700101','YYYYMMDD')+(".
                                "IAM_ASSET.SI_ERSTELLT_AM".
                                "/86400))"),

#
#      new kernel::Field::Creator(
#                name          =>'creator',
#                group         =>'source',
#                label         =>'Creator',
#                dataobjattr   =>'isocountry.createuser'),
#
#      new kernel::Field::Owner(
#                name          =>'owner',
#                group         =>'source',
#                label         =>'last Editor',
#                dataobjattr   =>'isocountry.modifyuser'),
#
#      new kernel::Field::Editor(
#                name          =>'editor',
#                group         =>'source',
#                label         =>'Editor Account',
#                dataobjattr   =>'isocountry.editor'),
#
#      new kernel::Field::RealEditor(
#                name          =>'realeditor',
#                group         =>'source',
#                label         =>'real Editor Account',
#                dataobjattr   =>'isocountry.realeditor'),
#
   );
   $self->setDefaultView(qw(name status id typ osrelease ipaddress cdate));
   $self->setWorktable("DARWIN_JOIN_L4_ASSETS_STO_MD_S");
   return($self);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsphd"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default addr asset source));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ".
            "left outer join PHD_PM_JOIN_L1_L_ASSET_IAM_ASS ".
            "on $worktable.\"ASSET_ASSETID\"=".
                "\"PHD_PM_JOIN_L1_L_ASSET_IAM_ASS\".\"ASSET_ASSETID\" ".
            "left outer join IAM_ASSET ".
            "on $worktable.\"ASSET_ASSETID\"=".
                "\"IAM_ASSET\".\"ASSETID\" ";

   return($from);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}




1;
