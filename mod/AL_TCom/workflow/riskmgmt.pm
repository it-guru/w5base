package AL_TCom::workflow::riskmgmt;
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
use kernel::WfClass;
use itil::workflow::riskmgmt;
use Text::Wrap qw($columns &wrap);

@ISA=qw(itil::workflow::riskmgmt);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      $self->SUPER::getDynamicFields(@_),
      new kernel::Field::Select(  name          =>'extdescdtagmonetaryimpact',
                                  label         =>'Total damage within DTAG '.
                                                  '(form an estimate)',
                                  value         =>['','0','1','2','3'],
                                  default       =>'',
                                  htmleditwidth =>'200',
                                  transprefix   =>'DTAGMONIMP.',
                                  group         =>'riskdesc',
                                  container     =>'headref'),

      new kernel::Field::Select(  name          =>'extdesctelitmonetaryimpact',
                                  label         =>'Total damage within TelIT '.
                                                  '(form an estimate)',
                                  value         =>['','0','1','2','3','4'],
                                  default       =>'',
                                  htmleditwidth =>'200',
                                  transprefix   =>'TELITMONIMP.',
                                  group         =>'riskdesc',
                                  container     =>'headref'),


      ));

}


sub getMandatoryParamFields
{
   my $self=shift;

   return(qw(extdescriskdowntimedays extdescriskoccurrency 
             extdescarisedate extdescdtagmonetaryimpact 
             extdesctelitmonetaryimpact));
}




sub isRiskParameterComplete
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(0) if (!$self->SUPER::isRiskParameterComplete($oldrec,$newrec));

   if (effVal($oldrec,$newrec,"extdescdtagmonetaryimpact") eq ""){
      return(0);
   }
   return(1);


}


sub RiskEstimation
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $st=shift;

   $self->SUPER::RiskEstimation($current,$mode,$st);

   my $id=$current->{id};
   my $cdate=CalcDateDuration($current->{createdate},NowStamp("en"));

   my $relations=$self->getParent->getFieldRawValue("relations",$current);

   my @childid=map({
      $_->{dstwfid}
   } grep({
      $_->{dststate}<20 && $_->{name} eq "riskmesure"
   } @{$relations}));



   my $wf=$self->getParent->Clone();

   $wf->SetFilter({id=>\@childid});
   my $outoftime=0;
   foreach my $mrec ($wf->getHashList(qw(name 
                                         wffields.plannedstart 
                                         wffields.plannedend 
                                         shortactionlog))){
      if ($#{$st->{raw}->{riskmgmtcondition}}!=-1){
         push(@{$st->{raw}->{riskmgmtcondition}},"<hr>");
      }
      if ($mrec->{plannedend} ne ""){
         my $t=CalcDateDuration($mrec->{plannedend},NowStamp("en"));
         if ($t->{totalminutes}>5){
            $outoftime++;
         }
      }
      
      push(@{$st->{raw}->{riskmgmtcondition}},"<b>".$mrec->{name}."</b>");
      push(@{$st->{raw}->{riskmgmtcondition}},
           $mrec->{plannedstart}."-".$mrec->{plannedend});
      my $state;
      foreach my $arec (@{$mrec->{shortactionlog}}){
         if ($arec->{name} eq "wfaddnote"){
            $state=$arec->{comments};
         }
      }
      if (defined($state)){
         push(@{$st->{raw}->{riskmgmtcondition}},$state);
      }
   }

   if ($outoftime){
      push(@{$st->{raw}->{riskmgmtestimation}},
           $self->T("measure out of time"));

   }

   if ($current->{stateid}>1){
      if ($#{$relations}==-1){
         push(@{$st->{raw}->{riskmgmtestimation}},
              $self->T("no measure workflows"));
      }
   }

   my $incompl=0;
   foreach my $vname (qw(extdescriskoccurrency 
                         extdescdtagmonetaryimpact
                         itrmcriticality 
                         extdescarisedate)){
      if ($self->getParent->getFieldRawValue("wffields.".$vname,
                                                      $current) eq ""){
         $incompl++;
      }
   }



   if ($cdate->{days}>2){
      if ($incompl){
         push(@{$st->{raw}->{riskmgmtestimation}},
              $self->T("incomplete risk data"));
      }
   }
   if ($#{$st->{raw}->{riskmgmtestimation}}==-1){
      push(@{$st->{raw}->{riskmgmtestimation}},"OK");
   }

}




