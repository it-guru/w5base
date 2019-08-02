package itil::riskmgmtbase;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA $VERSION $DESCRIPTION);
use kernel;
use kernel::App::Web;
use kernel::App::Web::InterviewLink;
use kernel::DataObj::DB;
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);


$VERSION="1.0";
$DESCRIPTION=<<EOF;
Object to handle base data for processmanagement risk
EOF




sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   #######################################################################
   # modify existing fields from parent
   my @fullinherit=(qw(name mandator cistatus 
                       criticality customerprio 
                       applmgr databoss
                       opmode));

   my @fielddrop=(qw(mdate creator cdate owner editor realeditor));

   $self->DelFields(@fielddrop);

   foreach my $fldname ($self->getFieldList("collectively")){
      my $fldobj=$self->getField($fldname);
      if (defined($fldobj)){
         $fldobj->{readonly}=1;
         next if (in_array(\@fullinherit,$fldobj->Name()));
         $fldobj->{searchable}=0;
         $fldobj->{htmldetail}=0;
      }
   }

   delete($self->{workflowlink});
   #######################################################################

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'OverflowID',
                dataobjattr   =>"riskmgmtbase.id"),

      new kernel::Field::Select(
                name          =>'itrmcriticality',
                group         =>'riskdata',
                label         =>'ITRM criticality',
                allowempty    =>1,
                htmleditwidth =>'30px',
                useNullEmpty  =>1,
                value         =>[qw(0 1 2 3 4 5)],
                dataobjattr   =>'riskmgmtbase.itrmcriticality'),

      new kernel::Field::Select(
                name          =>'solutionopt',
                group         =>'riskdata',
                label         =>'Solution OPT',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::riskmgmtbase::solutionopt',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::riskmgmtbase::solutionopt',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawsolutionopt'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawsolutionopt',
                group         =>'riskdata',
                label         =>'raw Interface Monitoring',
                dataobjattr   =>'riskmgmtbase.solutionopt'),


      new kernel::Field::Number(
                name          =>'ibipoints',
                group         =>'riskdata',
                label         =>'IBI Points',
                allowempty    =>1,
                dataobjattr   =>'riskmgmtbase.ibipoints'),

      new kernel::Field::Currency(
                name          =>'ibiprice',
                group         =>'riskdata',
                label         =>'IBI Euro',
                allowempty    =>1,
                dataobjattr   =>'riskmgmtbase.ibiprice'),
   );


   $self->setWorktable("riskmgmtbase");  
   $self->setDefaultView(qw(name applid opmode criticality
                            solutionopt itrmcriticality ibipoints ibiprice));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;

   my $from=$self->SUPER::getSqlFrom($mode,@_);

   $from.=" left outer join riskmgmtbase ".
          "on appl.id=riskmgmtbase.id";

   return($from);
}



sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   $newrec->{ofid}=$oldrec->{id};  # als Referenz in der Overflow die
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   return(1);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   return(1);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority();

   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "default");
   }
   splice(@l,$inserti,$#l-$inserti,("riskdata",@l[$inserti..($#l+-1)]));

   return(@l);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,"default")){
      push(@l,"riskdata");
   }

   return(@l);
}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub prepUploadFilterRecord
{
   my $self=shift;
   my $newrec=shift;

   if ((!defined($newrec->{id}) || $newrec->{id} eq "")
       && $newrec->{name} ne ""){
      my $o=$self->Clone();
      $o->SetFilter({name=>\$newrec->{name}});
      my @l=$o->getHashList(qw(id));
      if ($#l==0){
         my $crec=$l[0];
         $newrec->{id}=$crec->{id};
         delete($newrec->{name});
      }
      elsif($#l>0){
         $self->LastMsg(ERROR,"not unique name");
      }
   }
   $self->SUPER::prepUploadFilterRecord($newrec);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @l;
   my @databossedit=(qw(riskdata));
   if ($self->IsMemberOf("admin")){
      push(@l,@databossedit);
   }

   if ($rec->{mandatorid}!=0 &&
      $self->IsMemberOf($rec->{mandatorid},[qw(RSKManager 
                                               RSKPManager 
                                               RSKPManager2)],"down")){
      push(@l,@databossedit);
   }


   return(@l);
}


sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   my @pages=$self->SUPER::getHtmlDetailPages($p,$rec);
   my %pages=@pages;

   if (exists($pages{StandardDetail})){
      return('StandardDetail'=>$self->T("Standard-Detail"));
   }
   return(@pages);
}





1;
