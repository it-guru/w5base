package TS::topappl;
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
use kernel::Field;
use TS::appl;
@ISA=qw(TS::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'systemlocations',
                readonly      =>1,
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                vjoinconcat   =>"\n\n",
                label         =>'System locations',
                onRawValue    =>\&calcSystemLocations),
      new kernel::Field::Text(
                name          =>'customerapplname',
                readonly      =>1,
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                label         =>'Customer Application name',
                onRawValue    =>\&calcCustApplName),
      new kernel::Field::Text(
                name          =>'systemosclass',
                readonly      =>1,
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                label         =>'Operationsystem class',
                onRawValue    =>\&calcSystemOSClass),
      new kernel::Field::Text(
                name          =>'tsmclearname',
                readonly      =>1,
                depend        =>'tsmid',
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                vjoinconcat   =>"\n\n",
                label         =>'TSM',
                onRawValue    =>\&calcClearTSM),

      new kernel::Field::Text(
                name          =>'businessteamtlclearname',
                readonly      =>1,
                depend        =>'businessteambossid',
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                vjoinconcat   =>"\n\n",
                label         =>'Businessteam TL',
                onRawValue    =>\&calcCleanBSTL),
                
	  new kernel::Field::Text(
                name          =>'headofdepartmentclearname',
                readonly      =>1,
                depend        =>'businessteamid',
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                vjoinconcat   =>"\n\n",
                label         =>'Head of Department',
                onRawValue    =>\&calcCleanHeadOfDept),
                                
	  new kernel::Field::Text(
                name          =>'headofresortclearname',
                readonly      =>1,
                depend        =>'businessteamid',
                group         =>'topagaddinfos',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                vjoinconcat   =>"\n\n",
                label         =>'Head of Resort',
                onRawValue    =>\&calcCleanHeadOfRes),                
   );

   $self->setDefaultView(qw(name customerapplname 
                            criticality servicesupport 
                            businessdepart
                            businessteam 
                            systemlocations systemosclass
                            tsmclearname  
                            businessteamtlclearname 
                            oncallphones databoss));

   return($self);
}

sub calcClearTSM
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();
   my $targetfld=$app->getField("tsmid",$current);
   my $targetid=$targetfld->RawValue($current);
   $targetid=[$targetid] if (ref($targetid) ne "ARRAY");

   my $u=$app->getPersistentModuleObject("base::user");
   $u->SetFilter({userid=>$targetid});
   my %u=();
   foreach my $urec ($u->getHashList(qw(phonename))){
      $u{$urec->{phonename}}++;
   }
   return([sort(keys(%u))]);
}


sub calcCustApplName
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();

   my $ca=$app->getPersistentModuleObject("TCOM::custappl");
   $ca->SetFilter({id=>\$id});
   my ($carec)=$ca->getOnlyFirst(qw(custname));
   if (defined($carec) && $carec->{custname} ne ""){
      return($carec->{custname});
   }
   return(undef);
}

sub calcCleanBSTL
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();
   my $targetfld=$app->getField("businessteambossid",$current);
   my $targetid=$targetfld->RawValue($current);
   $targetid=[$targetid] if (ref($targetid) ne "ARRAY");

   my $u=$app->getPersistentModuleObject("base::user");
   $u->SetFilter({userid=>$targetid});
   my %u=();
   foreach my $urec ($u->getHashList(qw(phonename))){
      $u{$urec->{phonename}}++;
   }
   
   return([sort(keys(%u))]);
}


sub calcCleanHeadOfDept
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();
   my $targetfld=$app->getField("businessteamid",$current);
   my $targetid=$targetfld->RawValue($current);
   $targetid=[$targetid] if (ref($targetid) ne "ARRAY");
   
   my $grp=$app->getPersistentModuleObject("base::grp");
   my $businessdepartid=$grp->getParentGroupIdByType($targetid->[0],"depart");
   
   my %u=();
   if ($businessdepartid ne ""){
      my $lgur=$app->getPersistentModuleObject("base::lnkgrpuserrole");
      $lgur->SetFilter({grpid=>$businessdepartid, nativrole=>'RBoss'});
      foreach my $lgurrec ($lgur->getHashList(qw(userid))){
      		my $u=$app->getPersistentModuleObject("base::user");
      		$u->SetFilter({userid=>$lgurrec->{userid}});
      		foreach my $urec ($u->getHashList(qw(phonename))){
         		$u{$urec->{phonename}}++;
      		}
      }
   }
   
   return([sort(keys(%u))]);
}


