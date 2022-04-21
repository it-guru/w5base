package base::uservote;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::DB;
use kernel::Field;
use kernel::App::Web::VoteLink;
@ISA=qw(kernel::App::Web::Listedit use kernel::App::Web::VoteLink
        kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'uservote.id'),
                                                  
      new kernel::Field::Text(
                name          =>'parentobj',
                sqlorder      =>'NONE',
                label         =>'Parent-Object',
                dataobjattr   =>'uservote.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                label         =>'RefID',
                dataobjattr   =>'uservote.refid'),

      new kernel::Field::Text(
                name          =>'entrymonth',
                label         =>'EntryMonth',
                dataobjattr   =>'uservote.entrymonth'),

      new kernel::Field::Number(
                name          =>'voteval',
                label         =>'numeric value of voge',
                dataobjattr   =>'uservote.voteval'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'uservote.createdate'),
                                                  
      new kernel::Field::Creator(
                name          =>'creator',
                searchable    =>0,
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'uservote.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'CreatorID',
                dataobjattr   =>'uservote.createuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'uservote.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'uservote.realeditor'),

   );
   $self->setDefaultView(qw(linenumber creator parentobj refid 
                            entrymonth voteval cdate));
   $self->setWorktable("uservote");
   return($self);
}


sub isCopyValid
{
   my $self=shift;
   my $rec=shift; 
   return(0);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

 #  if (!$self->IsMemberOf([qw(admin)],"RMember")){
   my $userid=$self->getCurrentUserId();
   foreach my $flt (@flt){
      $flt->{creatorid}=\$userid; 
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

  # my $name=trim(effVal($oldrec,$newrec,"name"));
  # if ($name=~m/^\s*$/i){
  #    $self->LastMsg(ERROR,"invalid name '%s' specified",$name); 
  #    return(undef);
  # }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return("ALL") if ($rec->{creatorid}==$userid || $self->IsMemberOf("admin"));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("ALL") if (!defined($rec));
   return("default","rel") if ($rec->{creatorid}==$userid || 
                         $self->IsMemberOf("admin"));
   return(undef);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(vote Display),$self->SUPER::getValidWebFunctions());
}


sub vote
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   print $self->HttpHeader("text/javascript",charset=>'UTF-8');

   my @p=split(/\//,$p);
   
   my $parentobj=$p[1]."::".$p[2];
   my $pobj=getModuleObject($self->Config,$parentobj);
   if (!defined($pobj)){
      die("uservote::vote pobj $parentobj can not be created");
   }
   my $refid=$p[3];
   $refid=~s/[^0-9a-z_+-]//gi;
   if ($refid eq ""){
      die("uservote::vote pobj $parentobj refid missing");
   }

   my $userid=$self->getCurrentUserId();
   my $logstamp=$self->getLogStamp();
   my $o=getModuleObject($self->Config,$parentobj);
   my $html="<div>Unknown QState</div>";
   my $uservotelevel="?";
   if (defined($o)){
      my $idfield=$o->IdField();
      if (defined($idfield)){
         my $voteval=0;
         $voteval=-100 if ($p[4] eq "contra");
         $voteval=100 if ($p[4] eq "pro");
        
        
         if ($self->IsMemberOf("admin")){
            $voteval=$voteval*3;
         }
         else{
            my $ulog=getModuleObject($self->Config,"base::userlogon");

         }
        
         if ($voteval!=0){
            #printf STDERR ("fifi userid=$userid\n");
            #printf STDERR ("fifi logstamp=$logstamp\n");
            #printf STDERR ("fifi func=$func\n");
            #printf STDERR ("fifi p=$p\n");
            #printf STDERR ("fifi parentobj=$parentobj\n");
            #printf STDERR ("fifi refid=$refid\n");
            #printf STDERR ("fifi voteval=$voteval\n");

            if ($pobj->can("HandleUserVote")){
               my $idfield=$pobj->IdField();
               if (defined($idfield)){
                  $pobj->SetFilter({$idfield->Name=>\$refid});
                  my ($voterec,$msg)=$pobj->getOnlyFirst(qw(ALL));
                  if (!defined($voterec)){
                     die("uservote::vote - prec missing $parentobj '$refid'");
                  }
                  $pobj->HandleUserVote($voterec,$voteval);
               }
            }


            if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
               $self->ValidatedInsertRecord({
                  parentobj=>$parentobj,
                  refid=>$refid,
                  entrymonth=>$logstamp,
                  voteval=>$voteval,
                  cdate=>NowStamp("en"),
                  creatorid=>$userid
               });
            }
         }
         my $idname=$idfield->Name();
         $o->SetFilter({$idname=>\$refid});
         my ($refrec,$msg)=$o->getOnlyFirst(qw(uservotelevel));
         if (defined($refrec)){
            my $state="green";
            my $title="QIndex:".$refrec->{uservotelevel}." = ";
            $title.=$self->T("Document quality");
            $title.=": ";
            if ($refrec->{uservotelevel}>1000){
               $state="ok";
               $title.=$self->T("perfect");
            }
            elsif ($refrec->{uservotelevel}<-1000){
               $state="bad";
               $title.=$self->T("untrustworthy");
            }
            elsif ($refrec->{uservotelevel}<-600){
               $state="red";
               $title.=$self->T("bad");
            }
            elsif ($refrec->{uservotelevel}<-100){
               $state="yellow";
               $title.=$self->T("dubious");
            }
            else{
               $state="green";
               $title.=$self->T("OK");
            }

            $html="<img style='margin-bottom:2px' title='${title}' ".
                  "src='%ROOT%/base/load/doc-${state}.gif'><br>";
            
            $html.=$self->extendCurrentRating($refrec->{uservotelevel});
            $uservotelevel=$refrec->{uservotelevel};
         }
      }
   }
   my %e=(
      refid        =>  $refid,
      uservotelevel=>  $uservotelevel,
      html         =>  $html ,
   );
   my $l=[\%e];

   eval("use JSON;");
   if ($@ eq ""){
      my $json;
      eval('$json=to_json($l, {ascii => 1});');
      print $json;
   }
   else{
      printf STDERR ("ERROR: ganz schlecht: %s\n",$@);
   }
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","rel","soure");
}


1;
