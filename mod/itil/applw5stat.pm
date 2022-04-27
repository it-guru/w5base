package itil::applw5stat;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler
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
   my $self=bless($type->SUPER::new(%param),$type);

   my @view=$self->getFieldList();
   @view=grep(!/^(name|cistatus|businessteam)$/,@view); # remove qc data
   foreach my $fieldname (@view){
       my $fobj=$self->getField($fieldname);
       if ($fobj){
          $fobj->{uivisible}=0;
       }
   }
   $self->setDefaultView(qw(name cistatus businessteam));
   delete($self->{workflowlink});
   delete($self->{history});
   return($self);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;

   my %f=$self->SUPER::getDetailFunctions($rec);

   foreach my $k (keys(%f)){
      next if ($f{$k}=~m/DetailClose/);
      next if ($f{$k}=~m/Print/);
      delete($f{$k});
   }
   return(%f);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my @addflt;
   $self->addApplicationSecureFilter([''],\@addflt);
   push(@flt,\@addflt);
   my @addflt=({cistatusid=>"!7"});
   push(@flt,\@addflt);
   return($self->SetFilter(@flt));
}


sub addApplicationSecureFilter
{
   my $self=shift;
   my $namespace=shift;
   my $addflt=shift;


   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                       [orgRoles(),qw(RCFManager RCFManager2 RTechReportRcv
                                      RAuditor RMonitor)],"down");
   my @grpids=keys(%grps);
   my $userid=$self->getCurrentUserId();

   foreach my $ns (@$namespace){ 
      if ($self->getField($ns.'sectargetid')){
         push(@$addflt,{$ns.'sectargetid'=>\$userid,
            $ns.'sectarget'=>\'base::user',
            $ns.'secroles'=>"*roles=?applmgr2?=roles*"}
         );
      }
      if ($ENV{REMOTE_USER} ne "anonymous"){
         foreach my $fld (qw(databossid tsmid tsm2id 
                             opmid opm2id )){
            if ($self->getField($ns.$fld)){
               push(@$addflt,{$ns.$fld=>\$userid});
            }
         }
         foreach my $fld (qw(businessteamid)){
            if ($self->getField($ns.$fld)){
               push(@$addflt,{$ns.$fld=>\@grpids});
            }
         }
      }
   }
}



sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   my %p=$self->SUPER::getHtmlDetailPages($p,$rec);

   foreach my $k (keys(%p)){
      next if ($k=~m/StandardDetail/);
      delete($p{$k});
   }
   return(%p);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec,@_);

   my @l=qw(default technical header);


   return(@l);
}


sub HtmlDetail
{
   my $self=shift;
   my %param=@_;

   $self->ProcessDataModificationOP();
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   if ($self->SecureSetFilter(\%flt)){
      my ($rec,$msg)=$self->getOnlyFirst(qw(name id businessteam cistatusid)); 


      my $w5stat=getModuleObject($self->Config,"base::w5stat");

      $w5stat->SetFilter({
         fullname=>$rec->{name},
         sgroup=>"Application",
         dstrange=>"!*KW*",
         statstream=>\'default'
      });
      $w5stat->Limit(10);
      my @l=$w5stat->getHashList(qw(-dstrange sgroup id));

      if ($#l!=-1){
         my $requestid=$l[0]->{id};
         $w5stat->ShowEntry($requestid,"ALL");
      }
      else{
         print $self->HttpHeader("text/html");
         print $self->HtmlHeader(style=>['default.css',
                                         'kernel.App.Web.css'],
                                 title=>"xx",
                                 submodal=>1,
                                 js=>['toolbox.js','subModal.js',
                                      'kernel.App.Web.js'],
                                 body=>1,form=>1);
         printf ("No Report found");
         print $self->HtmlBottom(body=>1,form=>1);
      }
   }
   else{
      print($self->noAccess());
      return(undef);
   }
}






1;

