package itil::autodiscdata;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscdata.id'),
                                                  
      new kernel::Field::Text(
                name          =>'engine',
                htmleditwidth =>'80px',
                label         =>'Engine',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                dataobjattr   =>'autodiscdata.engine'),

      new kernel::Field::Text(
                name          =>'target',
                htmlwidth     =>'250px',
                label         =>'Target',
                readonly      =>1,
                dataobjattr   =>
                   'if (system.name is null,swinstance.fullname,system.name)'),

      new kernel::Field::Text(
                name          =>'targettyp',
                htmlwidth     =>'250px',
                label         =>'Target Type',
                readonly      =>1,
                dataobjattr   =>
                   "if (system.name is null,'INSTANCE','SYSTEM')"),

      new kernel::Field::Interface(
                name          =>'systemid',
                htmlwidth     =>'250px',
                label         =>'SystemID',
                dataobjattr   =>'autodiscdata.system'),

      new kernel::Field::Interface(
                name          =>'swinstanceid',
                htmlwidth     =>'250px',
                label         =>'SoftwareinstanceID',
                dataobjattr   =>'autodiscdata.swinstance'),

      new kernel::Field::XMLInterface(
                name          =>'data',
                uivisible     =>1,
                htmldetail    =>1,
                label         =>'AutodiscoveryData',
                dataobjattr   =>'autodiscdata.addata'),

      new kernel::Field::Text(
                name          =>'enginefullname',
                label         =>'Engine fullname',
                group         =>'source',
                readonly      =>1,
                dataobjattr   =>'autodiscengine.fullname'),

      new kernel::Field::Text(
                name          =>'enginedataobj',
                label         =>'Engine DataObj',
                group         =>'source',
                readonly      =>1,
                dataobjattr   =>'autodiscengine.addataobj'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscdata.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'autodiscdata.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'autodiscdata.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'autodiscdata.realeditor'),
   

   );
   $self->setDefaultView(qw(engine targettyp target  mdate));
   $self->setWorktable("autodiscdata");
   return($self);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();

   my $from="$worktable left outer join system ".
            "on autodiscdata.system=system.id ".
            "left outer join swinstance ".
            "on autodiscdata.swinstance=swinstance.id ".
            "left outer join autodiscengine ".
            "on autodiscdata.engine=autodiscengine.name";
   return($from);
}


sub isCopyValid
{
   my $self=shift;

   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(undef);
}







sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) &&
       ($newrec->{systemid} eq "" &&
        $newrec->{swinstanceid} eq "")){
      $self->LastMsg(ERROR,"invalid object reference specified");
      return(0);
   }

   return(1);
}


sub LoadAutoDiscDataSet
{
   my $self=shift;
   my $targettyp=shift;
   my $targetid=shift;

   my $d={};

   $self->ResetFilter();
   if ($targettyp eq "SYSTEM"){
      $self->SetFilter({systemid=>\$targetid,targettyp=>\$targettyp});
      $self->SetCurrentView(qw(data engine enginefullname enginedataobj));
      my ($rec,$msg)=$self->getFirst();
      if (defined($rec)){
         my $f=$self->getField("data");
         do{
            my $discrec={
               enginefullname=>$rec->{enginefullname},
               data=>$f->RawValue($rec)->{xmlroot}
            }; 
            $d->{type}->{$rec->{enginedataobj}}=$discrec;
            $d->{engine}->{$rec->{engine}}=$discrec;
            ($rec,$msg)=$self->getNext();
         } until(!defined($rec));
      }
   }
   return($d);
}

sub SoftwareAnalyseAutoDiscDataSet
{
   my $self=shift;
   my $adrec=shift;
   my $rec=shift;
   my $enginedataobj=shift;
   my $path=shift;
   my $searchexpr=shift;
   my $software=shift;
   my $control=shift;
   $software=[split(/\|/,$software)] if (ref($software) ne "ARRAY");

   my $sourcepath="/type/".$enginedataobj."/data".$path;


   my @needSW=@$software;
   my $needSW="^(".join("|",@needSW).")\$";

   my @mgmtSWdirect=HashExtr($rec->{software},"/software",qr/$needSW/);
   my @mgmtSWidirect;
   if ($rec->{isclusternode}){
      my $itclustid=$rec->{itclustid};
      if ($itclustid ne ""){
         my $itclust=getModuleObject($self->Config,"itil::itclust");
         $itclust->SetFilter({id=>\$itclustid});
         my ($clustrec)=$itclust->getOnlyFirst(qw(software));
         @mgmtSWidirect=HashExtr($clustrec->{software},"/software",qr/$needSW/);
      }
   }
   if (my @discSW=HashExtr($adrec,$sourcepath,$searchexpr)){
      $control->{resultMsg}=[] if (!defined($control->{resultMsg}));
      my @resultMsg=();
      my $enginefullname=$adrec->{type}->{$enginedataobj}->{enginefullname};
      my %discVers;
      map({$discVers{$_->{version}}++} @discSW);
      my @discVers=sort(keys(%discVers));
   
   
      if ($#mgmtSWdirect==-1 && $#mgmtSWidirect==-1){
         push(@{$control->{resultMsg}},
            sprintf("It seems, there are missing ".
                    "Software Installation %s ".
                    "in versions like %s based on ".
                    "AutoDiscovery system %s\n",
                    join(" or ",@needSW),
                    join(" or ",@discVers),
                    $enginefullname)
         );
      }
      else{
         my @missedVers;
         foreach my $v (@discVers){
            my $found=0;
            my $qv=quotemeta($v);
            foreach my $mrec (@mgmtSWdirect,@mgmtSWidirect){
               if (($mrec->{version}=~m/^$qv\./) ||
                   $mrec->{version} eq $v){  # nur Anfang vergleichen
                  $found++;
               }
            }
            push(@missedVers,$v) if (!$found);
         }
         if ($#missedVers!=-1){
            push(@{$control->{resultMsg}},
               sprintf("It seems, there are missing ".
                       "Software Installation %s ".
                       "in versions like %s based on ".
                       "AutoDiscovery system %s\n",
                       join(" or ",@needSW),
                       join(" and ",@missedVers),
                       $enginefullname)
            );
         }
         my @oddInst;
         foreach my $mrec (@mgmtSWdirect){
            my $found=0;
            foreach my $drec (@discSW){
               my $qVers=quotemeta($drec->{version});
               if (($mrec->{version}=~m/^$qVers\./) ||
                   $drec->{version} eq $mrec->{version}){
                  $found++;
               }
            }
            if (!$found){
               push(@oddInst,$mrec->{software}."-".$mrec->{version})
            }
         }
         if ($#oddInst!=-1){
            foreach my $oddInst (@oddInst){
               push(@{$control->{resultMsg}},
                  sprintf("The Software Installation %s ".
                          "could not be autodetected by ".
                          "AutoDiscovery system %s\n",
                          $oddInst,$enginefullname)
               );
            }
         }

      }
   }
}







1;
