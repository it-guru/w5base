package base::XLSExpand;
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
use kernel::App::Web;
use File::Temp(qw(tempfile));
@ISA    = qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->LoadSubObjs("ext/XLSExpand","XLSExpand");
   return($self);
}  

sub getValidWebFunctions
{  
   my ($self)=@_;
   return(qw(Main Welcome Result OutInfo));
}

sub Main
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css',
                                   'XLSExpand.css'],
                           target=>'out',multipart=>1,
                           action=>'Result',
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();
   print(<<EOF);
<style>
body{
  overflow:hidden;
}
</style>
EOF
   print("<table width=\"100%\" height=\"100%\" border=0 ".
         "cellspacing=0 cellpadding=0>");
   printf("<tr><td height=1%% valign=top>%s</td></tr>",$self->getAppTitleBar());
   print $self->getParsedTemplate("tmpl/XLSExpand",{});
   my @collabel=('A'..'Z');
   my $o="<option value=\"\">--</option>";
   for(my $c=0;$c<=$#collabel;$c++){
      $o.="<option value=\"$c\">".
          sprintf("%2s",$collabel[$c]).
          "</option>";
   }
   $o.="</select>";

   my %inkey=();
   my %outkey=();
   my $il="";
   my $ol="";
   foreach my $obj (values(%{$self->{XLSExpand}})){
      my $h=$obj->GetKeyCriterion();
      foreach my $v (keys(%{$h->{in}})){
         $inkey{$h->{in}->{$v}->{label}}=$v;
      }
      foreach my $v (keys(%{$h->{out}})){
         $outkey{$h->{out}->{$v}->{label}}=$v;
      }
   }
   foreach my $l (sort(keys(%inkey))){
      $il.="<tr><td>$l</td>".
           "<td width=1%><select onchange=\"chgstat(this)\" name=\"IN:$inkey{$l}\">$o</td></tr>"; 
   }
   foreach my $l (sort(keys(%outkey))){
      $ol.="<tr><td>$l</td>".
           "<td width=1%><select disabled name=\"OUT:$outkey{$l}\">$o</td></tr>"; 
   }
   print(<<EOF);
<table width="100%" cellpadding=10><tr><td>
  <table width="100%" border=0>
  <tr>
  <td width=50% height=1%><b>Eingangskriterien:</b></td>
  <td width=50% height=1%><b>Auffüll Informationen:</b></td>
  </tr>
  <tr id=ref>
    <td width=50%>
      <div id=inlist style="height:100px;overflow:auto">
      <table width="100%" border=1 cellpadding=0 cellspacing=0>$il</table>
      </div>
    </td>
    <td width=50%>
      <div id=outlist style="height:100px;overflow:auto">
      <table width="100%" border=1 cellpadding=0 cellspacing=0>$ol</table>
      </div>
    </td>
  </tr>
  </table>
</td></tr></table>
EOF
   print("</td>");
   print("<tr><td height=80px valign=top>");
   print(<<EOF);
<table width="100%" border=1 height=100%  cellpadding=0 cellspacing=0>
<tr>
<td width=40% valign=top >Eingabedatei:<br>
<input type=file name=file size=30 style="width:100%"><br><br>
Als Eingabe Datei können derzeit nur Excel-Dateien
verarbeitet werden.
</td>
<td width=20% align=center><input id=do type=button onClick="sendFile();" value=" => verarbeiten => "></td>
<td width=40% valign=top id=outref><iframe name=out id=out src=OutInfo width=40 height=20 frameborder=0 style="border-width:0px;padding:0;maring:0"></iframe>
</td>
</tr>
</table>
EOF
   print("</td></tr></table>");
   print(<<EOF);
<script language="JavaScript">

function ResizeAll()
{
   var il=document.getElementById("inlist");
   var ol=document.getElementById("outlist");
   il.style.height="10px";
   ol.style.height="10px";
   var ref=document.getElementById("ref");
   var newh=ref.offsetHeight-60;
   il.style.height=newh+"px";
   ol.style.height=newh+"px";

   var out=document.getElementById("out");
   out.style.height="10px";
   out.style.width="10px";
   var outref=document.getElementById("outref");
   var newheight=outref.offsetHeight;
   var newwidth=outref.offsetWidth;
   out.style.height=newheight+"px"; 
   out.style.width=newwidth+"px"; 
}

function sendFile()
{
   var dox=document.getElementById("do");
   dox.disabled=true;
   var out=document.getElementById("out");
   out.src="OutInfo";
   window.setTimeout("doSubmit();",1000); 
}

function chgstat(t)
{
  var ol=document.getElementById("outlist");
  var al=ol.getElementsByTagName('select');
  var il=document.getElementById("inlist");
  var ul=il.getElementsByTagName('select');
  var j=0;
  var y=0;

  for (i = 0; i < al.length; i++) {
         al[i].disabled=true;
  }

  while(j < ul.length && y == 0) 
  {
     if (ul[j].value){
        for (i = 0; i < al.length; i++) {
            al[i].disabled=false;
        }
        y = 1;
     }
     j = j + 1;
  }
}

