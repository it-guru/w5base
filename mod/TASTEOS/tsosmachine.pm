package TASTEOS::tsosmachine;
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
use TASTEOS::lib::Listedit;
use JSON;
@ISA=qw(TASTEOS::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(          
            name               =>'id',  
            searchable         =>1,    
            htmlwidth          =>'200px',
            align              =>'left',
            label              =>'MachineID'),

      new kernel::Field::Text(     
            name               =>'systemid',
            searchable         =>1,
            readonly      =>sub{
               my $self=shift;
               my $rec=shift;
               if (defined($rec)){
                  return(1);
               }
               return(0);
            },
            label              =>'SystemID'),

     # new kernel::Field::TextDrop(                 # Static Datenobjekte  
     #       name               =>'system',         # koenen keine 
     #       searchable         =>1,                # Kreuzreferenzierungen!!
     #       vjointo            =>'TASTEOS::tsossystem',
     #       vjoinon            =>['systemid'=>'id'],
     #       vjoindisp          =>'name',
     #       uivisible     =>sub{
     #              my $self=shift;
     #              my $mode=shift;
     #              my %param=@_;
     #              if (exists($param{current})){
     #                 return(1);
     #              }
     #              return(0);
     #       },
     #       readonly           =>1,
     #       label              =>'System'),

      new kernel::Field::Text(     
            name               =>'name',
            searchable         =>1,
            htmlwidth          =>'200px',
            label              =>'Name'),

      new kernel::Field::Text(     
            name               =>'riskCategoryName',
            searchable         =>1,
            label              =>'risk Category Name'),

      new kernel::Field::Text(     
            name               =>'riskCategoryFactor',
            searchable         =>1,
            label              =>'risk Category Factor'),

      new kernel::Field::Text(
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name description));
   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($self->IsMemberOf("admin")){
      return("default");
   }
   return(undef);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}



sub DataCollector
{
   my $self=shift;
   my $filterset=shift;


   return(undef) if (!$self->genericSimpleFilterCheck4TASTEOS($filterset));
   my $filter=$filterset->{FILTER}->[0];

   if (!exists($filter->{id})){
      return(undef) if (!$self->checkMinimalFilter4TASTEOS($filter,"systemid"));
   }
   my $query=$self->decodeFilter2Query4TASTEOS($filter);
   my $systemid=$query->{systemid};

   $systemid=~s/[\.\/]//g;

   my $dbclass="systems/$systemid/machines";
   my $requesttoken=$systemid;

   if ($query->{id} ne ""){  # change op, if machine id is direct addressed
      $dbclass="machines/$query->{id}";
      $requesttoken=$query->{id};
   }


   return($self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>$requesttoken,
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

         my $h=[
            'access-token'=>$apikey,
            'Content-Type','application/json',
         ];

         if ($systemid ne ""){
            push(@$h,'system-id',$systemid);
         }
         return($h);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         if ($code eq "401"){  # 401 bedeutet nicht gefunden
            return([],"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TSOS response");
         return(undef);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;

         if (ref($data) eq "ARRAY"){
            map({
                      $_->{systemid}=$query->{systemid};
                   } @{$data});
            return($data);
         }
         else{  # zugriff direkt über den GET Request auf EINE machine
            $data->{systemid}=$data->{systemId}; # fixup API Bug
            return([$data]);
         }
         return(undef);
      }
   ));
}





sub InsertRecord
{
   my $self=shift;
   my $newrec=shift;  # hash ref

   my $dbclass="machines";

   my %new;
   foreach my $k (keys(%$newrec)){
      my $dk=$k;
      $dk="systemId" if ($k eq "systemid");
      $new{$dk}=$newrec->{$k};
      $new{$dk}=$new{$dk}->[0] if (ref($new{$dk}) eq "ARRAY");
   }





   my $d=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"INS.".$newrec->{name}.time(),
      method=>'POST',
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
         return(['access-token'=>$apikey,
                 %new,
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         my $code=shift;
         my $message=shift;
         $d=trim($d);
         $d=~s/'//g;
         $d=~s/"//g;
         my $resp="{\"machineid\":\"$d\"}";
         return($resp);
      }
   );

   return($d->{machineid});
}


sub UpdateRecord
{
   my $self=shift;
   my $newrec=shift; 
   my $flt=shift; 

   my $dflt=$self->decodeFilter2Query4TASTEOS($flt);
   my $id=$dflt->{id};

   if ($id eq ""){
      $self->LastMsg(ERROR,"update error - missing id");
      return(undef);
   }

   my %upd=();
   foreach my $k (keys(%$newrec)){
      my $kk=$k;
      $kk="systemId" if ($k eq "systemid");  # systemid->systemId map
      $upd{$kk}=$newrec->{$k};
   }


   my $dbclass="machines/$id";

   #printf STDERR ("fifi UpdateRecord: $dbclass %s\n",Dumper(\%upd));

   my ($d,$code,$message)=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"UPD.".$id.".".time(),
      method=>'PUT',
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl.$dbclass;
         return($dataobjurl);
      },
      content=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $d=encode_json(\%upd);
         #printf STDERR ("content=$d\n");
         return($d);
      },
      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         return(['access-token'=>$apikey,
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         my $code=shift;
         my $message=shift;
         my $resp="[]";
         return($resp);
      }
   );
   if ($code eq "200"){
      return(1);
   }
   return(undef);
}


sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;  # hash ref

   my $dbclass="machines/$oldrec->{id}";

   my ($d,$code,$message)=$self->CollectREST(
      dbname=>'TASTEOS',
      method=>'DELETE',
      requesttoken=>"DEL.".$oldrec->{id},
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
         return(['access-token'=>$apikey,
                 'machineId'=>$oldrec->{id},
                 'Content-Type','application/json']);
      },
      preprocess=>sub{   # create a valid JSON response
         my $self=shift;
         my $d=shift;
         $d=trim($d);
         if ($d eq ""){
            $d="0";
         }
         my $resp="{\"exitcode\":\"$d\"}";
         return($resp);
      }
   );
   if ($code eq "200"){
      return(1);
   }
   return(undef);
}



1;
