package base::workflowrepjob;
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
use kernel::DataObj::DB;
use kernel::Field;
use DateTime::TimeZone;
use Text::ParseWords;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'Workflow Report JobID',
                sqlorder      =>'none',
                dataobjattr   =>'wfrepjob.id'),

      new kernel::Field::Text(
                name          =>'targetfile',
                label         =>'WebFS target file/URL/Mail',
                dataobjattr   =>'wfrepjob.targetfile'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Report name',
                dataobjattr   =>'wfrepjob.reportname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'wfrepjob.cistatus'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'wfrepjob.timezone'),

      new kernel::Field::Number(
                name          =>'mday',
                label         =>'due day',
                default       =>'1',
                dataobjattr   =>'wfrepjob.mday'),

      new kernel::Field::Text(
                name          =>'runmday',
                label         =>'run on day',
                dataobjattr   =>'wfrepjob.runmday'),

      new kernel::Field::Text(
                name          =>'fltclass',
                label         =>'Filter: Class',
                dataobjattr   =>'wfrepjob.flt_class'),

      new kernel::Field::Text(
                name          =>'fltstep',
                label         =>'Filter: Step',
                dataobjattr   =>'wfrepjob.flt_step'),

      new kernel::Field::Text(
                name          =>'fltname',
                label         =>'Filter: Name',
                dataobjattr   =>'wfrepjob.flt_name'),

      new kernel::Field::Text(
                name          =>'fltdesc',
                label         =>'Filter: Description',
                dataobjattr   =>'wfrepjob.flt_desc'),

      new kernel::Field::Text(
                name          =>'flt1name',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter1: Fieldname',
                dataobjattr   =>'wfrepjob.flt1_name'),

      new kernel::Field::Text(
                name          =>'flt1value',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter1: Fieldvalue',
                dataobjattr   =>'wfrepjob.flt1_value'),

      new kernel::Field::Text(
                name          =>'flt2name',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter2: Fieldname',
                dataobjattr   =>'wfrepjob.flt2_name'),

      new kernel::Field::Text(
                name          =>'flt2value',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter2: Fieldvalue',
                dataobjattr   =>'wfrepjob.flt2_value'),

      new kernel::Field::Text(
                name          =>'flt3name',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter3: Fieldname',
                dataobjattr   =>'wfrepjob.flt3_name'),

      new kernel::Field::Text(
                name          =>'flt3value',
                htmlhalfwidth =>1,
                group         =>'wffieldsfilter',
                label         =>'Filter3: Fieldvalue',
                dataobjattr   =>'wfrepjob.flt3_value'),

      new kernel::Field::Textarea(
                name          =>'repfields',
                label         =>'Report Fieldnames',
                dataobjattr   =>'wfrepjob.repfields'),

      new kernel::Field::Textarea(
                name          =>'funcrawcode',
                label         =>'function code',
                dataobjattr   =>'wfrepjob.funccode'),

      new kernel::Field::Link(
                name          =>'funccode',
                depend        =>['funcrawcode'],
                label         =>'function code',
                onRawValue    =>\&getFuncCode),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfrepjob.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'wfrepjob.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'wfrepjob.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'wfrepjob.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wfrepjob.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'wfrepjob.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'wfrepjob.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'wfrepjob.realeditor'),


                                  
   );
   $self->setDefaultView(qw(targetfile name cdate));
   $self->setWorktable("wfrepjob");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","wffieldsfilter","source");
}


sub getFuncCode
{
   my $self=shift;
   my $current=shift;
   my $code=$current->{funcrawcode};
   my @fl;

   foreach my $f (split(/\s*;\s*/,$code)){
      if (my ($fname,$fdata)=$f=~m/^(\S+)\((.*)\)$/){
         my %r=(rawcode=>$f);
         if ($fdata ne ""){
            my @words=parse_line(',',0,$fdata);
            if ($#words!=-1){
               $r{fparam}=\@words;
            }
         }
         if ($fname eq "EntryCount" &&    # check function name
             ($#{$r{fparam}}==1 ||        # check param count
              $#{$r{fparam}}==2)    &&
             $r{fparam}->[0] ne ""  &&     # check param val
             $r{fparam}->[1] ne ""){
            $r{init}=\&init_EntryCount;
            $r{store}=\&store_EntryCount;
            $r{finish}=\&finish_EntryCount;
            push(@fl,\%r);
         }
      }
   }
   return(\@fl);
}

sub init_EntryCount
{
   my ($self,$DataObj,$fentry,$repjob,$slot,$param,$period,$WfRec,$sheet)=@_;
}

sub store_EntryCount
{
   my ($self,$DataObj,$fentry,$repjob,$slot,$param,$period,$WfRec,$sheet)=@_;

   my $countkey=$fentry->{fparam}->[0];
   my $countname=$fentry->{fparam}->[1];
   my $countinfo=$fentry->{fparam}->[2];
   if (exists($WfRec->{$countkey})){
      my $d=$WfRec->{$countkey};
      $d=[$d] if (ref($d) ne "ARRAY");
      if (defined($d)){
         foreach my $countval (@{$d}){
            if (!defined($slot->{'EntryCount'.$countkey}->{$countval})){
               $slot->{'EntryCount'.$countkey}->{$countval}=[];
            }
            my $countdata=1;
            if ($countinfo ne ""){
               $countdata=$WfRec->{$countinfo}; 
            }
            push(@{$slot->{'EntryCount.'.$countkey}->{$countval}},$countdata); 
         }
      }
   }
}

sub finish_EntryCount
{
   my ($self,$DataObj,$fentry,$repjob,$slot,$param,$period,$WfRec,$sheet)=@_;

   my $countkey=$fentry->{fparam}->[0];
   my $countname=$fentry->{fparam}->[1];
   my $countinfo=$fentry->{fparam}->[2];
   my $sheet=$slot->{'workbook'}->{o}->addworksheet($countname);
   my @linelabels=sort(keys(%{$slot->{'EntryCount.'.$countkey}}));
   for(my $row=0;$row<=$#linelabels;$row++){
      $sheet->write_string($row,0,$linelabels[$row],
                    $self->Format($slot,'default'));
      $sheet->write_number($row,1,
         $#{$slot->{'EntryCount.'.$countkey}->{$linelabels[$row]}}+1,
         $self->Format($slot,'longint'));
      if ($countinfo ne ""){
         $sheet->write_string($row,2,
            join(", ",@{$slot->{'EntryCount.'.$countkey}->{$linelabels[$row]}}),
            $self->Format($slot,'default'));
      }
   }
   $sheet->set_column(0,0,18);
   $sheet->set_column(1,1,10);
   if ($countinfo ne ""){
      $sheet->set_column(2,2,200);
   }
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" || $name=~m/\s/){
      $self->LastMsg(ERROR,"invalid report name '\%s' specified",
                     $name);
      return(undef);
   }
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return(undef);
}





1;