function doSubmit()
{
   window.setTimeout("document.getElementById(\\"do\\").disabled=false;",2000);
   document.forms[0].submit();
}
addEvent(window, "load", ResizeAll);
addEvent(window, "resize", ResizeAll);
</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


sub OutInfo
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1);
   print(<<EOF);
<style> body{ padding:10px; } </style>
In der erzeugten Ausgabedatei werden die ausgewählten
Informationen als zusätzliche Spalten angefügt.
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub Result
{
   my $self=shift;

   foreach my $v (Query->Param()){
      Query->Delete($v) if (Query->Param($v) eq "");
   }

   my ($filename,$orgname,$size)=$self->LoadFile();
   if (!defined($filename) && !($self->LastMsg())){
      $self->LastMsg(ERROR,"invalid or unknown file specified"); 
   }
   if (defined($filename) && $filename ne ""){
      if ($size>0){
         if (!$self->ProcessFile($filename,$orgname)){
            if (!$self->LastMsg()){
               $self->LastMsg(ERROR,"unknown problem while parsing excel file");
            }
         }
      }
      else{
         $self->LastMsg(ERROR,"zero sized or unaccessable file");
      }
      unlink($filename);
   }
   if ($self->LastMsg()){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.App.Web.css'],
                              body=>1);
      print("<style> body{ padding:10px; } </style>");
      print $self->findtemplvar({},"LASTMSG");
      print $self->HtmlBottom(body=>1);
   }
   my %q=Query->MultiVars();
   #print STDERR (Dumper(\%q));

}

sub LoadFile
{
   my $self=shift;
   my $infile=Query->Param("file");
   my $orgname=scalar($infile);

   if ($infile eq ""){
      return(undef);
   }
   else{
      no strict;
      my $fh;
      ($fh, $filename)=tempfile();
      my $s=0;
      if (seek($infile,0,SEEK_SET)){
         my $bsize=1024;
         my $data;
         while(1){
           my $nread = read($infile, $data, $bsize);
           last if (!$nread);
           $s+=$nread;
           if (syswrite($fh,$data,$nread)!=$nread){
              $self->LastMsg(ERROR,"error while writing tempfile");
              return(undef);
           }
         }
         close($fh);
      }
      return($filename,$orgname,$s);
   }
   return(undef);
}

