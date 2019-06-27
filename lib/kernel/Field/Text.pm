package kernel::Field::Text;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{multilang}=0      if (!defined($self->{multilang}));
   $self->{xlsnumformat}='@' if (!defined($self->{xlsnumformat}));

   return($self);
}

sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;
   my $ordername=shift;

   if ($self->{multilang} && (($mode=~m/^where/) || $mode eq "select")){
      my $lang=$self->getParent->Lang();
      my $dataobjattr=$self->{dataobjattr};
      my $f="trim(replace(if (instr($dataobjattr,concat(\"[$lang:]\")),if(instr(substr($dataobjattr,instr($dataobjattr,concat(\"[$lang:]\"))+6),\"[\"),substr(substr($dataobjattr,instr($dataobjattr,concat(\"[$lang:]\"))+6),1,instr(substr($dataobjattr,instr($dataobjattr,concat(\"[$lang:]\"))+6),\"[\")-1),substr($dataobjattr,instr($dataobjattr,concat(\"[$lang:]\"))+6)),if(instr($dataobjattr,\"[\"),substr($dataobjattr,1,instr($dataobjattr,\"[\")-1),$dataobjattr)),char(10),\" \"))";
      return($f);
   }
   return($self->SUPER::getBackendName($mode,$db,$ordername));
}




sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   if ($FormatAs ne "edit" && defined($self->{expandvar})){
      $d=~s/\%([a-zA-Z][^\%]+?)\%/&{$self->{expandvar}}($self,$1,$current)/ge;
   }

   if (($FormatAs eq "edit" || $FormatAs eq "workflow") && 
       !defined($self->{vjointo})){
      $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);
      my $readonly=0;
      if ($self->readonly($current)){
         $readonly=1;
      }
      if ($self->frontreadonly($current)){
         $readonly=1;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      return($self->getSimpleInputField($d,$readonly));
   }
   $d=[$d] if (ref($d) ne "ARRAY");
   if ($FormatAs eq "HtmlDetail"){
      $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
   }
   if ($FormatAs eq "OneLine"){
      return($d);
   }
   if ($FormatAs eq "SOAP"){
      $d=[map({quoteSOAP($_)} @{$d})];
   }
   if ($FormatAs eq "HtmlV01"){
      $d=[map({quoteHtml($_)} @{$d})];
   }
   if ($FormatAs ne "XMLV01"){
      if ($self->{preferArray} && ($FormatAs eq "SOAP" ||
                                   $FormatAs eq "JSON")){
         return($d); 
      }
      my $vjoinconcat=$self->{vjoinconcat};
      $vjoinconcat="; " if (!defined($vjoinconcat));
      if (($FormatAs eq "HtmlDetail" ||
           $FormatAs eq "edit") && ($vjoinconcat=~m/\n/)){
         $vjoinconcat=~s/\n/<br>\n/g;
      }
      if (defined($self->{sortvalue})){
         {  # make it unique, if it should be sorted
            my %u=();
            map({$u{$_}++} @$d);
            @$d=keys(%u);
         }
         if (lc($self->{sortvalue}) eq "asc"){
            $d=join($vjoinconcat,sort(@$d));
         }
         elsif (lc($self->{sortvalue}) eq "none"){
            $d=join($vjoinconcat,@$d);
         }
         else{
            $d=join($vjoinconcat,reverse(sort(@$d)));
         }
      }
      else{
         $d=join($vjoinconcat,@$d);
      }
   }
   
   if ($FormatAs eq "HtmlV01"){
      $d=~s/\n/<br>\n/g;
      if ($self->{htmlnowrap}){
         $d=~s/[ \t]/&nbsp;/g;
         ##############################
         #$d=~s/-/&minus;/g;
         # see hypher explaination in 
         # lib/kernel/Output/HtmlV01.pm
         $d="<nobr>".$d."</nobr>";
      }
   }
   $d.=" ".$self->{unit} if ($d ne "" && $FormatAs eq "HtmlDetail");
   if (exists($self->{background})){
      $d=$self->BackgroundColorHandling($FormatAs,$current,$d);
   }
   return($d);
}





1;
