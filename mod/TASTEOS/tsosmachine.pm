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
use UUID::Tiny(':std');
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
            name               =>'machineNumber',
            searchable         =>0,
            label              =>'Machine Number'),

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
            readonly           =>1,
            label              =>'risk Category Name'),

      new kernel::Field::Text(     
            name               =>'riskCategoryId',
            searchable         =>1,
            label              =>'risk Category Id'),

      new kernel::Field::Text(     
            name               =>'riskCategoryFactor',
            searchable         =>1,
            readonly           =>1,
            label              =>'risk Category Factor'),

      new kernel::Field::Date(
            name              =>'lastscan',
            searchable        =>1,
            readonly           =>1,
            label             =>'LastScanDate'),

      new kernel::Field::Text(
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

      new kernel::Field::Link(
            name              =>'salt',
            label             =>'MachineID create salt'),

      new kernel::Field::Link(
            name              =>'w5systemid',
            label             =>'System W5BaseID'),


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



#sub genericReadREST
#{
#   my $self=shift;
#   my $data=shift;
#   my $machineid=shift;
#
#   my $d=$self->CollectREST(
#      dbname=>'TASTEOS',
#      requesttoken=>$data."/".$machineid,
#      url=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#         $baseurl.="/"  if (!($baseurl=~m/\/$/));
#         my $dataobjurl=$baseurl."machines/".$machineid."/reports";
#         $dataobjurl.="?format=JSON";
#         return($dataobjurl);
#      },
#      headers=>sub{
#         my $self=shift;
#         my $baseurl=shift;
#         my $apikey=shift;
#
#         my $h=[
#            'access-token'=>$apikey,
#            'Content-Type','application/json',
#         ];
#         return($h);
#      },
#      onfail=>sub{
#         my $self=shift;
#         my $code=shift;
#         my $statusline=shift;
#         my $content=shift;
#         my $reqtrace=shift;
#
#         if ($code eq "404"){  # 404 bedeutet nicht gefunden
#            return([],"200");
#         }
#       #  if ($code eq "400"){
#       #     my $json=eval('decode_json($content);');
#       #     if ($@ eq "" && ref($json) eq "HASH" &&
#       #         $json->{error}->{message} ne ""){
#       #        $self->LastMsg(ERROR,$json->{error}->{message});
#       #        return(undef);
#       #     }
#       #  }
#         msg(ERROR,$reqtrace);
#         $self->LastMsg(ERROR,"unexpected data TasteOS response in genRead");
#         return(undef);
#      }
#   );
#   return($d);
#}



sub getCredentialName
{
   my $self=shift;

   return("TASTEOS");
}




sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   foreach my $fset (values(%$filterset)){
      foreach my $flt (@{$fset}){
         if (ref($flt) eq "HASH"){
            if (exists($flt->{w5systemid})){
               my $id=$flt->{w5systemid};
               if ($id ne ""){
                  my $o=$self->getPersistentModuleObject("w5add",
                           "itil::addlnkapplgrpsystem");
                  $o->SetFilter({systemid=>$id});
                  my @l=$o->getHashList(qw(applgrpid systemid additional));
                  if ($#l==-1){
                     # we have a search request to a w5systemid, witch is
                     # not mapped in itil::addlnkapplgrpsystem to a TasteOS
                     # machine id.
                     # This needs to get an empty result.
                     return([]);
                  }
                  foreach my $srec (@l){
                     my $machineId;
                     if (ref($srec->{additional}) eq "HASH"){
                        my $a=$srec->{additional};
                        if (exists($a->{TasteOS_MachineID})){
                           $machineId=$a->{TasteOS_MachineID};
                        }
                     }
                     $machineId=$machineId->[0] if (ref($machineId) eq "ARRAY");
                     if ($machineId ne ""){
                        $flt->{id}=$machineId;
                     }
                  }
               }
               if (!defined($flt->{id})){
                  $flt->{id}="-1";
                  return([]);
               }
               delete($flt->{w5systemid});
            }
         }
      }
   }


   return(undef) if (!$self->genericSimpleFilterCheck4TASTEOS($filterset));
   my $filter=$filterset->{FILTER}->[0];

   if (!exists($filter->{id})){
      return(undef) if (!$self->checkMinimalFilter4TASTEOS($filter,"systemid"));
   }
   my $query=$self->decodeFilter2Query4TASTEOS($filter);
   my $systemid=$query->{systemid};

   $systemid=~s/[\.\/]//g;

   return([]) if ($query->{id} eq "" && $systemid eq "");

   my $dbclass="systems/$systemid/machines";
   my $requesttoken=$systemid;

   if ($query->{id} ne ""){  # change op, if machine id is direct addressed
      $dbclass="machines/$query->{id}";
      $requesttoken=$query->{id};
   }


   return($self->CollectREST(
      dbname=>$self->getCredentialName(),
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
         if ($code eq "403"){  # 403 Datensatz durch den TasteOS Cleanup
            return([],"200");  # gelöscht
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
         }
         else{  # zugriff direkt über den GET Request auf EINE machine
            $data->{systemid}=$data->{systemId}; # fixup API Bug
            $data=[$data];
         }
         map({
             $_->{lastscan}=$self->ExpandTimeExpression(
                                $_->{lastScanDate},undef,"GMT");;
         } @{$data});
         return($data);
      }
   ));
}





