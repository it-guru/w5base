#!/bin/perl
package Text::ParseWhere;
use strict;
use Text::ParseWords;
use Data::Dumper;

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);

   return($self);
}

sub _parseWords($$)
{
   my $self=shift;
   my $WhereExp=shift;
  
   my @w; 
   foreach my $w (quotewords('\s+',1,$WhereExp)){
      if ($w=~m/^\(/i){
         my @stack;
         while($w=~s/^\(//){
            push(@stack,"(");
         }
         push(@w,@stack);
      }
      if ($w=~m/^[a-z0-9]+=/i){
         push(@w,($w=~m/^([a-z0-9]+)(=)(.*)$/i));
      }
      else{
         push(@w,$w);
      }
      if ($w[$#w]=~m/\)$/i){
         my @stack;
         while($w[$#w]=~s/\)$//){
            push(@stack,")");
         }
         push(@w,@stack);
      }
   }
   return(@w);
}

sub _classifyElements
{
   my $self=shift;
   my @w=@_;
   my @e;

   my @COM=qw(like and or =);
   foreach my $w (@w){
      my $qw=quotemeta($w);
      if (grep(/^${qw}$/i,@COM)){
         push(@e,{type=>'COM',name=>$w});
      }
      elsif (grep(/^${qw}$/i,"(",")")){
         push(@e,{type=>'BRACKET',name=>$w});
      }
      elsif ($w=~m/^".*"$/){
         push(@e,{type=>'VALUE',val=>$w});
      }
      elsif ($w=~m/^'.*'$/){
         push(@e,{type=>'CONST',val=>$w});
      }
      else{
         push(@e,{type=>'VARNAME',name=>$w});
      }
   }
   return(@e);
}

sub compileExpression
{
   my $self=shift;
   my $WhereExp=shift;

   #
   # Pass1: parse words
   #
   my @w=$self->_parseWords($WhereExp);

   #
   # Pass2: classify element list
   #
   my @e=$self->_classifyElements(@w);

   #
   # syntax and structur check
   #

   #
   # build perl eval code
   #
   my $cmd="sub{my \$H=shift;return(";
   while(my $e=shift(@e)){
      if ($e->{type} eq "VARNAME"){
         $cmd.="\$H->{'$e->{name}'}";
      }
      if ($e->{type} eq "CONST"){
         $cmd.="$e->{val}";
      }
      if ($e->{type} eq "BRACKET"){
         $cmd.="$e->{name}";
      }
      if ($e->{type} eq "COM" && $e->{name} eq "="){
         $cmd.=" eq ";
      }
      if ($e->{type} eq "COM" && lc($e->{name}) eq "and"){
         $cmd.=" and ";
      }
      if ($e->{type} eq "COM" && lc($e->{name}) eq "or"){
         $cmd.=" and ";
      }
      if ($e->{type} eq "COM" && lc($e->{name}) eq "like"){
         $cmd.=" = ";
      }
   }
   $cmd.=")};";
   $self->Code($cmd);
   

   my $match=eval($cmd);
   return($match);
}

sub errString
{
   my $self=shift;
   if ($#_!=-1){
      $self->{'errString'}=join("\n",@_);
   }
   return($self->{'errString'});

}

sub Code
{
   my $self=shift;
   if ($#_!=-1){
      $self->{'Code'}=join("\n",@_);
   }
   return($self->{'Code'});

}

1;

