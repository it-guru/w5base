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
   my ($self)=@_;
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
      my @comp=Query->Param("comp");
      push(@comp,"itil::system($rec->{id})");
      Query->Param("comp"=>\@comp);
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
   if (Query->Param("ADD")){
      $self->AddComponent();
   }
   my $objectname=Query->Param("objectname");
   my @comp=Query->Param("comp");
   my $comp;
   foreach my $curcomp (@comp){
      if (my ($objname,$id,$add)=$curcomp=~m/^(.+?)\((\d+)\)(.*)$/){
         my $o=getModuleObject($self->Config,$objname);
         $o->SetFilter(id=>\$id);
         my ($rec,$msg)=$o->getOnlyFirst(qw(name));
         if (defined($rec)){
            $comp.="<tr><td align=left>".
                   "<input type=hidden name=comp ".
                   "value=\"$objname($id)\">$rec->{name}</td>".
                   "<td width=1%>X</td>";
         }
      }
   }

   print <<EOF;
<style>
body{
   overflow:hidden;
}
</style>
<table border=0 cellspacing=0 cellpadding=0 height=100% width=100%>
EOF

   printf("<tr><td colspan=2 height=1%% style=\"padding:1px\" ".
             "valign=top>%s</td></tr>",$self->getAppTitleBar());
   print <<EOF;
<tr height=10%>
<td width=500 valign=top>

<div style="height:120px;background:silver;padding:5px;margin:5px;margin-left:1;margin-top:0;border-style:solid;border-color:black;border-width:1px">
<table height=100% border=0 cellspacing=0 cellpadding=3>
<tr>
<td width=1%>
<select name=objecttype style="width:100px">
<option value="itil::system(name)">System</option>
</select></td>
<td><input name=objectname value="$objectname" type=text style="width:100%"></td>
<td width=1%><input name=ADD style="width:120px" type=submit value=" => hinzufügen =>"></td>
</tr>
<tr>
<td colspan=3 align=right>
<table width=100% cellspacing=0 cellpadding=0>
<tr>
<td>Mit dem Ausfallsanalyse Werkzeug können die Auswirkungen eines Ausfalls einer Komponente des IT-Betriebes und die entsprechenden Kontakte analysiert werden. <font color=red><b>Achtung:&nbsp;pre&nbsp;Beta!!</b></font>
<td>
</td>
<td valign=bottom>
<input style="width:120px" onclick="doAnalyse();" type=button value=" analysieren ">
</td></tr></table>
</td>
</tr>
</table>
</div>

</td>
<td valign=top>
<div style="height:80px;overflow:auto">
<u>Komponentenliste:</u><br>

<div id=complist>
<table width=95% border=1>$comp</table>
</div>