sub InsertRecord
{
   my $self=shift;
   my $newrec=shift;  # hash ref

   my $dbclass="machines";
   my %new;


   my $tsossys=getModuleObject($self->Config,"TASTEOS::tsossystem");

   my $uarec=$tsossys->getUnassignedMachinesRec();

   return(undef) if (!defined($uarec));

   #
   # check, if machineNumber is already in 'Unassigned Machines' System
   #
   my $foundMachineIdInUnassinged;

   foreach my $uaMachineRec (@{$uarec->{machines}}){
     # msg(INFO,"check ".$uaMachineRec->{machineNumber});
      if ($uaMachineRec->{machineNumber} eq $newrec->{machineNumber}){
         if (!$foundMachineIdInUnassinged){
            $self->Log(WARN,"backlog",
                     "TasteOS: ".
                     "move MachineID '$uaMachineRec->{id}' from ".
                     "UnassignedMachines to SystemID '$newrec->{systemid}'");
            if (($uaMachineRec->{name} ne $newrec->{name}) ||
                ($uaMachineRec->{riskCategoryId} ne 
                 $newrec->{riskCategoryId}) || 
                ($uaMachineRec->{systemid} ne $newrec->{systemid}) ){
               if ($self->ValidatedUpdateRecord($uaMachineRec,$newrec,{
                      id=>$uaMachineRec->{id}
                   })){
                  $foundMachineIdInUnassinged=$uaMachineRec->{id};
                  $self->Log(WARN,"backlog",
                           "TasteOS: ".
                           "set MachineID '$uaMachineRec->{id}' to ".
                           "riskCategoryId='$newrec->{riskCategoryId}'");
               }
            }
         }
         else{
           msg(INFO,"drop doublicate $uaMachineRec->{machineNumber} ".
                    "id=$uaMachineRec->{id}");
           $self->ValidatedDeleteRecord({id=>$uaMachineRec->{id}});
         }
      }
   }
   if ($foundMachineIdInUnassinged){
      return($foundMachineIdInUnassinged);
   }

   foreach my $k (keys(%$newrec)){
      my $dk=$k;
      $dk="systemId" if ($k eq "systemid");
      if ($k eq "salt"){
         my $TasetOSNS='ea28d30f-b10e-45c2-8619-4f5ce4cde7c1';
         my $saltuuid=create_uuid(UUID_V5,$TasetOSNS,$newrec->{$k});
         my $reqMachineId=uuid_to_string($saltuuid);
         msg(INFO,"TasteOS request machine-id $reqMachineId on Insert\n".
                  "based on salt '".$newrec->{$k}."' with \n".
                  "TasetOSNS: $TasetOSNS");
         $new{'machine-id'}=$reqMachineId;
      }
      else{
         $new{$dk}=$newrec->{$k};
         $new{$dk}=$new{$dk}->[0] if (ref($new{$dk}) eq "ARRAY");
      }
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
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "409"){  # 409 conflict
            return({machineid=>$new{'machine-id'}},"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TSOS response");
         return(undef);
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
      next if ($k eq "lastscan");
      next if ($k eq "riskCategoryName");
      $kk="systemId" if ($k eq "systemid");  # systemid->systemId map
      $upd{$kk}=$newrec->{$k};
   }


   my $dbclass="machines/$id";

   #printf STDERR ("fifi UpdateRecord: $dbclass %s\n",Dumper(\%upd));

   my ($d,$code,$message)=$self->CollectREST(
      dbname=>'TASTEOS',
      requesttoken=>"UPD.".$id.".".time(),
      method=>'PATCH',
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

sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(id systemid name lastscan));


   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{

         #####################################################################
         #my %e=(
         #   section=>'SYSTEMNAME',
         #   scanname=>$rec->{systemname}, 
         #   quality=>-50,    # relativ schlecht verlässlich
         #   processable=>1,
         #   forcesysteminst=>1  # MUSS System zugeordnet sein
         #);
         #push(@res,\%e);
         #####################################################################

         if ($#res==-1){  # read only first entry
            if ($rec->{lastscan} ne ""){
               my $d=CalcDateDuration($rec->{lastscan},NowStamp("en"));
               if (defined($d)){
                  msg(INFO,"found TasteOS scan for '".$rec->{name}."' ".
                           "with age of ".$d->{totaldays});
                  if ($d->{totaldays}<9){
                     my %e=(
                        section=>'SOFTWARE',
                        scanname=>"TasteOS-Agent",
                        scanextra2=>"1.0.0",
                        quality=>2,    # schlechter als AM
                        processable=>1,
                        backendload=>$rec->{lastscan},
                        autodischint=>$self->Self.": ".$rec->{id}.
                                      ": ".$rec->{systemid}.
                                      ": ".$rec->{name}
                     );
                     # TasteOS Rec
                     $e{forcesysteminst}=1;
                     $e{allowautoremove}=1;
                     $e{quality}=100; 
                     push(@res,\%e);
                  }
               }
            }
            else{
               msg(INFO,"TasteOS entry found but without lastscan");
            }
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}




1;
