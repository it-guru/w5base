package itil::FaultAnalytics;
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
use vars qw(@ISA $override);
use kernel;
use kernel::date;
use kernel::App::Web;
use POSIX;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main Welcome doAnalyse));
}


sub AddComponent
{
   my ($self,$comp)=@_;
   my $objecttype=Query->Param("objecttype");
   my $objectname=Query->Param("objectname");

   if ($objecttype eq "itil::system(name)"){
      my $o=getModuleObject($self->Config,"itil::system");
      $o->SetFilter(name=>\$objectname);
      my ($rec,$msg)=$o->getOnlyFirst(qw(id));
      if (!defined($rec)){
         $self->LastMsg(ERROR,"object not found"); 
         return();
      }
      my $compname="itil::system($rec->{id})";
      my $qcompname=quotemeta($compname);
      if (!grep(/^$qcompname$/,@$comp)){
         push(@$comp,"itil::system($rec->{id})");
      }
   }
   if ($objecttype eq "itil::appl(name)"){
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter(name=>\$objectname);
      my ($rec,$msg)=$o->getOnlyFirst(qw(id));
      if (!defined($rec)){
         $self->LastMsg(ERROR,"object not found"); 
         return();
      }
      my $compname="itil::appl($rec->{id})";
      my $qcompname=quotemeta($compname);
      if (!grep(/^$qcompname$/,@$comp)){
         push(@$comp,"itil::appl($rec->{id})");
      }
   }
   if ($objecttype eq "base::location(name)"){
      my $o=getModuleObject($self->Config,"base::location");
      $objectname=~s/\*//g;
      $objectname=~s/\?//g;
      $o->SetFilter([{name=>\$objectname},{location=>$objectname}]);
      my $found=0;
      foreach my $rec ($o->getHashList(qw(id))){
         my $compname="base::location($rec->{id})";
         my $qcompname=quotemeta($compname);
         if (!grep(/^$qcompname$/,@$comp)){
            push(@$comp,"base::location($rec->{id})");
         }
         $found++;
      }
      if (!$found){
         $self->LastMsg(ERROR,"object not found"); 
         return();
      }
   }
}

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           js=>['toolbox.js','kernel.App.Web.js'],
                           submodal=>1,
                           form=>1,
                           body=>1,
                           title=>$self->T($self->Self()));
   my @comp=Query->Param("comp");
   if (Query->Param("ADD")){
      $self->AddComponent(\@comp);
   }
   if (Query->Param("DEL") ne ""){
      my $qd=quotemeta(Query->Param("DEL"));
      @comp=grep(!/^$qd$/,@comp);
   }
   my $objectname=Query->Param("objectname");
   my $comp;
   foreach my $curcomp (@comp){
      if (my ($objname,$id,$add)=$curcomp=~m/^(.+?)\((\d+)\)(.*)$/){
         my $o=getModuleObject($self->Config,$objname);
         $o->SetFilter(id=>\$id);
         my ($rec,$msg)=$o->getOnlyFirst(qw(name));
         if (defined($rec)){
            $comp.="<tr><td class=complistname>".
                   "<input type=hidden name=comp ".
                   "value=\"$objname($id)\">$rec->{name}</td>".
                   "<td width=1% class=complistdel>".
                   "<span class=sublink>".
                   "<img onclick=RemoveComponent('$objname($id)') ".
                   "src=\"../../base/load/minidelete.gif\" border=0>".
                   "</span></td>";
         }
      }
   }

   print <<EOF;
<style>
body{
   overflow:hidden;
}
.complist{
   border-top-style:solid;
   border-top-width:1px;
   border-top-color:black;
}
.complistdel{
   border-bottom-style:solid;
   border-bottom-width:1px;
   border-bottom-color:black;
}
.complistname{
   border-bottom-style:solid;
   border-bottom-width:1px;
   border-bottom-color:black;
}

