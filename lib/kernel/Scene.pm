package kernel::Scene;
use vars qw(@ISA);
use strict;
use kernel;

@ISA=qw();

sub new
{
   my $type=shift;
   my $name=shift;
   my $self=bless({@_},$type);
   $self->{name}=$name;
   $self->setFormat("a4");

   # calc current depth
   my $path;
   if (defined(Query->Param("FunctionPath"))){
      $path=Query->Param("FunctionPath");
   }
   $path=~s/\///;
   my @l=split(/\//,$path);
   $self->{depth}=$#l;
   $self->{code}=[
    "var canvas = null;\n".
    "canvas = new draw2d.Canvas(\"$name\");\n"];

   return($self);
}

sub setFormat
{
   my $self=shift;

   if (int($_[0]) eq $_[0] && int($_[1]) eq $_[1]){
      $self->{xmax}=$_[0];
      $self->{ymax}=$_[1];
   }
   else{
      if (uc($_[0]) eq "A4" && $_[0]==1){
         $self->{xmax}=928;
         $self->{ymax}=645;
      }
      if (uc($_[0]) eq "A4" && $_[0]==0){
         $self->{xmax}=645;
         $self->{ymax}=928;
      }
   }
}

sub addShape
{
   my $self=shift;
   my $id=shift;
   my $type=shift;
   my $x=shift;
   my $y=shift;

   my $l=$#{$self->{code}}+1;

   if ($type=~m/^draw2d\.shape/){
      if ($type=~m/^draw2d\.shape\.basic\.Rectangle$/){
         push(@{$self->{code}},
           "var shp$l=new $type();\n".
           "var p=new draw2d.HybridPort(\"t1\");\n".
           "shp$l.addPort(p,new draw2d.layout.locator.TopLocator(shp$l));\n".
           "var p=new draw2d.HybridPort(\"b1\");\n".
           "shp$l.addPort(p,new draw2d.layout.locator.BottomLocator(shp$l));\n".
           "var p=new draw2d.HybridPort(\"r1\");\n".
           "shp$l.addPort(p,new draw2d.layout.locator.LeftLocator(shp$l));\n".
           "var p=new draw2d.HybridPort(\"l1\");\n".
           "shp$l.addPort(p,new draw2d.layout.locator.RightLocator(shp$l));\n".
           "shp$l.setId(\"$id\");\n".
           "shp$l.setDimension(60,60);\n".
           "canvas.addFigure(shp$l, $x,$y);\n".
           "");
      }
      else{
         push(@{$self->{code}},
              "var shape$l=new $type();\n".
              "shape$l.setId(\"$id\");\n".
              "canvas.addFigure(shape$l, $x,$y);\n");
      }
   }
}

sub renderedScene
{
   my $self=shift;
   my $d="<script type=\"text/javascript\" language=\"JavaScipt\">\n".
         "\$(window).load(function () {\n";

   $d.=join("",@{$self->{code}});

   $d.="});\n</script>\n\n";
   return($d);
}

sub htmlContainer
{
   my $self=shift;
   my $xmax=$self->{xmax};
   my $ymax=$self->{ymax};
   my $d=<<EOF;
  <div id="gfx_holder" 
       style="width:${xmax}px; 
             border-style:solid;border-color:black;
             border-width:1px;
             height:${ymax}px;"></div>
EOF
   return($d);
}

sub htmlBootstrap
{
   my $self=shift;
   my @prefix;
   for(my $c=0;$c<=$self->{depth};$c++){
      push(@prefix,"..");
   }
   my @js;
   foreach my $l (qw(lib/raphael.js lib/jquery-1.8.1.min.js 
                     lib/jquery-ui-1.8.23.custom.min.js 
                     lib/jquery.layout.js lib/jquery.autoresize.js 
                     lib/jquery-touch_punch.js lib/jquery.contextmenu.js 
                     lib/rgbcolor.js lib/canvg.js lib/Class.js 
                     lib/json2.js src/draw2d.js)){
      push(@js,join("/",@prefix)."/../../../static/draw2d/".$l);
   }
   my $d="";
   foreach my $js (@js){
      $d.="<script language=\"JavaScript\"  ".
          "type=\"text/javascript\" src=\"$js\"></script>\n";
   }
   return($d);
}

1;
