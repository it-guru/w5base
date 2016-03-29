package HTML::TreeGrid;

use Data::Dumper;
use strict;
use warnings;

our $VERSION = "0.01";

our $S="<span style=\"width:0px;font-size:1px\">";

sub new 
{
   my $pkg = shift;
   my %self=@_;

   # setup defaults and get parameters
   $self{'grid_width'}=20                if (!exists($self{'grid_width'}));
   $self{'grid_minwidth'}=790            if (!exists($self{'grid_minwidth'}));
   $self{'name'}="HtmlGrid"              if (!exists($self{'name'}));
   $self{'label'}="This is the label"    if (!exists($self{'label'}));
   $self{'style'}="standard"             if (!exists($self{'style'}));
   $self{'fullpage'}="1"                 if (!exists($self{'fullpage'}));
   $self{'connector_style'}="solid"      if (!exists($self{'connector_style'}));
   $self{'connector_color'}="black"      if (!exists($self{'connector_color'}));
   $self{'connector_width'}="1"          if (!exists($self{'connector_width'}));
   $self{'entity_width'}="140"           if (!exists($self{'entity_width'}));
   $self{'entity_color'}="#EBEBEB"       if (!exists($self{'entity_color'}));
   $self{'xmax'}=20                      if (!exists($self{'xmax'}));


   my $self = bless(\%self,$pkg);
   $self->Clear();
   return($self);
}

sub Clear
{
   my $self=shift;

   $self->{'G'}=[[]];   # clear grid;
}

sub Cell
{
   my $self=shift;
   my $x=shift;
   my $y=shift;

   my $row=$self->G->[$y];
   if (!defined($row)){
      $self->G->[$y]=[];
   }
   if (ref($self->G->[$y]->[$x]) ne "HASH"){
      $self->G->[$y]->[$x]={tdclass=>[],Entity=>''};
   }
   return($self->G->[$y]->[$x]);
}

sub Line
{
   my $self=shift;
   my $x1=shift;
   my $y1=shift;
   my $x2=shift;
   my $y2=shift;

   if ($y1!=$y2 && $x1!=$x2){         # we only can draw horizontal or vertical
      my $midy=$y1+int(($y2-$y1)/2);  # lines - soo we need a trick
      $self->Line($x1,$midy,$x2,$midy);
      $self->Line($x1,$y1,$x1,$midy);
      $self->Line($x2,$midy,$x2,$y2);
      return();
   }

   if ($x1>$x2){
      my $t=$x1;
      $x1=$x2;
      $x2=$t;
   }
   if ($y1>$y2){
      my $t=$y1;
      $y1=$y2;
      $y2=$t;
   }


   for(my $x=$x1;$x<$x2;$x++){
      push(@{$self->Cell($x,$y1)->{tdclass}},"tb");
   }
   for(my $y=$y1;$y<$y2;$y++){
      push(@{$self->Cell($x1,$y)->{tdclass}},"lb");
   }



}

sub SetCell
{
   my $self=shift;
   my $x1=shift;
   my $y1=shift;
   my $value=shift;


}

sub SetEntity
{
   my $self=shift;
   my $x1=shift;
   my $y1=shift;
   my $param;
   if (ref($_[0]) eq "HASH"){
      $param=shift;
   }
   my @block=@_;
   my $name=$self->{'name'};

   my $row=$self->G->[$y1];
   if (!defined($row)){
      $self->G->[$y1]=[];
   }
   $self->G->[$y1]->[$x1]={} if (!defined($self->G->[$y1]->[$x1]));

   my $e="<div class=\"${name}Entity\"";
   my @style;
   if (defined($param) && defined($param->{entity_width})){
      push(@style,"width:".$param->{entity_width}."px;");
      my $ml=int($param->{entity_width}/2);
      push(@style,"margin-left:-".$ml."px;");
   }
   if (defined($param) && defined($param->{entity_color})){
      push(@style,"background-color:".$param->{entity_color}.";");
   }
   if ($#style!=-1){
      $e.=" style=\"".join("",@style)."\""; 
   }

   $e.=">";

   while(my $k=shift(@block)){
      my $v=shift(@block);
      if ($v ne ""){
         $e.="<div class=\"${name}Entity${k}\">".$v."</div>\n";
      }
   }
   $e.="</div>";

   $self->G->[$y1]->[$x1]->{'Entity'}=$e;
}