</style>
<table border=0 cellspacing=0 cellpadding=0 height=\"100%\" width=\"100%\">
EOF

   printf("<tr><td colspan=2 height=1%% style=\"padding:1px\" ".
             "valign=top>%s</td></tr>",$self->getAppTitleBar());
   my $lastmsg=$self->findtemplvar({},"LASTMSG");
   my $objecttype=Query->Param("objecttype");
   my @objecttypes=("itil::system(name)"=>"System",
                    "itil::appl(name)"=>'Anwendung',
                    "base::location(name)"=>"Standort");
   my $objecttypes="<select name=objecttype style=\"width:100px\">";
   while(my $k=shift(@objecttypes)){
      my $n=shift(@objecttypes);
      $objecttypes.="<option value=\"$k\"";
      if ($k eq $objecttype){
         $objecttypes.=" selected";
      }
      $objecttypes.=">$n</option>";
   }
   $objecttypes.="</select>";

   print <<EOF;
<tr height=10%>
<td width=500 valign=top>

<div style="height:120px;background:silver;padding:5px;margin:5px;margin-left:1;margin-top:0;border-style:solid;border-color:black;border-width:1px">
<table height=100% border=0 cellspacing=0 cellpadding=3>
<tr>
<td width=1%>$objecttypes</td>
<td><input name=objectname value="$objectname" type=text style="width:100%"></td>
<td width=1%><input name=ADD style="width:120px" type=submit value=" => hinzufügen =>"></td>
</tr>
<tr>
<td colspan=3 align=right>
<table width="100%" cellspacing=0 cellpadding=0>
<tr>
<td>Mit dem Ausfallsanalyse Werkzeug können die Auswirkungen eines Ausfalls einer Komponente des IT-Betriebes und die entsprechenden Kontakte analysiert werden.
<td>
</td>
<td valign=bottom>
<select style="width:120px">
<option>HTML Ausgabe</option>
<!--
<option>native HTML</option>
<option>Text only</option>
-->
</select>
<input style="width:120px" onclick="doAnalyse();" type=button value=" analysieren ">
</td></tr></table>
</td>
</tr>
</table>
</div>

</td>
<td valign=top>
<div style="height:80px;overflow:auto">
<b>Komponentenliste:</b><br>

<div id=complist>
<table width=95% class=complist border=0 cellspacing=0 cellpadding=0>$comp</table>
</div>

</div>
</td>
</tr>
<tr height=1%>
<td colspan=2><hr></td>
</tr>
<tr height=1%>
<td colspan=2>$lastmsg</td>
</tr>
<tr>
<td colspan=2>
<iframe src="Welcome" name=result width=99% height=99%></iframe>
</td>
</tr>
</table>
<script language="JavaScript">
function doAnalyse()
{
   var oldtarget=document.forms[0].target;
   var oldaction=document.forms[0].action;
   document.forms[0].target="result";
   document.forms[0].action="doAnalyse";
   document.forms[0].submit();
   document.forms[0].target=oldtarget;
   document.forms[0].action=oldaction;
}
function RemoveComponent(oname)
{
   document.forms[0].elements['DEL'].value=oname;
   document.forms[0].submit();
}
</script>
<input type=hidden name="DEL">
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub Welcome
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           title=>$self->T($self->Self()));
   print $self->HtmlBottom(body=>1,form=>1);
}

