package kernel::Wf;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA @EXPORT);
use strict;
use kernel;
use kernel::App;
use Exporter;
@EXPORT=qw(&addWorkflow2Mail);
@ISA=qw(Exporter kernel::App);


#  addWorkflow2Mail($self->getParent,
#               $wf,$user,$wfheadid,"dailyreport","timezone",
#               \@$emailhead,\@$emailsubheader,
#               \@$emailprefix,\@$emailtstamp,\@$emailtext,\@$emailpostfix,
#               \@$emailbottom);

sub addWorkflow2Mail
{
   my $self=shift;
   my $wf=shift;           # access object to base::workflow
   my $user=shift;         # access object to base::user
   my $wfheadid=shift;
   my $param=shift;
   my $mode=$param->{mode};
   my $tz=$param->{tz};
   my ($emailhead,$emailsubheader,$emailprefix,$emailtstamp,$emailtext,
       $emailpostfix,$emailbottom)=@_;

   $wf->ResetFilter();
   $wf->SetFilter({id=>\$wfheadid});
   my ($wfrec,$msg)=$wf->getOnlyFirst(qw(name openusername 
                                         shortactionlog initialsite
                                         mdate));
   #msg(DEBUG,"wfrec=%s",Dumper($wfrec));

   my $nr=0;
   my $outoffscope=0;
   if (ref($wfrec->{shortactionlog}) eq "ARRAY"){
      foreach my $wfact (@{$wfrec->{shortactionlog}}){
         my $username="";
         if ($wfact->{owner} ne ""){
            $user->ResetFilter();
            $user->SetFilter({userid=>\$wfact->{owner}});
            my ($actu,$msg)=$user->getOnlyFirst(qw(fullname email));
            if (defined($actu)){
               $username=$actu->{fullname}; 
               if ($actu->{email} ne ""){
                  $username="<a class=emaillink ".
                            "href=\"mailto:".$actu->{email}."\">".
                            $username."</a>";
               }
            }
         }
         my $date=new kernel::Field::Date();
         $date->setParent($self);
         my ($str,$ut,$dayoffset)=$date->getFrontendTimeString( 
                                  "HtmlMail",$wfact->{cdate},$tz);

         my $isinscope=1;          
         if (my $duration=CalcDateDuration($wfact->{cdate},
                                           $wfrec->{mdate},"GMT")){
            if ($duration->{totalminutes}>($param->{hours}+2)*60){  
               $outoffscope++;
               $isinscope=0;
            }
         }

 
 

         if ($isinscope==1 &&!($wfact->{comments}=~m/^\s*$/)){
            my $data=$wfact->{comments};
            $data=~s/&/&amp;/g;
            $data=~s/</&lt;/g;
            $data=~s/>/&gt;/g;
            if ($nr==0){
               push(@$emailsubheader,FormatSubHeader($self,$wfrec));
               push(@$emailhead,$wfrec->{name});
               if ($outoffscope>0){
                  push(@$emailhead,undef);
                  push(@$emailsubheader,undef);
                  push(@$emailtext,"...");
                  push(@$emailpostfix,undef);
                  push(@$emailtstamp,undef);
               }
               push(@$emailtext,$data);
               push(@$emailpostfix,$username);
               push(@$emailtstamp,$str);
            }
            else{ 
               push(@$emailsubheader,undef);
               push(@$emailhead,undef);
               push(@$emailtext,$data);
               push(@$emailpostfix,$username);
               push(@$emailtstamp,$str);
            }
            $nr++;
         }
      }
   }
   if ($nr==0){
      push(@$emailtstamp,undef);
      if ($outoffscope>0){
         push(@$emailtext,"...");
      }
      else{
         push(@$emailtext,undef);
      }
      push(@$emailpostfix,undef);
      push(@$emailsubheader,FormatSubHeader($self,$wfrec));
      push(@$emailhead,$wfrec->{name});
   }


}

sub FormatSubHeader
{
   my $self=shift;
   my $wfrec=shift;
   my $label="";

   $label.="<b>".$wfrec->{name}."</b><br>"; 
   $label.=$self->T($wfrec->{class},$wfrec->{class}).":"; 
   if (defined($wfrec->{affectedapplication})){
      my @l=($wfrec->{affectedapplication});
      if (ref($wfrec->{affectedapplication}) eq "ARRAY"){
         @l=@{$wfrec->{affectedapplication}};
      }
      $label.=" ".join(", ",@l);
   }
   if (defined($wfrec->{affectedsystem})){
      my @l=($wfrec->{affectedsystem});
      if (ref($wfrec->{affectedsystem}) eq "ARRAY"){
         @l=@{$wfrec->{affectedsystem}};
      }
      $label.=" <u>".join(", ",@l)."</u>";
   }
   if ($wfrec->{initialsite} ne "" && $wfrec->{initialsite} ne "JobServer"){
      my $lang="";
      if ($wfrec->{initiallang} ne ""){
         $lang="/$wfrec->{initiallang}";
      }
      my $imgtitle="current state of workflow";
      my $linktitle="direct link to orkflow";
      $label="<img title=\"$imgtitle\" class=status border=0 ".
             "src=\"$wfrec->{initialsite}".
             "/public/base/workflow/ShowState/$wfrec->{id}$lang\">".
             $label;
      $label="<a title=\"$linktitle\" ".
             " href=\"$wfrec->{initialsite}/auth/base/workflow/ById/".
             "$wfrec->{id}\" class=directlink>".$label."</a>";
   }
       
   return($label);
}





1;

