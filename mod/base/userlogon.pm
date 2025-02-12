package base::userlogon;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(        name        =>'id',
                                    label       =>'W5BaseID',
                                    dataobjattr =>['userlogon.account',
                                                   'userlogon.loghour']),
                                  
      new kernel::Field::Text(      name        =>'account',
                                    label       =>'Account',
                                    dataobjattr =>'userlogon.account'),

      new kernel::Field::Text(      name        =>'logonhour',
                                    label       =>'Logon Hour',
                                    dataobjattr =>'userlogon.loghour'),

      new kernel::Field::Date(      name        =>'logondate',
                                    sqlorder    =>'desc',
                                    label       =>'Logon-Date',
                                    dataobjattr =>'userlogon.logondate'),

      new kernel::Field::Text(      name        =>'logonip',
                                    label       =>'Logon IP',
                                    htmlwidth   =>'80px',
                                    dataobjattr =>'userlogon.logonip'),

      new kernel::Field::Text(      name        =>'logonbrowser',
                                    label       =>'Logon Browser',
                                    dataobjattr =>'userlogon.logonbrowser'),

      new kernel::Field::Text(      name        =>'lang',
                                    label       =>'Language',
                                    dataobjattr =>'userlogon.lang'),

      new kernel::Field::Text(      name        =>'site',
                                    label       =>'Site',
                                    dataobjattr =>'userlogon.site'),

   );
   $self->setDefaultView(qw(logondate account logonip logonbrowser));
   $self->setWorktable("userlogon");
   return($self);
}


sub Validate
{
   my ($self,$oldrec,$newrec)=@_;
   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_account"))){
      my $account=$ENV{REMOTE_USER};
     Query->Param("search_account"=>
                  "\"$account\"");
   }
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my $account=$ENV{REMOTE_USER};
      my @addflt=({account=>\$account});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}




sub isViewValid
{
   my ($self,$rec)=@_;
   return("ALL");
}

sub isWriteValid
{
   my ($self,$rec)=@_;
   return(undef);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/env.jpg?".$cgi->query_string());
}



sub isAnonymousAccessValid
{
    my $self=shift;
    return(1) if ($_[0] eq "userCount");
    return($self->SUPER::isAnonymousAccessValid(@_));
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"userCount");
}


sub userCount
{
   my $self=shift;

   print($self->HttpHeader("text/javascript"));

   my $n="???";

   $self->ResetFilter();
   $self->SetFilter({logondate=>">now-1h"});
   my $cnt=$self->CountRecords();
   $n=$cnt;

   my $d="";
   my $JSONP=Query->Param("callback");
   $JSONP="_JSONP" if ($JSONP eq "");
   $d.="$JSONP({";
   $d.="\"count\":\"$n\"";
   $d.="});";

   print($d);
}

1;
