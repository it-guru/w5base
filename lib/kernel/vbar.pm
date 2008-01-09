package kernel::vbar;
use vars qw(@ISA);
use strict;
use kernel;

@ISA=qw();

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);

   $self->{RangeMin}=undef;
   $self->{RangeMax}=undef;
   $self->{RangeMaxSpaceFactor}=1.01;
   $self->{prefix}="VBAR";
   $self->{Segmentation}=1;
   $self->{SegmentParam}={};
   $self->{BarHeight}="25";
   $self->{SpanHeight}="5";
   return($self);
}

sub AddSpan
{
   my $self=shift;
   my $line=shift;
   my $name=shift;
   my $from=shift;
   my $to=shift;
   my %param=@_;
   $line=0 if (!defined($line));
   
   $self->{span}->{$name}=[] if (!defined($self->{span}->{$name}));
   push(@{$self->{span}->{$name}},{from=>$from,
                                   to=>$to,
                                   line=>$line,
                                   param=>\%param});
}

sub SetSegmentation($)
{
   my $self=shift;
   my $n=shift;
   $self->{Segmentation}=$n;
}

sub GetSegmentation
{
   my $self=shift;
   return($self->{Segmentation});
}

sub SetLabel
{
   my $self=shift;
   my $name=shift;
   my $label=shift;
   my $param=shift;

   $param={} if (!defined($param));
   $param->{label}=$label if (defined($label));
   $param->{label}=$name if (!defined($param->{label}));

   $self->{label}->{$name}=$param;
   $self->{span}->{$name}=[] if (!defined($self->{span}->{$name}));
}

sub SetBarHeight
{
   my $self=shift;
   my $min=shift;
   $self->{BarHeight}=$min;
}

sub GetBarHeight
{
   my $self=shift;
   return($self->{BarHeight}) if (defined($self->{BarHeight}));
}

sub SetSpanHeight
{
   my $self=shift;
   my $min=shift;
   $self->{SpanHeight}=$min;
}

sub GetSpanHeight
{
   my $self=shift;
   return($self->{SpanHeight}) if (defined($self->{SpanHeight}));
}

sub SetRangeMin
{
   my $self=shift;
   my $min=shift;
   $self->{RangeMin}=$min;
}

sub GetRangeMin
{
   my $self=shift;
   return($self->{RangeMin}) if (defined($self->{RangeMin}));
   my $min=undef;
   foreach my $name (sort(keys(%{$self->{span}}))){
      foreach my $span (@{$self->{span}->{$name}}){
         $min=$span->{to} if ($min>$span->{to} || !defined($min));
      }
   }
   $min=0 if (!defined($min));
   return($min);
}

sub SetRangeMax
{
   my $self=shift;
   my $max=shift;
   $self->{RangeMax}=$max;
}

sub GetRangeMax
{
   my $self=shift;
   return($self->{RangeMax}) if (defined($self->{RangeMax}));
   my $max=0;
   foreach my $name (sort(keys(%{$self->{span}}))){
      foreach my $span (@{$self->{span}->{$name}}){
         $max=$span->{to} if ($max<$span->{to});
      }
   }
   $max=$max;
   $max=1 if ($max==0);
   return($max);
}

sub SetPrefix
{
   my $self=shift;
   my $prefix=shift;
   $self->{prefix}=$prefix;
}

