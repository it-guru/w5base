package TS::AppComStatus;
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
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=2;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Percent(
                name          =>'appcomst',
                label         =>'AppCom goal achievement',
                group         =>'source',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $l=$app->getPersistentModuleObject("itil::lnkapplsystem");
                   $l->SetFilter({applid=>$current->{id},
                                  systemcistatusid=>\'4'});
                   my @l=$l->getHashList(qw(systemid));
                   return(undef) if ($#l==-1);
                   my $n=$#l+1;
                   my $ok=0;
                   my $s=$app->getPersistentModuleObject("itil::system");
                   foreach my $lnkrec ($l->getHashList(qw(systemid))){
                      $s->SetFilter({id=>\$lnkrec->{systemid}});
                      my ($srec,$msg)=$s->getOnlyFirst(qw(servicesupport));
                      if ($srec->{servicesupport}=~m/^OSY AC/){
                         $ok++;
                      }
                   }
                   my $p=$ok*100/$n;
                 
                   return($p);
                }),
      new kernel::Field::Boolean(
                name          =>'isfullappcom',
                label         =>'full AppCom',
                group         =>'source',
                htmldetail    =>0,
                searchable    =>0,
                markempty     =>1,
                depend        =>['appcomst'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $p=$app->getField("appcomst")->RawValue($current);
                   return(undef) if (!defined($p));
                   return(1) if ($p>=100);
                   return(0);
                })
   );
   delete($self->{workflowlink});
   $self->setFieldParam(qr/^(name|cistatus|businessteam|mandator|isnosysappl)$/,
                        NEGMATCH=>1,
                        searchable=>0);
   $self->{ResultLineClickHandler}=undef;
   $self->setDefaultView(qw(name mandator cistatus systemcount 
                            appcomst isfullappcom));

   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_mandator"))){
     Query->Param("search_mandator"=>
                  "!Extern");
   }
   if (!defined(Query->Param("search_businessteam"))){
     Query->Param("search_businessteam"=>
                  "DTAG.TSI.Prod.CSS.AO.DTAG.TH2 ".
                  "DTAG.TSI.Prod.CSS.AO.DTAG.TH2.*");
   }
   if (!defined(Query->Param("search_isnosysappl"))){
     Query->Param("search_isnosysappl"=>$self->T("no"));
   }

   $self->SUPER::initSearchQuery();
}

sub isWriteValid
{
   my $self=shift;
   return();
}

sub isUploadValid
{
   my $self=shift;

   return(0);
}

sub getAnalytics
{
   my $self=shift;
   return('Analytics'=>$self->T('Analytics','kernel::App::Web'));
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(Analytics));
}

sub Analytics
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'Analytics');
   printf("<br><br><center>Analytics comming soon!");
   print $self->HtmlBottom(body=>1,form=>1);
}













1;
