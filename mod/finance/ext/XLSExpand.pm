package finance::ext::XLSExpand;
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
use kernel::XLSExpand;
use Data::Dumper;
@ISA=qw(kernel::XLSExpand);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub GetKeyCriterion
{
   my $self=shift;
   my $d={in=>{'finance::costcenter::name'=>{label=>'Kostenknoten'},
              },
          out=>{
                'finance::costcenter::name'     =>{label=>'Finanz/CRM: Kontierungsobjekt: CO-Nummber/PSP'},
                'finance::costcenter::fullname' =>{label=>'Finanz/CRM: Kontierungsobjekt: Bezeichnung'},
                'finance::costcenter::delmgr'   =>{label=>'Finanz/CRM: Kontierungsobjekt: SDM'},
                'finance::costcenter::itsem'   =>{label=>'Finanz/CRM: Kontierungsobjekt: IT-SeM'}
               },
         };
   return($d);
}

sub ProcessLine
{
   my $self=shift;
   my $line=shift;
   my $in=shift;
   my $out=shift;
   my $loopcount=shift;

   if (defined($in->{'finance::costcenter::name'}) &&
       !defined($in->{'finance::costcenter::id'})){
      my $o=$self->getParent->getPersistentModuleObject('finance::costcenter');
      if (ref($in->{'finance::costcenter::name'}) eq "HASH"){
         $o->SetFilter({name=>[keys(%{$in->{'finance::costcenter::name'}})],
                        cistatusid=>'4'});
      }
      else{
         $o->SetFilter({name=>\$in->{'finance::costcenter::name'},
                        cistatusid=>'4'});
      }
      my $c=0;
      foreach my $orec ($o->getHashList(qw(id name fullname))){
         $in->{'finance::costcenter::id'}->{$orec->{id}}++;
         $c++;
      }
      return(0) if ($c); # input data has been enriched
   }
 
   # output
   foreach my $appsekvar (qw(name delmgr itsem fullname)){
      if (exists($out->{'finance::costcenter::'.$appsekvar})){
         if (!defined($in->{'finance::costcenter::id'}) &&
             defined($out->{'finance::costcenter::name'})){
            my $o=$self->getParent->getPersistentModuleObject(
                  'finance::costcenter');
            if (ref($out->{'finance::costcenter::name'}) eq "HASH"){
               $o->SetFilter({
                    name=>[keys(%{$out->{'finance::costcenter::name'}})],
                    cistatusid=>'4'});
            }
            else{
               $o->SetFilter({
                    name=>\$out->{'finance::costcenter::name'},
                    cistatusid=>'4'});
            }
            foreach my $orec ($o->getHashList(qw(id))){
               $in->{'finance::costcenter::id'}->{$orec->{id}}++;
            }
         }
         if (defined($in->{'finance::costcenter::id'})){
            my $o=$self->getParent->getPersistentModuleObject(
                                                       'finance::costcenter');
            my $id=[keys(%{$in->{'finance::costcenter::id'}})];
            $o->SetFilter({id=>$id});
            foreach my $rec ($o->getHashList($appsekvar)){
               if (defined($rec->{$appsekvar})){
                  if (ref($rec->{$appsekvar}) ne "ARRAY"){
                     $rec->{$appsekvar}=[$rec->{$appsekvar}]; 
                  }
                  foreach my $v (@{$rec->{$appsekvar}}){
                      if ($v ne ""){
                         $out->{'finance::costcenter::'.$appsekvar}->{$v}++;
                      }
                  }
               } 
            }
         }
      }
   }
   return(1);
}





1;
