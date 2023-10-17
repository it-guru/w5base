package base::QuickFind::user;
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

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^ci$/,@$stag) &&
       (!defined($tag) || grep(/^$tag$/,qw(user contact kontakt)))){
      my $flt=[{fullname=>"*$searchtext*",cistatusid=>"<=5",
                usertyp=>['user','extern']},
               {userid=>\"$searchtext",cistatusid=>"<=5"}];
      my $dataobj=getModuleObject($self->getParent->Config,"base::user");
      $dataobj->SetFilter($flt);
      my $limit=10;
      $dataobj->Limit($limit+1);
      my $c=0;
      foreach my $rec ($dataobj->getHashList(qw(fullname))){
         my $dispname=$rec->{fullname};
         $c++;
         if ($c<=$limit){
            push(@l,{group=>$self->getParent->T("base::user","base::user"),
                     id=>$rec->{userid},
                     parent=>$self->Self,
                     name=>$dispname});
         }
         else{
            push(@l,{group=>$self->getParent->T("base::user","base::user"),
                     id=>undef,
                     parent=>$self->Self,
                     name=>"..."});
            last;
         }
      }
   }
   return(@l);
}

sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $dataobj=getModuleObject($self->getParent->Config,"base::user");
   $dataobj->SetFilter({userid=>\$id});
   my @fl=qw(givenname surname  
             office_mobile office_phone
             privat_mobile privat_phone
             ssh1publickey
             ssh2publickey
             );
   my ($rec,$msg)=$dataobj->getOnlyFirst(@fl);

   $dataobj->ResetFilter();
   $dataobj->SecureSetFilter([{userid=>\$id}]);
   my ($secrec,$msg)=$dataobj->getOnlyFirst(qw(userid));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($dataobj,{search_userid=>$id});
      }
      $htmlresult.="<table>";
      my @l=@fl;
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$dataobj->getField($v)->Label();
            my $data=$dataobj->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                         $v,"formated");
            if ($v=~m/^ssh/){
               $data=join("<wbr />",split(/(.{0,11})/,$data));
              # $data="<div style=\"width:400px\">$data</div>";
            }
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>";
         }
      }
      $htmlresult.="</table>";
   }
   return($htmlresult);
}



1;
