package base::location;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   sub AddressBuild{
      my $self=shift;
      my $current=shift;
      my $a="";
      $a.=" ".$current->{country};
      $a.=" ".$current->{zipcode};
      $a.=" ".$current->{location};
      $a.=" ".$current->{address1};
      return($a);
   }

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'location.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                label         =>'Location name',
                dataobjattr   =>'location.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'location.cistatus'),

      new kernel::Field::Text(
                name          =>'label',
                label         =>'Location label',
                dataobjattr   =>'location.label'),

      new kernel::Field::Text(
                name          =>'address1',
                htmlwidth     =>'200px',
                label         =>'Street address',
                dataobjattr   =>'location.address1'),

      #
      # country codes based on ISO-3166-Alpha2
      # http://de.wikipedia.org/wiki/ISO-3166-1-Kodierliste
      #
      new kernel::Field::Select(
                name          =>'country', 
                htmleditwidth =>'50px',
                value         =>['DE','US','GB','UK',
                                 'FR','IT','DK','CZ',
                                 'TR','ES','CN','RC',
                                 'BE','MY','SK','JP',
                                 'CH','AT','SG','PT'],
                label         =>'Country',
                dataobjattr   =>'location.country'),

      new kernel::Field::Text(
                name          =>'zipcode',
                label         =>'ZIP Code',
                dataobjattr   =>'location.zipcode'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                dataobjattr   =>'location.location'),

      new kernel::Field::TextDrop(
                name          =>'response',
                label         =>'Location responsible',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['responseid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'responseid',
                dataobjattr   =>'location.response'),

      new kernel::Field::TextDrop(
                name          =>'response2',
                label         =>'Deputy location responsible',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['response2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'response2id',
                dataobjattr   =>'location.response2'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'base::location'}],
                vjoininhash   =>['mdate','targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::Text(
                name          =>'roomexpr',
                group         =>'control',
                label         =>'Room Expression',
                dataobjattr   =>'location.roomexpr'),

      new kernel::Field::GoogleMap(
                name          =>'googlemap',
                group         =>'map',
                htmlwidth     =>'500px',
                label         =>'GoogleMap',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location'],
                marker        =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $m="";
                   $m=$current->{label};
                   $m="<b>$m</b>" if ($m ne "");
                   $m.="<br>" if ($m ne "");
                   if ($current->{address1} ne ""){
                      $m.="<br>".$current->{address1};
                   }
                   my $o=$current->{country};
                   if ($current->{zipcode} ne ""){
                      $o.="-" if ($o ne "");
                      $o.=$current->{zipcode};
                   }
                   if ($current->{location} ne ""){
                      $o.=" " if ($o ne "");
                      $o.=$current->{location};
                   }
                   if ($o ne ""){
                      $m.="<br>$o";
                   }
                   return($m);
                },
                address=>\&AddressBuild),

      new kernel::Field::GoogleAddrChk(
                name          =>'googlechk',
                group         =>'map',
                htmldetail    =>0,
                htmlwidth     =>'200px',
                label         =>'Google Address Check',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location'],
                address=>\&AddressBuild),

      new kernel::Field::Text(
                name          =>'gpslongitude',
                group         =>'gps',
                label         =>'longitude',
                dataobjattr   =>'location.gpslongitude'),

      new kernel::Field::Text(
                name          =>'gpslatitude',
                group         =>'gps',
                label         =>'latitude',
                dataobjattr   =>'location.gpslatitude'),

      new kernel::Field::Text(
                name          =>'refcode1',
                group         =>'control',
                label         =>'Reference Code1',
                dataobjattr   =>'location.refcode1'),

      new kernel::Field::Text(
                name          =>'refcode2',
                group         =>'control',
                label         =>'Reference Code2',
                dataobjattr   =>'location.refcode2'),

      new kernel::Field::Text(
                name          =>'refcode3',
                group         =>'control',
                label         =>'Reference Code3',
                dataobjattr   =>'location.refcode3'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'location.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'location.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'location.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'location.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'location.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'location.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'location.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'location.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'location.realeditor'),


   );
   $self->setDefaultView(qw(location address1 name cistatus));
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","contacts","map","gps");
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("location");
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/location.jpg?".$cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $self->Normalize($newrec);
   my $country=trim(effVal($oldrec,$newrec,"country"));
   my $location=trim(effVal($oldrec,$newrec,"location"));
   my $label=trim(effVal($oldrec,$newrec,"label"));
   my $address1=trim(effVal($oldrec,$newrec,"address1"));
   my $zipcode=trim(effVal($oldrec,$newrec,"zipcode"));
   if ($zipcode ne "" && !($zipcode=~m/^\d{4,6}$/)){
      $self->LastMsg(ERROR,"invalid zipcode");
      return(0);
   }
   if ($location eq ""){
      $self->LastMsg(ERROR,"invalid location");
      return(0);
   }

   my $name="";
   $name.=($name ne "" && $country  ne "" ? "." : "").$country;
   $name.=($name ne "" && $location ne "" ? "." : "").$location;
   $name.=($name ne "" && $address1 ne "" ? "." : "").$address1;
   $name.=($name ne "" && $label    ne "" ? "." : "").$label;
   $name=~s/ü/ue/g;
   $name=~s/ö/oe/g;
   $name=~s/ä/ae/g;
   $name=~s/Ü/Ue/g;
   $name=~s/Ö/Oe/g;
   $name=~s/Ä/Ae/g;
   $name=~s/ß/ss/g;
   $name=~s/\s/_/g;
   $newrec->{'name'}=$name;

   return(1);
}

