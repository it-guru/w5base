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
                htmldetail    =>'NotEmpty',
                label         =>'referral'),

      new kernel::Field::Text(
                name          =>'vjointo',
                htmlwidth     =>'300px',
                htmldetail    =>'0',
                label         =>'vjointo'),

      new kernel::Field::Text(
                name          =>'vjoinonfrom',
                htmlwidth     =>'300px',
                htmldetail    =>'0',
                label         =>'vjoinonfrom'),

      new kernel::Field::Text(
                name          =>'vjoinonto',
                htmlwidth     =>'300px',
                htmldetail    =>'0',
                label         =>'vjoinonto'),


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
      my $cachedir=$self->Config->Param("DataObjCacheStore");
      $cachedir.="/" if (!($cachedir=~m/\/$/));
      my $DataObjCacheFile=$cachedir.$self->Self.".cache.db.tmp";
      my $pat="$instdir/mod/*/*.pm";
      my @sublist=glob($pat);
      my $maxmtime=0;
      @sublist=map({my $qi=quotemeta($instdir);
                    my $mtime = (stat($_))[9];
                    $maxmtime=$mtime if ($maxmtime<$mtime);
                    $_=~s/^$instdir//;
                    $_=~s/\/mod\///; $_=~s/\.pm$//;
                    $_=~s/\//::/g;
                    $_;
                   } @sublist);
      my @data=();
      if ((stat($DataObjCacheFile))[9]>$maxmtime){
         if (open(F,"<",$DataObjCacheFile)){
            my $VAR1;
            eval(join("",<F>));
            if (defined($VAR1)){
               $c->{data}=$VAR1;
            }
            else{
               msg(ERROR,"read from cache $DataObjCacheFile failed: $@");
            }
            close(F);
         }
      }
      if (!defined($c->{data})){
         msg(INFO,"recreate data on dir '%s'",$instdir);
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
                     $rec{vjointo}=$fo->getNearestVjoinTarget();
                     if (ref($rec{vjointo}) eq "SCALAR"){
                        $rec{vjointo}=${$rec{vjointo}};
                     }
                     $rec{vjoinonfrom}="";
                     $rec{vjoinonto}="";
                     $rec{referral}="";
                     if ($rec{vjointo} ne ""){
                        if (ref($fo->{vjoinon}) eq "ARRAY"){
                           $rec{vjoinonfrom}=$fo->{vjoinon}->[0];
                           $rec{vjoinonto}=$fo->{vjoinon}->[1];
                        }
                        else{
                           $rec{vjoinonfrom}="COMPLEX";
                           $rec{vjoinonto}="COMPLEX";
                        }
                        $rec{referral}=$modname."::".$rec{vjoinonfrom}.
                                       " -> ".
                                       $rec{vjointo}."::".$rec{vjoinonto};
                     }
                     push(@data,\%rec);
                  }
               }
            }
         }
         if (open(F,">",$DataObjCacheFile)){
            print F (Dumper(\@data));
            close(F);
         }
         else{
            msg(ERROR,"fail to write cache file $DataObjCacheFile");
         }
         $c->{data}=\@data;
      }
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
