package AL_TCom::MyW5Base::myP800hist;
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
@ISA=qw(kernel::MyW5Base);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
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
                          'base::MyW5Base::myP800$',
                          func=>'Main');

   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getQueryTemplate
{
   my $self=shift;
   my @s=$self->getContractList("html");


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>\%affectedcontract(label)\%:</td>
<td class=finput width=90%>$s[0]</td>
<td colspan=2></td>
</tr>
</table>
</div>
%StdButtonBar(print,search)%
EOF
   return($d);
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}



sub Result
{
   my $self=shift;
   my %q=$self->{DataObj}->getSearchHash();

   my $userid=$self->getParent->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   my $dc=Query->Param("EXVIEWCONTROL");
   my @q=();
   my %mainq1=%q;
   if ($mainq1{affectedcontract} eq ""){
      $self->getParent->LastMsg(ERROR,"no contract specified");
      return(undef);
   }
   $mainq1{stateid}=['1','21'];

   my %q1;
   my %q2;
   my %q3;
   my %q4;
   my %q5;
   $q1{semid}=\$userid;
   $q2{tsmid}=\$userid;
   $q3{databossid}=\$userid;
   $q4{sem2id}=\$userid;
   $q5{tsm2id}=\$userid;
   push(@q,\%q1,\%q2,\%q3,\%q4,\%q5);


   $self->{appl}->ResetFilter();
   $self->{appl}->SecureSetFilter(\@q);
   my @l=$self->{appl}->getHashList("id");
   my @appl=("none");
   if ($#l>-1){
      @appl=map({$_->{id}} @l);
   }
   $mainq1{affectedapplicationid}=\@appl;
   #my $m=Query->Param("P800_TimeRange");
   #$m="now" if (!defined($m) || $m eq ""); 
   return($self->FinalDataFilter(\%mainq1));
}

sub FinalDataFilter
{
   my $self=shift;
   my $mainq1=shift;

   $mainq1->{class}=[grep(/^.*::P800$/,keys(%{$self->{DataObj}->{SubDataObj}}))];

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([$mainq1]);
   $self->{DataObj}->setDefaultView(qw(linenumber affectedcontract
                                                  affectedapplication
                                       wffields.p800_reportmonth
                                       wffields.p800_app_incidentcount
                                       wffields.p800_app_changecount
                                       wffields.p800_app_changecount_customer
                                       wffields.p800_app_applicationcount
                                       wffields.p800_app_interfacecount
                                       wffields.p800_app_customerwt
                                   ));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}




sub getContractList
{
   my $self=shift;
   my $mode=shift;
   my $c=$self->getParent->getPersistentModuleObject("itil::appl");
   my %l=();
   my $userid=$self->getParent->getCurrentUserId();

   my (%q1,%q2,%q3,%q4,%q5); 
   my @q;

   $q1{semid}=\$userid;
   $q1{cistatusid}='<=5';
   $q2{databossid}=\$userid;
   $q2{cistatusid}='<=5';
   $q3{sem2id}=\$userid;
   $q3{cistatusid}='<=5';
   $q4{tsmid}=\$userid;
   $q4{cistatusid}='<=5';
   $q5{tsm2id}=\$userid;
   $q5{cistatusid}='<=5';
   push(@q,\%q1,\%q2,\%q3,\%q4,\%q5);
   $c->ResetFilter(); 
   $c->SetFilter(\@q); 
   my %contractlist=();
   my $maxlen=0;
   foreach my $arec ($c->getHashList("id","name","custcontracts")){
      if (ref($arec->{custcontracts}) eq "ARRAY"){
         foreach my $crec (@{$arec->{custcontracts}}){
            if ($crec->{custcontract} ne ""){
               $contractlist{$crec->{custcontract}}={
                                               id=>$crec->{custcontractid},
                                               no=>$crec->{custcontract},
                                               name=>$crec->{custcontractname}};
               if ($maxlen<length($crec->{custcontract})){
                  $maxlen=length($crec->{custcontract});
               }
            }
         }
      }
   }

 
   if ($mode eq "raw"){
      return(values(%contractlist));
   }
   if ($mode eq "html"){
      my $oldval=Query->Param("search_affectedcontract");
      my $s="<select name=search_affectedcontract style=\"width:100%\">".
            "<option></option>";
      foreach my $crec (values(%contractlist)){
         $s.="<option value=\"$crec->{no}\" ";
         $s.="selected" if ($oldval eq $crec->{no});
         $s.=">".sprintf("%${maxlen}s %s",$crec->{no},$crec->{name}).
             "</option>";
      }
      $s.="</select>";
    #  my @s=$c->getHtmlSelect("search_affectedcontract","name",
    #                          ["name","fullname"],AllowEmpty=>1);
      return($s)
   }
   return(undef);
}



1;