sub Normalize
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{address1}=~m/ALTE POTSDAMER.*7/){
      $rec->{address1}="Alte Potsdamer Straße 7";
   }
   if ($rec->{address1}=~m/Karl-Marx-Straße109-113/i){
      $rec->{address1}="Karl-Marx-Straße 109-113";
   }
   if (defined($rec->{address1})){
      $rec->{address1}=~s/Memmelsdorferstr.*e/Memmelsdorfer Straße/g;
      $rec->{address1}=~s/([S|s])tr\./$1traße/g;
      $rec->{address1}=~s/([S|s])trasse/$1traße/g;
      $rec->{address1}=~s/([S|s])ttrasse/$1traße/g;
      $rec->{address1}=~s/([S|s])ttraße/$1traße/g;
      $rec->{address1}=~s/(\d)\s([a-z])$/$1$2/i;
      $rec->{address1}=trim($rec->{address1});
   }
   #if (!defined($rec->{country}) || $rec->{country} eq ""){
   #   $rec->{country}="DE";
   #}
   if (defined($rec->{label})){
      $rec->{label}="T-Systems SCZ Mitte"   if ($rec->{label}=~m/SCZ Mitte/);
      $rec->{label}="T-Systems SCZ Ost"    if ($rec->{label}=~m/Magdeburg SCZ/);
      $rec->{label}="T-Systems SCZ Nord"    if ($rec->{label}=~m/SCZ Nord/);
      $rec->{label}="T-Systems SCZ Südwest" if ($rec->{label}=~m/SCZ Südwest/);
      $rec->{label}="T-Systems SCZ Südwest" if ($rec->{label}=~m/SCZ Suedwest/);
      $rec->{label}="T-Systems SCZ Süd"     if ($rec->{label}=~m/SCZ Süd/);
      $rec->{label}="T-Systems SCZ Süd"     if ($rec->{label}=~m/SCZ Sued/);
      $rec->{label}="T-Systems SCZ West"    if ($rec->{label}=~m/SCZ West/);
      $rec->{label}="T-Punkt"               if ($rec->{label}=~m/T-Punkt/);
      $rec->{label}=""     if ($rec->{label}=~m/Bamberg Memmelsdorfer/);
   }
   if ($rec->{location}=~m/^berlin$/i){
      $rec->{location}="Berlin";
   }
   if ($rec->{address1}=~m/Gutenberg.*$/ && $rec->{location} eq "Bamberg"){
      $rec->{label}="T-Systems SCZ Süd";
   }
   if ($rec->{address1}=~m/Hauptwach.*$/ && $rec->{location} eq "Bamberg"){
      $rec->{label}="T-Punkt";
   }
   if ($rec->{address1}=~m/Salamander.*$/ && $rec->{location} eq "Göppingen"){
      $rec->{label}="T-Systems SCZ Südwest";
   }
   if ($rec->{address1}=~m/Fichtenhain.*10.*/ && $rec->{location} eq "Krefeld"){
      $rec->{address1}="Europapark Fichtenhain B 10";
      $rec->{label}="T-Systems SCZ West";
   }
   $rec->{country}=trim($rec->{country});
   $rec->{label}=trim($rec->{label});
}

sub getLocationByHash
{
   my $self=shift;
   my %req=@_;
   #printf STDERR ("Request0=%s\n",Dumper(\%req));
   $self->Normalize(\%req);
   #printf STDERR ("Request1=%s\n",Dumper(\%req));

   return(undef) if ($req{country}=~m/^\s*$/);
   return(undef) if ($req{location}=~m/^\s*$/);
#   if (defined($req{srcid}) && defined($req{srcsys})){
#      $self->ResetFilter();
#      $self->SetFilter({'srcsys'=>\$req{srcsys},srcid=>\$req{srcid}});
#      $self->SetCurrentView(qw(ALL));
#      $self->ForeachFilteredRecord(sub{
#                         $self->ValidatedUpdateRecord($_,
#                          {srcid=>undef,srcsys=>undef},{id=>\$_->{id}});
#                      });
#
#
#   }

   my @id=$self->ValidatedInsertOrUpdateRecord(\%req,
                                               {label=>\$req{label},
                                                country=>\$req{country},
                                                address1=>\$req{address1},
                                                location=>\$req{location}});
   return($id[0]);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","contacts","gps") if ($self->IsMemberOf("admin"));
   return(undef);
}


1;
