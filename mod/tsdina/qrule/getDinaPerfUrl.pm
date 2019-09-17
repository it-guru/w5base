#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if the system is known in DINA. If this is, the local perfurl is
refreshed to display the "Performance" Tab.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Make sure the system is also available in DINA.

[de:]

Püfen Sie, ob das System auch in DINA bekannt ist.


=cut

package tsdina::qrule::getDinaPerfUrl;
use strict;
use vars qw(@ISA);
use JSON;
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
   return(["itil::system","AL_TCom::system","TS::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $newUrl=undef;
   my @msg;

   $newUrl="" if ($rec->{'cistatusid'}==6);

   my $ua;
   my $html;
   eval('
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;

$ua=new LWP::UserAgent(env_proxy=>0);
#$ua->cookie_jar(HTTP::Cookies->new(file => "/tmp/.w5base.cookies.txt"));
$ua->timeout(60);
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de-AT; rv:1.8.1.4) Gecko/20070509 SeaMonkey/1.1.2");
$html=new HTML::Parser();
');
   if ($@ ne ""){
      msg(ERROR,$@);
   }
   else{
      my $id=$rec->{id};
      my $loadurl="https://dina.telekom.de/cam/darwin/get_dina_host_id.jsp?".
                  "darwin_id=$id";
      my $response = $ua->get($loadurl);  # loading related dinaID to 
                                          # current record from DINA system
      if ($response->is_success) {
          my $h;
          eval('$h=decode_json($response->decoded_content);');
          if (ref($h) eq "HASH"){
             if ($h->{success}){
                $newUrl="https://dina.telekom.de/cam/darwin/host.jsp?host=".
                        "$h->{dina_host_id}";
             }
          }
          else{
             msg(ERROR,"unexpected result while querying DINA ".
                       "for host $rec->{name}");
          }
      }
   }
   my $perfgate=undef;   # searching for the correct perfgate entry
   for(my $g=1;$g<=3;$g++){   
      if ($rec->{"perf${g}url"} eq "" ||
          ($rec->{"perf${g}url"}=~m/dina.telekom.de/)){
         $perfgate=$g;
         last;
      }
   }

   if (defined($perfgate)){  # store pergate state in system record
      if ($newUrl ne ""){
         my $newrec={"perf${perfgate}date"=>NowStamp("en")};
         if ($rec->{"perf${perfgate}url"} ne $newUrl){
            push(@msg,"setting new performance url for DINA");
            $newrec->{"perf${perfgate}url"}=$newUrl;
         }
         else{
            $newrec->{mdate}=$rec->{mdate};  # dont change mdate if url is not
         }                                   # changed
         my $swop=$dataobj->Clone();
         $swop->ValidatedUpdateRecord($rec,$newrec,{id=>\$rec->{id}});
      }
      else{  # TODO:
             # check if perf${perfgate}date older then 14d
             # then clear the entry
      }
   }


   return(0,{qmsg=>\@msg});

}




1;
