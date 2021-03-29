package PAT::event::PATDataLoad;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);




sub PATDataLoad
{
   my $self=shift;

   $self->LoadsrcBusinessSeg();
   $self->LoadsrcICTname();
   $self->LoadsrcSubProcess();


   return({exitcode=>1,exitmsg=>'OK'});
}

sub LoadsrcBusinessSeg
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"PAT::srcBusinessSeg");
   my $wobj=getModuleObject($self->Config,"PAT::businessseg");

   $o->SetFilter({});


   foreach my $rec ($o->getHashList(qw(ALL))){
      #next if ($rec->{title}=~m/^keine Steuerung/);
      my $srcsys=$o->Self();
      my $bsegopt=$rec->{bsegopt};
      $bsegopt="" if (!defined($bsegopt));
      my $orgshort=$rec->{orgshort};
      $orgshort="" if (!defined($orgshort));

      my $title=$rec->{title};
      if (length($title)>20){
         $title=substr($title,0,20)."...";
      }
      my @id=$wobj->ValidatedInsertOrUpdateRecord({
            name=>$title,
            title=>$rec->{bseg},
            comments=>$rec->{comments},
            bsegopt=>$bsegopt,
            sopt=>$rec->{sopt},
            orgshort=>$orgshort,
            orgname=>$rec->{organisation},
            mdate=>$rec->{mdate},
            cdate=>$rec->{cdate},
            srcload=>NowStamp("en"),
            srcsys=>$srcsys,
            srcid=>$rec->{id},
         },
         {
            srcsys=>\$srcsys,
            srcid=>\$rec->{id}
         }
      );
   }

   $wobj->ResetFilter();
   $wobj->SetCurrentView(qw(srcid name title id));
   $self->{bseg}=$wobj->getHashIndexed(qw(id srcid));
}

sub LoadsrcSubProcess
{
   my $self=shift;
   #print Dumper($self->{bseg});

   {
      my $to=getModuleObject($self->Config,"PAT::srcTimes");
      $to->SetFilter({});
      $to->SetCurrentView(qw(title id));
      $self->{times}=$to->getHashIndexed(qw(id));
   }
   {
      my $to=getModuleObject($self->Config,"PAT::srcThreshold");
      $to->SetFilter({});
      $to->SetCurrentView(qw(title id));
      $self->{threshold}=$to->getHashIndexed(qw(id));
   }

   my $o=getModuleObject($self->Config,"PAT::srcSubProcess");
   my $wobj=getModuleObject($self->Config,"PAT::subprocess");
   my $wlobj=getModuleObject($self->Config,"PAT::lnksubprocessictname");

   $o->SetFilter({});


   foreach my $rec ($o->getHashList(qw(ALL))){
      #next if ($rec->{title}=~m/^keine Steuerung/);
      my $srcsys=$o->Self();

      my $bsid=$self->{bseg}->{srcid}->{$rec->{srcBusinessSegId}}->{id};

      my $onlinetime=$self->{times}->{id}->{$rec->{onlinetimeid}}->{title};
      my $usetime=$self->{times}->{id}->{$rec->{usetimeid}}->{title};
      my $coretime=$self->{times}->{id}->{$rec->{coretimeid}}->{title};

      my $ibicoretime=
           $self->{times}->{id}->{$rec->{ibicoretimeid}}->{title};
      my $ibinonprodtime=
           $self->{times}->{id}->{$rec->{ibinonprodtimeid}}->{title};
      my $ibithcoretime=
           $self->{threshold}->{id}->{$rec->{ibithcoretimeid}}->{title};
      my @ibithcoretime=split(/;/,$ibithcoretime);
      my $ibithnonprodtime=
           $self->{threshold}->{id}->{$rec->{ibithnonprodtimeid}}->{title};
      my @ibithnonprodtime=split(/;/,$ibithnonprodtime);

      my @id=$wobj->ValidatedInsertOrUpdateRecord({
            name=>$rec->{title},
            title=>$rec->{subarea},
            businesssegid=>$bsid,
            mdate=>$rec->{mdate},
            comments=>$rec->{comments},
            description=>$rec->{description},
            cdate=>$rec->{cdate},
            onlinetime=>$onlinetime,
            usetime=>$usetime,
            coretime=>$coretime,
            ibicoretime=>$ibicoretime,
            ibithcoretimemonfri=>$ibithcoretime[0],
            ibithcoretimesat=>$ibithcoretime[1],
            ibithcoretimesun=>$ibithcoretime[2],
            ibinonprodtime=>$ibinonprodtime,
            ibithnonprodtimemonfri=>$ibithnonprodtime[0],
            ibithnonprodtimesat=>$ibithnonprodtime[1],
            ibithnonprodtimesun=>$ibithnonprodtime[2],
            srcload=>NowStamp("en"),
            srcsys=>$srcsys,
            srcid=>$rec->{id},
         },
         {
            srcsys=>\$srcsys,
            srcid=>\$rec->{id}
         }
      );
      if ($#id==0){
         my %reclist;
         foreach my $rellevel (qw(4 3 2 1)){
            foreach my $id (@{$rec->{"r$rellevel"}}){
               next if ($id eq "");
               my $ictnameid=$self->{ictname}->{srcid}->{$id}->{id};
               next if ($ictnameid eq "");
               $reclist{$id}={
                  ictnameid=>$ictnameid,
                  subprocessid=>$id[0],
                  rawrelevance=>$rellevel,
                  srcid=>$id[0].'-'.$id,
                  srcsys=>$srcsys
               };
            }
         }
         foreach my $relrec (values(%reclist)){
            my @lid=$wlobj->ValidatedInsertOrUpdateRecord($relrec,
               { srcsys=>\$relrec->{srcsys}, srcid=>\$relrec->{srcid} }
            );
         }
      }
   }
}


sub LoadsrcICTname
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"PAT::srcICTname");
   my $wobj=getModuleObject($self->Config,"PAT::ictname");

   $o->SetFilter({});

   my %ictname;

   foreach my $rec ($o->getHashList(qw(ALL))){
      #print Dumper($rec);
      next if (exists($ictname{$rec->{title}}));
      my $srcsys=$o->Self();

      my $title=$rec->{title};
      if (length($title)>60){
         $title=substr($title,0,60)."...";
      }
      my @id=$wobj->ValidatedInsertOrUpdateRecord({
            name=>$title,
            comments=>$rec->{comments},
            ictoid=>$rec->{ictoid},
            mdate=>$rec->{mdate},
            cdate=>$rec->{cdate},
            srcload=>NowStamp("en"),
            srcsys=>$srcsys,
            srcid=>$rec->{id},
         },
         {
            srcsys=>\$srcsys,
            srcid=>\$rec->{id}
         }
      );
      if ($#id==0){
         $ictname{$rec->{title}}++;
      }
   }
   $wobj->ResetFilter();
   $wobj->SetCurrentView(qw(srcid name title id));
   $self->{ictname}=$wobj->getHashIndexed(qw(id srcid));
}



1;