sub calcCleanHeadOfRes
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();
   my $targetfld=$app->getField("businessteamid",$current);
   my $targetid=$targetfld->RawValue($current);
   $targetid=[$targetid] if (ref($targetid) ne "ARRAY");
   
   my $grp=$app->getPersistentModuleObject("base::grp");
   my $businessdepartid=$grp->getParentGroupIdByType($targetid->[0],"resort");
   
   my %u=();
   if ($businessdepartid ne ""){
      my $lgur=$app->getPersistentModuleObject("base::lnkgrpuserrole");
      $lgur->SetFilter({grpid=>$businessdepartid, nativrole=>'RBoss'});
      foreach my $lgurrec ($lgur->getHashList(qw(userid))){
      		my $u=$app->getPersistentModuleObject("base::user");
      		$u->SetFilter({userid=>$lgurrec->{userid}});
      		foreach my $urec ($u->getHashList(qw(phonename))){
         		$u{$urec->{phonename}}++;
      		}
      }
   }
   
   return([sort(keys(%u))]);
}	

sub calcSystemLocations
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();

   if ($id ne ""){
      my $lnk=$app->getPersistentModuleObject("itil::lnkapplsystem");
      $lnk->SetFilter({systemcistatusid=>\'4',applid=>\$id});
      my %lid=();
      my %l=();
      foreach my $sys ($lnk->getHashList(qw(assetlocationid))){
         if ($sys->{assetlocationid} ne ""){
            $lid{$sys->{assetlocationid}}++;
         }
      }
      my $loc=$app->getPersistentModuleObject("base::location");
      $loc->SetFilter({cistatusid=>\'4',id=>[keys(%lid)]});
      foreach my $locrec ($loc->getHashList(qw(location address1))){
         my $l=$locrec->{location};
         $l.="\n" if ($l ne "" && $locrec->{address1} ne "");
         $l.=$locrec->{address1} if ($locrec->{address1} ne "");
         $l{$l}++; 
      }

      return([sort(keys(%l))]);
   }
   return(undef);
}


sub calcSystemOSClass
{
   my $self=shift;
   my $current=shift;
   my $id=$current->{id};
   my $app=$self->getParent();

   if ($id ne ""){
      my $lnk=$app->getPersistentModuleObject("itil::lnkapplsystem");
      $lnk->SetFilter({systemcistatusid=>\'4',applid=>\$id});
      my %o=();
      foreach my $sys ($lnk->getHashList(qw(osclass))){
         if ($sys->{osclass} ne ""){
            $o{$sys->{osclass}}++;
         }
      }
      return([sort(keys(%o))]);
   }
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      my @g=$self->SUPER::isViewValid($rec);
      push(@g,"topagaddinfos") if (grep(/^(default|ALL)$/,@g));
      return(@g);
   }
   return($self->SUPER::isViewValid($rec));
}

sub getCustomerControlRecords
{
   my $self=shift;
   my $topapplgroups=getModuleObject($self->Config,"TS::topapplgroups");
   my @customer=$topapplgroups->getHashList(qw(ALL));
   return(@customer);
}

sub arrangeSearchData
{
   my $self=shift;
   my $searchframe=shift;
   my $extframe=shift;
   my $defaultsearch=shift;
   my %param=@_;
   my $d;
   my @customer=$self->getCustomerControlRecords();
   $d.="<input type=hidden name=search_customer value=\"NONE\">";
   $d.="<input type=hidden name=search_cistatusid value=\"NONE\">";
   $d.="<input type=hidden name=search_customerprio value=\"NONE\">";
   # Anwendungen im Mandaten DSS sind laut Hr. Weidner keine Top-Anwendungen
   $d.="<input type=hidden name=search_mandator value=\"!DSS\">";
   $d.="<table width=\"100%\"><tr><td align=center>";
   foreach my $rec (@customer){
      $d.="<input style=\"margin-right:2px;margin-left:2px;width:120px\" ".
          "type=button ".
          "onclick=topSearch(\"$rec->{name}\") value=\"$rec->{label}\">";
   }
   $d.="<td>";
   $d.="<td width=1%>";
   $d.="<img onclick=DoPrint() style=\"cursor:pointer;cursor:hand\" ".
       "border=0 src=\"../../base/load/miniprint.gif\">";
   $d.="</td>";
   $d.="</tr>";
   $d.="</table>";
   $d.=<<EOF;
<script language="JavaScript">
function topSearch(l)
{
   var customer=document.forms[0].elements['search_customer'];
   var customerprio=document.forms[0].elements['search_customerprio'];
   var cistatusid=document.forms[0].elements['search_cistatusid'];
   document.forms[0].elements['UseLimit'].value='1000';
EOF
   foreach my $rec (@customer){
      $d.="if (l==\"$rec->{name}\"){customer.value=\"$rec->{customer}\";}\n";
      $d.="if (l==\"$rec->{name}\"){cistatusid.value=\"$rec->{cistatusid}\";}\n";
      $d.="if (l==\"$rec->{name}\"){customerprio.value=\"$rec->{customerprio}\";}\n";
   }


   $d.=<<EOF;
   nativeDoSearch();
}
</script>
EOF
   return($d);
}






1;
