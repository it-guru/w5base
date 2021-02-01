package itil::licproduct;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
#
#  This program is free licproduct; you can redistribute it and/or modify
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'licproduct.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                uploadable    =>0,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'Fullname',
                dataobjattr   =>"concat(producer.name,".
                                "if(producer.name<>'','-',''),".
                                "licproduct.name)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'licproduct.name'),

      new kernel::Field::Text(
                name          =>'pgroup',
                label         =>'Product family',
                dataobjattr   =>'licproduct.pgroup'),

      new kernel::Field::Text(
                name          =>'metric',
                label         =>'Lizenzmetrik',
                dataobjattr   =>'licproduct.lmetric'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'licproduct.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'producer',
                label         =>'Producer',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::producer',
                vjoinon       =>['producerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'producerid',
                dataobjattr   =>'licproduct.producer'),

      new kernel::Field::Text(
                name          =>'itemno',
                label         =>'Item/Order-No.',
                dataobjattr   =>'licproduct.itemno'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'licproduct.comments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                #uivisible     =>sub{
                #   my $self=shift;
                #   my $mode=shift;
                #   my %param=@_;
                #   my $rec=$param{current};
                #   my $d=$rec->{$self->Name()};
                #   if (ref($d) eq "HASH" && keys(%$d)){
                #      return(1);
                #   }
                #   return(0);
                #},
                dataobjattr   =>'licproduct.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'licproduct.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                uploadable    =>1,
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'licproduct.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'licproduct.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'licproduct.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'licproduct.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"licproduct.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(licproduct.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'licproduct.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'licproduct.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'licproduct.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'licproduct.realeditor'),
   

   );
   $self->setDefaultView(qw(name metric cistatus mdate cdate));
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.itil.licproduct"],
                         uniquesize=>120};
   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->setWorktable("licproduct");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable ".
            "left outer join producer on licproduct.producer=producer.id";

   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/licproduct.jpg?".$cgi->query_string());
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       ($newrec->{name}=~m/^\s*$/ || length(trim($newrec->{name}))<3)){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!(trim(effVal($oldrec,$newrec,"producerid"))=~m/^\d+$/)){
      $self->LastMsg(ERROR,"invalid producer specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default options doccontrol class phonenumbers source));
}




sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));

   my @l=("header","default","source","attachments","history");
  
   return(@l);
}

sub isCopyValid
{
   my $self=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub prepUploadFilterRecord
{
   my $self=shift;
   my $newrec=shift;

   if ((!defined($newrec->{id}) || $newrec->{id} eq "")
       && $newrec->{srcid} ne ""){
      my $o=$self->Clone();
      $o->SetFilter({srcid=>\$newrec->{srcid}});
      my @l=$o->getHashList(qw(id));
      if ($#l==0){
         my $crec=$l[0];
         $newrec->{id}=$crec->{id};
         delete($newrec->{srcid});
      }
      elsif($#l>0){
         $self->LastMsg(ERROR,"not unique srcid");
      }
   }
   $self->SUPER::prepUploadFilterRecord($newrec);
}






1;
