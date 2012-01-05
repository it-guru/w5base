package itil::itstatus;
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
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub asXML
{
   my $self=shift;
   Query->Param("FormatAs"=>'XMLV01');

   return($self->Display());
}

sub asJSONP
{
   my $self=shift;
   Query->Param("FormatAs"=>'JSONP');

   return($self->Display());
}

sub RSS
{
   my $self=shift;
   my $wf=$self->getFilteredWfModuleObject();
   my ($func,$p)=$self->extractFunctionPath();

   # sample set: /RSS/DTAG/TSS,DSS/1,2/*/en
   #                  |    |       |   | |
   #                  |    |       |   | +--- lang (default: en)
   #                  |    |       |   |
   #                  |    |       |   +----- item prio (default: *)
   #                  |    |       |
   #                  |    |       +--- event prio (default: *)
   #                  |    |
   #                  |    +--- mandator (default: *)
   #                  |
   #                  +--- customer (needed)
   #
   $p=~s/^\///;

   my ($customer,$mandator,$prio,$itemprio,$lang)=split(/\//,$p);

#   printf STDERR ("fifi0 ($p)\n");
#   printf STDERR ("fifi1 ($customer,$mandator,$prio,$lang)\n");

   if ($lang ne "en" && $lang ne "de"){
      $lang="en";
   }
   if ($itemprio eq ""){
      $itemprio="*";
   }
   $ENV{HTTP_ACCEPT_LANGUAGE}=$lang;

   my $sitename=$self->Config->Param("SITENAME");

   print($self->HttpHeader("text/xml",charset=>'UTF-8'));
   printf("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
   printf("<rss version=\"2.0\" ".
          "xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" ".
          "xmlns:im=\"http://www.infomantis.de/download/namespace/gorss.xml\" ".
          "xmlns:taxo=\"http://purl.org/rss/1.0/modules/taxonomy/\" ".
          "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" ".
          "xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n");
   printf("<channel>\n");
   if ($customer ne ""){
      printf("<title>%s: %s</title>",$self->T("IT Status"));
      printf("<link>%s</link>","https://darwin.telekom.de");
      printf("<language>%s</language>",$ENV{HTTP_ACCEPT_LANGUAGE});
      printf("<description>%s</description>",
             "Information channel about current active events\n".
             "parameters:\n".
             "customer: $customer ;\n".
             "mandator: $mandator ;\n".
             "event prio: $prio ;\n".
             "item prio: $itemprio ;");
      $wf->SetCurrentOrder("eventstartrev");


      my @customer=split(/[,;]/,$customer);
      my @mandator=split(/[,;]/,$mandator);
      my @prio=split(/[,;]/,$prio);
      my @itemprio=split(/[,;]/,$itemprio);
      if ($#itemprio==-1 || ($itemprio[0] eq "" && $#itemprio==0)){
         $itemprio[0]="*";
      }
      if ($#prio==-1 || ($prio[0] eq "" && $#prio==0)){
         $prio[0]="*";
      }
      if ($#mandator==-1 || ($mandator[0] eq "" && $#mandator==0)){
         $mandator[0]="*";
      }
      my $c=0;
      my $baseurl=$self->Config->Param("EventJobBaseUrl");
      foreach my $WfRec ($wf->getHashList(qw(ALL))){
         if ($self->FilterRSS($WfRec)){
            my $item="???";
            if ($WfRec->{eventmode} eq "EVk.appl"){
               $item=$WfRec->{affectedapplication};
               $item=join(", ",@$item) if (ref($item));
            }
            if ($WfRec->{eventmode} eq "EVk.infraloc"){
               $item=$WfRec->{affectedlocation};
               $item=join(", ",@$item) if (ref($item));
            }
            if ($WfRec->{eventmode} eq "EVk.bprocess"){
               $item=$WfRec->{affectedbusinessprocess};
               $item=join(", ",@$item) if (ref($item));
            }
            if ($WfRec->{eventmode} eq "EVk.appl"){
               if (!in_array(['*'],\@mandator)){  # user dont want to see all
                  next if (!in_array(\@mandator,$WfRec->{mandator}));
               }
            }
            if (!in_array(['*'],\@customer)){  # user dont want to see all
               my $found=0;
               chk: foreach my $chkcus (@customer){
                  my $qcust=quotemeta($chkcus);
                  my $re="^($qcust|$qcust\\..*)\$";
                  my $evcust=$WfRec->{affectedcustomer};
                  $evcust=[$evcust] if (!ref($evcust));
                  if (grep(/$re/,@$evcust)){
                     $found=1;
                     last chk;
                  }
               }
               next if (!$found);
            }
            if (!in_array(['*'],\@prio)){  # user dont want to see all
               if (!in_array([$WfRec->{eventstatclass}],\@prio)){
                  next;
               }
            }
            if (!in_array(['*'],\@itemprio)){  # user dont want to see all
               if (!in_array([$WfRec->{affecteditemprio}],\@itemprio)){
                  next;
               }
            }
            $item=~s/_/ /g;
            if ($WfRec->{eventmode} eq "EVk.infraloc"){
               $item=~s/\./; /g;
            }
            my $title=$item;
           # my $title=$item."\n (Prio".$WfRec->{eventstatclass}.")";
            my $desc=$WfRec->{eventshortsummary};
            if ($ENV{'SERVER_NAME'} ne ""){
               my ($proto)=$ENV{SCRIPT_URI}=~m/^(\S+):.*/;
               $baseurl=$proto."://".
                        $ENV{'SERVER_NAME'}.
                        "/".
                        $self->Config->getCurrentConfigName();
            }
            $desc=extractLanguageBlock($desc,$lang);
            my $link=$baseurl."/auth/base/workflow/ById/".$WfRec->{id};
            printf("<item>");
            $c++;
            printf("<title>%s</title>",XmlQuote($title));
            #printf("<link>%s</link>",XmlQuote($link));
            printf("<subject>%s</subject>",XmlQuote("This is the subject"));
            printf("<description>%s</description>",XmlQuote($desc));
            printf("<pubDate>%s</pubDate>",
              scalar($self->ExpandTimeExpression($WfRec->{eventstart},
                                                 "RFC822","UTC","CET")));
            printf("</item>");
         }
      }
      if ($c==0){
         my $okimg=$baseurl."/static/rssfeed/ok.gif?".substr(NowStamp(),0,8);
         printf("<item>");
         printf("<description>%s</description>",
                XmlQuote($self->T("There are no current messages")));
         printf("<im:enclosure url=\"$okimg\" ".
                "size=\"small\" alt_text=\"%s\" ".
                "size_x=\"190\" size_y=\"60\" />",
                XmlQuote($self->T("There are no current messages")));
      #   printf("<pubDate>%s</pubDate>",
      #     scalar($self->ExpandTimeExpression(NowStamp("en"),
      #                                        "RFC822","UTC","CET")));
         printf("</item>");
      }
   }
   else{
      printf("<title>W5Base: eventnotification channel: ".
             "invalid customer specified</title>");
   }
   printf("</channel>\n");
   printf("</rss>\n");

   delete($ENV{HTTP_ACCEPT_LANGUAGE});
   return();
}

sub FilterRSS
{
   my $self=shift;
   my $WfRec=shift;
   return(1);
}

sub getFilteredWfModuleObject
{
   my $self=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'raweventmode',
                label         =>'Raw eventmode as API key',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return($current->{headref}->{eventmode});
                }),
      new kernel::Field::Text(
                name          =>'eneventshortsummary',
                label         =>'Raw eventmode as API key',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(quoteHtml(extractLanguageBlock(
                          $current->{headref}->{eventshortsummary},"en")));
                }),
      new kernel::Field::Text(
                name          =>'deeventshortsummary',
                label         =>'Raw eventmode as API key',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(quoteHtml(extractLanguageBlock(
                          $current->{headref}->{eventshortsummary},"de")));
                })
   );

   my %flt;
   $flt{class}=[grep(/^.*::eventnotify$/,
                keys(%{$wf->{SubDataObj}}))];

   $flt{stateid}="<20";
   $flt{isdeleted}=\'0';

   $wf->SetNamedFilter("BASE",\%flt);
   $wf->SetFilter([{eventend=>"<now AND >now-60m"},
                   {eventend=>"[EMPTY]"}]);

   return($wf);
}

sub Display
{
   my $self=shift;
   my $wf=$self->getFilteredWfModuleObject();
   my %param=(ExternalFilter=>1,CurrentView=>[qw(id name eventstart eventend

                                                 wffields.eventshortsummary
                                                 mandator

                                                 raweventmode
                                                 deeventshortsummary
                                                 eneventshortsummary
                                                 wffields.eventmode
                                                 wffields.affecteditemprio
                                                 wffields.eventstatclass
                                                 wffields.affectedapplication
                                                 wffields.affectedlocation
                                                 wffields.affectedcustomer)]);
   return($wf->Result(%param));
}

sub getValidWebFunctions
{
   my ($self)=@_;


   return(qw(asXML RSS asJSONP));
}
