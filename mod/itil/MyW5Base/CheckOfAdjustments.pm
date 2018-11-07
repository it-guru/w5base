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

   $self->{Field}->{trangefrom}=new kernel::Field::Date(
                Parent        =>$self,
                name          =>'trangefrom',
                label         =>'From');
   $self->{Field}->{trangefrom}->setParent($self);

   $self->{Field}->{trangeto}=new kernel::Field::Date(
                Parent        =>$self, 
                name          =>'trangeto',
                label         =>'To');
   $self->{Field}->{trangeto}->setParent($self);

   $self->{Val}->{ifcheck}=["none","moderat","full","excessive"];


   $self->{DataObj}->AddFields(
      new kernel::Field::Text(
                   Parent        =>$self, 
                   name          =>'inmsel'),
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
                   return($MyW5BaseContext->{CheckOfChanges}->{curLevel});
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
   return(1);
}



sub getQueryTemplate
{
   my $self=shift;
   my $dataobj=$self->getDataObj();


   if (!defined(Query->Param("search_trangefrom"))){
      Query->Param("search_trangefrom"=>$self->T("now")."-24h");
   }
   if (!defined(Query->Param("search_trangeto"))){
      Query->Param("search_trangeto"=>"start+1d");
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

   my $isel="<select name=search_inmsel style=\"width:100%\">";
   my $oldval=Query->Param("search_inmsel");
   foreach my $inmopt ("no","yes"){
      $isel.="<option value=\"$inmopt\"";
      $isel.=" selected" if ($inmopt eq $oldval);
      $isel.=">".$self->T($inmopt)."</option>";
   }
   $isel.="</select>";

   my $reptypl=$self->T("interface consideration");
   my $ichk=$self->T("incident consideration");
   my $kwtext=$self->T("keyword containment");

   #######################################################################

   my $showallsel;
   $showallsel="checked" if (Query->Param("SHOWALL"));

   
   my $froml=$self->{Field}->{trangefrom}->Label;
   my $froms=$self->{Field}->{trangefrom}->FormatedSearch();

   my $tol=$self->{Field}->{trangeto}->Label;
   my $tos=$self->{Field}->{trangeto}->FormatedSearch();


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
<td class=fname width=10%>&nbsp;</td>
<td class=finput width=40%>&nbsp;</td>
<td class=fname width=10%>$ichk:</td>
<td class=finput width=40%>$isel</td>
</tr>
<tr>
<td class=fname width=10%>$kwtext:</td>
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


   my $from=$flt->{trangefrom}; 
   my $to=$flt->{trangeto}; 

   my $keywords=$flt->{name};

   delete ($flt->{duration});
   delete ($flt->{trangeto});
   delete ($flt->{trangefrom});
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
   my $ifcheck=$flt->{ifcheck};

   if ( $flt->{affectedapplication} ne "" && 
         $flt->{affectedapplication} ne "*"){
      my $app=getModuleObject($self->Config,"itil::appl");
      $app->SetFilter({cistatusid=>\'4',name=>$flt->{affectedapplication}});
      @apps=$app->getHashList(qw(id name));
   }
   msg(INFO,"CoC with app cnt=".($#apps+1)." and trange=$t->{totaldays}");

   if ($#apps==-1 || $#apps>99 || $ifcheck eq "excessive"){
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
            "more than 1 application search is limit to a timerange of one month");
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

   my $MyW5BaseContext=$self->{Context};
   msg(INFO,"CoC with ifcheck $flt->{ifcheck}");
   if ($flt->{ifcheck} eq "none"){
      delete($flt->{ifcheck});
   }
   elsif ($flt->{ifcheck} eq "excessive"){
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
         my @l=$lnkappl->getHashList(qw(fromapplid toapplid));
         Dumper(\@l);
         my %uids;
         map({
            $uids{$_->{toapplid}}++;
            $uids{$_->{fromapplid}}++;
         } @l);
         $MyW5BaseContext->{CheckOfChanges}->{ifappids}=[keys(%uids)];
      }
      delete($flt->{affectedapplication});
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

 #  $flt->{eventstart}="<\"$to\" OR [EMPTY]";
 #  $flt->{eventend}=">\"$from\" OR [EMPTY]";
   $flt->{isdeleted}=\'0';


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
   $MyW5BaseContext->{CheckOfChanges}->{ifcheck}=$ifcheck;

   $self->{DataObj}->{AutoSortTableHtmlV01}={
      'targetmatchlevel'=>1
   };


   #msg(INFO,"CheckOfChanges:".Dumper($MyW5BaseContext->{CheckOfChanges}));
   

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
         if ($MyW5BaseContext->{CheckOfChanges}->{ifcheck} ne "excessive"){
            return(0) if ($fnd<$n);
         }
         else{
            $maxlevel=20 if ($fnd<$n);
            if ($fnd==$n){
               $maxlevel=75;
            }
            if ($fnd>$n){
               $maxlevel=80+($fnd*3);
            }
         }
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
         my $oindex=$off*35.0/$tq;
         $oindex=35.0 if ($oindex>35);
         $level-=$oindex; 
      }
      if (exists($MyW5BaseContext->{CheckOfChanges}->{appids})){
         if (!in_array($MyW5BaseContext->{CheckOfChanges}->{appids},
                       $rec->{affectedapplicationid})){
            $level*=0.45;
         }
         else{
            $level*=1.48;
         }
      }
      if (exists($MyW5BaseContext->{CheckOfChanges}->{ifappids})){
         my $fndiapps=0;
         foreach my $ifid (@{$MyW5BaseContext->{CheckOfChanges}->{ifappids}}){
            if (in_array($ifid,$rec->{affectedapplicationid})){
               $fndiapps++;
            }
         }
         if ($fndiapps>5){
            $level*=1.39;
         }
         elsif ($fndiapps>1){
            $level*=1.34;
         }
         elsif ($fndiapps>0){
            $level*=1.24;
         }
         else{
            $level*=0.36;
         }
      }
      $level=10 if ($level<10);
      $level=99.9 if ($level>99.9);
      $MyW5BaseContext->{CheckOfChanges}->{curLevel}=$level;
      return(1);
   };
   my $dataobj=$self->getDataObj();
   msg(INFO,"MyW5Base CheckOfAdjustments Filter=%s",Dumper($flt));
   $dataobj->ResetFilter();

   my %f1=%{$flt};
   my %f2=%{$flt};


   $f1{eventstart}="<=\"$to GMT\" OR [EMPTY]";
   $f1{eventend}=">=\"$from GMT\" OR [EMPTY]";

   #return($dataobj->SetFilter([\%f1,\%f2]));
   return($dataobj->SetFilter(\%f1));
   #return($dataobj->SetFilter($flt,\%flt2));
   #######################################################################


   return(1);
}




sub Result
{
   my $self=shift;
   my %q=$self->getDataObj()->getSearchHash();

   if ($q{trangefrom}=~m/(^|[^a-z])end([^a-z]|$)/i){
      $q{trangefrom}=~s/(^|[^a-z])end([^a-z]|$)/$1$q{trangeto}$2/gi;
   }
   if ($q{trangeto}=~m/(^|[^a-z])start([^a-z]|$)/i){
      $q{trangeto}=~s/(^|[^a-z])start([^a-z]|$)/$1$q{trangefrom}$2/gi;
   }

   my ($from,$to);

   my $f;
   if (!($f=$self->{Field}->{trangefrom}->Unformat($q{trangefrom}))){
      return(undef);
   }
   $from=$f->{trangefrom};

   if (!($f=$self->{Field}->{trangeto}->Unformat($q{trangeto}))){
      return(undef);
   }
   $to=$f->{trangeto};

   $q{trangeto}=$to;
   $q{trangefrom}=$from;
   my ($fromday)=$from=~m/^(\S+)/;
   my ($today)=$to=~m/^(\S+)/;



   $q{trange}="$from/$to";

   $q{class}=[grep(/^.*::(change|opmeasure)$/,
               keys(%{$self->{DataObj}->{SubDataObj}}))];

    if ($q{inmsel} eq "yes"){
       $q{class}=[grep(/^.*::(change|opmeasure|incident)$/,
                   keys(%{$self->{DataObj}->{SubDataObj}}))];
    }
    delete($q{inmsel});


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


sub Welcome
{
   my $self=shift;
   print $self->getParent->HttpHeader("text/html");
   print $self->getParent->HtmlHeader(style=>['default.css','mainwork.css'],
                           body=>1,form=>1);
   my $module=$self->Module();
   my $appname=$self->App();
   my $tmpl="tmpl/$appname.welcome";


   print $self->getParent->getParsedTemplate($tmpl,{skinbase=>$module});
   print $self->getParent->HtmlBottom(body=>1,form=>1);
   return(0);
}





1;