sub calculateRiskState
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $st=shift;

   $self->SUPER::calculateRiskState($current,$mode,$st);


   my $v={};
   foreach my $vname (qw(extdescriskoccurrency 
                         extdescdtagmonetaryimpact
                         itrmcriticality 
                         extdescarisedate)){
      $v->{$vname}=$self->getParent->getFieldRawValue("wffields.".$vname,
                                                      $current);
   }

   if ($v->{extdescarisedate} eq ""){
      push(@{$st->{raw}->{riskmgmtcalclog}},"ERROR: missing date of rise");
   }
   if ($v->{extdescriskoccurrency} eq ""){
      push(@{$st->{raw}->{riskmgmtcalclog}},"ERROR: missing pct occurrency");
   }
   if ($v->{extdescdtagmonetaryimpact} eq ""){
      push(@{$st->{raw}->{riskmgmtcalclog}},"ERROR: missing DTAG mony impact");
   }
   if ($#{$st->{raw}->{riskmgmtcalclog}}!=-1){
      $st->{raw}->{riskmgmtcolor}="hotpink";
      $st->{raw}->{riskmgmtpoints}="???";
   }
   else{
      my $d=CalcDateDuration(NowStamp("en"),$v->{extdescarisedate});
      $v->{extdescarisedatedays}=$d->{days};

      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: days to rise:  $v->{extdescarisedatedays}");

      if ($v->{extdescarisedatedays}<30){
         $v->{extdescarisedatedayspoint}=3;
      }
      elsif ($v->{extdescarisedatedays}<6*30){
         $v->{extdescarisedatedayspoint}=2;
      }
      elsif ($v->{extdescarisedatedays}<12*30){
         $v->{extdescarisedatedayspoint}=1;
      }
      else{
         $v->{extdescarisedatedayspoint}=0;
      }

      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: days to rise in points :  ".
           "$v->{extdescarisedatedayspoint}");



      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: DTAG monetary impact row number ".
           "(wffields.extdescdtagmonetaryimpact): ".
           "$v->{extdescdtagmonetaryimpact}");
      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: risk of occurrency (wffields.extdescriskoccurrency):".
           " $v->{extdescriskoccurrency}");
      if (in_array([0,1,2],$v->{extdescriskoccurrency})){
         $v->{extdescriskoccurrencylevel}=0;
      }
      elsif (in_array([3,4],$v->{extdescriskoccurrency})){
         $v->{extdescriskoccurrencylevel}=1;
      }
      elsif (in_array([5,6],$v->{extdescriskoccurrency})){
         $v->{extdescriskoccurrencylevel}=2;
      }
      elsif (in_array([7,8],$v->{extdescriskoccurrency})){
         $v->{extdescriskoccurrencylevel}=3;
      }
      else{
         $v->{extdescriskoccurrencylevel}=4;
      }

      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: risk level ".
           "column number $v->{extdescriskoccurrencylevel}");


      my $mtrx=[
             [ qw  (    0    0    1    2    3 ) ],
             [ qw  (    1    2    3    4    5 ) ],
             [ qw  (    2    4    6    8    9 ) ],
             [ qw  (    3    5    7    9   10 ) ]
      ];
      $v->{magicriskkey}=
         $mtrx->[$v->{extdescdtagmonetaryimpact}]->
                [$v->{extdescriskoccurrencylevel}];
      push(@{$st->{raw}->{riskmgmtcalclog}},
           "INFO: magic risk key $v->{magicriskkey}");

      $st->{raw}->{riskmgmtpoints}=$v->{magicriskkey}+
                                   $v->{extdescarisedatedayspoint}+
                                   $v->{itrmcriticality};

      if ($st->{raw}->{riskmgmtpoints}<=7){
         $st->{raw}->{riskmgmtcolor}="green";
      }
      elsif ($st->{raw}->{riskmgmtpoints}<=12){
         $st->{raw}->{riskmgmtcolor}="yellow";
      }
      else{
         $st->{raw}->{riskmgmtcolor}="red";
      }
   }


}





1;
