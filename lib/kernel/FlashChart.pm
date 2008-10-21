package kernel::FlashChart;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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

sub buildChart
{
   my $self=shift;
   my $name=shift;
   my $data=shift;
   my %param=@_;
   my $d="";
   $param{width}=540            if (!defined($param{width}));
   $param{height}=300           if (!defined($param{height}));
   $param{mode}="line_dot"      if (!defined($param{mode}));
   $param{legend}=$param{label} if (!defined($param{legend}));
   my $w=$param{width};
   my $h=$param{height};
   my $swfobjcode="static/open-flash-chart/actionscript/open-flash-chart.swf";
   my $so="SO_$name";


   my $vstring="";
   my $ymax=9;
   if (defined($param{minymax})){
      $ymax=$param{minymax};
   }
   if (ref($data) eq "ARRAY"){
      foreach my $d (@$data){
         $vstring.="," if ($vstring ne "");
         if (defined($d)){
            $vstring.=$d;
            $ymax=$d if ($ymax<$d);
         }
         else{
            $vstring.="null";
         }
      }
   }
   $ymax=calcScaleMax($ymax*1.01);
  
   
   my $datacode;
  
   my $maxdataset; 
   if (defined($param{greenline})){
      my @grline;
      for(my $c=0;$c<12;$c++){
         push(@grline,$param{greenline});
      }
      my $grline=join(",",@grline);
      $datacode="$so.addVariable(\"values\",\"$grline\");\n".
                "$so.addVariable(\"line\",\"1,0x00ff00\");\n".
                "$so.addVariable(\"values_2\",\"$vstring\");\n".
                "$so.addVariable(\"$param{mode}_2\",\"3,0xff0000,".
                $param{legend}.",10,4\");\n";
      $maxdataset=2;
   }
   else{
      $datacode="$so.addVariable(\"values\",\"$vstring\");\n".
                "$so.addVariable(\"$param{mode}\",\"3,0xff0000,".
                $param{legend}.",10,4\");\n";
      $maxdataset=1;
   }
   if (defined($param{avg})){
      $maxdataset++;
      $datacode.="$so.addVariable(\"values_$maxdataset\",\"".
                 join(",",@{$param{avg}})."\");\n".
                 "$so.addVariable(\"line_$maxdataset\",\"1,0x86B34B,".
                 $self->T("averange").",10,4\");\n";
   }
   if (defined($param{employees})){
      $maxdataset++;
      my $y2max=19;
      my $vstring;
      foreach my $d (@{$param{employees}}){
         $vstring.="," if ($vstring ne "");
         if (defined($d)){
            $vstring.=$d;
            $y2max=$d if ($y2max<$d);
         }
         else{
            $vstring.="null";
         }
      }
      $y2max=calcScaleMax($y2max*1.01);
      $datacode.="$so.addVariable(\"values_$maxdataset\",\"$vstring\");\n".
                 "$so.addVariable(\"line_$maxdataset\",\"1,0x0000ff,".
                 $self->T("count of employees").",10,4\");\n".
                 "$so.addVariable(\"y2_lines\",\"$maxdataset\");\n".
                 "$so.addVariable(\"y2_max\",\"$y2max\");\n".
                 "$so.addVariable(\"y2_legend\",\"".
                 $self->T("employees").",10,4\");\n".
                 "$so.addVariable(\"show_y2\",\"true\");\n";
   }
   if (defined($param{ymax})){
     $datacode.="$so.addVariable(\"y_max\",\"$param{ymax}\");\n";
   }
   else{
     $datacode.="$so.addVariable(\"y_max\",\"$ymax\");\n";
   }
   my $xlabel;
   if (!defined($param{xlabel}) || ref($param{xlabel}) ne "ARRAY"){
      $xlabel="Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Okt,Nov,Dez";
   }
   else{
      $xlabel=join(",",@{$param{xlabel}});
   }


   $d=<<EOF;
<div id="$name" style="padding:0px;margin:10px;border:1px solid #30579f;
                       width:${w}px;height:${h}px;"></div>
<script language="JavaScript">
function buildChart$name()
{
   var $so=new SWFObject("../../../$swfobjcode","$name",
                         "$w","$h","9","#FFFFFF");
   if ($so){
      $so.addVariable("variables","true");
      $so.addVariable("title","$param{label},{font-size: 15;}");
      $so.addVariable("bg_colour","#f4f4f4");
      $so.addVariable("y_label_size","15");
      $so.addVariable("y_ticks","5,10,5");
      $datacode
      $so.addVariable("x_labels","$xlabel");
      //$so.addVariable("x_axis_steps","2");
      $so.addParam("allowScriptAccess", "always" );//"sameDomain");
      //$so.addParam("onmouseout", "onrollout2();" );
      $so.write("$name");
   }
   else{
      alert("error: can not create a flash object");
   }
}
addEvent(window,"load",buildChart$name);
</script>
EOF
   return($d);
}

sub calcScaleMax
{
   my $max=shift;

   my $scalemax=0.001;
   my $chk1=10;
   my $chk2=5;
   while(1){
      if ($max<$scalemax*$chk2){
         $scalemax=$scalemax*$chk2;
         last;
      }
      $chk2=$chk2*10;
      if ($max<$scalemax*$chk1){
         $scalemax=$scalemax*$chk1;
         last;
      }
      $chk1=$chk1*10;
   }
   return($scalemax);
}

1;

