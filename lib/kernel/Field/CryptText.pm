package kernel::Field::CryptText;
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
@ISA    = qw(kernel::Field::Text);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{xlsnumformat}='@' if (!defined($self->{xlsnumformat}));

   return($self);
}



sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   if (($FormatAs eq "edit" || $FormatAs eq "workflow")){
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
      my $htmlcode=$self->getSimpleInputField($d,$readonly);
      my $js=<<EOF;
<div style="display:none;visibility:hidden" id='_CryptForm'>
<table border=1 width=100%>

<tr>
<td width="1\%">PassPhrase:</td>
<td><input style='width:100%' type=password id=_in1></td>
</tr>

<tr>
<td width="1\%">Text:</td>
<td><input style='width:100%' type=text id=_in2></td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=button value=' W5XOR Crypt ' onClick="var _in1=window.document.getElementById('_in1');var _in2=window.document.getElementById('_in2');if (_in2.value!='' && _in1.value==''){alert('missing passphrase');}else{hidePopWin(true,0,{_in1:_in1.value,_in2:_in2.value});}">
</td>
</tr>

</table>
</div>
<script lang="JavaScript" type="text/javascript"
   src="../../base/load/crypto_jsbn.js"></script>
<script lang="JavaScript" type="text/javascript"
   src="../../base/load/crypto_jsbn2.js"></script>
<script lang="JavaScript" type="text/javascript"
   src="../../base/load/crypt_xor.js"></script>

<script lang="JavaScript" type="text/javascript">
function endCrypt(data,isBreaked){
   if ((!isBreaked) && data){
      var e=window.document.getElementById("$name");
      if (data._in2=='' && data._in1==''){
            e.value="";
      }
      else{
         var v=W5XOR_encrypt(data._in2,data._in1);
         if (v!=""){
            e.value="W5XOR:"+v;
         }
      }
   }
}
addEvent(window, "load",function(){
   var e=window.document.getElementById("$name");
   addEvent(e,"focus",function(){
      
      parent.parent.showPopWin(function(){
         var e=window.document.getElementById("_CryptForm");
         return(e.innerHTML);
      },500,180,endCrypt);
   });
});


</script>

EOF

      return($js.$htmlcode);
   }
   return($self->SUPER::FormatedDetail($current,$FormatAs));
}






1;
