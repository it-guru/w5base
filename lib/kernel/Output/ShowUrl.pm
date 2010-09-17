package kernel::Output::ShowUrl;
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
use base::load;
use kernel::Formater;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
 
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_asctab.gif");
}
sub Label
{
   return("Output to one line");
}
sub Description
{
   return("Writes in one ASCII line.");
}

sub MimeType
{
   return("text/html");
}

sub getEmpty
{
   my $self=shift;
   my %param=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   return($d);
}

sub isRecordHandler
{
   return(0);
}



sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=ISO-8895-1\n\n";
   return($d);
}

sub quoteData
{
   my $d=shift;

   $d=~s/;/\\;/g;
   $d=~s/\r\n/\\n/g;
   $d=~s/\n/\\n/g;
   return($d); 
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my ($d,$p);
   my $url=$ENV{SCRIPT_URI};
   my $q=Query->MultiVars(); 

   foreach my $v (keys(%$q)){
      delete($q->{$v}) if (!defined($q->{$v}) || $q->{$v} eq "");
      delete($q->{$v}) if ($v eq "UseLimit" || $v eq "UseLimitStart");
   }
   delete($q->{CurrentView}) if ($q->{CurrentView} eq "default");
   $q->{FormatAs}=~s/^.*;//;
   foreach my $v (sort(keys(%$q))){
      my $d=$q->{$v};
      $d=[$q->{$v}] if (ref($q->{$v}) ne "ARRAY");
      foreach my $val (@{$d}){
         $p.=sprintf("%20s = %s\n",$v,$val);
      }
   }
   my $bmlink=$ENV{SCRIPT_URI};
   $bmlink=~s/^.*\/auth\//..\/..\//;
   
   
   my $query=kernel::cgi::Hash2QueryString($q); 
   $bmlink.="?".$query if ($query ne "");
   $url.="?".$query if ($query ne "");
   my $bmname=Query->Param("bmname");
  
   $d=<<EOF;
<link rel=stylesheet  href="../../base/load/default.css"></link>
<link rel=stylesheet  href="../../base/load/frames.css"></link>
<form method=POST target=bmcreate action="../../base/userbookmark/WebBookmarkCreate"><center><div class=winframe style="margin-top:5px;width:555px">
<div class=winframehead>Bookmark create: (Beta - Modul!)
</div>
<table border=0 width=100%>
<tr>
<td width=1% nowrap>Bookmark name:</td>
<td><input style="width:100%" type=input name=bmname value="$bmname"></td>
<td width=1%><input type=submit name=bmcreate value=" create ">
<input type=hidden value="$bmlink" name=bmlink>
<input type=hidden value="_self" name=bmtarget>
</td>
</tr>
<tr>
<td colspan=3>
<iframe src="../../base/userbookmark/WebBookmarkCreate"
        style="width:97%;height:40px;padding:5px" name=bmcreate></iframe></td>
</tr>
</table>
</div>
<br>
<br>
</form>

<div class=winframe style="width:555px">
<div class=winframehead>Developer Informations:
</div>
<div class=winframebody>
This Module allows developers to view direct access URL's to access
data structures in W5Base.<br>
<div class=winframe style="width:500px;overflow:auto;margin:20px;padding:5px">
GET URL:<br>
$url
</div>
<div class=winframe style="width:500px;overflow:auto;margin:20px;padding:5px">
URI:<br>
$ENV{SCRIPT_URI}
<xmp>$p</xmp></div></div></div>
EOF

   return($d);
}

1;
