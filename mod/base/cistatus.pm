package base::cistatus;
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
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(      name     =>'id',
                                  label    =>'CI-StateID'),
      new kernel::Field::Text(    name     =>'name',
                                  label    =>'CI-State'),
      new kernel::Field::Text(    name     =>'info',
                                  label    =>'CI-State-Info')
   );
   $self->{'data'}=[ 
                     {id=>0 , info=>'bla angefordertert status'},
                     {id=>1 , info=>'bla angefordertert status'},
                     {id=>2 , info=>'bestellter status'},
                     {id=>3 , info=>'verfügbarer status'},
                     {id=>4 , info=>'ci ist aktiv'},
                     {id=>5 , info=>'zeitweise deaktivert'},
                     {id=>6 , info=>'verschrottet'},
                     {id=>7 , info=>'entsorgt'}];
   $self->setDefaultView(qw(id name info));
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
}

sub show                 # is used, to make the cistatus visible for emails
{
   my $self=shift;
   my $func=$self->Query->Param("FUNC");

   if (defined(Query->Param("HTTP_ACCEPT_LANGUAGE"))){
      $ENV{HTTP_ACCEPT_LANGUAGE}=Query->Param("HTTP_ACCEPT_LANGUAGE");
   }

   my ($pack,$mod,$id)=$func=~m#^show/(.*)/(.*)/(.*)$#;
   my $cistatus=0;
   #msg(INFO,"base::cistatus pack=$pack mod=$mod id=$id");
   if (defined($pack) && defined($mod) && defined($id) &&
       $pack ne "" && $mod ne "" && $id ne ""){
      my $m=getModuleObject($self->Config,$pack."::".$mod);
      if (defined($m)){
         my $idname=$m->IdField->Name();
         if ($idname ne ""){
            $m->SetFilter({$idname=>\$id});
            my ($rec,$msg)=$m->getOnlyFirst(qw(cistatusid));
            if (defined($rec) && defined($rec->{cistatusid})){
               $cistatus=$rec->{cistatusid};
            }
         }
      }
   }



   my $filename=$self->getSkinFile("base/img/cistatus$cistatus.gif");
   my %param;

   #msg(INFO,"base::cistatus request=$func result filename=$filename");

   print $self->HttpHeader("image/gif",%param);
   if (open(MYF,"<$filename")){
      binmode MYF;
      binmode STDOUT;
      while(<MYF>){
         print $_;
      }
      close(MYF);
   }
}


sub isAnonymousAccessValid
{
    my $self=shift;
    my $method=shift;
    return(1) if ($method eq "show");
    return(0);
}



sub RawValue
{
   my $self=shift;
   my $field=shift;
   my $rec=shift;

   if ($field eq "name"){
      return($self->T("CI-Status($rec->{id})"));
   }
   return($self->SUPER::RawValue($field,$rec));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  
   



1;
