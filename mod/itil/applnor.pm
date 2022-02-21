package itil::applnor;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use itil::appldoc;
@ISA=qw(itil::appldoc);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   $param{Worktable}='applnor';
   $param{doclabel}='-NOR';
   $param{displayall}=sub{
      my $self=shift;
      my $current=shift;
      return(1) if ($self->getParent->IsMemberOf("admin"));
      return(0);
   };
   my $self=bless($type->SUPER::new(%param),$type);
   my $haveitsemexp="costcenter.itsem is not null ".
                    "or costcenter.itsemteam is not null ".
                    "or costcenter.itseminbox is not null ".
                    "or costcenter.itsem2 is not null";


   my $ic=$self->getField("isactive");
   $ic->{label}="active NOR certificate";
   $ic->{translation}='itil::applnor';

   $self->AddFields( 
      new kernel::Field::Link(
                name          =>'databossid',
                label         =>'Delivery Manager',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem,costcenter.delmgr)"),
   );

   $self->AddFields(
      new kernel::Field::Databoss(),
                insertafter=>'mandator'

   );


   $self->AddFields(
      new kernel::Field::Text(
                name          =>'custcontract',
                label         =>'customer contract',
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>'additional'),
                insertafter=>'name'
   );

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'adv',
                label         =>'relevant ADV',
                readonly      =>'1',
                searchable    =>0,
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'normodel',
                label         =>'relevant NOR-Solutionmodel',
                readonly      =>'1',
                searchable    =>0,
                weblinkto     =>'NONE',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'itnormodel'),

      new kernel::Field::Interface(
                name          =>'advdstateid',
                label         =>'dstateid of relevant ADV',
                readonly      =>'1',
                searchable    =>0,
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'dstateid'),

      new kernel::Field::Boolean(
                name          =>'scddata',
                label         =>'SCD Datahandling',
                readonly      =>'1',
                searchable    =>0,
                weblinkto     =>'NONE',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'scddata'),


      new kernel::Field::Select(
                name          =>'modules',
                label         =>'Modules',
                readonly      =>'1',
                searchable    =>0,
                vjoinconcat   =>",\n",
                depend        =>'advid',
                getPostibleValues=>sub{
                   $self=shift;
                   my $app=$self->getParent();
                   my $o=$app->ModuleObject("itil::appladv");
                   return($o->getAllPosibleApplModules());
                },
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $f=$self->getField("advid");
                   my $advid=$f->RawValue($current);
                   my $o=$app->ModuleObject("itil::appladv");
                   $o->SetFilter({id=>\$advid});
                   my ($rec,$msg)=$o->getOnlyFirst(qw(modules));
                   if (defined($rec)){
                      return($rec->{modules});
                   }
                   return([]);
                }),

      new kernel::Field::Text(
                name          =>'advid',
                htmldetail    =>0,
                label         =>'linked ADV ID',
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{   # if the record 'isactive' then
                   my $self=shift;     # use the 'isactive' ADV - else
                   my $current=shift;  # use the storedadvid
                   my $app=$self->getParent();
                   if (!defined($current->{dstate}) ||
                       $current->{dstate}==10){
                      if ($current->{srcparentid} ne ""){
                         my $o=$app->ModuleObject("itil::appladv");
                         $o->SetFilter({srcparentid=>\$current->{srcparentid},
                                        isactive=>'1 [EMPTY]'});
                         my ($rec,$msg)=$o->getOnlyFirst(qw(id
                                                            fullname));
                         # you need to select two fields, because selectfix
                         # only effects on views with more then one field!
                         return($rec->{id});
                      }
                   }
                   my $so=$app->getField("storedadvid",$current);
                   my $storedadvid=$so->RawValue($current);
                   return($storedadvid);
                }),

      new kernel::Field::Interface(
                name          =>'storedadvid',
                label         =>'stored ADV ID',
                selectfix     =>1,
                readonly      =>1,
                searchable    =>0,
                container     =>'additional'),

      new kernel::Field::Date(
                name          =>'advmdate',
                label         =>'ADV Modificationdate',
                readonly      =>'1',
                searchable    =>0,
                weblinkto     =>'NONE',
                group         =>'source',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'mdate'),
   );

   my $adv=getModuleObject($self->Config,"itil::appladv");
   if (defined($adv)){
      my @allmodules=$adv->getAllPosibleApplModules();
      $self->{allModules}=[];
      while(my $k=shift(@allmodules)){
         shift(@allmodules);
         push(@{$self->{allModules}},$k);
      }
   }
   else{
      msg(ERROR,"can not create itil::appladv object");
   }

   foreach my $module (@{$self->{allModules}}){
      $self->AddGroup($module,translation=>'itil::ext::custcontractmod');
      $self->AddFields(
         new kernel::Field::Text(
                   name          =>$module."DeliveryCountries", 
                   label         =>"Delivery Countries",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryOrgs", 
                   label         =>"Delivery Organisations",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Textarea(
                   name          =>$module."DeliveryAddresses", 
                   label         =>"Delivery Addresses",
                   group         =>$module,
                   vjoinconcat   =>"\n",
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),

         new kernel::Field::Boolean(
                   name          =>$module."isSCDconform", 
                   label         =>"SCD conform",
                   group         =>$module,
                   readonly      =>1,
                   markempty     =>1,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>sub{
                       my $self=shift;
                       return(undef);
                   }),

         new kernel::Field::Text(
                   name          =>$module."DeliveryItemID", 
                   label         =>"Delivery ConfigItem IDs",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryGroup", 
                   label         =>"Delivery Groups",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryGroupID", 
                   label         =>"Delivery GroupIDs",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryContactID", 
                   label         =>"Delivery Contacts",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."ADVCountryRest", 
                   label         =>"ADV Country restrictions",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   readonly      =>1,
                   searchable    =>0,
                   onRawValue    =>sub{
                      my $self=shift;
                      my $current=shift;
                      my $advid=$current->{advid};
                      my $adv=getModuleObject($self->getParent->Config,
                                              "itil::appladv");
                      $adv->SetFilter({id=>\$advid});
                      my ($rec,$msg)=$adv->getOnlyFirst($module."CountryRest",
                                                      "itnormodelid");
                      if (defined($rec)){
                         if ($rec->{$module."CountryRest"} ne ""){
                            return($rec->{$module."CountryRest"});
                         }
                         if ($rec->{itnormodelid} ne ""){
                            my $nor=getModuleObject($self->getParent->Config,
                                              "itil::itnormodel");
                            $nor->SetFilter({id=>\$rec->{itnormodelid}});
                            my ($norrec,$msg)=$nor->getOnlyFirst("defcountry");
                            if (defined($norrec) && 
                                $norrec->{defcountry} ne ""){
                               return($norrec->{defcountry});
                            }
                         }
                      }
                      return("II");
                   }),

         new kernel::Field::Boolean(
                   name          =>$module."isCountryCompliant", 
                   label         =>"valid against ADV country restrictions",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   markempty     =>1,
                   depend        =>[$module."ADVCountryRest"],
                   searchable    =>0,
                   readonly      =>1,
                   onRawValue    =>sub{
                       my $self=shift;
                       my $current=shift;
                       my $cur=$current->{$self->{group}."DeliveryCountries"};
                       my $solfld=$self->getParent->getField(
                               $self->{group}."ADVCountryRest");
                       return(undef) if (!defined($solfld));
                       my $sol=$solfld->RawValue($current);
                       return(1) if ($sol eq "");
                       $cur=[split(/[;,]\s*/,uc($cur))] if (!ref($cur));
                       $sol=[split(/[;,]\s*/,uc($sol))] if (!ref($sol));
                       my $c=getModuleObject($self->getParent->Config,
                                             "base::isocountry");
                       my @l=$c->getCountryEntryByToken(1,@$sol); # resolv
                       return(0) if ($#l==-1);                    # EU o.e.
                       $sol=[map({$_->{token}} @l)];
                       foreach my $chk (@$cur){
                          if (!in_array($sol,$chk)){
                             return(0);
                          }
                       }
                       return(1);
                   }),

      );
   }

   $self->AddFields(
      new kernel::Field::Text(
                name          =>"SUMMARYdeliveryCountry", 
                label         =>"delivery and production country",
                group         =>"summary",
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my @m=$self->getParent->currentModules($current);
                    my $res=1;
                    my %country;
                    foreach my $m (@m){
                       my $fo=$self->getParent->getField($m.
                                                         "DeliveryCountries");
                       if (defined($fo)){
                          my $l=$fo->RawValue($current);
                          $l=[split(/[;,\s]\s*/,$l)] if (ref($l) ne "ARRAY");
                          foreach my $ll (@$l){
                             $country{$ll}++;
                          }
                       }
                    }
                    return([keys(%country)]);
                }),

      new kernel::Field::Text(
                name          =>"SUMMARYdeliveryRegion", 
                label         =>"delivery and production region",
                group         =>"summary",
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my $fo=$self->getParent->getField("SUMMARYdeliveryCountry");
                    my $l=$fo->RawValue($current);
                    if ($#{$l}==-1){
                       return("?");
                    }
                    #
                    # Achtung: Eine Erbringungsregion kann auch direkt ein
                    #          Land sein (z.B. DE oder SK)
                    #
                    if ($#{$l}==0){
                       return($l->[0]);
                    }
                    my $c=getModuleObject($self->getParent->Config,
                                          "base::isocountry");
                    my @eu=$c->getCountryEntryByToken(1,"EU");

                    @eu=map({$_->{token}} @eu);
                    my $allfound=1;
                    foreach my $chk (@$l){
                       if (!in_array(\@eu,$chk)){
                          $allfound=0;last;
                       }
                    }
                    return("EU") if ($allfound);

                    my @europe=$c->getCountryEntryByToken(1,"EUROPE");
                    @europe=map({$_->{token}} @europe);
                    my $allfound=1;
                    foreach my $chk (@$l){
                       if (!in_array(\@europe,$chk)){
                          $allfound=0;last;
                       }
                    }
                    return("EUROPE") if ($allfound);

                    return("II");
                }),

      new kernel::Field::Boolean(
                name          =>"SUMMARYisSCDconform", 
                label         =>"total conform against ADV SCD restrictions",
                group         =>"summary",
                readonly      =>1,
                markempty     =>1,
                searchable    =>0,
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my $fo=$self->getParent->getField("scddata");
                    my $scddata=$fo->RawValue($current);
                    if ($scddata eq "1"){
                       return($self->getParent->validateSCDconform($current));
                    }
                    return(1);
                }),

      new kernel::Field::Boolean(
                name          =>"SUMMARYisCountryCompliant", 
                label         =>"total valid against ADV country restrictions",
                group         =>"summary",
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my @m=$self->getParent->currentModules($current);
                    my $res=1;
                    foreach my $m (@m){
                       my $fo=$self->getParent->getField($m.
                                                         "isCountryCompliant");
                       if (!defined($fo)){
                          $res=0;last;
                       }
                       if (!($fo->RawValue($current))){
                          $res=0;last;
                       }
                    }
                    return($res);
                }),
      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'applnor.comments'),
   );


   return($self);
}

