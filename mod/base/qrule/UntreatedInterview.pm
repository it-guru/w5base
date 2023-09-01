package base::qrule::UntreatedInterview;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Take a look on untreaded interview questions.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This QRule checks the upcoming interview questions 
for unanswered questions or lapsed answers.
To eliminate this problem, simply answer all unanswered or lapsed responses.

[de:]

Diese QRule überprüft die anstehenden Interview-Fragen auf
unbeantwortete Fragen bzw. verfallene Antworten.
Zur Beseitigung dieser Problematik, beantworten Sie einfach
alle unbeantworteten bzw. veraltete Beanwortungen.

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   if (exists($rec->{cistatusid})){
      return(0,undef) if ($rec->{cistatusid}>5);
   }

   my $idfield=$dataobj->IdField();
   my $objname=$dataobj->SelfAsParentObject();
   if (defined($idfield)){
      my $id=$rec->{$idfield->Name()};
      if ($id ne ""){
         my $itodo=getModuleObject($dataobj->Config,"base::interviewtodocache");
         $itodo->SetFilter({
            dataobject=>\$objname,
            dataobjectid=>\$id,
         });
         my @l=$itodo->getHashList(qw(id));
         if ($#l!=-1){
            my $msg="there are open/outdated interview questions"; 
            push(@qmsg,$msg);
            $itodo->ResetFilter();
            $itodo->SetFilter({
               dataobject=>\$objname,
               dataobjectid=>\$id,
               cdate=>"<now-56d"
            });
            @l=$itodo->getHashList(qw(id));
            if ($#l!=-1){
               push(@dataissue,$msg);
               $errorlevel=3 if ($errorlevel<3);
            }
         }
      }
   }

   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
