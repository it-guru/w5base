package kernel::DataObj::REST;
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
use kernel::DataObj::Static;

use JSON;
use Text::ParseWords;

use POSIX ":sys_wait_h";

@ISA = qw(kernel::DataObj::Static);

sub new
{
   my $type=shift;

   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}



sub Initialize
{
   my $self=shift;
   $self->{'data'}=\&_DataCollector;
   return(1);
}


sub _DataCollector
{
   my $self=shift;

   return($self->DataCollector(@_));
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;
   msg(ERROR,"default DataCollector called in $self");
   return(undef);
}


sub Filter2RestPath
{
   my $self=shift;
   my $pathTmpl=shift;
   my $filterSet=shift;

   my $restFinalAddr=$pathTmpl;
   my $constParam={};
   my $requesttoken=undef;
   my %qparam;

   # ToDo: check if ODATA filtering - if yes, allow in simplifyFilterSet
   #       flat SCALAR and ARRAY values


   my ($filter,$queryToken)=$self->simplifyFilterSet($filterSet);

   return(undef) if (!defined($filter));

   my @ODATAandLst;
   my $isODATA=0;
   foreach my $fn (keys(%{$filter})){  # paas1 loop
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $const=1;
         if ($filter->{$fn}=~m/[ *?]/){
            $const=0;
         }
         if (ref($fld->{RestFilterType}) eq "CODE"){
            if ($const){  # works only with cons values (normaly IdField)
               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
                                                \%qparam,$constParam,$filter);
            }
         }
         if (ref($fld->{RestFilterType}) eq "ARRAY"){  # idpath default handling
            my $RestFilterPathSep=$fld->{RestFilterPathSep};
            if ($RestFilterPathSep eq ""){
               $RestFilterPathSep='@';
            }
            if ($const){
               my @pathVar=split($RestFilterPathSep,$filter->{$fn});
               for(my $c=0;$c<=$#{$fld->{RestFilterType}};$c++){
                  my $pvar=$fld->{RestFilterType}->[$c];
                   $filter->{$pvar}=$pathVar[$c];
               }
               delete($filter->{$fn});
            }
         }
      }
   }
   foreach my $fn (keys(%{$filter})){
      my $fld=$self->getField($fn);
      if (defined($fld)){
         my $const=1;
         if ($filter->{$fn}=~m/[ *?]/){
            $const=0;
         }
         if ($const){
            $constParam->{$fn}=$filter->{$fn};
            if ($fld->{RestFilterType} eq "CONST2PATH"){
               $restFinalAddr.="/" if (!($restFinalAddr=~m/\/$/));
               $restFinalAddr.=$filter->{$fn};
            }
            if ($restFinalAddr=~m/\{$fn\}/){
               my $constVal=$filter->{$fn};
               $restFinalAddr=~s/\{$fn\}/$constVal/g;
            }
            delete($filter->{$fn});
         }
         if ($fld->{RestFilterType} eq "ODATA"){
            $isODATA++;
            my @ODATAorLst;
            my $fieldname=$fn;
            $fieldname=$fld->{dataobjattr}  if (defined($fld->{dataobjattr}));
            $fieldname=$fld->{ODATA_filter} if (defined($fld->{ODATA_filter}));

            #
            # ToDo - in ODATA filters, SCALAR and ARRAY refs processing
            #

            my $fstr=$filter->{$fn};
            if (ref($fstr) eq "SCALAR"){
               my @l=($$fstr);
               $fstr=\@l;
            }
            if (ref($fstr) eq "ARRAY"){
               foreach my $word (@$fstr){
                  my $exp="'".$word."'";
                  my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                  push(@ODATAorLst,"$v eq $e");
               }
            }


            my $isdate=0;
            if (grep(/kernel::Field::Date/,
                   Class::ISA::self_and_super_path($fld->Self))
                   >0) {
               $isdate=1;
            }
            if ($fld->{ODATA_constFilter}){
               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
               $qparam{$fieldname}=join(",",@words);
            }
            else{
               my @words=parse_line('[,;]{0,1}\s+',0,$fstr);
               for(my $c=0;$c<=$#words;$c++){
                  if ($words[$c] eq "AND" || $words[$c] eq "OR"){
                     $self->LastMsg(ERROR,
                                    "no ODATA support for AND or OR");
                     return(undef);
                  }
                  if ($words[$c]=~m/'/){
                     $self->LastMsg(ERROR,
                                    "no ODATA support for ".
                                    "single quotes");
                     return(undef);
                  }
                  my $val=$words[$c];
                  my $compop="eq";
                  my $compopcount=0;
                  while($val=~m/^[<>]/){
                     if ($compopcount>0){
                        $self->LastMsg(ERROR,"illegal usage of ".
                                             "comparison operator");
                        return(undef);
                     }
                     if ($val=~m/^<=/){
                        $val=~s/^<=//;
                        $compop="le";
                     }
                     elsif ($val=~m/^</){
                        $val=~s/^<//;
                        $compop="lt";
                     }
                     elsif ($val=~m/^>=/){
                        $val=~s/^>=//;
                        $compop="ge";
                     }
                     elsif ($val=~m/^>/){
                        $val=~s/^>//;
                        $compop="gt";
                     }

                     elsif ($val=~m/^</){
                        $val=~s/^<//;
                        $compop="lt";
                     }
                     if ($val=~m/^>/){
                        $val=~s/^>//;
                        $compop="tg";
                     }
                     $compopcount++;
                  }
                  if ($isdate){
                     my $tz=$fld->timezone();
                     my $usertz=$self->UserTimezone();
                     my $d=$self->ExpandTimeExpression(
                            $val,"EDM", $usertz, $tz);
                     return(undef) if (!defined($d));
                     $val=$d;
                  }
                     my $exp="'".$val."'";
                     my ($v,$e)=$self->caseHdl($fld,$fieldname,$exp);
                     push(@ODATAorLst,"$v $compop $e");
               }
            }
            if ($#ODATAorLst!=-1){
               push(@ODATAandLst,join(" or ",@ODATAorLst));
            }
         }
         elsif (ref($fld->{RestFilterType}) eq "CODE"){
            if ($const){  # works only with cons values (normaly IdField)
               my $bk=&{$fld->{RestFilterType}}($fld,$filter->{$fn},
                                                \%qparam,$constParam,$filter);
            }
         }
      }
   }
   if ($isODATA){
      if ($#ODATAandLst!=-1){
         $qparam{'$filter'}=join(" and ",@ODATAandLst);
      }
      if ($self->{_LimitStart}==0 && $self->{_Limit}>0 &&
          !($self->{_UseSoftLimit})){
         $qparam{'$top'}=$self->{_Limit};
         if ($self->{_LimitStart}>0){
            $qparam{'$skip'}=$self->{_LimitStart};
         }
      }
      else{
         $qparam{'$top'}=99999;
      }
   }
   if ($restFinalAddr=~m/\{[^{}]+\}/){

      my @varlist;
      while ($restFinalAddr =~ /\{([^{}]+)\}/g) {
          my $fn=$1;
          my $fld=$self->getField($fn);
          if (defined($fld)){
             $fn=$fld->Label();
          }
          push(@varlist,$fn);
        #  pos($restFinalAddr);
       #   print STDERR "Word is $1, ends at position ", pos $restFinalAddr, "\n";
      }
      if ($#varlist>0){
         $self->LastMsg(ERROR,"missing constant query '%s' parameters",
                              join(",",@varlist));
      }
      else{
         $self->LastMsg(ERROR,"missing constant query '%s' parameter",
                              join(",",@varlist));
      }
      return(undef);
   }

   return($restFinalAddr,$requesttoken,$constParam);
}





1;