sub validateSCDconform
{
   my $self=shift;
   my $current=shift;

   return(undef);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::applnor");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $bk=$self->SUPER::Validate($oldrec,$newrec,$origrec);
   if ($bk){
      if (effVal($oldrec,$newrec,"dstate")==20){
         $newrec->{storedadvid}=effVal($oldrec,$newrec,"advid");
      }
   }
   return($bk);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec);

   my @modules=$self->currentModules($rec);
   push(@l,"nordef","advdef","misc","summary",@modules,"qc");
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec) && $rec->{dstate}<30){
      my @l;
      my @modules=$self->currentModules($rec);
      push(@l,"nordef","advdef","misc",@modules);
      my $userid=$self->getCurrentUserId();

      return() if ($rec->{advid} eq "");
      return() if ($rec->{advdstateid}<20);


      return(@l) if ($rec->{databossid} eq $userid ||
                     $rec->{delmgr2id} eq $userid ||
                     $self->IsMemberOf("admin"));
      if ($rec->{delmgrteamid} ne ""){
         return(@l) if ($self->IsMemberOf($rec->{delmgrteamid}));
      }
   }
   return();
}

sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   if ($fld->{name} eq "MApplDeliveryGroup" || 
       $fld->{name} eq "MApplDeliveryItemID" ||
       $fld->{name} eq "MApplDeliveryGroupID" ||
       $fld->{name} eq "custcontract"){
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$current->{srcparentid}});
      my ($rec,$msg)=$o->getOnlyFirst(qw(id businessteam businessteamid 
                                         systems custcontracts));
      if (defined($rec)){
         $self->autoFillAddResultCache(
            ["MApplDeliveryGroupID",
             $rec->{businessteamid},$current->{srcparentid}],
            ["MApplDeliveryGroup",
             $rec->{businessteam}, $current->{srcparentid}],
            ["MApplDeliveryItemID",
             $rec->{id}, $current->{srcparentid}]);

         my %osssystemid=();
         my %ossystemid=();
         my %mfssystemid=();
         my %mfsystemid=();
         my $sys=getModuleObject($self->Config,"itil::system");
         foreach my $s (@{$rec->{systems}}){
            my $sysid=$s->{systemid};
            if ($sysid ne ""){
               $sys->ResetFilter();
               $sys->SetFilter({id=>\$sysid});
               my $class=$sys->getVal(qw(osclass));
               if ($s->{systemsystemid} ne ""){
                  $osssystemid{$s->{systemsystemid}}++;
               }
               $ossystemid{$sysid}++;
            }
         };
         my %con=();
         foreach my $contr (@{$rec->{custcontracts}}){
            if ($contr->{custcontractcistatusid}<=4 &&
                $contr->{custcontractcistatusid}>=2){
               $con{$contr->{custcontract}}++;
            }
         }
         $self->autoFillAddResultCache(
            ["custcontract",
             [keys(%con)], $current->{srcparentid}],
            ["MSystemOSsystemsystemid",
             [keys(%osssystemid)], $current->{srcparentid}],
            ["MSystemOSDeliveryItemID",
             [keys(%ossystemid)], $current->{srcparentid}]);
      }
   }
   elsif (
          $fld->{name} eq "MMiddleWareDeliveryGroup" || 
          $fld->{name} eq "MMiddleWareDeliveryItemID" ||
          $fld->{name} eq "MMiddleWareDeliveryGroupID" ||
          $fld->{name} eq "MDBDeliveryGroup" || 
          $fld->{name} eq "MDBDeliveryItemID" ||
          $fld->{name} eq "MDBDeliveryGroupID"
         ){
      my $o=getModuleObject($self->Config,"itil::swinstance");
      $o->SetFilter({applid=>\$current->{srcparentid},
                     cistatusid=>"<=5"});
      foreach my $rec ($o->getHashList(qw(id swteam swteamid swnature))){
         if ($fld->{group} eq "MDB"){
            next if (!in_array(lc($rec->{swnature}),
                               ["mysql","mssql","postgesql","db2",
                                "oracle db server","informix"]));
         }
         if ($fld->{group} eq "MMiddleWare"){
            next if (in_array(lc($rec->{swnature}),
                              ["mysql","mssql","postgesql","db2",
                               "oracle db server","informix"]));
         }
         $self->autoFillAddResultCache(
            [$fld->{group}."DeliveryGroupID",
             $rec->{swteamid},$current->{srcparentid}],
            [$fld->{group}."DeliveryGroup",
             $rec->{swteam}, $current->{srcparentid}],
            [$fld->{group}."DeliveryItemID",
             $rec->{id}, $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MSystemOSDeliveryGroupID" ||
          $fld->{name} eq "MSystemOSDeliveryGroup"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $r=$self->autoFillGetResultCache($fld->{group}."systemsystemid",
                                          $current->{srcparentid});
      my $o=getModuleObject($self->Config,"itil::system");
      $o->SetFilter({systemid=>$r});
      foreach my $srec ($o->getHashList(qw(adminteam adminteamid))){
         if ($srec->{adminteam} ne ""){
            $self->autoFillAddResultCache(
               [$fld->{group}."DeliveryGroupID",
                $srec->{adminteamid},$current->{srcparentid}],
               [$fld->{group}."DeliveryGroup",
                $srec->{adminteam},$current->{srcparentid}]);
         }
      }
   }
   elsif ($fld->{name} eq "MHardwareOSDeliveryItemID" ||
          $fld->{name} eq "MHardwareOSDeliveryGroup" ||
          $fld->{name} eq "MHardwareOSDeliveryGroupID"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $loadfrom=$fld->{group};
      $loadfrom=~s/^MHardware/MSystem/;
      my $r=$self->autoFillGetResultCache($loadfrom."systemsystemid",
                                          $current->{srcparentid});
      if (defined($r)){
         my $o=getModuleObject($self->Config,"itil::asset");
         $o->SetFilter({systemids=>$r});
         foreach my $srec ($o->getHashList(qw(location id
                                              guardianteam guardianteamid))){
            $self->autoFillAddResultCache(
               [$fld->{group}."DeliveryItemID", 
                $srec->{id}, $current->{srcparentid}],
               [$fld->{group}."DeliveryGroup", 
                $srec->{guardianteam}, $current->{srcparentid}],
               [$fld->{group}."DeliveryGroupID",
                $srec->{guardianteamid},
                $current->{srcparentid}]);
         }
      }
   }
   elsif ($fld->{name}=~m/^.*DeliveryContactID$/){
      my $gfld=$self->getField($fld->{group}."DeliveryGroupID",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid)){
         $refid=[$refid] if (!ref($refid));
         my $o=getModuleObject($self->Config,"base::grp");
         $o->SetFilter({grpid=>$refid,
                        cistatusid=>"<=5"});
         my @uidlist=();
         foreach my $rec ($o->getHashList("users")){
            foreach my $urec (@{$rec->{users}}){
               if ($urec->{usertyp} eq "user" ||
                   $urec->{usertyp} eq "extern"){
                  push(@uidlist,$urec->{userid});
               }
            }
         }
         $self->autoFillAddResultCache([$fld->{name},
                                        \@uidlist,
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name}=~m/^.*DeliveryCountries$/){
      my (%ucount);
      if ($fld->{group} eq "MHardwareOS"){
         my $fo=$self->getField($fld->{group}."DeliveryItemID",$current);
         my $i=$fo->RawValue($current);
         if (defined($i)){
            my $o=getModuleObject($self->Config,"itil::asset");
            $o->SetFilter({id=>$i});
            my @l=$o->getHashList(qw(locationid));
            if ($#l!=-1){
               my $o=getModuleObject($self->Config,"base::location");
               $o->SetFilter({id=>[map({$_->{locationid}} @l)]});
               foreach my $rec ($o->getHashList(qw(country))){
                  $ucount{uc($rec->{country})}++;
               } 
            }
         }
      }
      $self->autoFillAddResultCache(
         [$fld->{name},
          [keys(%ucount)], $current->{srcparentid}]);
   }
   elsif ($fld->{name}=~m/^.*DeliveryAddresses$/){
      my (%uadr);
      if ($fld->{group} eq "MHardwareOS" ){
         my $fo=$self->getField($fld->{group}."DeliveryItemID",$current);
         my $i=$fo->RawValue($current);
         if (defined($i)){
            my $o=getModuleObject($self->Config,"itil::asset");
            $o->SetFilter({id=>$i});
            my @l=$o->getHashList(qw(locationid));
            if ($#l!=-1){
               my $o=getModuleObject($self->Config,"base::location");
               $o->SetFilter({id=>[map({$_->{locationid}} @l)]});
               foreach my $rec ($o->getHashList(qw(zipcode address1 location))){
                  if (defined($rec)){
                     my $adr=$rec->{zipcode};
                     if ($rec->{location} ne ""){
                        $adr.=" " if ($adr ne "");
                        $adr.=$rec->{location};
                     }
                     if ($rec->{address1} ne ""){
                        $adr.="; " if ($adr ne "");
                        $adr.=$rec->{address1};
                     }
                     if ($adr ne ""){
                        $uadr{$adr}++;
                     }
                  }
               } 
            }
         }
      }
      my $gfld=$self->getField($fld->{group}."DeliveryContactID",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid)){
         my ($rec,$msg);
         foreach my $uid (@{$refid}){
            my $adr;
            my $CacheKey="DeliveryContactAddr-".$uid;
            my $r=$self->autoFillGetResultCache($CacheKey);
            if (!defined($r)){
               my $rec=$self->resolvUserID($uid);
               if (defined($rec)){
                  $adr=$rec->{office_zipcode};
                  if ($rec->{office_location} ne ""){
                     $adr.=" " if ($adr ne "");
                     $adr.=$rec->{office_location};
                  }
                  if ($rec->{office_street} ne ""){
                     $adr.="; " if ($adr ne "");
                     $adr.=$rec->{office_street};
                  }
               }
               $adr="unknown/invalid address at '$uid'" if ($adr eq "");
               $self->autoFillAddResultCache([$CacheKey,$adr]);
               $r=$self->autoFillGetResultCache($CacheKey);
            }

            $uadr{$r->[0]}++;
         }
      }
      $self->autoFillAddResultCache(
         [$fld->{name},
          [sort(keys(%uadr))], $current->{srcparentid}]);
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}

sub resolvUserID
{
   my $self=shift;
   my $uid=shift;

   my ($rec,$msg);
   if ($uid=~m/^\d{10,20}$/){
      my $o=getModuleObject($self->Config,"base::user");
      ($rec,$msg)=$o->getOnlyFirst({userid=>\$uid},
                                    qw(office_zipcode
                                       office_location
                                       office_street));
   }
   elsif ($uid=~m/^\S{3,8}$/){
      my $o=getModuleObject($self->Config,"base::user");
      ($rec,$msg)=$o->getOnlyFirst({posix=>\$uid},
                                    qw(office_zipcode
                                       office_location
                                       office_street));
   }
   return($rec);
}

sub currentModules
{
   my $self=shift;
   my $current=shift;

   my $m=$self->getField("modules")->RawValue($current);
   return(@$m);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default),@{$self->{allModules}},qw(summary misc source qc));
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/applnor.jpg?".$cgi->query_string());
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::applnor");
}















1;
