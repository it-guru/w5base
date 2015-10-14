package kernel::Field::DataDump;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   if (!defined($self->{onRawValue})){
      $self->{onRawValue}=sub{
         my $self=shift;
         my $current=shift;
         my %rec=();

         my $depend=$self->{depend};
         my @depend;
         if (ref($depend) eq "ARRAY"){
            @depend=@$depend;
         }
         my @sqlctrl=@{$self->{sqldepend}};
         $rec{order}=[];
         while(my $k=shift(@sqlctrl)){
           my $ctrl=shift(@sqlctrl);
           my $fields="*";
           my $from=$k;
           my $where="";
           push(@{$rec{order}},$k);
           $from=$ctrl->{from}   if (exists($ctrl->{from}));
           $fields=$ctrl->{fields}     if (exists($ctrl->{fields}));
           $where=$ctrl->{where} if (exists($ctrl->{where}));
           if (exists($ctrl->{joinon}) && ref($ctrl->{joinon}) eq "ARRAY"){
              my $srcval=$current->{$ctrl->{joinon}->[0]};
              my $dstname=$ctrl->{joinon}->[1];
              $where="(".$where.") and " if ($where ne "");
              $where.=$dstname."='".$srcval."'";
           }
           my $cmd="select ".$fields." from ".$from." where ".$where;
           $cmd=$ctrl->{cmd} if (exists($ctrl->{cmd}));
           my $workdb=new kernel::database($self->getParent,$ctrl->{dbname});
           if ($workdb->Connect()){
              my @l=$workdb->getHashList($cmd);
              if ($workdb->Ping()){
                 $rec{res}->{$k}={
                    'SQLcommand'=>$cmd,
                    'SQLdbname'=>$ctrl->{dbname},
                    'Result'=>\@l
                 };
                 $workdb->Disconnect();
              }
           }
           if (!exists($rec{res}->{$k})){
              $rec{res}->{$k}={
                 SQLerror=>'query problem',
                 SQLcmd=>$cmd
              };
           }
         }
         return(\%rec);
      };
   }
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($FormatAs=~m/Html.*/){
      my $maxdatalen=78;
      if ($FormatAs eq "HtmlDetail"){
         $maxdatalen=37;
      }
      my $res="<table class=subtable>";
      for(my $setno=0;$setno<=$#{$d->{order}};$setno++){
         my $k=$d->{order}->[$setno];
         if (ref($d->{res}->{$k}->{Result}) eq "ARRAY" &&
             $#{$d->{res}->{$k}->{Result}}>-1){
            $res.="<tr><td colspan=3 class=hl><b>$k</b></td></tr>";
            my @l;
            for(my $recno=0;$recno<=$#{$d->{res}->{$k}->{Result}};$recno++){
             
               my $n=keys(%{$d->{$k}->{Result}->[$recno]});
              # $n=$n+1;
               push(@l,"<tr><td rowspan=$n valign=top width=5>[".
                       "$recno]</td>");
               my @fl=sort(keys(%{$d->{res}->{$k}->{Result}->[$recno]}));
               my $fno=0;
               foreach my $name (@fl){
                  $fno++;
                  #push(@l,"<tr>") if ($#l!=0);
                  push(@l,"<td width=5></td>") if ($fno>1);
                  my $d=$d->{res}->{$k}->{Result}->[$recno]->{$name};
                  if (defined($d)){
                     $d=~s/\n/ /g;
                      
                     if (length($d)>$maxdatalen){
                        $d=substr($d,0,$maxdatalen-3)."...";
                     }
                  }
                  else{
                     $d="[NULL]";
                  }
                  $d=quoteHtml($d);
                  if ($d eq ""){
                     $d="&nbsp;";
                  }
                  push(@l,"<td width=20% valign=top>".$name."</td>".
                          "<td valign=top>".$d."</td>");
                  push(@l,"</tr>");
               }
               #push(@l,"</tr>") if ($#l==0);
            }
            $res.=join("\n",@l);
         }
      }
      $res.="</table>";
      return($res);
   }
   return($self->SUPER::FormatedDetail($current,$FormatAs));
}






1;
