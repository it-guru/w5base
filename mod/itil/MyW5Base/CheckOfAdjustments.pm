package itil::MyW5Base::CheckOfAdjustments;
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
use kernel::MyW5Base;
use Text::ParseWords;
@ISA=qw(kernel::MyW5Base);

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
   if (!exists($self->{Context})){
      $self->{Context}={};
   }
   my $MyW5BaseContext=$self->{Context};
   
   if (!exists($MyW5BaseContext->{CheckOfChanges})){
      $MyW5BaseContext->{CheckOfChanges}={};
   }
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   $self->{appl}=getModuleObject($self->getParent->Config,"itil::appl");

   $self->{Field}->{from}=new kernel::Field::Date(
                Parent        =>$self,
                name          =>'from',
                label         =>'From');
   $self->{Field}->{from}->setParent($self);

   $self->{Field}->{to}=new kernel::Field::Date(
                Parent        =>$self, 
                name          =>'to',
                label         =>'To');
   $self->{Field}->{to}->setParent($self);

   $self->{Val}->{ifcheck}=["none","moderat","full"];


   $self->{DataObj}->AddFields(
      new kernel::Field::Percent(
                name          =>'targetmatchlevel',
                label         =>'target match level',
                searchable    =>0,
                htmldetail    =>'0',
                htmlwidth     =>'50px',
                depend        =>['affectedapplication','description','name'],
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return(sprintf("%03d",
                          $MyW5BaseContext->{CheckOfChanges}->{curLevel}));
                })
   );


   return(0) if (!defined($self->{DataObj}));
   return($self->SUPER::Init(@_));
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}


sub isSelectable
{
   my $self=shift;
   my %param=@_;
# 
#   my $u=$param{user};
#   if (ref($u->{groups}) eq "ARRAY"){  
#      foreach my $grprec (@{$u->{groups}}){ 
#         if (ref($grprec->{roles}) eq "ARRAY"){
#            return(1) if (in_array($grprec->{roles}, 
#                          [qw(
#                              RINManager 
#                              RINManager2 
#                              RINOperator
#                              RCHManager 
#                              RCHManager2 
#                              RCHOperator
#                              RPRManager 
#                              RPRManager2 
#                              RPROperator
#                              RAuditor 
#                              RMonitor)],
#                          @{$grprec->{roles}}));
#         }
#      }
#   }
   return(1);
   my $dataobj=$self->getDataObj();
   return(1) if ($dataobj->IsMemberOf("admin"));
   return(0);
}



sub getQueryTemplate
{
   my $self=shift;
   my $dataobj=$self->getDataObj();


   if (!defined(Query->Param("search_from"))){
      Query->Param("search_from"=>$self->T("now")."-24h");
   }
   if (!defined(Query->Param("search_to"))){
      Query->Param("search_to"=>$self->T("now")."-5m");
   }


   #######################################################################
   my @ifcheck=@{$self->{Val}->{ifcheck}};

   my $reptyp="<select name=search_ifcheck style=\"width:100%\">";
   my $oldval=Query->Param("search_ifcheck");
   foreach my $ifcheck (@ifcheck){
      $reptyp.="<option value=\"$ifcheck\"";
      $reptyp.=" selected" if ($ifcheck eq $oldval);
      $reptyp.=">".$self->T($ifcheck)."</option>";
   }
   $reptyp.="</select>";
   my $reptypl=$self->T("interface consideration");
   #######################################################################

   my $showallsel;
   $showallsel="checked" if (Query->Param("SHOWALL"));

   
   my $froml=$self->{Field}->{from}->Label;
   my $froms=$self->{Field}->{from}->FormatedSearch();

   my $tol=$self->{Field}->{to}->Label;
   my $tos=$self->{Field}->{to}->FormatedSearch();


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$froml:</td>
<td class=finput width=40%>$froms</td>
<td class=fname width=10%>$tol:</td>
<td class=finput width=40%>$tos</td>
</tr>
<tr>
<td class=fname width=10%>\%affectedapplication(label)\%:</td>
<td class=finput width=40%>\%affectedapplication(search)\%</td>
<td class=fname width=10%>$reptypl:</td>
<td class=finput width=40%>$reptyp</td>
</tr>
<tr>
<td class=fname width=10%>Stichwort-Eingrenzung:</td>
<td class=finput colspan=3>\%name(search)\%</td>
</tr>
</table>
</div>
%StdButtonBar(bookmark,search)%
EOF
   return($d);
}


#sub SetFilter
#{
#   my $self=shift;
#   my $dataobj=$self->getDataObj();
#
#
#
#}