sub init
{
   my $self=shift;
   my $barh=$self->{BarHeight};
   my $d="";
   $d.=<<EOF;
<style>
table.VBAR{
   width:100%;
   border-collapse:collapse;
}
div.VBAR_HeadSegment{
   float:left;
   overflow:hidden; 
   border-style:none;
   border-width:0px;
   padding:0;
   margin:0;
}
div.VBAR_DataSegment{
   float:left;
   overflow:hidden; 
   border-style:none;
   border-width:0px;
   padding:0;
   margin:0;
   height:100%;
}
div.VBARbar{
   overflow:hidden; 
   border-style:solid;
   border-width:0px;
   padding:0;
   margin:0;
   height:100%;
}
div.VBARlabel{
   height:$self->{BarHeight}px;
   border-bottom-style:solid;border-bottom-color:black;
   border-bottom-width:1px;vertical-align:middle;
   padding-left:5px;padding-right:5px;
   padding-top:2px;
   vertical-align:middle;
}
span.VBARlabel{
   overflow:hidden; 
   border-style:none;
}
//tr.VBARvline{
//   height:${barh}px;
//}
td.VBARbar{
   vertical-align:top;
}
hr.VBAR{
   margin:0;padding:0;border-width:1px;height:1px;
}
</style>
EOF
   $d.="<script language=\"JavaScript\">".
       $self->getMarkLib().
       "</script>";
   return($d);
}


sub render
{
   my $self=shift;
   my $rMin=$self->GetRangeMin();
   my $rMax=$self->GetRangeMax();
   my $segCount=$self->GetSegmentation();
   my $d="<script language=\"JavaScript\">".$self->getMarkScript()."</script>";
   $d.="<table class=$self->{prefix} cellspacing=0 cellpadding=0 border=0>\n";
   $d.="<tr class=$self->{prefix}hline>".
       "<td valign=bottom style=\";border-right:solid;border-width:1px\">".
       "<div class=$self->{prefix}label>&nbsp;</div></td>";
   $d.="<td>";
   $d.="<div style=\"overflow:hidden;width:500px;".
       "height:1px;padding:0;margin:0\"></div>";
   $d.="<div class=$self->{prefix}bar>";
   $d.=$self->GetRenderedHeadline();
   $d.="</div>";
   $d.="</td></tr>\n";
   my $line=1;
   foreach my $name (sort({ 
                           my $bk;
                           if (defined($self->{label}->{$a}->{order}) ||
                               defined($self->{label}->{$b}->{order})){
                              $bk=$self->{label}->{$a}->{order} <=>
                                  $self->{label}->{$b}->{order};
                           }
                           else{
                              $bk=$a cmp $b;
                           }
                           $bk; } keys(%{$self->{span}}))){
      $d.="<tr class=$self->{prefix}vline>";
      my $label=$name;
      $label=$self->{label}->{$name}->{label};
      $label="unknown" if ($label eq "");
      my $css.="border-bottom:solid;border-width:1px";
      if ($line==1){
         $css.=";border-top:solid;border-width:1px";
      }
      $css.=";border-right:solid;border-width:1px";
      $d.="<td width=1% nowrap><div class=$self->{prefix}label>".
          "$label</div></td>";
      $d.="<td class=$self->{prefix}bar nowrap valign=center>";
      $d.="<div id=$name ".
          "onMouseDown=\"$self->{prefix}Mark(this,$rMin,$rMax,$segCount)\" ".
          "class=$self->{prefix}bar>";
      $d.=$self->GetRenderedBar($name,$line);
      $d.="</div>";
      $d.="</td>\n";
      $d.="</tr>\n";
      $line++;
   }
   $d.="</table>\n";

   return($d);
}

sub GetRenderedHeadline
{
   my $self=shift;
   my $sec=$self->GetSegmentation();
   my $rMax=$self->GetRangeMax();
   my $rMin=$self->GetRangeMin();

   my $d="";
   my $area=$rMax-$rMin;
   my $l=$area/$sec;
   $area*=$self->{RangeMaxSpaceFactor};
   $area=1 if ($area==0);
 
   for(my $c=0;$c<$sec;$c++){
      my %p=%{$self->GetSegmentParam($c)};
      my $label="";
      if (defined($p{label})){
         $label=$p{label};
         delete($p{label});
      }
      my $w=int(100*$l/$area);
      $d.=$self->GetSegmentDiv(undef,$c,0,$label);
   }
   return($d);
}

sub SetSegmentParam
{
   my $self=shift;
   my $n=shift;
   my %param=@_;
   if (!keys(%param)){
      delete($self->{SegmentParam}->{$n});
   } 
   else{
      $self->{SegmentParam}->{$n}=\%param;
   }
}

