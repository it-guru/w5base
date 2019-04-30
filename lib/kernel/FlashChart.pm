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
   my $so="SO_$name";


   my $maxdataset=0; 
   my $datacode="";

   my $vstring="";
   my $ymax=9;
   {
      $maxdataset++;
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
  
      $datacode.="{\n";
      $datacode.="var vset={\n";
      $datacode.="   label: '$param{legend}',\n";
      $datacode.="   fill: false,\n";
      $datacode.="   backgroundColor: 'rgb(255, 99, 132)',\n";
      $datacode.="   borderColor: 'rgb(255, 99, 132)',\n";
      $datacode.="   data: [$vstring]\n";
      $datacode.="};\n";
      $datacode.="config.data.datasets.push(vset);\n";
      $datacode.="}\n";
      
   }
#   if (defined($param{avg})){
#      $maxdataset++;
#      $datacode.="$so.addVariable(\"values_$maxdataset\",\"".
#                 join(",",@{$param{avg}})."\");\n".
#                 "$so.addVariable(\"line_$maxdataset\",\"1,0x86B34B,".
#                 $self->T("averange").",10,4\");\n";
#   }
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
      my $label=$self->T("count of employees");
      $datacode.="{\n";
      $datacode.="var vset={\n";
      $datacode.="   label: '$label',\n";
      $datacode.="   fill: false,\n";
      $datacode.="   backgroundColor: 'rgb(54, 162, 235)',\n";
      $datacode.="   borderColor: 'rgb(54, 162, 235)',\n";
      $datacode.="   data: [$vstring]\n";
      $datacode.="};\n";
      $datacode.="config.data.datasets.push(vset);\n";
      $datacode.="}\n";
   }
   if (defined($param{ymax})){
     $datacode.="config.options.scales.yAxes.push({\n";
     $datacode.=" display:true,";
     $datacode.=" ticks:{suggestedMin:0,";
     $datacode.=" suggestedMax:$param{ymax}}";
     $datacode.="};\n";
   }
   else{
     $datacode.="config.options.scales.yAxes.push({\n";
     $datacode.=" display:true,";
     $datacode.=" ticks:{suggestedMin:0,";
     $datacode.=" suggestedMax:$ymax}";
     $datacode.="});\n";
   }


   my $xlabel;
   if (!defined($param{xlabel}) || ref($param{xlabel}) ne "ARRAY"){
      $xlabel="'Jan','Feb','Mar','Apr','May','Jun',".
              "'Jul','Aug','Sep','Okt','Nov','Dez'";
   }
   else{
      $xlabel=join(",",map({"'".$_."'";} @{$param{xlabel}}));
   }
   my $titlecode="";
   if ($maxdataset>1){
      $titlecode="title: {display: true,text: '$param{legend}'},";
   }

   $d=<<EOF;
<canvas id="$name" style="padding:0px;margin:4px;border:1px solid #30579f;
                       width:${w}px;height:${h}px;"></canvas>
<script language="JavaScript">
function buildChart$name()
{
   var config = {
         type: 'line',
         data: { labels: [$xlabel], datasets: [] },
         options: {
            responsive: true,$titlecode
            tooltips: {
               mode: 'index',
               intersect: false,
            },
            hover: {
               mode: 'nearest',
               intersect: true
            },
            layout:{
               padding: {
                left: 10,
                right: 20,
                top: 10,
                bottom: 10
               }
            },
            scales: {
               xAxes: [{ display: true }], yAxes: []
            }
         }
      }; 
   var $so=document.getElementById('$name').getContext('2d');
   if ($so){
      $datacode;
      window.$so=new Chart($so,config);
   }
   else{
      alert("error: can not create a canvas object");
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

