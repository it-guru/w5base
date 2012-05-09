package AL_TCom::event::mkP800swi;
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
use kernel::date;
use kernel::Event;
use kernel::Output;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;
   $self->RegisterEvent("mkP800swi","mkP800swi");
   return(1);
}

sub mkP800swi
{
   my $self=shift;
   my %param=@_;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $sw=getModuleObject($self->Config,"itil::swinstance");
   my $ss=getModuleObject($self->Config,"itil::servicesupport");
   my ($year,$month,$day, $hour,$min,$sec) = Today_and_Now("GMT");
   my $start=sprintf("%02d/%04d",$month,$year);
   $sw->ResetFilter();
   $sw->SetFilter({autogendiary=>1,cistatusid=>4});
   #$sw->SetFilter({fullname=>'adslnidb.Oracle.primary.1521.u8nc0'}); for debugging

   $sw->SetCurrentView("fullname","appl","applid","id","servicesupportid",
                       "swteam","databoss","databossid","swnature");

   my ($rec,$msg)=$sw->getFirst();
   if (defined($rec)){
      do{
         my $ssrec;
         printf("TEST1 %s\n", Dumper($rec));
         if ($rec->{servicesupportid} ne ""){
            $ss->ResetFilter();
            $ss->SetFilter({id=>\$rec->{servicesupportid},cistatusid=>'<=4'});
            ($ssrec)=$ss->getOnlyFirst(qw(flathourscost comments name fullname
                                          servicedescription));
         }
         if (defined($ssrec) && $rec->{appl} ne ""){
            my $eventstart=$self->getParent->ExpandTimeExpression(
                                                           "$year-$month-15-1M");
            my $eventend=$self->getParent->ExpandTimeExpression(
                                                           "$year-$month-15");
            my $entrytime=$self->getParent->ExpandTimeExpression("now");
            my $srcid=sprintf("%s-%s",$start,$rec->{id});
            my $srcsys=$self->Self();
            my $tcomworktime=int($ssrec->{flathourscost}*60);
            my $detaildescription=$ssrec->{servicedescription};
            $detaildescription="" if ($detaildescription eq "");
            my $tcomcodcomments="Software-Instance: $rec->{fullname}\n".
                                "Response-Team: $rec->{swteam}\n";
            if ($rec->{databoss} ne ""){
               $tcomcodcomments.="Instance databoss: $rec->{databoss}\n";
            }
            $tcomcodcomments.="Entry automaticly created - ".
                              "Technical contact: Vogler Hartmut\n";
            my $rec={name=>'T-Systems '.$rec->{swnature}.' support: '.
                           $rec->{appl},
                     srcid=>$srcid,
                     srcsys=>$srcsys,
                     srcload=>$entrytime,
                     affectedapplication=>$rec->{appl},
                     eventstart=>$eventstart,
                     eventend=>$eventend,
                     tcomcodrelevant=>'yes',
                     openusername=>$rec->{databoass},
                     openuser=>$rec->{databoassid},
                     tcomworktime=>$tcomworktime,
                     tcomcodcause=>'sw.addeff.swbase',
                     detaildescription=>$detaildescription,
                     tcomcodcomments=>$tcomcodcomments,
                    };

            $wf->ResetFilter();
            $wf->SetCurrentView(qw(ALL));
            $wf->SetFilter({srcsys=>\$rec->{srcsys},
                            srcid=>\$rec->{srcid}});
            my $found=0;
            my $id=0;
            $wf->ForeachFilteredRecord(sub{
                  my $oldrec=$_;
                  $found++;
                  if ($oldrec->{stateid}<20){
                     $wf->ValidatedUpdateRecord($oldrec,$rec,
                                                  {id=>$oldrec->{id}});
                     $id=$oldrec->{id};
                  }
            });
            if (!$found){
               $rec->{class}="AL_TCom::workflow::diary";
               $rec->{step}="AL_TCom::workflow::diary::dataload";
               $rec->{stateid}=4;
               $id=$wf->ValidatedInsertRecord($rec);
            }
            if (defined($id)){
               $wf->ResetFilter();
               $wf->SetFilter({id=>\$id});
               my ($WfRec)=$wf->getOnlyFirst(qw(ALL));
               if (defined($WfRec) && $WfRec->{stateid}!=17){
                  $wf->ValidatedUpdateRecord($WfRec,{
                                         stateid=>17,
                                         step=>'AL_TCom::workflow::diary::wfclose',
                                         },
                                         {id=>\$id});
               }
            }
         }
         
         ($rec,$msg)=$sw->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0});
}


1;
