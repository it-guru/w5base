package kernel::Field::FlexBox;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{'AllowInput'}=1 if (!exists($self->{'AllowInput'}));
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   if (($mode eq "edit" || $mode eq "workflow")){
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
      my $input=$self->getSimpleInputField($d,$readonly);
      my $targeturl=$self->{vjointo};
      $targeturl=~s/::/\//;
      $targeturl="../../$targeturl/Result";
      my $addparam="";
      if (defined($self->{vjoineditbase}) &&
          ref($self->{vjoineditbase}) eq "HASH"){
         foreach my $k (keys(%{$self->{vjoineditbase}})){
            $addparam.="search_".$k.": function() { return('".
                        $self->{vjoineditbase}->{$k}."')},";
         }
      }
      my $disp=$self->{vjoindisp};
      $input.=<<EOF;
<script language=JavaScript>
function FlexBox_Init_$name()
{
   \$("#$name").autocomplete("$targeturl", {
      max:50,
      mustMatch: true,
      minChars: 2,
      extraParams: {
          FormatAs: 'AutoFillData',
          CurrentView: '($disp)',
          UseLimit: '40',
          UseLimitStart: '0',
          AllowInput: '$self->{'AllowInput'}',
          $addparam
          search_$disp: function() { return \$("#$name").val()+"*"; }
      }
   });
}
\$(document).ready(function(){
   FlexBox_Init_$name();
});
</script>
EOF
      return($input);
   }
   $d=[$d] if (ref($d) ne "ARRAY");
   if ($mode eq "HtmlDetail"){
      $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
   }
   if ($mode eq "SOAP"){
      $d=[map({quoteSOAP($_)} @{$d})];
   }
   if ($mode eq "HtmlV01"){
      $d=[map({quoteHtml($_)} @{$d})];
   }
   if ($mode ne "XMLV01"){
      my $vjoinconcat=$self->{vjoinconcat};
      $vjoinconcat="; " if (!defined($vjoinconcat));
      $d=join($vjoinconcat,@$d);
   }
   
   if ($mode eq "HtmlV01"){
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
   $d.=" ".$self->{unit} if ($d ne "" && $mode eq "HtmlDetail");
   return($d);
}





1;
