package kernel::Output::XlsV01;
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
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}


sub FormaterOrderPrio
{
   return(100);
}



sub IsModuleSelectable
{
   eval("use Spreadsheet::WriteExcel::Big;");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}

sub forceDownloadAsAttachment
{
   my $self=shift;

   return(1);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xls.gif");
}
sub Label
{
   return("Output to XLS");
}
sub Description
{
   return("Writes the data in Excel/XLS Format.");
}

sub MimeType
{
   return("application/vnd.ms-excel");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".xls");
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getDataObj();
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n";
   $d.="Cache-Control: max-age=10\n\n";  # for Excel direct access
   return($d);
}

sub Init
{
   my $self=shift;
   my ($fh,$baseview)=@_;
   binmode($$fh) if (defined($fh));
   $self->setFilename("/tmp/tmp.$$.xls");
   $self->initWorkbook();
   $self->addSheet("W5Base");

   return($self->SUPER::Init(@_));
}


sub setFilename
{
   my $self=shift;
   my $filename=shift;
   $self->{filename}=$filename;
}

sub initWorkbook
{
   my $self=shift;

   eval("use Spreadsheet::WriteExcel::Big;");
   if ($@ eq ""){
      $self->{'workbook'}=Spreadsheet::WriteExcel::Big->new($self->{filename});
      $self->{'format'}={};
      $self->{'fcolors'}={};
      $self->{'maxlen'}=[];
      my $app=$self->getParent()->getParent();
      my $objname=$app->T($app->Self(),$app->Self());
      my $now=NowStamp("en");
      my $qval=$app->ExpandTimeExpression("$now+28d");
      $qval=~s/\s.*$//;

      my $author=$ENV{REMOTE_USER};
      my $userid;

      if ($app->can("getCurrentUserId")){
         $userid=$app->getCurrentUserId();
      }

      if ($userid ne ""){
         my $o=getModuleObject($app->Config,"base::user");
         if (defined($o)){
            $o->SetFilter({userid=>\$userid});
            my ($urec,$msg)=$o->getOnlyFirst(qw(fullname)); 
            if (defined($urec)){
               $author=$urec->{fullname};
            }
         }
      }

      my $comment=sprintf($app->T('This file must be deleted after %s .',
                          'kernel::Output::XlsV01'),$qval);

      $self->{'workbook'}->set_properties(
         title    => $app->T('XLS Export from','kernel::Output::XlsV01').
                     ' '.$objname,
         author   => $author,
         comments => $comment,
      );
      return($self->{'workbook'});
   }
   return(undef);
}


sub addSheet
{
   my $self=shift;
   my $sheetname=shift;
   $sheetname=~s/[^A-Z0-9]/_/gi;
   $self->{'worksheet'}=$self->{'workbook'}->addworksheet($sheetname);
   $self->{xlscollindex}={};
   $self->{maxcollindex}=0;
   return($self->{'worksheet'});
}


sub getColorIndex
{
   my $self=shift;
   my $colorstring=shift;

   if (!exists($self->{'fcolors'}->{$colorstring})){
      my $n=keys(%{$self->{'fcolors'}});
      $self->{'fcolors'}->{$colorstring}=
        $self->{'workbook'}->set_custom_color($n+10,$colorstring);
   }
   return($self->{'fcolors'}->{$colorstring});
}