sub ProcessFile
{
   my $self=shift;
   my $filename=shift;
   my $orgname=shift;
   my $newfile=$filename."new.tmp";
   my ($oExcel,$oBook);

   #
   # Pass 1: Parse IN-Excel
   #
   eval('
      use Spreadsheet::ParseExcel;
      use Spreadsheet::ParseExcel::SaveParser;
      $oExcel=new Spreadsheet::ParseExcel::SaveParser;
      $oBook=$oExcel->Parse($filename);
   ');
   if (!defined($oExcel) || !defined($oBook)){
      my $msg=$@;
      $self->LastMsg(ERROR,"Pass1: can't parse excel file");
      $self->LastMsg(ERROR,$msg);
      return(undef);
   }
   #
   # Check if summary Sheet already exists. If it is, this would produce
   # an exception on trying to add the summary sheet.
   #
   foreach my $sheet (@{$oBook->{Worksheet}}) {
      if ($sheet->{Name} eq "Summary"){
         $self->LastMsg(ERROR,"invalid XLS file - Summary sheet exists");
         return();
      }
   }

   #
   # Pass 2: Process Lines
   #
   for(my $iSheet=$oBook->{'SheetCount'}-1;$iSheet>=0;$iSheet--){
      my $oWkS=$oBook->{'Worksheet'}[$iSheet];
      next if (!defined($oWkS));
      my $maxrow;
      my %globalrec=();
      for(my $row=0;$row<=$oWkS->{'MaxRow'};$row++){
        my @rowarray=();
        for(my $col=0;$col<=$oWkS->{'MaxCol'};$col++){
           if ($oWkS->{'Cells'}[$row][$col]){
              $rowarray[$col]=$oWkS->{'Cells'}[$row][$col]->Value();
           }
        }
        my @orgdata=@rowarray;
        my %inrec=();
        my %outrec=();
        my %out=();
        my $haveindata=0;
        foreach my $invar (Query->Param()){
           if ($invar=~m/^IN:/){
              my $inindex=Query->Param($invar);
              $invar=~s/^IN://;
              $inrec{$invar}=trim($orgdata[$inindex]); 
              $inrec{$invar}=~s/[\*\?]//g;
              $haveindata=1 if ($inrec{$invar} ne "");
           }
           if ($invar=~m/^OUT:/){
              my $outindex=Query->Param($invar);
              $invar=~s/^OUT://;
              $out{$invar}=undef; 
              $outrec{$invar}=$outindex; 
           }
        }
        if (keys(%inrec)==0){
           $self->LastMsg(ERROR,"Pass2: no in criterion specified");
           unlink($filename);
           return(undef);
        }
        if (keys(%outrec)==0){
           $self->LastMsg(ERROR,"Pass2: no informations to append");
           unlink($filename);
           return(undef);
        }
        if ($haveindata){
           $maxrow=$row;
           #printf STDERR ("==>ourrec=%s\n---\n",Dumper(\%outrec));
           #printf STDERR ("0==>in=%s\n---\n",Dumper(\%inrec));
           my $res=$self->ProcessLine($row,\%inrec,\%out);
           #printf STDERR ("1==>in=%s\n---\n",Dumper(\%inrec));
           #printf STDERR ("1==>out=%s\n---\n",Dumper(\%out));
           foreach my $kout (keys(%out)){
              if (defined($out{$kout})){
                 my @d=($out{$kout});
                 if (ref($out{$kout}) eq "HASH"){
                    @d=sort(keys(%{$out{$kout}}));
                 }
                 foreach my $v (@d){
                    $globalrec{$kout}->{$v}++;
                 }
                 my $sep=",";
                 $sep=";" if ($kout=~m/mail/);    # use ; for contact and
                 $sep=";" if ($kout=~m/contact/); # mail keys
                 my $d=join("$sep ",@d);
                 if (defined($outrec{$kout})){
                    $oBook->AddCell($iSheet,$row,$outrec{$kout},$d,0);
                 }
              }
           }
        }
      }
      my %outkey;
      foreach my $obj (values(%{$self->{XLSExpand}})){
         my $h=$obj->GetKeyCriterion();
         foreach my $v (keys(%{$h->{out}})){
            $outkey{$v}=$h->{out}->{$v}->{label};
         }
      }
      my $oldstyle=1;
      if ($Spreadsheet::ParseExcel::VERSION eq "0.57" ||
          $Spreadsheet::ParseExcel::VERSION eq "0.59"){
          
         $oldstyle=0;
      }

      if (defined($maxrow) && keys(%globalrec)>0){
         my $c=0;
         $oBook->AddCell($iSheet,$maxrow+2,0,"Summary:",0);
         my $sSheet=$oBook->AddWorksheet('Summary');
         $sSheet->{Scale}=100;
         $sSheet=$oBook->{'SheetCount'}-1; # Last Sheet Number;
         $c++;
         my %l;
         foreach my $k (keys(%globalrec)){
            $oBook->AddCell($iSheet,$maxrow+2+$c,0,$outkey{$k}.":",0);
            $oBook->AddCell($iSheet,$maxrow+2+$c,1,
                            join("; ",sort(keys(%{$globalrec{$k}}))),0);

            if ($oldstyle){
               $oBook->AddCell($sSheet,0,$c-1,$outkey{$k},0);
            }
            else{
               $sSheet->AddCell(0,$c-1,$outkey{$k},0);
            }
            my $sRow=1;
            foreach my $v (sort(keys(%{$globalrec{$k}}))){
               if ($oldstyle){
                  $oBook->AddCell($sSheet,$sRow++,$c-1,$v,0);
               }
               else{
                  $sSheet->AddCell($sRow++,$c-1,$v,0);
               }
            }
            $c++;
         }
      }
   }




   #
   # Pass 3: Send created file
   #
   $oExcel->SaveAs($oBook,$newfile);
   if (open(F,"<$newfile")){
      my $label=".W5Base.XLSExpand.".$self->ExpandTimeExpression("now","stamp",
                           $self->UserTimezone(),$self->UserTimezone());
      $orgname=~s/\.xls$/$label\.xls/i;
      print($self->HttpHeader("application/vnd.ms-excel",
                              attachment=>1,
                              filename=>$orgname,
                              cache=>5));
      print join("",<F>);
      close(F);
   }
   else{
      $self->LastMsg(ERROR,"can't open tempoary result file");
      return(undef);
   }
   unlink($filename);
   unlink($newfile);

   return(1);
}


sub ProcessLine
{
   my $self=shift;
   my $line=shift;
   my $in=shift;
   my $out=shift;
   my $loopcount=1; 
   my @proclist=sort({$a->getPriority() <=> $b->getPriority()} 
                     values(%{$self->{XLSExpand}}));
   my @failproc;

   while($#proclist!=-1 && $loopcount<10){
      @failproc=();
      foreach my $obj (@proclist){
         #msg(INFO,"ProcessLine for $obj");
         my $isprocessed=$obj->ProcessLine($line,$in,$out,$loopcount);
         if (!$isprocessed){
            push(@failproc,$obj);
         }
         #msg(INFO,"ProcessLine for $obj returned $isprocessed");
      }
      if ($loopcount>1){
         @proclist=@failproc;
      }
      $loopcount++;
   }

   return(1);
}


1;
