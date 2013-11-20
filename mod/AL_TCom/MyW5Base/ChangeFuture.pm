package AL_TCom::MyW5Base::ChangeFuture;
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
use kernel::MyW5Base;
use Data::Dumper;
@ISA=qw(kernel::MyW5Base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{timerange}=['1'=>'>now AND <now+3d',
                       '2'=>'>now AND <now+14d',
                       '3'=>'>now AND <now+15d'];
   return($self);
}

sub Init
{
   my $self=shift;
   $self->{DataObj}=getModuleObject($self->getParent->Config,"base::workflow");
   $self->{appl}=getModuleObject($self->getParent->Config,"itil::appl");
   return(0) if (!defined($self->{DataObj}));
   return(1);
}

sub isSelectable
{
   my $self=shift;

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                                        'AL_TCom::MyW5Base::ChangeFuture$');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getQueryTemplate
{
   my $self=shift;
   my $timedrop=$self->getTimeRangeDrop("search_ES",
                                        $self->getParent,
                                        qw(nearfuture));
   my @spmodes=(
                '*'=>'*',
                'multi'=>
                $self->getParent->T("only multi application changes"),
                'divmulti'=>
                $self->getParent->T("only multi TSM responsibility"),
                'prio1ag'=>
                $self->getParent->T("only applications with customer prio 1")
               );
                
   my $oldval=Query->Param("search_SP");
   my $sp="<select name=search_SP>";
   while(defined(my $exp=shift(@spmodes))){
      my $nam=shift(@spmodes);
      $sp.="<option value=\"$exp\"";
      $sp.=" selected" if ($exp eq $oldval);
      $sp.=">$nam</option>";
   }
   $sp.="</select>";
   
   my $l1=$self->getParent->T("Change start timerange"); 
   my $l2=$self->getParent->T("Special selection"); 
   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>$l1:</td><td class=finput width=40% >$timedrop</td>
<td class=fname width=10%>$l2:</td><td class=finput width=40%>$sp</td>
<td colspan=2></td>
</tr>
</table>
</div>
%StdButtonBar(print,bookmark,search)%
EOF
   return($d);
}


sub Result
{
   my $self=shift;

   my $search_es=Query->Param("search_ES");
   my $search_sp=Query->Param("search_SP");

   my $flt={ eventstart=>$search_es,
             mandator=>"\"AL DTAG\"",
             class=>[grep(/^AL_TCom::.*::change$/,
                          keys(%{$self->{DataObj}->{SubDataObj}}))]};
   if ($search_sp eq "prio1ag"){
      $self->{appl}->ResetFilter();
      $self->{appl}->SetFilter({customerprio=>1,
                                mandator=>"\"AL DTAG\""});
      my @l=$self->{appl}->getHashList(qw(id));
      if ($#l==-1){
         $flt->{affectedapplicationid}=-1;
      }
      else{
         $flt->{affectedapplicationid}=[map({$_->{id}} @l)];
      }
   }

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter($flt);
   my @l=$self->{DataObj}->getHashList(qw(id affectedapplicationid));

  
   my @idl;
   foreach my $rec (@l){
      next if (ref($rec->{affectedapplicationid}) ne "ARRAY");
      if ($search_sp eq "multi" || $search_sp eq "divmulti"){
         if ($#{$rec->{affectedapplicationid}}>0){
            if ($search_sp eq "divmulti"){
               $self->{appl}->ResetFilter();
               $self->{appl}->SetFilter({id=>$rec->{affectedapplicationid}});
               my %tl;
               foreach my $arec ($self->{appl}->getHashList(qw(tsmid))){
                  $tl{$arec->{tsmid}}++;
               }
               if (keys(%tl)>1){
                  push(@idl,$rec->{id}); # is multi tsm
               }
            }
            else{
               push(@idl,$rec->{id});
            }
         }
      }
      else{
         push(@idl,$rec->{id});
      }
   }
   
   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter({id=>\@idl});

   $self->{DataObj}->setDefaultView(qw(linenumber eventstart srcid 
                                       state affectedapplication name));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}
1;
