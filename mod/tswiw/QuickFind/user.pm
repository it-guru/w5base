package tswiw::QuickFind::user;
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
   if ($ENV{REMOTE_USER} ne "anonymous"){
      push(@$stags,"citswiwuser","T-Systems WhoIsWho Person (slow)");
   }
}

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^citswiwuser$/,@$stag) &&
       (!defined($tag) || grep(/^$tag$/,qw(wiw)))){
      my $flt=[{surname=>"*$searchtext*"},
               {uid=>\$searchtext},
               {email=>\"*$searchtext*"}];
      my @words=split(/[, ]+/,$searchtext);
      if ($#words>0){
         $flt={surname=>"$words[0]*",
               givenname=>"$words[1]*"};
      }
      my $wiwuser=getModuleObject($self->getParent->Config,"tswiw::user");
      $wiwuser->SetFilter($flt);
      foreach my $rec ($wiwuser->getHashList(qw(surname givenname email))){
         my $dispname=$rec->{name};
         if ($rec->{surname} ne ""){
            $dispname.=$rec->{surname};
         }
         if ($rec->{givenname} ne ""){
            $dispname.=", " if ($dispname ne "");
            $dispname.=$rec->{givenname};
         }
         if ($rec->{email} ne ""){
            $dispname.=" " if ($dispname ne "");
            $dispname.='('.$rec->{email}.')';
         }
         push(@l,{group=>$self->getParent->T("tswiw::user","tswiw::user"),
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

   my $tswiwuser=getModuleObject($self->getParent->Config,"tswiw::user");
   $tswiwuser->SetFilter({id=>\$id});
   my @l=qw(surname givenname email office_phone office_mobile touid);
   my ($rec,$msg)=$tswiwuser->getOnlyFirst(@l);
   $tswiwuser->ResetFilter();
   $tswiwuser->SecureSetFilter([{id=>\$id}]);
   my ($secrec,$msg)=$tswiwuser->getOnlyFirst(qw(id));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($tswiwuser,{search_id=>$id});
      }
      $htmlresult.="<table>\n";
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$tswiwuser->getField($v)->Label();
            my $data=$tswiwuser->findtemplvar({current=>$rec,
                                               mode=>"HtmlDetail"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>\n";
         }
      }
   }
   return($htmlresult);
}



1;