sub doAnalyse
{
   my ($self)=@_;

   my @comp=Query->Param("comp");


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>'default.css',
                           title=>$self->T($self->Self()));

   my %incomp;
   my %outcomp;

   foreach my $comp (@comp){
      if (my ($objname,$id,$add)=$comp=~m/^(.+?)\((\d+)\)(.*)$/){
         $incomp{$objname}->{$id}->{$add}++;
      }
   }
   my %param;
   $self->analyse(\%incomp,\%outcomp,%param);
   printf STDERR ("incomp=%s\noutcomp=%s\n",Dumper(\%incomp),Dumper(\%outcomp));
   my $nowstamp=$self->ExpandTimeExpression('now',$self->Lang(),
                                                  $self->UserTimezone(),
                                                  $self->UserTimezone());
   my ($incomphtm,$incomptxt)=$self->FormatIncomp(\%incomp,\%outcomp,%param);
   my ($directhtm,$directtxt)=$self->FormatDirect(\%incomp,\%outcomp,%param);
   my ($indirecthtm,$indirecttxt)=$self->FormatIndirect(\%incomp,\%outcomp,
                                                         %param);
   my ($detailhtm,$detailtxt)=$self->FormatDetail(\%incomp,\%outcomp,
                                                         %param);

   my ($usercomphtm,$usercomptxt)=$self->FormatUserComp(\%incomp,\%outcomp,
                                                         %param);

   my $ndirect=keys(%{$outcomp{direct}->{system}->{name}})+
               keys(%{$outcomp{direct}->{application}->{name}});
   my $nindirect=keys(%{$outcomp{indirect}->{system}->{name}})+
                 keys(%{$outcomp{indirect}->{application}->{name}});
   
   print $self->getParsedTemplate("tmpl/FaultAnalytics",{
                                   static=>{
                                             NOW=>$nowstamp,
                                             INCOMP=>$incomphtm,
                                             DETAIL=>$detailhtm,
                                             USERCOMP=>$usercomphtm,
                                             DIRECT=>$directhtm,
                                             NDIRECT=>$ndirect,
                                             INDIRECT=>$indirecthtm,
                                             NINDIRECT=>$nindirect,
                                           }
                                  });

   print $self->HtmlBottom(body=>1,form=>1);
}


sub inRecords
{
   my ($self,$incomp)=@_;

   my @l;
   foreach my $objname (keys(%$incomp)){
      my $o=$self->getPersistentModuleObject($objname);
      foreach my $id (keys(%{$incomp->{$objname}})){
         $o->ResetFilter();
         $o->SetFilter(id=>\$id);
         my ($rec,$msg)=$o->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            $rec->{objname}=$objname;
            push(@l,$rec);
         }
      }
   }
   return(@l);
}

