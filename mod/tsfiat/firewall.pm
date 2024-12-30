package tsfiat::firewall;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use MIME::Base64;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);


   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'id',
                dataobjattr   =>'tsfiat_firewall.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'tsfiat_firewall.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>"concat(tsfiat_firewall.name,'-',".
                                "tsfiat_firewall.contextname)"),

      new kernel::Field::Text(
                name          =>'vendor',
                label         =>'Vendor',
                dataobjattr   =>'tsfiat_firewall.vendor'),

      new kernel::Field::Text(
                name          =>'domainname',
                label         =>'Domain name',
                dataobjattr   =>'tsfiat_firewall.domainname'),

      new kernel::Field::Text(
                name          =>'domainid',
                label         =>'Domain id',
                dataobjattr   =>'tsfiat_firewall.domainid'),

      new kernel::Field::Boolean(
                name          =>'isexcluded',
                label         =>'is excluded',
                dataobjattr   =>'tsfiat_firewall.isexcluded'),

      new kernel::Field::Boolean(
                name          =>'isoffline',
                label         =>'is offline',
                dataobjattr   =>'tsfiat_firewall.isoffline'),

      new kernel::Field::Boolean(
                name          =>'istopology',
                label         =>'is topology',
                dataobjattr   =>'tsfiat_firewall.istopology'),

      new kernel::Field::Text(
                name          =>'contextname',
                label         =>'Context name',
                dataobjattr   =>'tsfiat_firewall.contextname'),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP-Address',
                dataobjattr   =>'tsfiat_firewall.ipaddress'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tsfiat_firewall.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tsfiat_firewall.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tsfiat_firewall.modifydate'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'tsfiat_firewall.srcload'),

   );
   $self->setDefaultView(qw(name id ipaddress contextname mdate));
   $self->setWorktable("tsfiat_firewall");
   return($self);
}


sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"QueryByServerIP");
   return(@l);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","soure");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getFirewallTable
{
   my $self=shift;

   my $d=$self->CollectREST(
      dbname=>'tsfiat',
      useproxy=>0,
      verify_hostname=>0,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."W5Base/devices";
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
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data from FIAT (devices)");
         die();
      }
   );

   my $dexcl=$self->CollectREST(
      dbname=>'tsfiat',
      useproxy=>0,
      requesttoken=>'t'.time(),
      verify_hostname=>0,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."securechangeworkflow/api/securechange/".
                                 "devices/excluded?show_all=false";
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

         foreach my $device ($data->{device_ids}->nodes()){
            my $id="".$device->{CONTENT}; 
            push(@l,{id=>$id});
         }

         return(\@l);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data from FIAT (excluded)");
         die();
         return(undef);
      }
   );
   my %excl=();
   foreach my $rec (@$dexcl){
      $excl{$rec->{id}}++;
   }
   foreach my $rec (@$d){
      $rec->{isexcluded}=0;
      if (exists($excl{$rec->{id}})){
         $rec->{isexcluded}=1;
      }
   }

   return($d);
}


sub QueryByServerIP
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            query=>{
               typ=>'STRING',
               path=>0,
               init=>'10.105.204.109'
            },
            ipaddr=>{
               typ=>'STRING',
            }
         },undef,\&doQueryByServerIP,@_)
   );
}

sub doQueryByServerIP
{
   my $self=shift;
   my $param=shift;

   if (exists($param->{query}) && $param->{query} ne ""){
      if (!exists($param->{ipaddr}) || $param->{ipaddr} eq ""){
         $param->{ipaddr}=$param->{query};
      }
      if (exists($param->{ipaddr}) && $param->{ipaddr} ne $param->{query}){
         $param->{ipaddr}="-1";
      }
   }
   my $d=$self->getFirewallByIp($param->{ipaddr});

   if (ref($d) eq "ARRAY"){
      foreach my $fwrec (@$d){
         if ($fwrec->{id} ne ""){
            $self->ResetFilter();
            $self->SetFilter({id=>\$fwrec->{id}});
            my @l=$self->getHashList(qw(ALL));
            if ($#l!=-1){
               $fwrec->{firewall}=\@l;
            }
         }
      }
   }

   return($d);
}




sub getFirewallByIp
{
   my $self=shift;
   my $ip=shift;

   my $d=$self->CollectREST(
      dbname=>'tsfiat',
      useproxy=>0,
      retry_count=>6,
      retry_interval=>10,
      verify_hostname=>0,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."W5Base/last_hop?host=".$ip;
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

         foreach my $if ($data->{interfaces}->nodes()){
            my $id="".$if->{device_id}; 
            my $ip="".$if->{ip}; 
            my $mask="".$if->{mask}; 
            my $name="".$if->{name}; 
            if ($id ne ""){
               push(@l,{
                  id=>$id,
                  ip=>$ip,
                  mask=>$mask,
                  name=>$name
               });
            }
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




   #printf STDERR ("d=%s\n",Dumper($d));
   return($d);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isexcluded"))){
     Query->Param("search_isexcluded"=>$self->T("no"));
   }
}













1;
