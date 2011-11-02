package AL_TCom::event::mkp800;
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
use kernel::date;
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("mkp800","mkp800",timeout=>12000);
   $self->RegisterEvent("mkp800specialxls","mkp800specialxls");
   return(1);
}


sub mkp800
{
   my $self=shift;
   my %param=@_;
   my $app=$self->getParent;
   my @monthlist;
   my $xlsexp={};

   #
   # ACHTUNG: Die Monatsgrenze für P800 Reports ist GMT und nicht CET!!!
   #
   $ENV{LANG}="de";
   $param{customer}="DTAG.TDG"    if (!defined($param{customer}));
   $param{timezone}="GMT"         if (!defined($param{timezone}));
   if (defined($param{month})){
      if (my ($sM,$sY)=$param{month}=~m/^(\d+)\/(\d+)$/){
         $sM=undef if ($sM<1);
         $sM=undef if ($sM>12);
         $sY=undef if ($sY<2000);
         $sY=undef if ($sY>2100);
         if (!defined($sM) || !defined($sY)){
            msg(ERROR,"illegal month $param{month}");
            return({exicode=>1});
         }
         my $eM=$sM-1;
         my $eY=$sY;
         if ($sM==1){
            $eM=12;
            $eY=$sY-1;
         }
         @monthlist=(sprintf("%02d/%04d",$eM,$eY),$param{month});
      }
      elsif (defined($param{month})){
         msg(ERROR,"illegal month $param{month}");
         return({exicode=>1});
      }
   }
   else{
      my ($year,$month,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      my $eM=$month;
      my $eY=$year;
      my $sM=$month-1;
      my $sY=$year;
      if ($eM==1){
         $sM=12;
         $sY=$eY-1;
      }
      @monthlist=(sprintf("%02d/%04d",$sM,$sY),
                  sprintf("%02d/%04d",$month,$year));
   }
   my $bflexxwf=getModuleObject($self->Config,"tsbflexx::ifworkflow");
   if (!defined($bflexxwf) || !$bflexxwf->Ping()){
      msg(ERROR,"can not connect to b:flexx inteface database");
      return({exicode=>1});
   }

   my $startnow=$app->ExpandTimeExpression("now","en","GMT");
   msg(INFO,"start operation with time = $startnow");
   my %p800special=();
   foreach my $month (@monthlist){
      my ($sM,$sY)=$month=~m/^(\d+)\/(\d+)$/;
      my $eM=$sM+1;
      my $eY=$sY;
      if ($sM==12){
         $eM=1;
         $eY=$sY+1;
      }
      my $start=$month;
      my $end=sprintf("%02d/%04d",$eM,$eY);
      my $starttime=$app->ExpandTimeExpression($start,"en",$param{timezone});
      my $endtime=$app->ExpandTimeExpression($end."-1s","en",$param{timezone});

     
      msg(DEBUG,"Report : $start\n");
      msg(DEBUG,"Report start ($start): >=$starttime\n");
      msg(DEBUG,"Report end   ($end): <=$endtime\n");
     
      my @id=(); 
      my $wf=getModuleObject($self->Config,"base::workflow");
      $wf->ResetFilter();
      $wf->SetCurrentOrder("NONE");
      $wf->ResetFilter();
      $wf->SetCurrentOrder("NONE");
      $wf->SetCurrentView(qw(id affectedcontractid 
                             wffields.tcomcodrelevant
                             class stateid eventend ));
      $wf->SetFilter(eventend=>"\">=$starttime\" AND \"<=$endtime\"",
                     class=>[grep(/^AL_TCom::.*$/,keys(%{$wf->{SubDataObj}}))]);
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
                ( ($rec->{stateid}>=17 && $rec->{tcomcodrelevant} eq "yes") ||
                  ($rec->{stateid}>=16 && 
                   $rec->{class} eq "AL_TCom::workflow::businesreq"))){
               push(@id,$rec->{id});
               if (int($#id/1000.0)==$#id/1000.0){
                  msg(INFO,"loaded ".($#id));
               }
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      my %p800=();
      while (my $id=shift(@id)){
         $wf->ResetFilter();
         $wf->SetFilter({id=>\$id});
         my ($rec,$msg)=$wf->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
                ( ($rec->{stateid}>=17 && $rec->{tcomcodrelevant} eq "yes") ||
                  ($rec->{stateid}>=16 && 
                   $rec->{class} eq "AL_TCom::workflow::businesreq"))){
               $self->processRec($start,\%p800,$rec);
               $self->processRecSpecial($start,\%p800special,$rec,
                                        $xlsexp,$bflexxwf,$monthlist[1]);
            }
         }
      }
     
      my $now=$app->ExpandTimeExpression("now","en","CET");
      my $contr=getModuleObject($self->Config,"itil::custcontract");
      $contr->SetFilter({cistatusid=>[3,4],
                         customer=>"$param{customer} $param{customer}.*"});
      foreach my $contrrec ($contr->getHashList(qw(id))){
         $p800{$contrrec->{id}}={} if (!defined($p800{$contrrec->{id}}));
      }
      my $appl=getModuleObject($self->Config,"itil::appl");
      foreach my $cid (keys(%p800)){
         my $rec=$p800{$cid};
         $contr->ResetFilter;
         $contr->SetFilter(id=>\$cid);
         my ($contrrec,$msg)=$contr->getOnlyFirst(qw(ALL));
         next if (!defined($contrrec)); 
         $rec->{affectedapplicationid}=[];
         $rec->{affectedapplication}=[];
         if (ref($contrrec->{applications}) eq "ARRAY"){
            foreach my $apprec (@{$contrrec->{applications}}){
               if (defined($apprec->{applid})){
                  push(@{$rec->{affectedapplicationid}},$apprec->{applid});
               }
               if (defined($apprec->{appl})){
                  push(@{$rec->{affectedapplication}},$apprec->{appl});
               }
            }
         }
         $rec->{p800_app_applicationcount}=$#{$rec->{affectedapplicationid}}+1; 
         foreach my $applid (@{$rec->{affectedapplicationid}}){
            $appl->SetFilter(id=>\$applid);
            my ($arec,$msg)=$appl->getOnlyFirst("interfaces","systems");
            if (defined($arec) && defined($arec->{interfaces}) &&
                ref($arec->{interfaces}) eq "ARRAY"){
               foreach my $irec (@{$arec->{interfaces}}){
                  $rec->{p800_app_interfacecount}++;
               }
            }
            if (defined($arec) && defined($arec->{systems}) &&
                ref($arec->{systems}) eq "ARRAY"){
               foreach my $srec (@{$arec->{systems}}){
                  $rec->{p800_sys_count}++;
               }
            }
         }
         $rec->{srcsys}=$self->Self;
         $rec->{srcid}="${start}-".$cid;
         $rec->{class}='AL_TCom::workflow::P800';
         $rec->{step}='AL_TCom::workflow::P800::dataload';
         $rec->{stateid}=1;
         $rec->{createdate}=$now;
         $rec->{srcload}=$now;
         $rec->{closedate}=undef;
         $rec->{eventstart}=$starttime;
         $rec->{eventend}=$endtime;
         $rec->{openuser}=undef;
         $rec->{affectedcontractid}=[$contrrec->{id}];
         $rec->{affectedcontract}=[$contrrec->{name}];
         $rec->{name}="P800 - $start - ".$contrrec->{name};
         foreach my $v (qw(p800_app_changecount_customer
                           p800_app_change_customerwt
                           p800_app_incidentwt
                           p800_app_changewt
                           p800_sys_count
                           p800_app_applicationcount p800_app_interfacecount
                           p800_app_changecount p800_app_incidentcount
                           p800_app_specialcount p800_app_speicalwt 
                           p800_app_customerwt
                        )){
            $rec->{$v}=0 if (!defined($rec->{$v}));
         } 
         if ($contrrec->{fullname} ne ""){
            $rec->{name}.=" - ".$contrrec->{fullname};
         }
     
         $wf->SetCurrentView(qw(ALL));
         $wf->SetFilter({srcsys=>\$rec->{srcsys},
                         srcid=>\$rec->{srcid}});
         my $idfname=$wf->IdField()->Name();
         my $found=0;
         $wf->ForeachFilteredRecord(sub{
               my $oldrec=$_;
               $found++;
               if ($oldrec->{stateid}<20){
                  $wf->ValidatedUpdateRecord($oldrec,$rec,
                                               {$idfname=>$oldrec->{$idfname}});
               }
         });
         if (!$found){
            my $id=$wf->ValidatedInsertRecord($rec);
         }
      }
      my $srcsys=$self->Self;
      $wf->SetFilter(srcsys=>\$srcsys,srcid=>"$start-*",
                     srcload=>"\"<$now\"",stateid=>\'1',
                     class=>\'AL_TCom::workflow::P800',
                     step=>\'AL_TCom::workflow::P800::dataload');
      $wf->ForeachFilteredRecord(sub{
          $wf->ValidatedDeleteRecord($_);
      });
      if (defined($monthlist[1]) && $month eq $monthlist[1]){
         foreach my $cid (keys(%{$p800special{$month}})){
            my $rec=$p800special{$month}->{$cid};
            $contr->ResetFilter;
            $contr->SetFilter(id=>\$cid);
            my ($contrrec,$msg)=$contr->getOnlyFirst(qw(ALL));
            next if (!defined($contrrec)); 
            $rec->{affectedapplicationid}=[];
            $rec->{affectedapplication}=[];
            if (ref($contrrec->{applications}) eq "ARRAY"){
               foreach my $apprec (@{$contrrec->{applications}}){
                  if (defined($apprec->{applid})){
                     push(@{$rec->{affectedapplicationid}},$apprec->{applid});
                  }
                  if (defined($apprec->{appl})){
                     push(@{$rec->{affectedapplication}},$apprec->{appl});
                  }
               }
            }
            $rec->{srcsys}=$self->Self;
            $rec->{srcid}="${start}-".$cid."-special";
            $rec->{class}='AL_TCom::workflow::P800special';
            $rec->{step}='AL_TCom::workflow::P800special::dataload';
            $rec->{stateid}=21;
            $rec->{createdate}=$now;
            $rec->{srcload}=$now;
            $rec->{closedate}=$now;

            my $rstart=$app->ExpandTimeExpression("$month+19d-1M","en",
                                                  $param{timezone});
            my $rend=$app->ExpandTimeExpression("$month+19d-1s","en",
                                                $param{timezone});
      
            $rec->{eventstart}=$rstart;
            $rec->{eventend}=$rend;
            $rec->{openuser}=undef;
            $rec->{affectedcontractid}=[$contrrec->{id}];
            $rec->{affectedcontract}=[$contrrec->{name}];
            $rec->{name}="P800 Sonderleistung - $start - ".$contrrec->{name};
            foreach my $v (qw(p800_app_speicalwt 
                           )){
               $rec->{$v}=0 if (!defined($rec->{$v}));
            } 
            if ($contrrec->{fullname} ne ""){
               $rec->{name}.=" - ".$contrrec->{fullname};
            }
           
            $wf->SetCurrentView(qw(ALL));
            $wf->SetFilter({srcsys=>\$rec->{srcsys},
                            srcid=>\$rec->{srcid}});
            my $idfname=$wf->IdField()->Name();
            my $found=0;
            $wf->ForeachFilteredRecord(sub{
                  my $oldrec=$_;
                  $found++;
                  $wf->ValidatedUpdateRecord($oldrec,$rec,
                                              {$idfname=>$oldrec->{$idfname}});
            });
            if (!$found){
               my $id=$wf->ValidatedInsertRecord($rec);
            }

         }
         my $srcsys=$self->Self;
         $wf->SetFilter(srcsys=>\$srcsys,srcid=>"$start-*",
                        srcload=>"\"<$now\"",stateid=>\'21',
                        class=>\'AL_TCom::workflow::P800special',
                        step=>\'AL_TCom::workflow::P800special::dataload');
         $wf->ForeachFilteredRecord(sub{
             $wf->ValidatedDeleteRecord($_);
         });
         $self->xlsFinish($xlsexp,$month);  # stores the xls export in webfs
         $self->bflexxRawFinish($bflexxwf,$startnow,$starttime); 
      }
   }
   return({exitcode=>0});
}

sub processRec
{
   my $self=shift;
   my $start=shift;
   my $p800=shift;
   my $rec=shift;
   my $bflexxwf=shift;


   msg(DEBUG,"process %s srcid=%s",$rec->{id},$rec->{srcid});
   for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
      my $cid=$rec->{affectedcontractid}->[$c];
      $p800->{$cid}={} if (!defined($p800->{$cid}));
      if (!defined($rec->{headref}->{tcomworktime})){
          $rec->{headref}->{tcomworktime}=[0]; 
      }
      if (!defined($rec->{headref}->{tcomworktimespecial})){
          $rec->{headref}->{tcomworktimespecial}=[0]; 
      }
      if (ref($rec->{headref}->{tcomworktime}) eq "ARRAY"){
         $rec->{headref}->{tcomworktime}=$rec->{headref}->{tcomworktime}->[0]; 
      }
      if (ref($rec->{headref}->{tcomworktimespecial}) eq "ARRAY"){
         $rec->{headref}->{tcomworktimespecial}=
                 $rec->{headref}->{tcomworktimespecial}->[0]; 
      }
      if ($rec->{class}=~m/::change$/){
         $p800->{$cid}->{p800_app_changecount}++;
         $p800->{$cid}->{p800_app_changewt}+=$rec->{headref}->{tcomworktime};
         if ($rec->{tcomcodcause} ne "db.base.base" &&
             $rec->{tcomcodcause} ne "appl.base.base"){
            $p800->{$cid}->{p800_app_changecount_customer}+=1;
            $p800->{$cid}->{p800_app_customerwt}+=
                            $rec->{headref}->{tcomworktime};
            $p800->{$cid}->{p800_app_change_customerwt}+=
                            $rec->{headref}->{tcomworktime};
         }
      }
      if ($rec->{class}=~m/::diary$/ || $rec->{class}=~m/::businesreq$/){
         if ($rec->{tcomcodcause} ne "db.base.base" &&
             $rec->{tcomcodcause} ne "appl.base.base"){
            $p800->{$cid}->{p800_app_specialcount}++;
            $p800->{$cid}->{p800_app_speicalwt}+=
                           $rec->{headref}->{tcomworktime};
            $p800->{$cid}->{p800_app_customerwt}+=
                           $rec->{headref}->{tcomworktime};
         }
      }
      if ($rec->{class}=~m/::incident$/){
         $p800->{$cid}->{p800_app_incidentcount}++;
         $p800->{$cid}->{p800_app_incidentwt}+=$rec->{headref}->{tcomworktime};
         if ($rec->{tcomcodcause} ne "db.base.base" &&
             $rec->{tcomcodcause} ne "appl.base.base"){
            $p800->{$cid}->{p800_app_speicalwt}+=
                                   $rec->{headref}->{tcomworktimespecial};
         }
      }
   }
}


sub processRecSpecial
{
   my $self=shift;
   my $start=shift;
   my $p800=shift;
   my $rec=shift;
   my $xlsexp=shift;
   my $bflexxwf=shift;
   my $specialmon=shift;

   msg(DEBUG,"special process %s:%s end=%s",
              $rec->{id},$rec->{srcid},$rec->{eventend});
   msg(DEBUG,"special process %s: tcomcodcause=%s",
              $rec->{id},$rec->{tcomcodcause});
   if ((my ($eY,$eM,$eD,$eh,$em,$es)=$rec->{eventend}=~
          m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
      my ($wY,$wM,$wD,$wh,$wm,$ws)=($eY,$eM,$eD,$eh,$em,$es);
      eval('($wY,$wM,$wD)=Add_Delta_YMD("GMT",$wY,$wM,$wD,0,1,-19);');
      if ($@ eq ""){
         my $mon=sprintf("%02d/%04d",$wM,$wY);
         msg(DEBUG,"special process %s: report month =%s",$rec->{id},$mon);
         if ($rec->{tcomcodcause} ne "db.base.base" &&
             $rec->{tcomcodcause} ne "appl.base.base"){
            msg(DEBUG,"special process %s: is special",$rec->{id});
            $rec->{headref}->{specialt}=0;
            #
            # Da in Changes und Incidents verschiedene Felder verwendet wurden
            #
            $rec->{headref}->{specialt}+=$rec->{headref}->{tcomworktime};
            $rec->{headref}->{specialt}+=$rec->{headref}->{tcomworktimespecial};
            
            if ($mon eq $specialmon){
               $self->xlsExport($xlsexp,$rec,$mon,$eY,$eM,$eD);
               for(my $c=0;$c<=$#{$rec->{affectedcontractid}};$c++){
                  my $cid=$rec->{affectedcontractid}->[$c];
                  my $wt=$rec->{headref}->{specialt};
                  msg(DEBUG,"special process %s: for contractid=%s wt=%d",
                            $rec->{id},$cid,$wt);
                  if ($wt>0){
                     $p800->{$mon}={} if (!defined($p800->{$mon}));
                     $p800->{$mon}->{$cid}={} if (!defined($p800->{$mon}->{$cid}));
                     msg(DEBUG,"report special process $cid");
                     $p800->{$mon}->{$cid}->{p800_app_speicalwt}+=$wt;
                     if (!defined($p800->{$mon}->{$cid}->{additional})){
                        $p800->{$mon}->{$cid}->{additional}={wfheadid=>[],
                                                             srcid=>[]};
                     }
                     push(@{$p800->{$mon}->{$cid}->{additional}->{wfheadid}},
                          $rec->{id});
                     push(@{$p800->{$mon}->{$cid}->{additional}->{srcid}},
                          $rec->{srcid}) if ($rec->{srcid} ne "");
                  }
               }
            }
         }
         $self->bflexxRawExport($bflexxwf,$rec,$mon,$eY,$eM,$eD);
      }
   }
}



sub bflexxRawFinish
{
   my $self=shift;
   my $bflexxwf=shift;
   my $now=shift;
   my $starttime=shift;

   my $rec;
   do{      # seltsamer cleanup - aber nur so funktionierts mit ODBC und MSSQL
      $bflexxwf->ResetFilter(); 
      $bflexxwf->SetFilter(srcload=>"\"<$now\"",eventend=>"\">$starttime\"");
      ($rec)=$bflexxwf->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         $bflexxwf->ValidatedDeleteRecord($rec);
      }
   }until(!defined($rec));
}

sub bflexxRawExport
{
   my $self=shift;
   my $bflexxwf=shift;
   my $rec=shift;
   my $repmon=shift;
   my ($wY,$wM,$wD)=@_;


   my $bflexxwf=getModuleObject($self->Config,"tsbflexx::ifworkflow");
   if (defined($bflexxwf)){
      my $ag=$rec->{affectedapplication};
      $ag=[$ag] if (!ref($ag) eq "ARRAY");
      my $vert=$rec->{affectedcontract};
      $vert=[$vert] if (!ref($vert) eq "ARRAY");

      my $cause=$rec->{tcomcodcause};
      $cause=join(", ",@$cause) if (ref($cause) eq "ARRAY");

      my $comments=$rec->{tcomcodcomments};
      $comments=join("\n",@$comments) if (ref($comments) eq "ARRAY");

      my $extid=$rec->{tcomexternalid};
      $extid=join("\n",@$extid) if (ref($extid) eq "ARRAY");
      if ($extid eq ""){
         $extid=$rec->{customerrefno};
      }
      $extid=join("\n",@$extid) if (ref($extid) eq "ARRAY");
      if (!($extid=~m/W5B:/)){
         if ($extid ne ""){
            $extid="W5B:".$rec->{id}." ".$extid;
         }
         else{
            $extid="W5B:".$rec->{id};
         }
      }

      my $specialt=$rec->{headref}->{specialt};
      $specialt=join(", ",@$specialt) if (ref($specialt) eq "ARRAY");

      if (my ($m,$y)=$repmon=~m/^(\d+)\/(\d{4})/){
         $repmon=sprintf("%04d%02d",$y,$m);
      }
      foreach my $vertno (@$vert){
         if ($vertno ne ""){
            my $newrec={name=>$rec->{name},
                        eventend=>$rec->{eventend},
                        w5baseid=>$rec->{id},
                        class=>$rec->{class},
                        tcomworktime=>$specialt,
                        tcomcodcause=>$cause,
                        tcomcodcomments=>$comments,
                        tcomexternalid=>limitlen($extid,40,1),
                        appl=>join(", ",@$ag),
                        custcontract=>$vertno,
                        srcload=>NowStamp("en"),
                        srcid=>$rec->{srcid},
                        month=>$repmon,
                        srcsys=>$rec->{srcsys}};
            my $bflexxwf=getModuleObject($self->Config,"tsbflexx::ifworkflow");
            $bflexxwf->SetFilter({w5baseid=>\$newrec->{w5baseid},
                                  custcontract=>\$vertno});
            my ($oldrec,$msg)=$bflexxwf->getOnlyFirst(qw(ALL));


            if (defined($oldrec)){
               $bflexxwf->ValidatedUpdateRecord($oldrec,$newrec,
                                                {w5baseid=>\$newrec->{w5baseid},
                                                 custcontract=>\$vertno} );
            }
            else{
               $bflexxwf->ValidatedInsertRecord($newrec);
            }
            # fifi
            #$bflexxwf->ValidatedInsertOrUpdateRecord($newrec,
            #            {w5baseid=>\$newrec->{w5baseid},
            #             custcontract=>\$vertno});
         }   
      }   
   }
}


sub xlsExport
{
   my $self=shift;
   my $xlsexp=shift;
   my $rec=shift;
   my $repmon=shift;
   my ($wY,$wM,$wD)=@_;

   if (!defined($xlsexp->{xls})){
      if (!defined($xlsexp->{xls}->{state})){
         eval("use Spreadsheet::WriteExcel::Big;");
         $xlsexp->{xls}->{state}="bad";
         if ($@ eq ""){
            $xlsexp->{xls}->{filename}="/tmp/out.$$.xls";
            $xlsexp->{xls}->{workbook}=Spreadsheet::WriteExcel::Big->new(
                                                  $xlsexp->{xls}->{filename});
            if (defined($xlsexp->{xls}->{workbook})){
               $xlsexp->{xls}->{state}="ok";
               $xlsexp->{xls}->{worksheet}=$xlsexp->{xls}->{workbook}->
                                           addworksheet("P800 Sonderleistung");
               $xlsexp->{xls}->{format}->{default}=$xlsexp->{xls}->{workbook}->
                                                   addformat(text_wrap=>1,
                                                             align=>'top');
               $xlsexp->{xls}->{format}->{header}=$xlsexp->{xls}->{workbook}->
                                                   addformat(text_wrap=>1,
                                                             align=>'top',
                                                             bold=>1);
               $xlsexp->{xls}->{line}=0;
               my $ws=$xlsexp->{xls}->{worksheet};

               $ws->write($xlsexp->{xls}->{line},0,
                          "Tag.Monat.Jahr (GMT)",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(0,0,17);

               $ws->write($xlsexp->{xls}->{line},1,
                          "AG-Name",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(1,1,40);

               $ws->write($xlsexp->{xls}->{line},2,
                          "Vertrag Nr.",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(2,2,20);

               $ws->write($xlsexp->{xls}->{line},3,
                          "ID im Quellsystem",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(3,3,18);

               $ws->write($xlsexp->{xls}->{line},4,
                          "Ist Sunden",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(4,4,12);

               $ws->write($xlsexp->{xls}->{line},5,
                          "Tätigkeit (ID)",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(5,5,30);

               $ws->write($xlsexp->{xls}->{line},6,
                          "Servicemodul",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(6,6,30);

               $ws->write($xlsexp->{xls}->{line},7,
                          "Leistungs-Typ",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(7,7,30);

               $ws->write($xlsexp->{xls}->{line},8,
                          "Tätigkeit",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(8,8,30);

               $ws->write($xlsexp->{xls}->{line},9,
                          "Tätigkeit (Eingabe)",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(9,9,30);

               $ws->write($xlsexp->{xls}->{line},10,
                          "Beschreibung",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(10,10,140);

               $ws->write($xlsexp->{xls}->{line},11,
                          "ExternalID",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(11,11,18);

               $ws->write($xlsexp->{xls}->{line},12,
                          "Bemerkungen",
                          $xlsexp->{xls}->{format}->{header});
               $ws->set_column(12,12,30);

               $xlsexp->{xls}->{line}++;
            }
         }
         
      }
   }
   if (defined($xlsexp->{xls}) && $rec->{headref}->{specialt}>0){
      my $ag=$rec->{affectedapplication};
      $ag=[$ag] if (!ref($ag) eq "ARRAY");
      my $vert=$rec->{affectedcontract};
      $vert=[$vert] if (!ref($vert) eq "ARRAY");
      my $ws=$xlsexp->{xls}->{worksheet};
      my $srcid=$rec->{srcid};
      $srcid=$rec->{id} if ($srcid eq "");
      my $col=1;
      $ws->write($xlsexp->{xls}->{line},0,
           sprintf("%02d.%02d.%04d",$wD,$wM,$wY),
           $xlsexp->{xls}->{format}->{default});
      $ws->write_string($xlsexp->{xls}->{line},$col++,
           join(", ",@$ag),
           $xlsexp->{xls}->{format}->{default});
      $ws->write_string($xlsexp->{xls}->{line},$col++,
           join(", ",@$vert),
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},$col++,
           $srcid,
           $xlsexp->{xls}->{format}->{default});
      $ws->write($xlsexp->{xls}->{line},$col++,
           $rec->{headref}->{specialt}/60,
           $xlsexp->{xls}->{format}->{default});

      my $cause=$rec->{headref}->{tcomcodcause};
      $cause=join("",@$cause) if (ref($cause) eq "ARRAY");

      $ws->write_string($xlsexp->{xls}->{line},$col++,$cause,
           $xlsexp->{xls}->{format}->{default});


      my $smodule;
      if (my ($t)=$cause=~m/^(\S+?)\./){
         $smodule=$self->getParent->T($t,"AL_TCom::lib::workflow");
      }
      $ws->write_string($xlsexp->{xls}->{line},$col++,$smodule,
           $xlsexp->{xls}->{format}->{default});

      my $styp;
      if (my ($t)=$cause=~m/(\.\S+?\.)/){
         $styp=$self->getParent->T($t,"AL_TCom::lib::workflow");
      }
      $ws->write_string($xlsexp->{xls}->{line},$col++,$styp,
           $xlsexp->{xls}->{format}->{default});

      my $scause;
      if (my ($t)=$cause=~m/^\S+\.\S+(\.\S+)$/){
         $scause=$self->getParent->T($t,"AL_TCom::lib::workflow");
      }
      $ws->write_string($xlsexp->{xls}->{line},$col++,$scause,
           $xlsexp->{xls}->{format}->{default});


      $cause=$self->getParent->T($cause,"AL_TCom::lib::workflow");
      $ws->write_string($xlsexp->{xls}->{line},$col++,$cause,
           $xlsexp->{xls}->{format}->{default});
      my $name=$rec->{name};
      if ($self->getParent->Config->Param("UseUTF8")){
         $name=utf8($name)->latin1();
      }
      $ws->write_string($xlsexp->{xls}->{line},$col++,$name,
           $xlsexp->{xls}->{format}->{default});

      my $extid=$rec->{headref}->{tcomexternalid};
      $extid=join("",@$extid) if (ref($extid) eq "ARRAY");
      $ws->write_string($xlsexp->{xls}->{line},$col++,
           $extid,
           $xlsexp->{xls}->{format}->{default});

      my $comments=$rec->{tcomcodcomments};
      $comments=join("\n",@$comments) if (ref($comments) eq "ARRAY");
      $ws->write_string($xlsexp->{xls}->{line},$col++,
           $comments,
           $xlsexp->{xls}->{format}->{default});

      $xlsexp->{xls}->{line}++;
   }
}


sub xlsFinish
{
   my $self=shift;
   my $xlsexp=shift;
   my $repmon=shift;

   if (defined($xlsexp->{xls}) && $xlsexp->{xls}->{state} eq "ok"){
      $xlsexp->{xls}->{workbook}->close(); 
      my $file=getModuleObject($self->Config,"base::filemgmt");
      $repmon=~s/\//./g;
      my $filename=$repmon.".xls";
      if (open(F,"<".$xlsexp->{xls}->{filename})){
         my $dir="TSI-Connect/DTAG.TDG/ICTO-Sonderleistungsreports";
         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                               parent=>$dir,
                                               file=>\*F},
                                              {name=>\$filename,
                                               parent=>\$dir});
      }
      else{
         msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
      }
   }
}


sub mkp800specialxls
{
   my $self=shift;
   my %param=@_;

   msg(DEBUG,"param=%s",Dumper(\%param));
   my $o=getModuleObject($self->Config,"AL_TCom::p800specialxls");
   msg(DEBUG,"o=$o");

   return({exitcode=>0,msg=>'OK'});
}


1;
