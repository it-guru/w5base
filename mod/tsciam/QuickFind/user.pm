package tsciam::QuickFind::user;
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
      push(@$stags,"citsciamuser","DTAG CIAM Person");
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
   if (grep(/^citsciamuser$/,@$stag) &&
       (!defined($tag) || grep(/^$tag$/,qw(ciam)))){
      my $flt=[{surname=>"*$searchtext*",active=>'true'},
               {uid=>\$searchtext,active=>'true'},
               {email=>\"*$searchtext*",active=>'true'}];
      if (my ($sn,$gn)=$searchtext=~m/^(.*),\s+(.*)$/){
         $flt=[{surname=>"$sn*",givenname=>"$gn*",active=>'true'}];
      }
      if ($searchtext=~m/^[a-z0-9_]{2,8}$/){
         push(@$flt,{wiwid=>\$searchtext,active=>'true'});
      }
      if ($searchtext=~m/^[0-9]{2,10}$/){
         push(@$flt,{tcid=>\$searchtext,active=>'true'});
      }

      my $wiwuser=getModuleObject($self->getParent->Config,"tsciam::user");
      $wiwuser->SetFilter($flt);
      foreach my $rec ($wiwuser->getHashList(qw(twrid 
                                                surname givenname 
                                                email))){
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
         push(@l,{group=>$self->getParent->T("tsciam::user","tsciam::user"),
                  id=>$rec->{twrid},
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

   my $tsciamuser=getModuleObject($self->getParent->Config,"tsciam::user");
   $tsciamuser->SetFilter({twrid=>\$id});
   my @l=qw(surname givenname email wiwid tcid office_phone office_mobile
            office shortname);
   my ($rec,$msg)=$tsciamuser->getOnlyFirst(@l);
   $tsciamuser->ResetFilter();
   $tsciamuser->SecureSetFilter([{twrid=>\$id}]);
   my ($secrec,$msg)=$tsciamuser->getOnlyFirst(qw(twrid));

   if (defined($rec)){
      $htmlresult="";
      if (defined($secrec)){
         $htmlresult.=$self->addDirectLink($tsciamuser,{search_twrid=>$id});
      }
      $htmlresult.="<table>\n";
      foreach my $v (@l){
         if ($rec->{$v} ne ""){
            my $name=$tsciamuser->getField($v)->Label();
            my $data=$tsciamuser->findtemplvar({current=>$rec,
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
