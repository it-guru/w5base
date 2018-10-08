package kernel::App::Web::History;
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


sub getParsedHistorySearchTemplate
{
   my $self=shift;
   my $d;

   my $idobj=$self->IdField();
   my $idname=$idobj->Name();
   my $dataobjectid=Query->Param($idname);
   return("-undef ID - System ERROR-") if ($dataobjectid eq "");
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$dataobjectid});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   my $fobj=$self->getField("fullname");
   $fobj=$self->getField("name") if (!defined($fobj));
   my $title="History";
   if (defined($fobj)){
      my $t=$fobj->RawValue($rec);
      if ($t ne ""){
         $title.=": ".$t;
      }
   }
   $title=~s/"/ /g;
   $d.=<<EOF;
<script language="JavaScript">
function setTitle()
{
   var t="$title";
   window.document.getElementById("WindowTitle");
   parent.document.title=t;
   return(true);
}
addEvent(window, "load", setTitle);
</script>
EOF


   my $changes=$self->T("Data changes");
   my @tt=();
   push(@tt,">now-7d", $self->T("last Week"));
   push(@tt,">now-28d",$self->T("last 4 Weeks"));
   push(@tt,">now-84d",$self->T("last 12 Weeks"));
   push(@tt,">now-180d",$self->T("last 180 days"));
   push(@tt,">now-365d",$self->T("last 365 days"));
   if ($self->IsMemberOf("admin") ||
       $self->IsMemberOf("support")){
      push(@tt,"<now-365d AND >now-1000d",$self->T("older then 1 year"));
   }
   push(@tt,"",$self->T("all"));
   my $tt="<select name=ListTime style=\"width:150px\">";
   while(my $k=shift(@tt)){
      my $l=shift(@tt);
      $tt.="<option value=\"$k\">$l</option>";
   }
   $tt.="</select>";
   $d.=<<EOF;
<table width="100%" border=0>
<tr>
<td width=1% nowrap>$changes:</td>
<td>$tt</td>
<td width=1%>
<input class=button type=button value="Aktualisieren" onclick="DoSearch();">
</td>
</tr>
</table>
EOF
   return($d);
}

sub HtmlHistory
{
   my ($self)=@_;
   return($self->ListeditTabObjectSearch("HistoryResult",
                 $self->getParsedHistorySearchTemplate()));
}


sub HistoryResult
{
   my $self=shift;
   my %param=@_;

   my $dataobjectid=Query->Param("CurrentId");
   $dataobjectid=~s/^0*//;  # prevent leading zeros
   if ($dataobjectid ne ""){
      $self->ResetFilter();
      my $idobj=$self->IdField();
      my $idname=$idobj->Name();
      $self->SetFilter({$idname=>\$dataobjectid});
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my @view=$self->isViewValid($rec);
         if (grep(/^history$/,@view) ||
             grep(/^ALL$/,@view)){
            my @viewo=$self->getFieldObjsByView([qw(ALL)],current=>$rec);
            my @fields=();
            foreach my $fo (@viewo){
               my $grp=$fo->{group};
               $grp="default" if ($grp eq "");
               push(@fields,$fo->Name) if (grep(/^$grp$/,@view) ||
                                           grep(/^ALL$/,@view));
            }
            my $h=$self->getPersistentModuleObject("History","base::history");
            $h->setParent(); # reset parent link
            if (!$h->{IsFrontendInitialized}){
               $h->{IsFrontendInitialized}=$h->FrontendInitialize();
            }
            my $output=new kernel::Output($h);
            if ($h->validateSearchQuery()){
               $h->ResetFilter();
               my %q=$h->getSearchHash();
               my $dataobject=[$self->Self,$self->SelfAsParentObject()];
               if ($dataobject->[0] eq $dataobject->[1]){
                  my $s=$self->Self;
                  $dataobject=\$s;
               }
               $q{dataobject}=$dataobject;
               $q{dataobjectid}=\$dataobjectid;
               if (!$self->IsMemberOf("admin")){
                  $q{name}=\@fields;  # normal users can only be 
                                      # see real readable fields (security!)
               }
               my $listdate=Query->Param("ListTime");
               $q{cdate}=$listdate;
               $h->ResetFilter();
               $h->SecureSetFilter(\%q);
               return($h->Result(ExternalFilter=>1));
            }
         }
         else{
            print $self->noAccess($self->T("no access to 'history' fieldgroup"));
            return;
         }
      }
   }
   print $self->noAccess();
}

######################################################################

1;
