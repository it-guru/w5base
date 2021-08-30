package tsfiat::event::FiatKernelLoad;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use MIME::Base64;
@ISA=qw(kernel::Event);



# Modul to detect expiered SSL Certs based on Qualys scan data
sub FiatKernelLoad
{
   my $self=shift;
   my $queryparam=shift;

   my $obj=getModuleObject($self->Config,"tsfiat::firewall");

   my $start=NowStamp("en");

   my $d=$obj->CollectREST(
      dbname=>'tsfiat',
      useproxy=>0,
      verify_hostname=>0,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."W5Base/devices?model=fmg_firewall";
         return($dataobjurl);
      },

      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $apiuser=shift;
         my $headers=[Authorization =>'Basic '.
                                      encode_base64($apiuser.':'.$apikey)];
 
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         my @l;

         foreach my $device ($data->{devices}->nodes()){
            my $name=$device->{name}; 
            if ($name ne ""){
               my $isoffline=$device->{offline};
               $isoffline=lc($isoffline) eq "false"  ? 0:1;
               my $istopology=$device->{topology};
               $istopology=lc($istopology) eq "false"  ? 0:1;
               my $name=$device->{name};
               my $context=$device->{context_name};
               $name=~s/-$context$//;
               push(@l,{
                  id=>"".$device->{id},
                  parent_id=>"".$device->{parent_id},
                  ipaddress=>"".$device->{ip},
                  name=>$name,
                  domainname=>"".$device->{domain_name},
                  virtualtype=>"".$device->{virtual_type},
                  contextname=>"".$device->{context_name},
                  domainid=>"".$device->{domain_id},
                  isoffline=>$isoffline,
                  istopology=>$istopology,
                  vendor=>"".$device->{vendor},
                  model=>"".$device->{model},
                  srcload=>NowStamp("en")
               });
            }
            #printf STDERR ("name=%s\n",$device->{name});
            #printf ("node=%s\n",join(",",$device->nodes_keys()));
         }

         return(\@l);
      },
      #onfail=>sub{
      #   my $self=shift;
      #   my $code=shift;
      #   my $statusline=shift;
      #   my $content=shift;
      #   my $reqtrace=shift;
#
#         if ($code eq "404"){  # 404 bedeutet nicht gefunden
#            return([],"200");
#         }
#         msg(ERROR,$reqtrace);
#         $self->LastMsg(ERROR,"unexpected data TPC project response");
#         return(undef);
#      }
   );

   foreach my $rec (@$d){
       $obj->ValidatedInsertOrUpdateRecord($rec,{id=>$rec->{id}}); 

   }
   $obj->BulkDeleteRecord({srcload=>'<"'.$start.' GMT"'});
   
   #print STDERR ("rec=%s\n",Dumper($d));





   return({exitcode=>0,exitmsg=>'ok'});
}


1;
