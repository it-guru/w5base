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
   my $sitename=$self->Config->Param("SITENAME");
   print($self->HttpHeader("text/xml",charset=>'UTF-8'));
   printf("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
   printf("<rss version=\"2.0\">\n");
   printf("<channel>\n");
   printf("<title>%s: %s</title>",$sitename,"eventnotification");
   printf("<link>%s</link>","https://darwin.telekom.de");
   printf("<description>%s</description>",
          "Information channel about current active events\n".
          "path=$p");
   $wf->SetCurrentOrder("eventstartrev");
   foreach my $WfRec ($wf->getHashList(qw(ALL))){
      my $title=$WfRec->{name};
      my $desc=$WfRec->{eventdesciption};
      my $link="https://darwin.telekom.de/darwin/auth/base/workflow/ById/".
               $WfRec->{id};
      printf("<item>");
      printf("<title>%s</title>",XmlQuote($title));
      printf("<link>%s</link>",XmlQuote($link));
      printf("<desciption>%s</desciption>",XmlQuote($desc));
      printf("</item>");
   }


   printf("</channel>\n");
   printf("</rss>\n");
   return();
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

                                                 wffields.eventdesciption
                                                 mandator

                                                 raweventmode
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
