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


sub __slike
{
   my $v1=shift;
   my $subname=shift;
   my $v2=shift;

   return(0) if (ref($v1) ne "HASH" && ref($v1) ne "ARRAY");

   my $found=0;
   if (ref($v1) eq "ARRAY"){
      foreach my $rec (@{$v1}){
         if (ref($rec) eq "HASH"){
            if (exists($rec->{$subname})){
               my $match=__like($rec->{$subname},$v2);
               if ($match){
                  return(1);
               }
            }
         }
      }
   }
   if (ref($v1) eq "HASH"){
      if (exists($v1->{$subname})){
         my $match=__like($v1->{$subname},$v2);
         if ($match){
            return(1);
         }
      }
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
      if ($w=~m/^[a-z0-9]+(=|<|>|!=)/i){
         push(@w,($w=~m/^([a-z0-9]+)(=|<|>|!=)(.*)$/i));
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

   my @COM=qw(like and or = < > !=);
   foreach my $w (@w){
      my $qw=quotemeta($w);
      next if ($w eq "");  # skip blanks
      if (grep(/^${qw}$/i,@COM)){
         push(@e,{'type'=>'COM','name'=>$w});
      }
      elsif (grep(/^${qw}$/i,"(",")")){
         push(@e,{'type'=>'BRACKET','name'=>$w});
      }
      elsif ($w=~m/^".*"$/){
         push(@e,{'type'=>'VALUE','val'=>$w});
      }
      elsif ( ($#e!=-1 && $e[$#e]->{type} eq "COM" 
               && lc($e[$#e]->{name}) ne "and") &&
              ($#e!=-1 && $e[$#e]->{type} eq "COM" 
               && lc($e[$#e]->{name}) ne "or") &&
              ($#e!=-1 && $e[$#e]->{type} eq "COM") 
             && $w=~m/^[0-9]+(\.[0-9]+)?$/){
         # numbers without quotes can be only CONSTs,
         # if they are after a COM (compare) element and
         # the COM (compare) is not an OR or AND operation
         # If they are bevore a COM, they will be 
         # interpretated as varname (by index)
         my $typ="CONST";
         push(@e,{'type'=>'CONST','val'=>$w});
      }
      elsif ($w=~m/^'.*'$/){
         push(@e,{'type'=>'CONST','val'=>$w});
      }
      elsif ($w=~m/^[a-z0-9_]+$/i){
         push(@e,{'type'=>'VARNAME','name'=>$w,
                  'val'=>"\$H->{'$w'}"});
      }
      elsif (my ($varname,$subname)=$w=~m/^([a-z0-9_]+)\.([a-z0-9_]+)$/i){
         push(@e,{'type'=>'VARNAME','name'=>$varname,'subname'=>$subname,
                  'val'=>"\$H->{'$varname'}"});
      }
      else{
         push(@e,{'type'=>'INVALID'});
      }
      $e[$#e]->{'orig'}=$w;
   }
   #printf STDERR ("DEBUG: Elements=%s\n",Dumper(\@e));
   return(@e);
}

sub _checkSyn
{
   my $self=shift;
   my $e=shift;
   for(my $pos=0;$pos<=$#{$e};$pos++){
      if ($e->[$pos]->{'type'} eq "INVALID"){
         my $f;
         $self->errString("word or string at position ".$pos.
                          " invalid or not processable");
         return(undef);
      }
   }
   for(my $pos=0;$pos<=$#{$e};$pos++){
      if ($pos==0 && $e->[$pos]->{'type'} eq "COM"){
         $self->errString("operation at first command");
         return(undef);
      }
      if ($e->[$pos]->{'type'} eq "COM" && $e->[$pos]->{'name'} eq "like"){
         my $f;
         if (exists($e->[$pos-1]->{'subname'})){
            $f={'type'=>'FUNC',name=>'like',
                val=>"Text::ParseWhere::__slike(".
                                                 $e->[$pos-1]->{'val'}.
                                               ",'".
                                                 $e->[$pos-1]->{'subname'}."',".
                                                 $e->[$pos+1]->{'val'}.")"};
         }
         else{
            $f={'type'=>'FUNC',name=>'like',
                val=>"Text::ParseWhere::__like(".$e->[$pos-1]->{'val'}.",".
                                                 $e->[$pos+1]->{'val'}.")"};
         }
         splice(@{$e},$pos+1,1);
         #splice(@{$e},$pos+1,1);
         $e->[$pos]=$f;
         splice(@{$e},$pos-1,1);
      }
      if ($e->[$pos]->{'type'} eq "COM" && $e->[$pos]->{'name'} eq "="){
         my $f;
         if (exists($e->[$pos-1]->{'subname'})){
            $self->errString("equal operation not allowed on sub attributes");
            return(undef);
         }
      }
   }
   return(1);
}


   sub _getCurH
   {
      my $curh=shift;
      my $flt=shift;
       if (!defined($$curh)){
          $$curh={};
          push(@$flt,$$curh);
       }
       return($$curh);
   }


# Operator Präzedenz für W5Base Filter Hashes
# A || B && C          bedeutet A || (B && C)
# A && B || C && D     bedeutet (A && B) || (C && D)
# A && B && C || D     bedeutet (A && B && C) || D
# !A && B || C         bedeutet ((!A) && B) || C
# A && (B || C ) && D  nicht zulässig 


sub fltHashFromExpression
{
   my $self=shift;
   my $mode=shift;  # SIMPLE = like and sql are equal, " and ' makes no diff
   my $WhereExp=shift;
   my $fieldlist=shift;

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
   my @flt=();
   my $curh=undef;

   
   while(my $e=shift(@e)){
      if ($e->{type} eq "COM"){
         if (!defined($curh)){
            return(undef,"boolean operation on invalid position");
         }
         if (uc($e->{name}) eq "AND"){
            my $h=_getCurH(\$curh,\@flt);
         }
         if (uc($e->{name}) eq "OR"){
            $curh=undef;
            my $h=_getCurH(\$curh,\@flt);
         }
      }
      elsif ($e->{type} eq "VARNAME"){
         if (($e->{name}=~m/^[0-9]+$/) && 
             $e->{name}==int($e->{name})){
            if (defined($fieldlist->[int($e->{name})])){
               $e->{name}=$fieldlist->[int($e->{name})];
            }
            else{
               return(undef,"invalid field index '$e->{name}'");
            }
         }
         if (!grep(/^$e->{name}$/,@$fieldlist)){
            return(undef,"invalid field name '$e->{name}'");
         }
         if (my $op=shift(@e)){
            if ($op->{type} eq "COM"){
               if (my $val=shift(@e)){
                  if ($val->{type} eq "CONST" ||
                      $val->{type} eq "VALUE"){
                     if ($mode eq "SIMPLE"){
                        if ($op->{name} eq "=" ||
                            $op->{name} eq "like"){
                           my $h=_getCurH(\$curh,\@flt);
                           $h->{$e->{name}}=$val->{val};
                        }
                        elsif (lc($op->{name}) eq "in"){
                           return(undef,"comperator 'in' is not ".
                                        "supported in simple mode");
                        }
                     }
                  }
               }
            }
            else{
               return(undef,"missing comperator near '$op->{name}'");
            }
         }
      }
   }
   return(\@flt);
}

sub compileExpression
{
   my $self=shift;
   my $WhereExp=shift;

   #
   # Pass1: parse words
   #
   my @w=$self->_parseWords($WhereExp);
   if ($WhereExp ne "" && $#w==-1){
      $self->errString("syntax error - can not parse words");
      return(undef); 
   }
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
         if ($e->{type} eq "COM" && $e->{name} eq "!="){
            $cmd.=" ne ";
         }
         if ($e->{type} eq "COM" && $e->{name} eq ">"){
            $cmd.=" > ";
         }
         if ($e->{type} eq "COM" && $e->{name} eq "<"){
            $cmd.=" < ";
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
      #printf STDERR ("DEBUG src: $cmd\n"); 
     
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