</div>
</td>
</tr>
<tr height=1%>
<td colspan=2><hr></td>
</tr>
<tr height=1%>
<td colspan=2>&nbsp;</td>
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
</script>
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

   my $ndirect=keys(%{$outcomp{direct}->{system}->{name}})+
               keys(%{$outcomp{direct}->{application}->{name}});
   my $nindirect=keys(%{$outcomp{indirect}->{system}->{name}})+
                 keys(%{$outcomp{indirect}->{application}->{name}});
   
   print $self->getParsedTemplate("tmpl/FaultAnalytics",{
                                   static=>{
                                             NOW=>$nowstamp,
                                             INCOMP=>$incomphtm,
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
         my ($rec,$msg)=$o->getOnlyFirst(qw(name));
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

   my $d="<table border=1>";
   if (keys(%{$outcomp->{indirect}->{application}->{name}})){
      $d.="<tr><td>Applications</td><td>".
          join(", ",sort(keys(%{$outcomp->{indirect}->{application}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{indirect}->{businessprocess}})){
      foreach my $customer (sort(keys(%{$outcomp->{indirect}->
                                                  {businessprocess}}))){
         $d.="<tr><td>Geschäftsprozesse<br>$customer</td><td>".
             join(", ",sort(keys(%{$outcomp->{indirect}->{businessprocess}->
                                             {$customer}->{name}}))).
             "</td></tr>";
      }
   }
   if (keys(%{$outcomp->{indirect}->{techcontact}})){
      $d.="<tr><td>tech. Ansprechpartner</td><td>".
          join(", ",sort(keys(%{$outcomp->{indirect}->{techcontact}->
                                          {email}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{indirect}->{techcontact2}})){
      $d.="<tr><td>tech. Ansprechpartner Vetreter</td><td>".
          join(", ",sort(keys(%{$outcomp->{indirect}->{techcontact2}->
                                          {email}}))).
          "</td></tr>";
   }

   $d.="</table>";
   return($d);
}
   
sub FormatDirect
{
   my ($self,$incomp,$outcomp,%param)=@_;

   my $d="<table border=1>";
   if (keys(%{$outcomp->{direct}->{system}->{name}})){
      $d.="<tr><td>Systems</td><td>".
          join(", ",sort(keys(%{$outcomp->{direct}->{system}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{application}->{name}})){
      $d.="<tr><td>Applications</td><td>".
          join(", ",sort(keys(%{$outcomp->{direct}->{application}->{name}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{businessprocess}})){
      foreach my $customer (sort(keys(%{$outcomp->{direct}->
                                                  {businessprocess}}))){
         $d.="<tr><td>Geschäftsprozesse<br>$customer</td><td>".
             join(", ",sort(keys(%{$outcomp->{direct}->{businessprocess}->
                                             {$customer}->{name}}))).
             "</td></tr>";
      }
   }
   if (keys(%{$outcomp->{direct}->{techcontact}})){
      $d.="<tr><td>tech. Ansprechpartner</td><td>".
          join(", ",sort(keys(%{$outcomp->{direct}->{techcontact}->
                                          {email}}))).
          "</td></tr>";
   }
   if (keys(%{$outcomp->{direct}->{techcontact2}})){
      $d.="<tr><td>tech. Ansprechpartner Vetreter</td><td>".
          join(", ",sort(keys(%{$outcomp->{direct}->{techcontact2}->
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
      my $objlabel=$self->T($rec->{objname},$rec->{objname});
      $l{$rec->{name}}={name=>$rec->{name},objlabel=>$objlabel};
   }
   my $d="<table border=1>";
   my $dtxt="";
   foreach my $k (sort(keys(%l))){
      $d.="<tr><td>$l{$k}->{objlabel}</td><td>$l{$k}->{name}</td></tr>";
      $dtxt.="$l{$k}->{objlabel}:$l{$k}->{name}\n";
   }
   $d.="</table>";

   return($d,$dtxt);
}

sub analyse
{
   my ($self,$incomp,$outcomp,%param)=@_;
   my $user=$self->getPersistentModuleObject("base::user");
   my $system=$self->getPersistentModuleObject("itil::system");
   my $appl=$self->getPersistentModuleObject("itil::appl");
   my $applappl=$self->getPersistentModuleObject("itil::lnkapplappl");

   foreach my $rec ($self->inRecords($incomp)){
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
   my $o=getModuleObject($self->Config,"itil::lnkapplappl");
   $o->SetFilter(fromappl=>[keys(%{$outcomp->{direct}->{application}->{name}})],
                 toapplcistatus=>\'4');
   my @l=$o->getHashList(qw(toappl));
   foreach my $lnkrec (@l){
      $outcomp->{indirect}->{application}->{name}->{$lnkrec->{toappl}}->
                {'by interface'}++;
   }
       # at this, the fromapplcistatus should be considered
   $o->ResetFilter();
   $o->SetFilter(toappl=>[keys(%{$outcomp->{direct}->{application}->{name}})]);
   my @l=$o->getHashList(qw(fromappl));
   foreach my $lnkrec (@l){
      $outcomp->{indirect}->{application}->{name}->{$lnkrec->{fromappl}}->
                {'by interface'}++;
   }

   #
   # check direct businessprocess
   #
   my $o=getModuleObject($self->Config,"itil::businessprocess");
   foreach my $inmode (qw(direct indirect)){
      $o->ResetFilter();
      $o->SetFilter(cistatusid=>\'4',
                    applications=>[
                     keys(%{$outcomp->{$inmode}->{application}->{name}})]);
      my @l=$o->getHashList(qw(name customer));
      foreach my $brec (@l){
         $outcomp->{$inmode}->{businessprocess}->{$brec->{customer}}->
                   {name}->{$brec->{name}}++
      }
      $o->ResetFilter();
      $o->SetFilter(cistatusid=>\'4',
                    systems=>[
                     keys(%{$outcomp->{$inmode}->{system}->{name}})]);
      my @l=$o->getHashList(qw(name customer));
      foreach my $brec (@l){
         $outcomp->{$inmode}->{businessprocess}->{$brec->{customer}}->
                   {name}->{$brec->{name}}++
      }
   }




                              # direct->appl 
                              # direct->system
                              # direct->swinstance
                              # direct->technical
                              # direct->technical2
                              # indirect->appl
                              # indirect->system
                              # indirect->swinstance
                              # indirect->technical
                              # indirect->technical2
                              # critical->appl

   

}

1;
