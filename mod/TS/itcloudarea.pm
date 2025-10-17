package TS::itcloudarea;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use itil::itcloudarea;
@ISA=qw(itil::itcloudarea);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                readonly      =>1,
                label         =>'Incident Assignmentgroup ID',
                dataobjattr   =>'appl.acinmassignmentgroupid'),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                group         =>'inm',
                readonly      =>1,
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['acinmassignmentgroupid'=>'id'],
                vjoindisp     =>'fullname')
   );

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'applictono',
                htmldetail    =>0,
                uploadable    =>0,
                readonly      =>1,
                group         =>'appl',
                explore       =>150,
                label         =>'Applications ICTO-ID',
                dataobjattr   =>'appl.ictono'),
     insertafter=>'appl'
   );




   return($self);
}


sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"Analyse");
   return(@l);
}

sub Analyse
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            query=>{
               typ=>'STRING',
               path=>0,
               init=>'280962857063'
            },
            cloudareaname=>{
               typ=>'STRING',
            },
            cloudareasrcid=>{
               typ=>'STRING',
            },
            cloudshortname=>{
               typ=>'STRING'
            }
         },undef,\&doAnalyse,@_)
   );
}

sub doAnalyse
{
   my $self=shift;
   my $q=shift;

   my @indication;
   my $ipflt={};
   my %userid;
   my $userid;
   my @cadmin;
   my @tadmin;
   my %cadmin;
   my %tadmin;
   my @refurl;
   my @applcadminfields=qw(applmgrid);
   my @appltadminfields=qw(tsmid tsm2id opmid opm2id);
   my $notes;
   my %networks;
   my $r={};

   #print STDERR Dumper($q);
   my @cflt;
   if (exists($q->{query}) && $q->{query} ne ""){
      my $f1={cistatusid=>[3,4],srcid=>[$q->{query}]};
      my $f2={cistatusid=>[3,4],name=>[$q->{query}]};
      push(@cflt,$f1,$f2);
   }
   else{
      if ((exists($q->{cloudareaname}) && $q->{cloudareaname} ne "") ||
          (exists($q->{cloudareasrcid}) && $q->{cloudareasrcid} ne "") ||
          (exists($q->{cloudshortname}) && $q->{cloudshortname} ne "")){
         my $f1={cistatusid=>[3,4]};
         push(@cflt,$f1);
      }
      else{
         my $f1={id=>[-1]};
         push(@cflt,$f1);
      }
      my $f2={cistatusid=>[3,4],name=>$q->{cloudareaq}};
   }
   foreach my $flt (@cflt){
      if (exists($q->{cloudareaname}) && $q->{cloudareaname} ne ""){
         $flt->{name}=[$q->{cloudareaname}]
      }
      if (exists($q->{cloudareasrcid}) && $q->{cloudareasrcid} ne ""){
         $flt->{srcid}=[$q->{cloudareasrcid}]
      }
      if (exists($q->{cloudshortname}) && $q->{cloudshortname} ne ""){
         $flt->{itcloudshortname}=[$q->{cloudshortname}]
      }
   }

   $self->ResetFilter();
   $self->SetFilter(\@cflt);


   my @l=$self->getHashList(qw(
      id respappl respapplid fullname cloud name
      itcloudshortname srcid systems
   )); 

   my %applid;
   my %systemid;
   foreach my $rec (@l){
      if (ref($r->{itcloudareas}) ne "ARRAY"){
         $r->{itcloudareas}=[];
      }
      push(@{$r->{itcloudareas}},{
         fullname=>$rec->{fullname},
         cloudareaname=>$rec->{name},
         cloudareasrcid=>$rec->{srcid},
         cloud=>$rec->{cloud},
         cloudshortname=>$rec->{itcloudshortname}
      });
      if ($rec->{respapplid} ne ""){
         $applid{$rec->{respapplid}}++;
      }
      foreach my $sysrec (@{$rec->{systems}}){
         $systemid{$sysrec->{id}}++;
      }
   }

   my @criticality;
   my @ictono;
   my %opmode;
   my @related;

   $self->finalizeAnalysedContacts(
      [keys(%applid)],
      [keys(%systemid)],
      \%userid,
      \@indication,
      \@cadmin,
      \@tadmin,
      \@criticality,
      \@ictono,
      \@refurl,
      \%opmode,
      \@related
   );

   if ($#indication!=-1){
      $r->{indication}=\@indication;
   }
   if ($#cadmin!=-1){
      $r->{'Admin-C'}=\@cadmin;
   }
   if ($#tadmin!=-1){
      $r->{'Tech-C'}=\@tadmin;
   }
   if ($#refurl!=-1){
      $r->{refurl}=\@refurl;
   }
   if ($#ictono!=-1){
      $r->{ictono}=\@ictono;
   }
   if ($#criticality!=-1){
      $r->{criticality}=$criticality[0];
   }
   if (keys(%opmode)){
      $r->{opmode}=\%opmode;
   }
   if ($#related!=-1){
      $r->{related}=\@related;
   }
   if ($notes ne ""){
      $r->{notes}=$notes;
   }
   
   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}

1;