sub FormatIndirect
{
   my ($self,$incomp,$outcomp,%param)=@_;

   my $d="<table>";
   if (keys(%{$outcomp->{indirect}->{application}->{name}})){
      $d.="<tr><td class=col1>".$self->T("itil::appl","itil::appl").
          "</td><td class=col2>".
          join(", ",sort(keys(%{$outcomp->{indirect}->{application}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{indirect}->{businessprocess}})){
      foreach my $customer (sort(keys(%{$outcomp->{indirect}->
                                                  {businessprocess}}))){
         $d.="<tr><td class=col1>".
             $self->T("itil::businessprocess","itil::businessprocess").
             "<br>$customer</td>".
             "<td class=col2>".
             join(", ",sort(keys(%{$outcomp->{indirect}->{businessprocess}->
                                             {$customer}->{name}}))).
             "</td></tr>";
      }
   }
   if (keys(%{$outcomp->{indirect}->{techcontact}})){
      $d.="<tr><td class=col1>".$self->T("tech. Contact")."</td>".
          "<td class=col2>".
          join("; ",sort(keys(%{$outcomp->{indirect}->{techcontact}->
                                          {email}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{indirect}->{techcontact2}})){
      $d.="<tr><td class=col1>".$self->T("deputy tech. Contact")."</td>".
          "<td class=col2>".
          join("; ",sort(keys(%{$outcomp->{indirect}->{techcontact2}->
                                          {email}}))).
          "</td></tr>";
   }

   $d.="</table>";
   return($d);
}
   
sub FormatUserComp
{
   my ($self,$incomp,$outcomp,%param)=@_;

   my $d="<table>";
   $d.="<tr>";
   $d.="<td width=200 class=detailth>".$self->T("Contact")."</td>";
   $d.="<td class=detailth>".$self->T("Components")."</td>";
   $d.="</tr>";

   my %user;

   foreach my $k (sort(keys(%{$outcomp->{detail}}))){
      foreach my $user ($outcomp->{detail}->{$k}->{techcontact},
                        $outcomp->{detail}->{$k}->{techboss}){
         $user{$user}={} if (!exists($user{$user}));
         $user{$user}->{$outcomp->{detail}->{$k}->{name}}++;
      }
   }
   my $u=getModuleObject($self->Config,"base::user");
   $u->SetFilter({userid=>[keys(%user)],cistatusid=>\'4'});
   foreach my $userrec ($u->getHashList(qw(fullname userid))){
      my $userid=$userrec->{userid};
      $d.="<tr>";
      $d.="<td class=detailname>".
          $self->FormatUser($outcomp,$userid).
          "</td>";
      $d.="<td class=detail>".
          join(", ",sort(keys(%{$user{$userid}}))).
          "</td>";
      $d.="</tr>";
   }
   $d.="</table>";
   return($d);
}

sub FormatDetail
{
   my ($self,$incomp,$outcomp,%param)=@_;

   my $d="<table>";
   $d.="<tr>";
   $d.="<td class=detailth>".$self->T("Component")."</td>";
   $d.="<td class=detailth>".$self->T("tech. Contact")."<br>".
                             $self->T("deputy tech. Contact")."</td>";
   $d.="<td class=detailth>".$self->T("boss")."</td>";
   $d.="<td class=detailth>".$self->T("reason")."</td>";
   $d.="</tr>";
   foreach my $k (sort(keys(%{$outcomp->{detail}}))){
      $d.="<tr>";
      $d.="<td class=detailname>".$outcomp->{detail}->{$k}->{name}."</td>";
      $d.="<td class=techcontact>";
      my $d1=$self->FormatUser($outcomp,$outcomp->{detail}->{$k}->{techcontact});
      my $d2=$self->FormatUser($outcomp,$outcomp->{detail}->{$k}->{techcontact2});
      $d.=$d1;
      $d.="<br>".$d2 if ($d2 ne "" && $d2 ne $d1);
      $d.="</td>";
      $d.="<td class=techboss>";
      $d.=$self->FormatUser($outcomp,$outcomp->{detail}->{$k}->{techboss});
      $d.="</td>";
      $d.="<td class=detailreason>".
          join(",<br>",sort(keys(%{$outcomp->{detail}->{$k}->{reason}}))).
          "</td>";
      $d.="</tr>";
   }
   $d.="</table>";
   return($d);
}

sub FormatUser
{
   my $self=shift;
   my $outcomp=shift;
   my $user=shift;
   $user=[keys(%$user)] if (ref($user) eq "HASH");
   $user=[$user] if (ref($user) ne "ARRAY");
   my $d="";
   foreach my $userid (@$user){
      my $l;
      $l.=$outcomp->{user}->{$userid}->{surname};
      $l.=", " if ($l ne "" && $outcomp->{user}->{$userid}->{givenname} ne "");
      $l.=$outcomp->{user}->{$userid}->{givenname};
      $l=$outcomp->{user}->{$userid}->{fullname} if ($l eq "");
      if ($outcomp->{user}->{$userid}->{phone} ne ""){
         $l.="<br>$outcomp->{user}->{$userid}->{phone}";
      }
      if ($outcomp->{user}->{$userid}->{mobile} ne ""){
         $l.="<br>$outcomp->{user}->{$userid}->{mobile}";
      }
      $d.="<br>" if ($d ne "");
      $d.=$l;
   }
   return($d);
}
   
sub FormatDirect
{
   my ($self,$incomp,$outcomp,%param)=@_;

   my $d="<table>";
   if (keys(%{$outcomp->{direct}->{location}->{name}})){
      $d.="<tr><td class=col1>".$self->T("base::location","base::location").
          "</td><td class=col2>".
          join(", ",sort(keys(%{$outcomp->{direct}->{location}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{system}->{name}})){
      $d.="<tr><td class=col1>".$self->T("itil::system","itil::system").
          "</td><td class=col2>".
          join(", ",sort(keys(%{$outcomp->{direct}->{system}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{application}->{name}})){
      $d.="<tr><td class=col1>".$self->T("itil::appl","itil::appl").
          "</td><td class=col2>".
          join(", ",sort(keys(%{$outcomp->{direct}->{application}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{businessprocess}})){
      foreach my $customer (sort(keys(%{$outcomp->{direct}->
                                                  {businessprocess}}))){
         $d.="<tr><td class=col1>".
             $self->T("itil::businessprocess","itil::businessprocess").
             "<br>$customer</td>".
             "<td class=col2>".
             join(", ",sort(keys(%{$outcomp->{direct}->{businessprocess}->
                                             {$customer}->{name}}))).
             "</td></tr>";
      }
   }
   if (keys(%{$outcomp->{direct}->{techcontact}})){
      $d.="<tr><td class=col1>".$self->T("technical contact")."</td>".
          "<td class=col2>".
          join("; ",sort(keys(%{$outcomp->{direct}->{techcontact}->
                                          {email}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{techcontact2}})){
      $d.="<tr><td class=col1>".$self->T("deputy technical contact")."</td>".
          "<td class=col2>".
          join("; ",sort(keys(%{$outcomp->{direct}->{techcontact2}->
                                          {email}}))).
          "</td></tr>";
   }


   $d.="</table>";
   return($d);
}
   
sub FormatIncomp
{
   my ($self,$incomp,$outcomp,%param)=@_;
   
   my %l;
   foreach my $rec ($self->inRecords($incomp)){
      if ($rec->{objname} eq "base::location"){
         my $objlabel=$self->T($rec->{objname},$rec->{objname});
         $l{$rec->{name}}={name=>$rec->{name},objlabel=>$objlabel};
      }
      else{
         my $objlabel=$self->T($rec->{objname},$rec->{objname});
         $l{$rec->{name}}={name=>$rec->{name},objlabel=>$objlabel};
      }
   }
   my $d="<table>";
   my $dtxt="";
   foreach my $k (sort(keys(%l))){
      $d.="<tr><td class=col1>$l{$k}->{objlabel}</td>".
          "<td class=col2>$l{$k}->{name}</td></tr>";
      $dtxt.="$l{$k}->{objlabel}:$l{$k}->{name}\n";
   }
   $d.="</table>";

   return($d,$dtxt);
}

sub analyse
{
   my ($self,$incomp,$outcomp,%param)=@_;
   my $location=$self->getPersistentModuleObject("base::location");
   my $user=$self->getPersistentModuleObject("base::user");
   my $system=$self->getPersistentModuleObject("itil::system");
   my $appl=$self->getPersistentModuleObject("itil::appl");
   my $applappl=$self->getPersistentModuleObject("itil::lnkapplappl");

   foreach my $rec ($self->inRecords($incomp)){
      if ($rec->{objname} eq "base::location"){
         $outcomp->{direct}->{location}->{name}->{$rec->{name}}++;
         $outcomp->{direct}->{location}->{id}->{$rec->{id}}->{'location selected'}++;
      }
      if ($rec->{objname} eq "itil::appl"){
         $outcomp->{direct}->{application}->{name}->{$rec->{name}}->{'application selected'};
         $outcomp->{direct}->{application}->{id}->{$rec->{id}}->{'application selected'}++;
      }
      if ($rec->{objname} eq "itil::system"){
         $outcomp->{direct}->{system}->{systemid}->{$rec->{systemid}}++;
         $outcomp->{direct}->{system}->{name}->{$rec->{name}}->{'system selected'}++;
         $outcomp->{direct}->{system}->{id}->{$rec->{id}}->{'system selected'}++;
         #
         # check application relations
         #
         foreach my $appl (@{$rec->{applications}}){
            $outcomp->{direct}->{application}->{name}->{$appl->{appl}}->
                      {'system selected'}++;
            $outcomp->{direct}->{application}->{id}->{$appl->{applid}}++;
         }
         #
         # Check NFS connections
         #
         my $o=getModuleObject($self->Config,"itil::systemnfsnas");
         $o->SetFilter(systemid=>\$rec->{id});
         my @l=$o->getHashList(qw(fullsystemlist fullsystemidlist
                                  fullappllist fulltsmlist fulltsm2list));
         foreach my $nfsrec (@l){
            foreach my $id (@{$nfsrec->{fullsystemidlist}}){
               $outcomp->{direct}->{system}->{id}->{$id}->{'nfsaccess'}++;
            }
            foreach my $name (@{$nfsrec->{fullsystemlist}}){
               $outcomp->{direct}->{system}->{name}->{$name}->{'nfsaccess'}++;
            }
            foreach my $name (@{$nfsrec->{fullappllist}}){
               $outcomp->{direct}->{application}->{name}->{$name}->
                         {'nfsaccess'}++;
            }
            foreach my $name (@{$nfsrec->{fulltsmlist}}){
               $outcomp->{direct}->{techcontact}->{email}->{$name}->
                         {'nfs contact'}++;
            }
            foreach my $name (@{$nfsrec->{fulltsm2list}}){
               $outcomp->{direct}->{techcontact2}->{email}->{$name}->
                         {'nfs contact'}++;
            }
         }
      }
   }

   
   #
   # check direct interfaces
   #
   my $o=getModuleObject($self->Config,"itil::system");
   $o->SetFilter(location=>[keys(%{$outcomp->{direct}->{location}->{name}})],
                 cistatusid=>\'4');
   my @l=$o->getHashList(qw(name applications));
   foreach my $sysrec (@l){
      $outcomp->{direct}->{system}->
                {name}->{$sysrec->{name}}->{'by location'}++;
      if (ref($sysrec->{applications}) eq "ARRAY"){
         foreach my $apprec (@{$sysrec->{applications}}){
            $outcomp->{direct}->{application}->
                      {name}->{$apprec->{appl}}->{'system at location'}++;
         }
      }
   }
   #
   # check direct interfaces
   #
   my $o=getModuleObject($self->Config,"itil::lnkapplappl");
   $o->SetFilter(fromappl=>[keys(%{$outcomp->{direct}->{application}->{name}})],
                 toapplcistatus=>\'4');
   my @l=$o->getHashList(qw(toappl));
   foreach my $lnkrec (@l){
      next if ($lnkrec->{toappl} eq "");
      if (!exists($outcomp->{direct}->{application}->
                  {name}->{$lnkrec->{toappl}})){
         $outcomp->{indirect}->{application}->{name}->{$lnkrec->{toappl}}->
                   {'by interface'}++;
      }
      else{
         $outcomp->{direct}->{application}->{name}->{$lnkrec->{toappl}}->
                   {'by interface'}++;
      }
   }
       # at this, the fromapplcistatus should be considered
   $o->ResetFilter();
   $o->SetFilter(toappl=>[keys(%{$outcomp->{direct}->{application}->{name}})]);
  # my @l=$o->getHashList(qw(fromappl));
   my @l=$o->getHashList(qw(fromapplid));
   my @idl=map({$_->{fromapplid}} @l);
   my $o=getModuleObject($self->Config,"itil::appl");
   $o->SetFilter(id=>\@idl,cistatusid=>\'4');
   my @l=$o->getHashList(qw(name));
   
   foreach my $lnkrec (@l){
      next if ($lnkrec->{fromappl} eq "");
      if (!exists($outcomp->{direct}->{application}->
                  {name}->{$lnkrec->{fromappl}})){
         $outcomp->{indirect}->{application}->{name}->{$lnkrec->{fromappl}}->
                   {'by interface'}++;
      }
      else{
         $outcomp->{direct}->{application}->{name}->{$lnkrec->{fromappl}}->
                   {'by interface'}++;
      }
   }

   #
   # check direct businessprocess
   #
   my $o=getModuleObject($self->Config,"itil::businessprocess");
   foreach my $direct (qw(direct indirect)){
      if (exists($outcomp->{$direct}) && 
          exists($outcomp->{$direct}->{application})){
         $o->ResetFilter();
         $o->SetFilter(cistatusid=>\'4',
                       applications=>[
                        keys(%{$outcomp->{$direct}->{application}->{name}})]);
         my @l=$o->getHashList(qw(name customer));
         foreach my $brec (@l){
            $outcomp->{$direct}->{businessprocess}->{$brec->{customer}}->
                      {name}->{$brec->{name}}++
         }
         $o->ResetFilter();
         $o->SetFilter(cistatusid=>\'4',
                       systems=>[
                        keys(%{$outcomp->{$direct}->{system}->{name}})]);
         my @l=$o->getHashList(qw(name customer));
         foreach my $brec (@l){
            $outcomp->{$direct}->{businessprocess}->{$brec->{customer}}->
                      {name}->{$brec->{name}}++
         }
      }
   }


   #
   # check tech. contacts
   #
   foreach my $direct (qw(direct indirect)){
      if (exists($outcomp->{$direct}) && 
          exists($outcomp->{$direct}->{application})){
         $appl->ResetFilter();
         $appl->SetFilter(
                   name=>[keys(%{$outcomp->{$direct}->{application}->{name}})],
                   cistatusid=>'<=4');
         foreach my $rec ($appl->getHashList(qw(tsmemail tsm2email))){
             if ($rec->{tsmemail} ne "" && 
                 !exists($outcomp->{$direct}->{techcontact}->
                                   {email}->{$rec->{tsmemail}})){
                $outcomp->{$direct}->{techcontact}->{email}->
                               {$rec->{tsmemail}}->{'appl contact'}++;
             }
             if ($rec->{tsm2email} ne "" && 
                 !exists($outcomp->{$direct}->{techcontact}->
                                   {email}->{$rec->{tsm2email}}) ){
                $outcomp->{$direct}->{techcontact2}->{email}->
                          {$rec->{tsm2email}}->{'appl contact'}++;
             }
         }
      }
      if (exists($outcomp->{$direct}) && 
          exists($outcomp->{$direct}->{system})){
         $system->ResetFilter();
         $system->SetFilter(
                   name=>[keys(%{$outcomp->{$direct}->{system}->{name}})],
                   cistatusid=>'<=4');
         foreach my $rec ($system->getHashList(qw(admemail adm2email))){
             if ($rec->{admemail} ne "" && 
                 !exists($outcomp->{$direct}->{techcontact}->
                                   {email}->{$rec->{admemail}})){
                $outcomp->{$direct}->{techcontact}->{email}->
                               {$rec->{admemail}}->{'appl contact'}++;
             }
             if ($rec->{adm2email} ne "" && 
                 !exists($outcomp->{$direct}->{techcontact}->
                                   {email}->{$rec->{adm2email}}) ){
                $outcomp->{$direct}->{techcontact2}->{email}->
                          {$rec->{adm2email}}->{'system contact'}++;
             }
         }
      }
   }

   #
   # remove double names
   #
   foreach my $direct (qw(direct indirect)){
      if (exists($outcomp->{$direct}) && 
          exists($outcomp->{$direct}->{techcontact2})){
         foreach my $em (keys(%{$outcomp->{$direct}->{techcontact2}->{email}})){
            if (exists($outcomp->{$direct}->{techcontact}->{email}->{$em})){
               delete($outcomp->{$direct}->{techcontact2}->{email}->{$em});
            }
         }
      }
   }


   foreach my $direct (qw(direct indirect)){
      foreach my $an (keys(%{$outcomp->{$direct}->{application}->{name}})){
         my $k="itil::appl($an)";
         my $detail={};
         if (!exists($outcomp->{detail}->{$k})){
            $appl->ResetFilter();
            $appl->SetFilter(name=>\$an);
            my ($rec,$msg)=$appl->getOnlyFirst(qw(name tsm tsm2
                                                  businessteambossid));
            if (defined($rec)){
               my $found=0;
               if ($rec->{name} ne ""){
                  $detail->{name}=$rec->{name};
               }
               if ($rec->{tsmid} ne ""){
                  $detail->{techcontact}=$rec->{tsmid};
                  $self->LoadUserInfo($outcomp,$detail->{techcontact});
                  $found++;
               }
               if ($rec->{tsm2id} ne ""){
                  $detail->{techcontact2}=$rec->{tsm2id};
                  $self->LoadUserInfo($outcomp,$detail->{techcontact2});
                  $found++;
               }
               if (ref($rec->{businessteambossid}) eq "ARRAY"){
                  foreach my $boss (@{$rec->{businessteambossid}}){
                     $detail->{techboss}->{$boss}++;
                     $self->LoadUserInfo($outcomp,$boss);
                     $found++;
                  }
               }
               $outcomp->{detail}->{$k}=$detail if ($found);
            }
         }
         if (exists($outcomp->{detail}->{$k})){
            foreach my $reason (keys(%{$outcomp->{$direct}->{application}->
                                      {name}->{$an}})){
               $outcomp->{detail}->{$k}->{reason}->{$reason}++;
            }
         }
      }
      foreach my $sys (keys(%{$outcomp->{$direct}->{system}->{name}})){
         my $k="itil::system($sys)";
         my $detail={};
         if (!exists($outcomp->{detail}->{$k})){
            $system->ResetFilter();
            $system->SetFilter(name=>\$sys);
            my ($rec,$msg)=$system->getOnlyFirst(qw(name adm adm2
                                                    adminteambossid));
            if (defined($rec)){
               my $found=0;
               if ($rec->{name} ne ""){
                  $detail->{name}=$rec->{name};
               }
               if ($rec->{admid} ne ""){
                  $detail->{techcontact}=$rec->{admid};
                  $self->LoadUserInfo($outcomp,$detail->{techcontact});
                  $found++;
               }
               if ($rec->{adm2id} ne ""){
                  $detail->{techcontact2}=$rec->{adm2id};
                  $self->LoadUserInfo($outcomp,$detail->{techcontact2});
                  $found++;
               }
               if (ref($rec->{adminteambossid}) eq "ARRAY"){
                  foreach my $boss (@{$rec->{adminteambossid}}){
                     $detail->{techboss}->{$boss}++;
                     $self->LoadUserInfo($outcomp,$boss);
                     $found++;
                  }
               }
               $outcomp->{detail}->{$k}=$detail if ($found);
            }
         }
         if (exists($outcomp->{detail}->{$k})){
            foreach my $reason (keys(%{$outcomp->{$direct}->{system}->
                                      {name}->{$sys}})){
               $outcomp->{detail}->{$k}->{reason}->{$reason}++;
            }
         }
      }
   }
}


sub LoadUserInfo
{
   my $self=shift;
   my $outcomp=shift;
   my $userid=shift;
   if (!exists($outcomp->{user}->{$userid})){
      my $user=$self->getPersistentModuleObject("base::user");
      $user->SetFilter({userid=>\$userid});
      my ($rec,$msg)=$user->getOnlyFirst(qw(fullname surname givenname email
                                            office_phone office_mobile));
      if (defined($rec)){
         $outcomp->{user}->{$rec->{userid}}={fullname=>$rec->{fullname},
                                             surname=>$rec->{surname},
                                             givenname=>$rec->{givenname},
                                             email=>$rec->{email},
                                             phone=>$rec->{office_phone},
                                             mobile=>$rec->{office_mobile}};
      }
   }
}

1;