sub SetFilter
{
   my $self=shift;
   my $flt=shift;


   my $from=$flt->{from}; 
   my $to=$flt->{to}; 

   my $keywords=$flt->{name};

   delete ($flt->{duration});
   delete ($flt->{to});
   delete ($flt->{from});
   delete ($flt->{name});

   my $t;
   if ($from ne "" && $to ne ""){
      $t=CalcDateDuration($from,$to,"GMT");
   }
   if ($from eq "" || $to eq "" || $flt->{trange} eq "" || !defined($t)){
      $self->LastMsg(ERROR,"incomplete timerange specification");
      return(undef);
   }

   my @apps;

   if ( $flt->{affectedapplication} ne "" && 
         $flt->{affectedapplication} ne "*"){
      my $app=getModuleObject($self->Config,"itil::appl");
      $app->SetFilter({cistatusid=>\'4',name=>$flt->{affectedapplication}});
      @apps=$app->getHashList(qw(id name));
   }
   msg(INFO,"CoC with app cnt=".($#apps+1)." and trange=$t->{totaldays}");

   if ($#apps==-1 || $#apps>99){
      if ($t->{totalminutes}>(24*60*2)){
         $self->LastMsg(ERROR,
            "unspecific application search is limit to a timerange of 48h");
         return(undef);
      }
   }
   if ($#apps>10){
      if ($t->{totalminutes}>(24*60*14)){
         $self->LastMsg(ERROR,
            "more than 10 application search is limit to a timerange of 14d");
         return(undef);
      }
   }
   if ($#apps>0){
      if ($t->{totalminutes}>(24*60*34)){
         $self->LastMsg(ERROR,
            "more than 1 application search is limit to a timerange of 28d");
         return(undef);
      }
   }
   if ($#apps==0){
      if ($t->{totalminutes}>(24*60*28*12)){
         $self->LastMsg(ERROR,
            "1 application search is limit to a timerange of 12m");
         return(undef);
      }
   }

   msg(INFO,"CoC with ifcheck $flt->{ifcheck}");
   if ($flt->{ifcheck} eq "none"){
      delete($flt->{ifcheck});
   }
   elsif ($flt->{ifcheck} eq "moderat"){
      delete($flt->{ifcheck});
      if ($#apps!=-1){
         my $lnkappl=getModuleObject($self->Config,"itil::lnkapplappl");
         $lnkappl->SetFilter([
            {
               fromapplid=>[map({$_->{id}} @apps)],
               toapplcistatus=>[3,4,5],
               contype=>[0,1,2],
               cistatusid=>[3,4]
            },
            {
               toapplid=>[map({$_->{id}} @apps)],
               fromapplcistatus=>[3,4,5],
               contype=>[0,1,2],
               cistatusid=>[3,4]
            }
         ]);
         my @l=$lnkappl->getHashList(qw(fromappl toappl));
         Dumper(\@l);
         my %unames;
         map({$unames{$_->{toappl}}++;$unames{$_->{fromappl}}++;} @l);
         $flt->{affectedapplication}.=" ".join(" ",keys(%unames));
      }
   }
   elsif ($flt->{ifcheck} eq "full"){
      delete($flt->{ifcheck});
      if ($#apps!=-1){
         my $lnkappl=getModuleObject($self->Config,"itil::lnkapplappl");
         $lnkappl->SetFilter([
            {
               fromapplid=>[map({$_->{id}} @apps)],
               toapplcistatus=>[3,4,5],
               contype=>[0,1,2,3,4,5],
               cistatusid=>[3,4,5]
            },
            {
               toapplid=>[map({$_->{id}} @apps)],
               fromapplcistatus=>[3,4,5],
               contype=>[0,1,2,3,4,5],
               cistatusid=>[3,4,5]
            }
         ]);
         my @l=$lnkappl->getHashList(qw(fromappl toappl));
         Dumper(\@l);
         my %unames;
         map({
            $unames{$_->{toappl}}++;
            $unames{$_->{fromappl}}++;
         } @l);
         $flt->{affectedapplication}.=" ".join(" ",keys(%unames));
      }
   }
   #print STDERR Dumper($t);


   $flt->{eventstart}="<\"$to\" OR [EMPTY]";
   $flt->{eventend}=">\"$from\" OR [EMPTY]";
   $flt->{isdeleted}=\'0';


   my $MyW5BaseContext=$self->{Context};
   if ($keywords ne ""){
      my @words=parse_line('[,;]{0,1}\s+',0,$keywords);
      $MyW5BaseContext->{CheckOfChanges}->{keywords}=\@words;
   }
   else{
      delete($MyW5BaseContext->{CheckOfChanges}->{keywords});
   }
   $MyW5BaseContext->{CheckOfChanges}->{totalminutes}=$t->{totalminutes};

   if ($#apps==-1){
      delete($MyW5BaseContext->{CheckOfChanges}->{appids});
   }
   else{
      $MyW5BaseContext->{CheckOfChanges}->{appids}=[map({$_->{id}} @apps)];
   }
   $MyW5BaseContext->{CheckOfChanges}->{from}=$from;

   $self->{DataObj}->{AutoSortTableHtmlV01}={
      'targetmatchlevel'=>1
   };
   

   $self->{DataObj}->{SoftFilter}=sub{
      my $self=shift;
      my $rec=shift;
      return(1) if (!defined($rec));  # ViewEditor Modus
      my $txt;
      my $name=$rec->{name};      
      my $detail=$self->getField("wffields.changedescription",$rec);
      if (defined($detail)){
         $txt=$detail->RawValue($rec);
      }
      else{
         $txt=$rec->{detaildescription};
      }
      if (!exists($MyW5BaseContext->{CheckOfChanges})){
         msg(ERROR,"CheckOfChanges context error - contact developer");
         return(1);
      }
      my $maxlevel=99;
      my $wordfnd=0;
      if (exists($MyW5BaseContext->{CheckOfChanges}->{keywords})){
         $maxlevel=75;
         my $n=$#{$MyW5BaseContext->{CheckOfChanges}->{keywords}}+1;
         my $fnd=0;
         foreach my $word (@{$MyW5BaseContext->{CheckOfChanges}->{keywords}}){
            my $qw=quotemeta($word);
            my $ntxt=()=$txt=~m/$qw/gi;
            my $nname=()=$name=~m/$qw/gi;
            if ($nname>0 || $ntxt>0){
               $fnd+=1;
               $wordfnd+=($nname+$ntxt);
            }
         }
         return(0) if ($fnd<$n);
      }

      my $level=$maxlevel;
      if (exists($MyW5BaseContext->{CheckOfChanges}->{keywords})){
         $wordfnd=24 if ($wordfnd>24);
         $level+=$wordfnd;
      }
      my $tq=$MyW5BaseContext->{CheckOfChanges}->{totalminutes};
      
      my $evstart=$rec->{eventstart}; 
      if ($evstart ne "" && $MyW5BaseContext->{CheckOfChanges}->{from} ne ""){
         my $t=CalcDateDuration($MyW5BaseContext->{CheckOfChanges}->{from},
                                $evstart,"GMT");
         my $off=abs($t->{totalminutes});
         my $oindex=$off*25.0/$tq;
         $oindex=25.0 if ($oindex>25);
         $level-=$oindex; 
      }
      if (exists($MyW5BaseContext->{CheckOfChanges}->{appids})){
         if (!in_array($MyW5BaseContext->{CheckOfChanges}->{appids},
                       $rec->{affectedapplicationid})){
            $level-=20;
         }
      }


      
      




      $level="10" if ($level<10);



      $MyW5BaseContext->{CheckOfChanges}->{curLevel}=$level;

      #printf STDERR ("$MyW5BaseContext name:%s\nDetail:%s\n\n",$rec->{name},length($txt));
      return(1);
   };






   my $dataobj=$self->getDataObj();
   #msg(INFO,"MyW5Base Dataobj Filter=%s",Dumper($flt));
   $dataobj->ResetFilter();
   return($dataobj->SetFilter($flt));
   #return($dataobj->SetFilter($flt,\%flt2));
   #######################################################################


   return(1);
}




sub Result
{
   my $self=shift;
   my %q=$self->getDataObj()->getSearchHash();

   my ($from,$to);

   return(undef) if (!(my $f=$self->{Field}->{from}->Unformat($q{from})));
   $from=$f->{from};

   return(undef) if (!(my $f=$self->{Field}->{to}->Unformat($q{to})));
   $to=$f->{to};

   $q{to}=$to;
   $q{from}=$from;
   my ($fromday)=$from=~m/^(\S+)/;
   my ($today)=$to=~m/^(\S+)/;



   $q{trange}="$from/$to";

   $q{class}=[grep(/^.*::(change|opmeasure)$/,
               keys(%{$self->{DataObj}->{SubDataObj}}))];



   if (!$self->SetFilter(\%q)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"can not SetFilter on DataObj - unknown problem");
      }
      return(undef);
   }
   $self->{DataObj}->setDefaultView(qw(targetmatchlevel eventstart eventend
                                       nature name state));


   my %param=(ExternalFilter=>1,
              #Limit=>50    # ein Pageing möglich, da SoftFilter verwendet
   );
   return($self->{DataObj}->Result(%param));
}



1;
