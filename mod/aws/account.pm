package aws::account;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use JSON;
@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(     
            name               =>'id',
            searchable         =>1,
            label              =>'AWS-AccountID'),

      new kernel::Field::Text(
            name               =>'arn',
            label              =>'ARN'),

      new kernel::Field::Text(
            name               =>'email',
            label              =>'E-Mail'),

      new kernel::Field::Text(  
            name               =>'name',
            label              =>'Account-Name'),

      new kernel::Field::Text(
            name               =>'status',
            label              =>'Status'),

      new kernel::Field::SubList(
            name               =>'systems',
            label              =>'Systems',
            vjointo            =>\'aws::system',
            vjoinon            =>['id'=>'accountid'],
            vjoindisp          =>['id','ipaddress']),

      new kernel::Field::Container(
            name               =>'tags',
            label              =>'Tags',
            uivisible          =>1,
            htmlDetail         =>1 )
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name email status));
   return($self);
}

sub DataCollector
{
   my $self=shift;

   my $dbclass="accounts";

   return($self->CollectREST(
      dbname=>'aws',
      cachetime=>600,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         return($dataobjurl);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         return(['x-api-key'=>$apikey]);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{accounts}) && 
             ref($data->{accounts}) eq "HASH"){
            return([map({
                      #######################################################
                      # remap tags field to Container Strukture
                      my $tags=$_->{tags};
                      my %k;
                      if (ref($tags) eq "ARRAY"){
                         foreach my $l (@$tags){
                            if ($l->{Key} ne ""){
                               push(@{$k{$l->{Key}}},$l->{Value});
                            }
                         }
                      }
                      $_->{tags}=\%k;
                      #######################################################
                      $_;
                   } values(%{$data->{accounts}}))]);
         }
         else{
            $self->LastMsg(ERROR,"unexpected data structure from REST call");
         }
         return(undef);
      },
      useproxy=>1
   ));
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(TriggerEndpoint),$self->SUPER::getValidWebFunctions());
}


sub TriggerEndpoint
{
   my $self=shift;
   my %param;

   $param{charset}="UTF8";

   my $q=Query->MultiVars();

   delete($q->{MOD});
   delete($q->{FUNC});
   print $self->HttpHeader("application/javascript",%param);

   my $json=new JSON;
   $json->utf8(1);

   my $d=$json->encode({
      request=>$q,
      exitcode=>0,
      exitmsg=>'OK'
   });
   print $d;
   return(0);
}





1;