sub Format
{
   my $self=shift;
   my $formatname=shift;
   if (exists($self->{format}->{$formatname})){
      return($self->{format}->{$formatname});
   }

   my $name=$formatname;
   my $usecolor;
   if (my ($col)=$name=~m/\.color=\"(#[0-9a-fA-F]+)\"/){
      $name=~s/\.color=\"(#[0-9a-fA-F]+)\"//g;
      $usecolor=$self->getColorIndex($col);
   }
   my $usebgcolor;
   if (my ($col)=$name=~m/\.bgcolor=\"(#[0-9a-fA-F]+)\"/){
      $name=~s/\.bgcolor=\"(#[0-9a-fA-F]+)\"//g;
      $usebgcolor=$self->getColorIndex($col);
   }
   my $usebcolor;
   if (my ($col)=$name=~m/\.bcolor=\"(#[0-9a-fA-F]+)\"/){
      $name=~s/\.bcolor=\"(#[0-9a-fA-F]+)\"//g;
      $usebcolor=$self->getColorIndex($col);
   }
   my $numformat;
   if (($numformat)=$name=~m/\.numformat=\"(.+)\"/){
      $name=~s/\.numformat=\"(.+)\"//g;
   }

   my $format;
   if ($name eq "default"){
      $format=$self->{'workbook'}->addformat(text_wrap=>1,align=>'top');
   }
   elsif ($name eq "date.de"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy HH:MM:SS');
   }
   elsif ($name eq "date.en"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd HH:MM:SS');
   }
   elsif ($name eq "dayonly.de"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'dd.mm.yyyy');
   }
   elsif ($name eq "dayonly.en"){
      $format=$self->{'workbook'}->addformat(align=>'top',
                                          num_format => 'yyyy-mm-dd');
   }
   elsif ($name eq "longint"){
      $format=$self->{'workbook'}->addformat(align=>'top',num_format => '#');
   }
   elsif ($name eq "header"){
      $format=$self->{'workbook'}->addformat();
      $format->copy($self->Format("default"));
      $format->set_bold();
   } 
   elsif (my ($precsision)=$name=~m/^number\.(\d+)$/){
      $format=$self->{'workbook'}->addformat();
      $format->copy($self->Format("default"));
      my $xf="#";
      if ($precsision>0){
         $xf="0.";
         for(my $c=1;$c<=$precsision;$c++){$xf.="0";};
      }
      $format->set_num_format($xf);
   }
   if (defined($format)){
      if (defined($usecolor)){
         $format->set_color($usecolor);
      }
      if (defined($usebgcolor)){
         $format->set_bg_color($usebgcolor);
      }
      if (defined($usebcolor)){
         $format->set_border(1);
         $format->set_border_color($usebcolor);
      }
      if (defined($numformat)){
         $format->set_num_format($numformat);
      }
      $self->{format}->{$formatname}=$format;
      return($self->{format}->{$formatname}); 
   }
 #  print STDERR msg(WARN,"XLS: setting format '$name' as 'default'");
   return($self->Format("default"));
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getDataObj();
   my $d;
   my @cell=();
   my @cellobj=();
   foreach my $fo (@{$recordview}){
      next if ($fo->Type() eq "Link");
      next if ($fo->Type() eq "Container");
      my $name=$fo->Name();
      if (!defined($self->{xlscollindex}->{$name})){
         $self->{xlscollindex}->{$name}=$self->{maxcollindex};
         $self->{maxcollindex}++;
      }
      my $data="undef";
      if ($fo->UiVisible("XlsV01",current=>$rec)){ 
         if ($fo->can("getLineSubListData")){
            $data=$fo->getLineSubListData($rec,"xls");
         }
         else{
            $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      fieldbase=>$fieldbase,
                                      current=>$rec,
                                      mode=>$self->modeName(),
                                     },$name,"formated");
            #if ($self->getParent->getParent->Config->Param("UseUTF8")){
            #   $data=utf8($data);
            #   $data=$data->latin1();
            #}
         }
      }
      else{
         $data="-";
      }
      $data=~s/\r\n/\n/g;
      $cell[$self->{xlscollindex}->{$name}]=$data;
      $cellobj[$self->{xlscollindex}->{$name}]=$fo;
      foreach my $subline (split(/\n/,$data)){
         if (length($subline)>
             $self->{'maxlen'}->[$self->{xlscollindex}->{$name}]){
            $self->{'maxlen'}->[$self->{xlscollindex}->{$name}]=
                                                      length($subline);
         }
      }
   }
   for(my $cellno=0;$cellno<=$#cell;$cellno++){
      my $field;
      if (defined($cellobj[$cellno])){
         $field=$cellobj[$cellno];
      }
      my $data=$cell[$cellno];
      my $format="default";
      if (defined($field)){
         $format=$field->getXLSformatname($data);
      }
      if (!defined($data)){
         $data="";
      }
      if ($format=~m/^(date|dayonly)\./){
     # printf STDERR ("fifi: field=%s format=%s data=%s\n",$field->Name(),
     #                $format,$data);
         $self->{'worksheet'}->write_date_time($lineno+1,$cellno,$data,
                                               $self->Format($format));
      }
      else{
         $data="'".$data if ($data=~m/^=/);

         my $numformat=$self->Format($format)->{_num_format};
         if ($numformat eq '@'){
            $self->{'worksheet'}->write_string($lineno+1,$cellno,$data,
                                               $self->Format($format));
         } else {
            $self->{'worksheet'}->write($lineno+1,$cellno,$data,
                                        $self->Format($format));
         }
      }
   }
   return(undef);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my @view;
   if (ref($self->{fieldobjects}) eq "ARRAY"){
      @view=@{$self->{fieldobjects}};
   }

   for(my $cellno=0;$cellno<=$#view;$cellno++){
      #next if (!($view[$cellno]->UiVisible()));   # ist nicht mehr notwendig
      next if ($view[$cellno]->Type() eq "Container");
      my $xlscellno=$self->{xlscollindex}->{$view[$cellno]->Name()};
      my $label=$view[$cellno]->Label();
      my $fieldHeader="";
      $view[$cellno]->extendFieldHeader($self->{WindowMode},$rec,\$fieldHeader,
                                        $self->Self);
      $label.=$fieldHeader;
      my $format="header";
      { # color handling
         my $xlscolor=$view[$cellno]->xlscolor;
         my $xlsbgcolor=$view[$cellno]->xlsbgcolor;
         my $xlsbcolor=$view[$cellno]->xlsbcolor;
         my $colset=0;
         if (defined($xlscolor)){
            $format.=".color=\"".$xlscolor."\"";
         }
         if (defined($xlsbgcolor)){
            $format.=".bgcolor=\"".$xlsbgcolor."\"";
            $colset++;
         }
         if ($colset || defined($xlsbcolor)){
            if (!defined($xlsbcolor)){
               $xlsbcolor="#000000";
            }
            $format.=".bcolor=\"".$xlsbcolor."\"";
         }
      }

      if (length($label)>$self->{'maxlen'}->[$cellno]){
         $self->{'maxlen'}->[$xlscellno]=length($label);
      }
      $self->{'worksheet'}->write(0,$xlscellno,$label,
                                  $self->Format($format));
      { # column width calculation
         my $xlswidth;
         if (defined($view[$cellno]->htmlwidth())){
            $xlswidth=$view[$cellno]->htmlwidth()*0.3;
         }
         if (defined($view[$cellno]->xlswidth())){
            $xlswidth=$view[$cellno]->xlswidth();
         }
         if (!defined($xlswidth)){
            $xlswidth=$self->{'maxlen'}->[$xlscellno]*1.2;
         }
         $xlswidth=15 if (defined($xlswidth) && $xlswidth<15);
         $xlswidth=100 if ($xlswidth>100);
         if (defined($xlswidth)){
            $self->{'worksheet'}->set_column($xlscellno,$xlscellno,$xlswidth);
         }
      }
   }

   return(undef);
}

sub closeWorkbook
{
   my $self=shift;

   if (defined($self->{'workbook'})){
      $self->{'workbook'}->close();
      return($self->{'workbook'});
   }
   return(undef);
}


sub getEmpty
{
   my $self=shift;
   my (%param)=@_;
   my $d="";
   $self->Init();
   print STDOUT ($self->DownloadHeader().
                 $self->getHttpHeader());


   $self->Finish();

   return($d);
}


sub Finish
{
   my ($self,$fh)=@_;
   $self->closeWorkbook();

   if (open(F,"<$self->{filename}")){
      $|=1;
      my $buf;
      while(sysread(F,$buf,8192)){
         print STDOUT $buf;
      }
      close(F);
   }
   else{
      printf STDERR ("ERROR: can't open $self->{filename}\n");
   }
   unlink($self->{filename});
   return();
}

1;
