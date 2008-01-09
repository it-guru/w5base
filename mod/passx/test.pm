package passx::test;
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
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main));
}

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           js=>[qw( crypto_dessrc.js 
                                    crypto_desextra.js 
                                    crypto_jsbn.js     
                                    crypto_jsbn2.js     
                                    crypto_prng4.js     
                                    crypto_rng.js     
                                    crypto_rsa.js     
                                    crypto_rsa2.js
                                    asn1.js     )],
                           form=>1,body=>1,
                           title=>$self->T($self->Self()));
   print <<EOF;
<!--
RSA from http://www-cs-students.stanford.edu/~tjw/jsbn/rsa2.html
DES from http://www.tero.co.uk/des/test.php
-->
<table width=100% border=1>

   <tr>
    <td>
     Modulus:
    </td>
    <td>
     <textarea name="n" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     Public exponent (hex, F4=0x10001):
    </td>
    <td>
     <textarea name="e" type="text" rows=2 cols=70>1001</textarea>
    </td>
   </tr>

   <tr>
    <td>
     Private exponent(hex):
    </td>
    <td>
     <textarea name="d" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     P (hex):
    </td>
    <td>
     <textarea name="p" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     Q (hex):
    </td>
    <td>
     <textarea name="q" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     D mod (P-1) (hex):
    </td>
    <td>
     <textarea name="dmp1" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     D mod (Q-1) (hex):
    </td>
    <td>
     <textarea name="dmq1" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

   <tr>
    <td>
     1/Q mod P (hex):
    </td>
    <td>
     <textarea name="coeff" type="text" rows=2 cols=70></textarea>
    </td>
   </tr>

</table>
<input type=button value="Generate" onClick=do_genrsa()>

<script language="JavaScript">
function do_genrsa() {
  var before = new Date();
  var rsa = new RSAKey();
  var dr = document.forms[0];
  rsa.generate(parseInt(256),dr.e.value);
  dr.n.value = linebrk(rsa.n.toString(16),64);
  dr.d.value = linebrk(rsa.d.toString(16),64);
  dr.p.value = linebrk(rsa.p.toString(16),64);
  dr.q.value = linebrk(rsa.q.toString(16),64);
  dr.dmp1.value = linebrk(rsa.dmp1.toString(16),64);
  dr.dmq1.value = linebrk(rsa.dmq1.toString(16),64);
  dr.coeff.value = linebrk(rsa.coeff.toString(16),64);
  var after = new Date();
}



</script>




EOF





   print $self->HtmlBottom(body=>1,form=>1);
}


1;
