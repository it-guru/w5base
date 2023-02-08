package base::isocountry;
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

# 
#  based on ISO 3166 country codes  + SSG-FI extensions (II,EU und EUROPE)
# 

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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'isocountry.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                label         =>'full country name',
                dataobjattr   =>'isocountry.fullname'),

      new kernel::Field::Text(
                name          =>'token',
                label         =>'Country token',
                dataobjattr   =>'isocountry.token'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Countryname',
                dataobjattr   =>'isocountry.name'),

      new kernel::Field::Text(
                name          =>'zipcodeexp',
                label         =>'ZIP Code Expression',
                dataobjattr   =>'isocountry.zipcodeexp'),

      new kernel::Field::Text(
                name          =>'dialprefix',
                maxlength     =>'5',
                htmleditwidth =>'40',
                label         =>'internation calling prefix',
                dataobjattr   =>'isocountry.callingprefix'),

      new kernel::Field::Text(
                name          =>'intdialprefix',
                maxlength     =>'5',
                htmleditwidth =>'40',
                label         =>'internation dialing prefix (IDD)',
                dataobjattr   =>'isocountry.intdialprefix'),

      new kernel::Field::Boolean(
                name          =>'is_eu',
                label         =>'member of european union',
                dataobjattr   =>'isocountry.is_eu'),

      new kernel::Field::Boolean(
                name          =>'is_europe',
                label         =>'land of europe',
                dataobjattr   =>'isocountry.is_europe'),

      new kernel::Field::Boolean(
                name          =>'is_asia',
                label         =>'land of asia',
                dataobjattr   =>'isocountry.is_asia'),

      new kernel::Field::Boolean(
                name          =>'is_australia',
                label         =>'land of australia',
                dataobjattr   =>'isocountry.is_australia'),

      new kernel::Field::Boolean(
                name          =>'is_namerica',
                label         =>'land of north america',
                dataobjattr   =>'isocountry.is_namerica'),

      new kernel::Field::Boolean(
                name          =>'is_samerica',
                label         =>'land of south america',
                dataobjattr   =>'isocountry.is_samerica'),

      new kernel::Field::Boolean(
                name          =>'is_africa',
                label         =>'land of africa',
                dataobjattr   =>'isocountry.is_africa'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'isocountry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'isocountry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'isocountry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'isocountry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'isocountry.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'isocountry.realeditor'),

   );
   $self->setDefaultView(qw(token fullname dialprefix  intdialprefix
                            cistatus cdate mdate));
   $self->setWorktable("isocountry");
   return($self);
}

sub getCountryEntryByToken
{
   my $self=shift;
   my $allowGlobs=shift;  # EU, II, EUROPE
   my @token=@_;
   my @l;

   if ($allowGlobs){
      foreach my $ot (@token){
         foreach my $t (split(/[,;\s]\s*/,$ot)){
            $self->ResetFilter();
            if (uc($t) eq "EU"){        # EU
               $self->SetFilter({is_eu=>1});
            }
            elsif (uc($t) eq "II"){     # International
            }
            elsif (uc($t) eq "EUROPE"){ # Europa
               $self->SetFilter({is_europe=>1});
            }
            else{
               $self->SetFilter({token=>\$t});
            }
            my @subl=$self->getHashList(qw(token fullname is_eu is_europe));
            if ($#subl==-1){
               return();
            }
            push(@l,@subl);
         }
      }
   }
   else{
      $self->ResetFilter();
      $self->SetFilter({token=>\@token});
      @l=$self->getHashList(qw(token fullname is_eu is_europe));
   }

   return() if ($#l==-1);
   return(@l);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $token=trim(effVal($oldrec,$newrec,"token"));
   if (length($token)!=2 || ($token=~m/\s/)){
      $self->LastMsg(ERROR,"invalid token");
      return(0);
   }
   if ($name eq "" || ($name=~m/[^-a-z0-9\._ \(\)]/i)){
      $self->LastMsg(ERROR,"invalid country name");
      return(0);
   }
   my $dialprefix=effVal($oldrec,$newrec,"dialprefix");
   my $mdialprefix=$dialprefix;
   $mdialprefix=~s/[^0-9]//g;
   $mdialprefix="+".$mdialprefix;
   if ($dialprefix ne $mdialprefix){
      $newrec->{dialprefix}=$mdialprefix;
   }

   my $intdialprefix=effVal($oldrec,$newrec,"intdialprefix");
   my $mintdialprefix=$intdialprefix;
   $mintdialprefix=~s/[^0-9]//g;
   if ($intdialprefix ne $mintdialprefix){
      $newrec->{intdialprefix}=$mintdialprefix;
   }



   if (exists($newrec->{token}) ||
       exists($newrec->{name})  ){
      $newrec->{token}=uc($newrec->{token});
      my $fname=uc($token);
      $fname.=($fname ne "" && $name ne "" ? "-" : "").$name;
      $newrec->{'fullname'}=$fname;
      $newrec->{'fullname'}=~s/[\(\)]/ /g;
      $newrec->{'fullname'}=~s/\s/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
      $newrec->{'fullname'}=~s/__/_/g;
   }

   my $dp=effVal($oldrec,$newrec,"dialprefix");
   if ($dp ne ""){
      my $dpmod=$dp;
      $dpmod=~s/[^0-9]//g;
      if ($dpmod ne ""){
         $dpmod="+".$dpmod;
      }
      if ($dp ne $dpmod){
         $newrec->{dialprefix}=$dpmod;
      }
   }




   return(1);
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}





1;
