package base::event::W5ServerMONI;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub W5ServerMONI
{
   my $self=shift;
   my $dataobj=shift;
   my $field=shift;
   my $value=shift;

   if ($dataobj eq ""){
      return({exitcode=>255,exitmsg=>'missing dataobj'});
   }
   if ($field eq ""){
      return({exitcode=>255,exitmsg=>'missing search field'});
   }
   if ($value eq ""){
      return({exitcode=>255,exitmsg=>'missing search value'});
   }

   msg(INFO,"W5ServerMONI doing MONI on $dataobj");
   msg(INFO,"W5ServerMONI search in '$field'");
   msg(INFO,"W5ServerMONI search for value '$value'");

   my $o=getModuleObject($self->Config,$dataobj);

   if (!defined($o)){
      return({exitcode=>1,exitmsg=>"fail to instance dataobj '$dataobj'"});
   }

   my $fld=$o->getField($field);
   if (!defined($fld)){
      return({exitcode=>2,exitmsg=>"no field '$field' in dataobj '$dataobj'"});
   }
   Query->Param('search_'.$field=>$value);

   $o->SetFilter({$field=>\$value});
   $o->SetCurrentView($field);
   my $output=new kernel::Output($o);
   my %param=(ignViewValid=>1);
   if (!($output->setFormat("MONI",%param))){
      return({exitcode=>3,exitmsg=>"can not select MONI FormatAs"});
   }
   my $stdout=$output->WriteToScalar(HttpHeader=>0);
   $stdout=trim($stdout);
   if ($stdout ne "OK"){
      return({exitcode=>100,
              exitmsg=>"unexpected result value in returned field "});
   }
   return({exitcode=>0,exitmsg=>'ok'});
}





1;
