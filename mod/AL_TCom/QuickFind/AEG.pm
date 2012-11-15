package AL_TCom::QuickFind::AEG;
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
use kernel::QuickFind;
@ISA=qw(kernel::QuickFind);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub ExtendStags
{
   my $self=shift;
   my $stags=shift;
   push(@$stags,"ciaeg","TelekomIT Application Expert Group");
}

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^ciaeg$/,@$stag)){
      my $flt=[{name=>"*$searchtext*", cistatusid=>"<=5"},
              ];
      my $appl=getModuleObject($self->getParent->Config,"itil::appl");
      $appl->SetFilter($flt);
      foreach my $rec ($appl->getHashList(qw(name customer))){
         my $dispname=$rec->{name};
         if ($rec->{customer} ne ""){
            $dispname.=' @ '.$rec->{customer};
         }
         push(@l,{group=>"Application Expert Group",
                  id=>$rec->{id},
                  parent=>$self->Self,
                  name=>$dispname});
      }
   }
   return(@l);
}


sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({id=>\$id});
   my ($rec,$msg)=$appl->getOnlyFirst(qw(tsmid applmgrid contacts));

   if (defined($rec)){
print STDERR Dumper($rec);
      my $user=getModuleObject($self->getParent->Config,"base::user");
      my @aeg=('applmgr'=>{userid=>[$rec->{applmgrid}],
                           label=>$appl->getField("applmgr")->Label()},
               'tsm'    =>{userid=>[$rec->{tsmid}],
                           label=>$appl->getField("tsm")->Label()},
               'dba'    =>{userid=>[],
                           label=>$self->getParent->T("Database Admin")},
               'developerboss' =>{userid=>[],
                                  label=>$self->getParent->T("Developer")},
               'projectmanager'=>{userid=>[],
                                  label=>$self->getParent->T("Projectmanager")},
              );
      my %a=@aeg;

      foreach my $crec (@{$rec->{contacts}}){
         if ($crec->{target} eq "base::user" &&
             in_array($crec->{roles},"developerboss")){
            if (!in_array($a{developerboss}->{userid},$crec->{targetid})){
               push(@{$a{developerboss}->{userid}},$crec->{targetid});
            }
         }
         if ($crec->{target} eq "base::user" &&
             in_array($crec->{roles},"projectmanager")){
            if (!in_array($a{projectmanager}->{userid},$crec->{targetid})){
               push(@{$a{projectmanager}->{userid}},$crec->{targetid});
            }
         }
      }
      my $swi=getModuleObject($self->getParent->Config,"itil::swinstance");
      $swi->SetFilter({cistatusid=>\'4',applid=>\$rec->{id},
                       swnature=>["Oracle DB Server","MySQL","MSSQL","DB2"]});
      foreach my $srec ($swi->getHashList(qw(admid))){
         if (!in_array($a{dba}->{userid},$srec->{admid})){
            push(@{$a{dba}->{userid}},$srec->{admid});
         }
      }
      

      my @chkuid;
      foreach my $r (values(%a)){
         push(@chkuid,@{$r->{userid}});
      }
      $user->SetFilter({userid=>\@chkuid});
      $user->SetCurrentView(qw(phonename email));
      my $u=$user->getHashIndexed("userid");

      my $d="<table>";
      while(my $aegtag=shift(@aeg)){
         my $arec=shift(@aeg);
         $d.="<tr><td valign=top><b>".$arec->{label}.":</b></td>";
         my $c="";
         @{$arec->{userid}}=grep(!/^\s*$/,@{$arec->{userid}});
         if ($#{$arec->{userid}}!=-1){
            foreach my $userid (@{$arec->{userid}}){
               $c.="<br>--<br>\n" if ($c ne "");
               my $phone=quoteHtml($u->{userid}->{$userid}->{phonename});
               $c.="<pre>".$phone."</pre>";
            }
         }
         else{
            $c="?";
         }
         $d.="<td valign=top>".$c."</td></tr>\n";
      }
      $d.="</table>";
      $htmlresult=$d;
   }
   return($htmlresult);
}



1;