sub GetSegmentParam
{
   my $self=shift;
   my $n=shift;
   return($self->{SegmentParam}->{$n});
}

sub GetSegmentDiv
{
   my $self=shift;
   my $name=shift;
   my $n=shift;
   my $line=shift;
   my $data=shift;

   my $class="$self->{prefix}_";
   my %p=%{$self->GetSegmentParam($n)};
   if (!defined($name)){
      $class.="HeadSegment";
   }
   else{
      $class.="DataSegment";
   }

   my $area=100;
#*$self->{RangeMaxSpaceFactor};
   my $w=sprintf("%0.2f",97.0/$self->GetSegmentation());
   my $id="";
   $id="id=${name}_seg$n";
   my $d="<div $id class=$class style=\"width:$w\%\">";
   my $css="";
   my @cssp=qw(border-left border-right border-color border-width background
               border-top-color border-top-width border-top-style
               border-bottom-color border-bottom-width border-bottom-style
               border-left-color border-left-width border-left-style
               border-right-color border-right-width border-right-style);
   if ($n==0){
      $p{'border-left-width'}='1px';   
      $p{'border-left-color'}='black';   
      $p{'border-left-style'}='solid';   
   }
   if ($n==$self->GetSegmentation()-1){
      $p{'border-right-width'}='1px';   
      $p{'border-right-color'}='black';   
      $p{'border-right-style'}='solid';   
   }
   foreach my $varname (@cssp){
      my $v=$varname;
      $v="head-$v" if (!defined($name));
      if (defined($p{$v})){
         $css.=";$varname:$p{$v}";
      }
   } 
   if (defined($name)){
      $css.=";height:$self->{BarHeight}px";
      $css.=";border-bottom:solid;border-bottom-width:1px;";
      if ($line==1){
         $css.=";border-top:solid;border-top-width:1px;";
      }
   }
   $d.="<div style=\"overflow:hidden;$css\">";
   $d.=$data;
   $d.="</div></div>\n";
   return($d);
}

