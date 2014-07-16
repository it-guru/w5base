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

sub __like
{
   my $v1=shift;
   my $v2=shift;

   $v2=quotemeta($v2);
   $v2=~s/\\\*/.*/g;
   $v2=~s/_/./g;

   my $found=0;
   if (ref($v1) eq "ARRAY"){
      foreach my $rec (@$v1){
         my $v1=$rec;
         if ($v1=~m/^$v2$/i){
            return(1);
         }
      }
   }
   if ($v1=~m/^$v2$/i){
      return(1);
   }
   return(0);
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
         push(@e,{'type'=>'COM','name'=>$w});
      }
      elsif (grep(/^${qw}$/i,"(",")")){
         push(@e,{'type'=>'BRACKET','name'=>$w});
      }
      elsif ($w=~m/^".*"$/){
         push(@e,{'type'=>'VALUE','val'=>$w});
      }
      elsif ($w=~m/^'.*'$/){
         push(@e,{'type'=>'CONST','val'=>$w});
      }
      elsif ($w=~m/^[a-z0-9]+$/i){
         push(@e,{'type'=>'VARNAME','name'=>$w,
                  'val'=>"\$H->{'$w'}"});
      }
      else{
         push(@e,{'type'=>'INVALID'});
      }
      $e[$#e]->{'orig'}=$w;
   }
#printf STDERR ("e=%s\n",Dumper(\@e));
   return(@e);
}

sub _checkSyn
{
   my $self=shift;
   my $e=shift;

   for(my $pos=0;$pos<=$#{$e};$pos++){
      if ($pos==0 && $e->[$pos]->{'type'} eq "COM"){
         $self->errString("operation at first command");
         return(undef);
      }
      if ($e->[$pos]->{'type'} eq "COM" && $e->[$pos]->{'name'} eq "like"){
         my $f={'type'=>'FUNC',name=>'like',
                val=>"Text::ParseWhere::__like(".$e->[$pos-1]->{'val'}.",".
                                                 $e->[$pos+1]->{'val'}.")"};
         splice(@{$e},$pos+1,1);
         #splice(@{$e},$pos+1,1);
         $e->[$pos]=$f;
         splice(@{$e},$pos-1,1);
      }

   }
   return(1);
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
   # Pass3: check syntax and structur 
   #
   if ($self->_checkSyn(\@e)){
      #
      # Pass4: build perl eval code
      #
      my $cmd="sub{my \$H=shift;return(";
      while(my $e=shift(@e)){
         if ($e->{type} eq "VARNAME"){
            $cmd.=$e->{val};
         }
         if ($e->{type} eq "CONST"){
            $cmd.="$e->{val}";
         }
         if ($e->{type} eq "VALUE"){
            $cmd.="$e->{val}";
         }
         if ($e->{type} eq "FUNC"){
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
            $cmd.=" or ";
         }
         if ($e->{type} eq "COM" && lc($e->{name}) eq "like"){
            $cmd.=" = ";
         }
      }
      $cmd.=")};";
      $self->Code($cmd);
      #printf STDERR ("fifi cmd=$cmd\n"); 
     
      my $match=eval($cmd);
      $self->errString($@) if ($self->errString() eq "" && $@ ne "");
      return($match);
   }
   return(undef);
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

