package base::reflexion_fields;
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
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

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
                name          =>'fullname',
                align         =>'left',
                label         =>'fullqualified fieldname'),

      new kernel::Field::Text(
                name          =>'internalname',
                label         =>'internal name'),

      new kernel::Field::Text(
                name          =>'label',
                label         =>'Label'),

      new kernel::Field::Text(
                name          =>'modname',
                label         =>'Dataobject'),

      new kernel::Field::Text(
                name          =>'modnamelabel',
                label         =>'Dataobject Label'),

      new kernel::Field::Text(
                name          =>'dataobjattr',
                label         =>'Dataobject Attribute'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Fieldtype'),

      new kernel::Field::Text(
                name          =>'referral',
                htmlwidth     =>'300px',
                label         =>'referral'),

      new kernel::Field::Htmlarea(
                name          =>'spec',
                label         =>'Specification'),

   );
   $self->{'data'}=\&getData;



   $self->setDefaultView(qw(fullname  type label referral));
   return($self);
}

sub getData
{
   my $self=shift;
   my $c=$self->Context;
   if (!defined($c->{data})){
      my $instdir=$self->Config->Param("INSTDIR");
      msg(INFO,"recreate data on dir '%s'",$instdir);
      my $pat="$instdir/mod/*/*.pm";
      my @sublist=glob($pat);
      @sublist=map({my $qi=quotemeta($instdir);
                    $_=~s/^$instdir//;
                    $_=~s/\/mod\///; $_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my @data=();
      foreach my $modname (@sublist){
         my $o=getModuleObject($self->Config,$modname);
         if (defined($o)){
            if ($o->can("getFieldObjsByView")){
               my $spec={};
               if ($o->can("LoadSpec")){
                  $spec=$o->LoadSpec(undef);
               }
               foreach my $fo ($o->getFieldObjsByView([qw(ALL)])){
                  my %rec=();
                  $rec{fullname}=$modname."::".$fo->Name;
                  $rec{internalname}=$fo->Name;
                  $rec{label}=$fo->Label;
                  $rec{type}=$fo->Self;
                  $rec{modname}=$modname;
                  $rec{dataobjattr}=$fo->{dataobjattr};
                  $rec{spec}=$spec->{$fo->Name};
                  $rec{modnamelabel}=$o->T($modname,$modname);
                  $rec{referral}="";
                  if (exists($fo->{vjointo})){
                     $rec{referral}=$modname."::".$fo->{vjoinon}->[0].
                                    " -> ".
                                    $fo->{vjointo}."::".$fo->{vjoinon}->[1];
                  }
                  push(@data,\%rec);
               }
            }
         }
      }
      $c->{data}=\@data;
   }
   return($c->{data});
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  
   



1;
