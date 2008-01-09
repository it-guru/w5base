package timetool::tst;
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
use kernel::vbar;
@ISA    = qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}  

sub Main
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css' ],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1);
   my $vbar=new kernel::vbar();
   $vbar->AddSpan(undef,"voglerh" ,200,310,color=>'red');
   $vbar->AddSpan(undef,"emmertj" ,0,15,color=>'red');
   $vbar->AddSpan(2,"joe" ,3,230,color=>'blue');
   $vbar->AddSpan(3,"joe" ,4,230,color=>'red');
   $vbar->AddSpan(undef,"1emmertj" ,10,11,color=>'green');
   $vbar->AddSpan(undef,"1emmertj" ,13,15,color=>'blue');
   $vbar->AddSpan(undef,"1emmertj" ,17,25,color=>'red');
   $vbar->AddSpan(undef,"emmertj" ,100,110,color=>'green');
   $vbar->AddSpan(undef,"emmertj" ,120,125,color=>'blue');
   $vbar->AddSpan(undef,"emmertj" ,125,140,color=>'red');
   $vbar->AddSpan(undef,"emmertj" ,140,220,color=>'blue');
   $vbar->AddSpan(undef,"emmertj" ,220,310,color=>'green');
   $vbar->AddSpan(undef,"muellerc",180,220,color=>'black');
   $vbar->AddSpan(undef,"wieschoa",50,80,color=>'green');
   $vbar->AddSpan(undef,"wieschoa",150,220,color=>'red');
   $vbar->AddSpan(undef,"1emmertj" ,100,110,color=>'green');
   $vbar->AddSpan(undef,"1emmertj" ,120,125,color=>'green');
   $vbar->AddSpan(undef,"1emmertj" ,125,140,color=>'red');
   $vbar->AddSpan(undef,"1emmertj" ,140,220,color=>'blue');
   $vbar->AddSpan(undef,"1emmertj" ,220,230,color=>'green');
   $vbar->AddSpan(undef,"1muellerc",180,220,color=>'black');
   $vbar->AddSpan(undef,"1wieschoa",50,80,color=>'green');
   $vbar->AddSpan(undef,"1wieschoa",150,220,color=>'red');
   $vbar->AddSpan(2,"zz",40,310,color=>'yellow');
   $vbar->SetLabel("wieschoa","Wieschollek, Andreas");
   $vbar->SetLabel("voglerh","Vogler, Hartmut");
   $vbar->SetRangeMin(0);
   $vbar->SetSegmentation(31);
   for(my $s=0;$s<31;$s++){
      my %p=('label'=>"<center>".($s)."</center>",
             'head-background'=>'silver',
             'background'=>'#F9F9F9');
      $p{'head-border-left'}='solid' if ($s!=0);
      $p{'head-border-right'}='solid' if ($s==30);
      $p{'head-border-width'}='1px';
      $p{'head-border-color'}='gray';
    #  $p{'border-left'}='solid' if ($s!=0);
    #  $p{'border-right'}='solid' if ($s==30);
      $p{'border-width'}='1px';
      $p{'border-color'}='#E9E9E9';
      if ($s==7 || $s==17){
         $p{'border-color'}='black';
         $p{'border-left'}='solid';
         $p{'border-right'}='solid';
         $p{'border-width'}='1px';
         $p{'background'}='white';
      }
      $vbar->SetSegmentParam($s,%p);
   }

   
   print $vbar->render();

   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(Result Main Welcome TimeGridMain));
}

sub getRenderedBar
{
   my $self=shift;
   my $name=shift;
   my $d="";

}







1;
