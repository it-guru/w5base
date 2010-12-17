package kernel::AutoFormater;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::XLSReport;

#
# Templates must be stored in webfs:/Template/CLASS/MODULE/APP/FILE.EXT
#

# URL http://HOST/CONIFG/auth/MODULE/APP/AutoFormat/ID/CLASS/FILE.EXT

# is ViewValid syntax : AutoFormat AutoFormat.CLASS AutoFormat.CLASS.FILE

sub AutoFormat
{
   my ($self)=@_;
   my ($func,$p)=$self->extractFunctionPath();

   if (my ($id,$class,$file,$ext)=$p
       =~m#^/AutoFormat/([^/]+)/([^/]+)/([^\.]+)\.([a-z]{2,4})$#){
      $class=~s/[^a-z0-9]//gi;
      $ext=~s/[^a-z0-9]//gi;
      $file=~s/[^a-z0-9]//gi;
      $id=~s/[^a-z0-9]//gi;
      my $idobj=$self->IdField();
      if (!defined($idobj)){
         return($self->AutoFormatError("ERROR: can not identify id field"));
      }
      my $idname=$idobj->Name();
      $self->ResetFilter();
      $self->SetFilter({$idname=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (!defined($rec)){
         return($self->AutoFormatError("ERROR: record not found by id='$id'"));
      }
      my @viewgroups=$self->isViewValid($rec);
      if (!in_array(\@viewgroups,['ALL','AutoFormat','AutoFormat.'.$class,
                                  'AutoFormat.'.$class.'.'.$file])){
         return($self->AutoFormatError("ERROR: no access to AutoFormat file"));
      }
      if ($ext ne "xls"){
         return($self->AutoFormatError(
                "ERROR: AutoFormater only supports xls files"));
      }
      my $out;
      if ($ext eq "xls"){
         $out=new kernel::XLSReport($self,"$file.$ext");
         $out->initWorkbook();
      }

      if ($self->ProcessAutoFormat($class,$file,$ext,$out)){
         return;
      }
      my $msg="no ProcessAutoFormat implemented at current object";
      return($self->AutoFormatError(
             "AutoFormat: ".$msg."<br>".
             "CLASS=$class ID=$id FILE=$file EXT=$ext<br>".
             "Template='$tfile'<br>"));
   }
   return($self->AutoFormatError("AutoFormat '$p' not implemented"));
}


sub ProcessAutoFormat
{
   my $self=shift;
   my ($class,$file,$ext,$out)=@_;

   if ($class eq "Interview"){

   }
   return(0);
}



sub AutoFormatError
{
   my $self=shift;
   my $msg=shift;

   print $self->HttpHeader("text/html");
   print "<h1>".$msg."</h1>";
   return(0);
}


######################################################################

1;
