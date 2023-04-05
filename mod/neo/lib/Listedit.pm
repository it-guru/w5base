package neo::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use tardis::lib::Listedit;
use Text::ParseWords;
use Digest::MD5 qw(md5_base64);
@ISA=qw(tardis::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}



sub decodeFilter2Query4neo
{
   my $self=shift;
   my $dbclass=shift;
   my $idfield=shift;
   my $map=shift;
   my $filter=shift;
   my $const={}; # for constances witch are derevided from query
   my $requesttoken="SEARCH.".time();
   my $query="";
   my %qparam;

   if (ref($filter) eq "HASH"){
      my @andLst=();
      foreach my $filtername (keys(%{$filter})){
         my $f=$filter->{$filtername}->[0];
        
         foreach my $fn (keys(%{$f})){
            my $fld=$self->getField($fn);
            if (defined($fld)){
               if ($fn eq $idfield){  # Id Field handling
                  my $id; 
                  if (ref($f->{$fn}) eq "ARRAY" &&
                      $#{$f->{$fn}}==0){
                     $id=$f->{$fn}->[0];
                  }
                  elsif (ref($f->{$fn}) eq "SCALAR"){
                     $id=${$f->{$fn}};
                  }
                  else{
                     if ($f->{$fn}=~m/^\s*".+"\s*$/){
                        $f->{$fn}=~s/^\s*"//;
                        $f->{$fn}=~s/"\s*$//;
                     }
                     if (!($f->{$fn}=~m/[ *?]/)){
                        $id=$f->{$fn};
                     }
                  }
                  $const->{$fn}=$id;
                  if ($dbclass=~m/\{$idfield\}/){
                     $dbclass=~s/\{$idfield\}/$id/g;
                  }
                  else{
                     $dbclass=$dbclass."/".$id;
                  }
                  $requesttoken=$dbclass;
               }
               else{   # "normal" field handling
                  my $fieldname=$fn;
                  if (exists($fld->{dataobjattr})){
                     $fieldname=$fld->{dataobjattr};
                  }
                  my $fstr=$f->{$fn};
                  if (ref($fstr) eq "SCALAR"){
                     my @l=($$fstr);
                     $fstr=\@l;
                  }
                  if (ref($fstr) eq "ARRAY"){
                     $fstr=join(",",@$fstr);
                  }
                  $qparam{$fieldname}=$fstr;
                  $const->{$fieldname}=$fstr;
               }
            }
         }
      }
   }
   else{
      printf STDERR ("invalid Filterset in $self:%s\n",Dumper($filter));
      $self->LastMsg(ERROR,"invalid filterset for NEO query");
      return(undef);
   }

   if (ref($map)){
      foreach my $k (keys(%$map)){
         if (!exists($const->{$k})){
            my @vl;
            foreach my $v (@{$map->{$k}}){
               push(@vl,$qparam{$v});
            }
            $const->{$k}=join('@',@vl);
         }
         else{
            delete($qparam{$k});
            my @l=split(/\@/,$const->{$k});
            for(my $c=0;$c<=$#{$map->{$k}};$c++){
               $qparam{$map->{$k}->[$c]}=$l[$c];
               $const->{$map->{$k}->[$c]}=$l[$c];
            }
         }
      }
   }


   my $qstr=kernel::cgi::Hash2QueryString(%qparam);
   if ($qstr ne ""){
      $dbclass.="?".$qstr;
      $requesttoken=$dbclass;
   }
   
   return($dbclass,$requesttoken,$const);
}



sub onFailNeoHandler
{
   my $self=shift;
   my $code=shift;
   my $statusline=shift;
   my $content=shift;
   my $reqtrace=shift;


   my $jsoncontent;

   if ($content=~m/^{/){
      eval('use JSON;my $j=new JSON;$jsoncontent=$j->decode($content)');
   }

   if ($code eq "400" || $code eq "500"){
      if (defined($jsoncontent)){
         $self->LastMsg(ERROR,"NEO call result: ".$jsoncontent->{errorMessage});
      }
      else{
         $self->LastMsg(ERROR,"NEO call result unspecific error");
      }
      return(undef,$code);
   }
   msg(ERROR,$reqtrace);
   $self->LastMsg(ERROR,"unexpected NEO response");
   return(undef);




}




1;