sub SetBox
{
   my $self=shift;
   my $x1=shift;
   my $y1=shift;
   my $width=shift;
   my $html=shift;
   my $param;
   if (ref($_[0]) eq "HASH"){
      $param=shift;
   }
   my @block=@_;
   my $name=$self->{'name'};

   my $row=$self->G->[$y1];
   if (!defined($row)){
      $self->G->[$y1]=[];
   }
   $self->G->[$y1]->[$x1]={} if (!defined($self->G->[$y1]->[$x1]));

   my $e="<div ";
   my @style;
   push(@style,"width:".$width."px;");
   my $ml=int($width/2);
   push(@style,"margin-left:-".$ml."px;");
   if (defined($param) && defined($param->{entity_color})){
      push(@style,"background-color:".$param->{entity_color}.";");
   }
   if ($#style!=-1){
      $e.=" style=\"".join("",@style)."\""; 
   }

   $e.=">$html</div>";

   $self->G->[$y1]->[$x1]->{'Entity'}=$e;
}




sub ClearCell
{
   my $self=shift;
   my $x1=shift;
   my $y1=shift;

   my $row=$self->G->[$y1];
   if (!defined($row)){
      $self->G->[$y1]=[];
   }
   $self->G->[$y1]->[$x1]={};
}

sub G
{
   my $self=shift;

   return($self->{'G'});
}


sub Render
{
   my $self=shift;

   my $d="";

   $self->_addLevel2Grid(\$d);
   $self->_addLevel1Grid(\$d);
   $self->_addBodyEnvelope(\$d) if ($self->{'fullpage'});
   $self->_addCss(\$d)          if ($self->{'style'} ne "");
   $self->_addHtmlEnvelope(\$d) if ($self->{'fullpage'});

   return($d);
}

sub _addLevel2Grid
{
   my $self=shift;
   my $d=shift;
   my $name=$self->{'name'};
   my $label=$self->{'label'};

   $label=$S if (!exists($self->{'label'}));

   my $t="<table border=0 width=\"100%\" ";
   #$t.="border=1 "; 
   $t.="class=\"${name}Main\" cellspacing=\"0\" cellpadding=\"0\">\n";
   $t.="<tbody>\n";
   my $G=$self->G;
   
   my $maxrow=$#{$G};
   my $maxcol=0;
   if (defined($self->{'xmax'})){
      $maxcol=$self->{'xmax'};
   }
   else{
      for(my $row=0;$row<=$#{$G};$row++){
         for(my $col=0;$col<=$#{$G->[$row]};$col++){
            $maxcol=$col if ($maxcol<$col);
         }
      }
   }
   
   #print STDERR Dumper($G);
   #$t.="<!-- maxcol=$maxcol maxrow=$maxrow -->\n";

   for(my $row=0;$row<=$maxrow;$row++){
      $t.="<tr>\n";
      for(my $col=0;$col<=$maxcol;$col++){
         my $td="";
         my $tdclass="";
         if (defined($G->[$row]->[$col]->{Entity})){
            $td.=$G->[$row]->[$col]->{Entity};
         }
         my @tdclass=qw(b);
         if (defined($G->[$row]->[$col]->{tdclass})){
            push(@tdclass,@{$G->[$row]->[$col]->{tdclass}});
         }
         $tdclass=" class=\"".join(" ",@tdclass)."\"";
         $td.=$S;
         $t.="<td${tdclass}>".$td."</td>\n";
      }
      $t.="</tr>\n";
   }

   $t.="</tbody>\n";
   $t.="</table>\n";

   $$d.=$t;
}

