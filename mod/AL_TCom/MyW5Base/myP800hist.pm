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
use AL_TCom::lib::tool;
@ISA=qw(kernel::MyW5Base AL_TCom::lib::tool);

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

   my @appl=$self->getRequestedApplicationIds($userid,user=>1,
                                                      dep=>1,team=>1);
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

   my @applids=$self->getRequestedApplicationIds($userid,user=>1,
                                                         dep=>1,team=>1);
   my $contr=$self->getParent->getPersistentModuleObject("itil::custcontract");
   $contr->SetFilter({applicationids=>\@applids,cistatusid=>"<6"});
   my $maxlen=5;
   my %contractlist;
   foreach my $crec ($contr->getHashList("id","name","fullname")){
      $contractlist{$crec->{name}}={ id=>$crec->{id},
                                     no=>$crec->{name},
                                     name=>$crec->{fullname}};
      if ($maxlen<length($crec->{name})){
         $maxlen=length($crec->{name});
      }
   }
 
   if ($mode eq "raw"){
      return(values(%contractlist));
   }
   if ($mode eq "html"){
      my $oldval=Query->Param("search_affectedcontract");
      my $s="<select name=search_affectedcontract style=\"width:100%\">\n".
            "<option></option>";
      foreach my $crec (values(%contractlist)){
         $s.="<option value=\"$crec->{no}\" ";
         $s.="selected" if ($oldval eq $crec->{no});
         my $name=$crec->{name};
         $name=~s/  / /g;
         $name=~s/  / /g;
         my $label=sprintf("%-${maxlen}s %s",$crec->{no},$name);
         $label=~s/ /&nbsp;/g;
         $s.=">".$label."</option>\n";
      }
      $s.="</select>\n";
    #  my @s=$c->getHtmlSelect("search_affectedcontract","name",
    #                          ["name","fullname"],AllowEmpty=>1);
      return($s)
   }
   return(undef);
}



1;