sub GetRenderedBar
{
   my $self=shift;
   my $name=shift;
   my $line=shift;
   my $rMax=$self->GetRangeMax();
   my $rMin=$self->GetRangeMin();


   my $d="";
   my $area=$rMax-$rMin;
#   @span=sort({$a->[0]<=>$b->[0]} @span);
#   @span=sort({$a->[0]<=>$b->[0]} @span);
   my $segcount=$self->GetSegmentation();
   
   
   for(my $seg=0;$seg<$segcount;$seg++){
      my $segs=$rMin+(($area/$segcount)*$seg);
      my $sege=$rMin+(($area/$segcount)*($seg+1));
      my $sega=($sege-$segs);
      my $maxline=0;
      my $dd="";
      for(my $line=0;$line<=$maxline;$line++){
         my @span=();
         foreach my $span (@{$self->{span}->{$name}}){
            my $color="red";
            my $onclick=undef;
            $maxline=$span->{line} if ($maxline<$span->{line});
            next if ($line!=$span->{line});
            if (defined($span->{param}->{color})){
               $color=$span->{param}->{color};
            }
            if (defined($span->{param}->{onclick})){
               $onclick=$span->{param}->{onclick};
            }
            if ($segs>=$span->{from} && $sege<=$span->{to}){
               push(@span,[0,100,{color=>$color,onclick=>$onclick}]); 
            }
            elsif ($sege>$span->{to} && 
                   $segs<$span->{from}){
               my $s=($span->{from}-$segs)*100/$sega;
               my $w=($span->{to}-$span->{from})*100/$sega;
               push(@span,[$s,$w,{color=>$color,onclick=>$onclick}]); 
            }
            elsif ($segs>=$span->{from} && 
                   $sege>=$span->{to} && $segs<=$span->{to}){
               my $w=($span->{to}-$segs)*100/$sega;
               push(@span,[0,$w,{color=>$color,onclick=>$onclick}]); 
            }
            elsif ($sege<=$span->{to} && 
                   $segs<=$span->{from} && $sege>=$span->{from}){
               my $s=($span->{from}-$segs)*100/$sega;
               my $w=($sege-$span->{from})*100/$sega;
               push(@span,[$s,$w,{color=>$color,onclick=>$onclick}]); 
            }
         }
         @span=sort({$a->[0]<=>$b->[0]} @span);
         my @blanks;
         for(my $span=1;$span<=$#span;$span++){
            if ($span[$span-1]->[1]+$span[$span-1]->[0]!=$span[$span]->[0]){
               push(@blanks,[$span[$span-1]->[1]+$span[$span-1]->[0],
                    $span[$span]->[0]-($span[$span-1]->[1]+$span[$span-1]->[0]),
                    {color=>'transparent'}]);
            }
         }
         if ($#span>=0){
            if ($span[0]->[0]!=0){
               push(@blanks,[0,$span[0]->[0],{color=>'transparent'}]);
            }
            if ($span[$#span]->[0]+$span[$#span]->[1]!=100){
               push(@blanks,[$span[$#span]->[0]+$span[$#span]->[1],
                        100-$span[$#span]->[0]+$span[$#span]->[1],
                        {color=>'transparent'}]);
            }
         }
         else{
            push(@blanks,[0,100,{color=>'transparent'}]);
         }
         push(@span,@blanks);
        
         @span=sort({$a->[0]<=>$b->[0]} @span);
         $dd.="<table border=0 width=100% padding=0 ".
              "cellspacing=0><tr style=\"height:$self->{SpanHeight}px;".
              "\">";
         my $sum=0;
         for(my $spanno=0;$spanno<=$#span;$spanno++){
            my $span=$span[$spanno];
            next if ($span->[1]==0);
            my $style="overflow:hidden;border-style:none";
            $style.=";background:$span->[2]->{color};height:5px";
            my $onclick="";
            if ($span->[2]->{onclick} ne ""){
               $onclick=" onClick=\"$span->[2]->{onclick}\" ";
               $style.=";cursor:pointer;cursor:hand;font-size:1px;";
            }
            my $in="<div style=\"border-top:solid;".
                   "border-top-color:$span->[2]->{color};".
                   "border-top-width:$self->{SpanHeight}px;".
                   "font-size:1px;".
                   "margin:0;padding:0;\"></div>";
            $in="" if ($span->[2]->{color} eq "transparent" &&
                       $ENV{HTTP_USER_AGENT}=~m/MSIE/);

            $dd.="<td width=$span->[1]% ".
                 "style=\"font-size:1px;margin:0;padding:0;\">".
                 "<div $onclick style=\"$style\">$in</div></td>";
         }
         $dd.="</tr></table>";
      }
      my $sdiv=$self->GetSegmentDiv($name,$seg,$line,$dd);
      $d.=$sdiv;
   }
   return($d);
}

sub getMarkScript
{
   my $self=shift;

   my $mcall="onMarkAction";
   $mcall=$self->{onMarkAction} if ($self->{onMarkAction} ne "");
   my $d=<<EOF;
function $self->{prefix}activeEdit(selNode,markbar,selStart,selEnd)
{
 //  alert("id="+selNode.id+" s="+selStart+" e="+selEnd);
   $mcall(selNode,markbar,selStart,selEnd);
}


function $self->{prefix}Mark(markElement,rMin,rMax,segCount)
{
   var width=1;
   var refwidth=document.getElementById(markElement.id+"_seg0");
   if (refwidth && refwidth.offsetWidth>0){
      width=refwidth.offsetWidth;
   }
   return(StartMark(markElement,rMin,rMax,segCount,width,
                    $self->{prefix}activeEdit));
}
EOF
   return($d);
}


sub getMarkLib
{
   my $self=shift;


   my $d=<<EOF;

//--------------------------------------------------------------------
// Mark library     
//
var _CurrentMousePos=new Object();
var _MarkBar;

function StartMark(markElement,rMin,rMax,segCount,segWidth,backcall)
{
   _cleanupMarkbar();

   var tNode = markElement;
   var xPos = 0;
   var yPos = 0;
   while (tNode.nodeName != "BODY")
   {
      xPos += tNode.offsetLeft;
      yPos += tNode.offsetTop;
      tNode = tNode.offsetParent;

   }

   _MarkBar=document.createElement("div");
   _MarkBar.xmin=xPos;
   _MarkBar.rMin=rMin;
   _MarkBar.rMax=rMax;
   _MarkBar.rSegCount=segCount;
   _MarkBar.rSegWidth=segWidth;
   var x=_gridedVal(markElement.offsetLeft,markElement.offsetWidth,
                    _CurrentMousePos.x);
   _MarkBar.style.background="black";
   _MarkBar.style.width="1";
   _MarkBar.style.position="absolute";
   _MarkBar.style.top=(yPos+1)+"px";
   _MarkBar.style.left=xPos+"px";
   _MarkBar.style.height=markElement.offsetHeight-1;
   _MarkBar.style.opacity=0.2;
   _MarkBar.style.filter="alpha(opacity=20)";
   _MarkBar.startx=x;
   _MarkBar.disableChange=false;
   _MarkBar.backcall=backcall;
   _MarkBar.markNode=markElement;
   tNode.appendChild(_MarkBar);
   return(false);
}
function _gridedVal(start,base,x)
{
  // var g=base/_MarkBar.rSegCount;
  // var n=Math.round((x-start)/g)*g;
  // var g=x/_MarkBar.rSegWidth;
  // var n=start+(parseInt(g)*_MarkBar.rSegWidth); 
  // n=start+_MarkBar.rSegWidth; 
   return(x);
   
  // return(n);
}
function _MouseMoveHandler()
{
   if (_MarkBar && !_MarkBar.disableChange){
      var x=_gridedVal(_MarkBar.parentNode.offsetLeft,_MarkBar.parentNode.offsetWidth,_CurrentMousePos.x);
      if (x<_MarkBar.xmin){
         x=_MarkBar.xmin;
      }
      if (_CurrentMousePos.x-_MarkBar.startx>0){
         _MarkBar.style.left=_MarkBar.startx;
         _MarkBar.style.width=x-_MarkBar.offsetLeft;
      }
      else{
         _MarkBar.style.left=x;
         _MarkBar.style.width=(x-_MarkBar.startx)*-1;
      }
   }
}
function _MouseUpHandler(e)
{
   if (_MarkBar){
      var max=_MarkBar.parentNode.offsetWidth;
      var selStart=(_MarkBar.offsetLeft-_MarkBar.xmin);
      var selEnd=selStart+_MarkBar.offsetWidth;
      if (_MarkBar.backcall){
         _MarkBar.disableChange=true;
         _MarkBar.backcall(_MarkBar.markNode,_MarkBar,selStart,selEnd);
      }
   }
   _cleanupMarkbar();
   return(false);
}
function _grabMouse(currentEvent)
{
   if (currentEvent == null) currentEvent = window.event; 
   var target = currentEvent.target != null ? currentEvent.target : currentEvent.srcElement;    
   _CurrentMousePos.x=currentEvent.clientX;
   _CurrentMousePos.y=currentEvent.clientY;
   if (_MarkBar){
      _MouseMoveHandler();
      return(false);
   }
   return(true);
}
function _cleanupMarkbar()
{
   if (_MarkBar){
      if (_MarkBar.parentNode){
         _MarkBar.parentNode.removeChild(_MarkBar);
      }
      _MarkBar=undefined;
   }
}
function OnMouseDown(currentEvent)
{ 
   if (currentEvent == null) currentEvent = window.event; 
   var target = currentEvent.target != null ? currentEvent.target : currentEvent.srcElement; 
   alert('Button='+currentEvent.button+' className='+target.className+
         ' nodeName='+target.nodeName);
   return(false);
}
document.onmouseup=_MouseUpHandler;
//document.onmousedown=OnMouseDown;
document.onmousedown=_grabMouse;
document.onmousemove=_grabMouse;
EOF
   return($d);
}


1;