sub _addLevel1Grid
{
   my $self=shift;
   my $d=shift;
   my $name=$self->{'name'};
   my $label=$self->{'label'};
   my $grid_minwidth=$self->{'grid_minwidth'};

   $label=$S if (!exists($self->{'label'}));

   $$d="<table width=\"100%\" ".
       "class=\"${name}Envelope\" cellspacing=\"0\" cellpadding=\"0\">".
       "<tr><td>".
       "<div style=\"width:${grid_minwidth}px\">".$label."</div>".
       "</td>".
       "<tr><td>".$$d."</td></tr>".
       "</table>";

}

sub _addHtmlEnvelope
{
   my $self=shift;
   my $d=shift;

   $$d="<html>".$$d."</html>";
}

sub _addBodyEnvelope
{
   my $self=shift;
   my $d=shift;

   $$d="<body>".$$d."</body>";
}

sub _addCss
{
   my $self=shift;
   my $d=shift;
   my $name=$self->{'name'};

   my $connector_style=$self->{'connector_style'};
   my $connector_width=$self->{'connector_width'};
   my $connector_color=$self->{'connector_color'};

   my $entity_width=$self->{'entity_width'};
   my $entity_color=$self->{'entity_color'};

   my $s="";
   $s.="table.${name}Envelope{\n".
       "   font-family:Arial,Adobe Helvetica,Helvetica;\n".
       "   font-size:11px;\n".
       "   text-decoration:none;\n".
       "}\n";

   $s.="table.${name}Main{\n".
       "   font-family:Arial,Adobe Helvetica,Helvetica;\n".
       "   font-size:11px;\n".
       "   text-decoration:none;\n".
       "}\n";
   $s.="table.${name}Main tr{\n".
       "   height:10px;\n".
       "}\n";
   $s.="table.${name}Main tr td.b{\n".
       "   border-width:${connector_width}px;\n".
       "   border-color:${connector_color};\n".
       "   width:5%;\n".
       "}\n";
   $s.="table.${name}Main tr td.rb{\n".
       "   border-right-style:${connector_style};\n".
       "}\n";
   $s.="table.${name}Main tr td.lb{\n".
       "   border-left-style:${connector_style};\n".
       "}\n";
   $s.="table.${name}Main tr td.tb{\n".
       "   border-top-style:${connector_style};\n".
       "}\n";
   $s.="table.${name}Main tr td.bb{\n".
       "   border-bottom-style:${connector_style};\n".
       "}\n";

   my $ml=int($entity_width/2);

   $s.="div.${name}Entity{\n".
       "   position:absolute;\n".
       "   margin:0px;\n".
       "   padding:0px;\n".
       "   margin-top:-11px;\n".
       "   width:${entity_width}px;\n".
       "   margin-left:-${ml}px;\n".
       "   background-color:${entity_color};\n".
       "}\n";

   $s.="div.${name}EntityHeader{\n".
       "   font-size:12px;\n".
       "   border-style:solid;\n".
       "   border-color:black;\n".
       "   border-width:1px;\n".
       "   text-align:center;\n".
       "   vertical-align:middle;\n".
       "}\n";
   $s.="div.${name}EntityDescription{\n".
       "   height:30px;\n".
       "   padding:1px;\n".
       "   overflow:hidden;\n".
       "   border-style:solid;\n".
       "   border-color:black;\n".
       "   border-width:1px;\n".
       "   text-align:center;\n".
       "   vertical-align:middle;\n".
       "}\n";
   $s.="div.${name}EntityFooder{\n".
       "   font-size:10px;\n".
       "   padding:1px;\n".
       "   overflow:hidden;\n".
       "   border-style:solid;\n".
       "   border-top-style:none;\n".
       "   border-color:black;\n".
       "   border-width:1px;\n".
       "   text-align:center;\n".
       "   vertical-align:middle;\n".
       "}\n";

   $$d="<style>\n".$s."</style>".$$d;
}







