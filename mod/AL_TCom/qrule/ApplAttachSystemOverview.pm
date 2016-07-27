package AL_TCom::qrule::ApplAttachSystemOverview;
#######################################################################
=pod

=head3 PURPOSE

Check if a prio1 application have an SystemOverview Attachment.

=head3 IMPORTS

NONE

=head3 HINTS
Every Pri1 application must have an attachment with the System-Plan. These
plan must be name in convention ...
  ICTO_xxxx-applikationsname-SystemOverview-jjjjmmtt.pdf

For further questions please contact Mr. Bell 
https://darwin.telekom.de/darwin/auth/base/user/ById/13559244960000


[de:]

Es wurde festgelegt, das jede Prio1 Anwendung einen Systemplan als
PDF Anlage vorliegen haben muß.
Dieser Systemplan muß unter der Namenskonvention ...

  ICTO_xxxx-applikationsname-SystemOverview-jjjjmmtt.pdf

... benannt sein. Bei Rückfragen wenden Sie sich bitte an Hr. Bell
https://darwin.telekom.de/darwin/auth/base/user/ById/13559244960000


=cut
#######################################################################
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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);


   if ($rec->{customerprio}==1){
      if ($rec->{ictoid} ne ""){
         my $nameexpr=$rec->{ictono};
         $nameexpr=~s/-/_/; #Anscheinend soll der - als _ verwendet werden
         $nameexpr.="-".$rec->{name}."-SystemOverview-jjjjmmtt.pdf";
         my $found=0;
         my $ne=$nameexpr;
         $ne=~s/^/^/;
         $ne=~s/$/\$/;
         $ne=~s/-jjjjmmtt\./-\\d{8}./;
         if (exists($rec->{attachments}) &&
             ref($rec->{attachments}) eq "ARRAY"){
            foreach my $a (@{$rec->{attachments}}){
               if ($a->{name}=~m/$ne/){
                  $found++;
               }
            }
         }
         if (!($found)){
            $exitcode=3 if ($exitcode<3);
            push(@{$desc->{qmsg}},
                 $self->T('there is no SystemOverview attachment found'));
            push(@{$desc->{qmsg}},
                 $self->T('requested SystemOverview name').": ".$nameexpr);
            push(@{$desc->{dataissue}},
                 $self->T('there is no SystemOverview attachment found'));
         }

      }
      else{
         return(undef);
      }
   }
   else{
      return(undef);
   }
   return($exitcode,$desc);
}




1;
