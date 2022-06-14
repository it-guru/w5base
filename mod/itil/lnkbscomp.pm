package itil::lnkbscomp;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
  
   my $dst           =[
                       'itil::systemmonipoint' =>'fullname',
                       'itil::businessservice'=>'fullname',
                       'itil::system' =>'name',
                       'itil::appl'=>'name',
                      ];

   my $vjoineditbase =[
                       {'systemcistatusid'=>'<5'},
                       {'cistatusid'=>"<5"},
                       {'cistatusid'=>"<5"},
                       {'cistatusid'=>"<5"},
                      ];

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                group         =>'source',
                dataobjattr   =>'lnkbscomp.id'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                onRawValue    =>\&mkFullname,
                depend        =>['uppername','name']),


      new kernel::Field::Link(
                name          =>'businessserviceid',
                selectfix     =>1,
                label         =>'Businessservice ID',
                dataobjattr   =>'lnkbscomp.businessservice'),

      new kernel::Field::TextDrop(
                name          =>'uppername',
                label         =>'Businessservice name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::businessservice',
                vjoinon       =>['businessserviceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'variant',
                label         =>'Variant',
                htmlwidth     =>'50',
                htmleditwidth =>'30px',
                allownative   =>1,
                selectfix     =>1,
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   my @lst;
                   my $app=$self->getParent();
                   my $businessserviceid;
                   if (defined($current)){
                      $businessserviceid=$current->{businessserviceid};
                   }
                   else{
                      $businessserviceid=Query->Param('businessserviceid');
                   }
                   if ($businessserviceid ne ""){
                      my $max=0;
                      my $op=$app->Clone();
                      $op->SetFilter({businessserviceid=>\$businessserviceid});
                      my @l=$op->getHashList(qw(sortkey variant lnkpos id));
                      foreach my $rec (@l){
                         $max=$rec->{variant} if ($rec->{variant}>$max);
                      }
                      $max++;
                      foreach(my $cc=1;$cc<=$max;$cc++){
                         push(@lst,$cc,$cc);
                      }
                   }
                   else{
                      foreach(my $cc=1;$cc<=999;$cc++){
                         push(@lst,$cc,$cc);
                      }
                      push(@lst,"","");
                      push(@lst,"E",999);
                      return(@lst);
                   }
                   return(@lst);
                },
                dataobjattr   =>'lnkbscomp.varikey'),

      new kernel::Field::Select(
                name          =>'lnkpos',
                label         =>'Pos',
                htmlwidth     =>'50',
                allownative   =>1,
                default       =>'999',
                htmleditwidth =>'40px',
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   my @lst;
                   my $app=$self->getParent();
                   my $businessserviceid;
                   if (defined($current)){
                      $businessserviceid=$current->{businessserviceid};
                   }
                   else{
                      $businessserviceid=Query->Param('businessserviceid');
                   }
                   if ($businessserviceid ne ""){
                      my $max=0;
                      my $op=$app->Clone();
                      $op->SetFilter({businessserviceid=>\$businessserviceid});
                      my @l=$op->getHashList(qw(sortkey variant lnkpos id));
                      foreach my $rec (@l){
                         $max=$rec->{lnkpos} if ($rec->{lnkpos}>$max);
                      }
                      $max++;
                      foreach(my $cc=1;$cc<$max;$cc++){
                         push(@lst,$cc,$cc);
                      }
                      push(@lst,999,"E");
                   }
                   else{
                      foreach(my $cc=1;$cc<=999;$cc++){
                         push(@lst,$cc,$cc);
                      }
                      push(@lst,"","");
                      return(@lst);
                   }
                   return(@lst);
                },
                dataobjattr   =>'lnkbscomp.lnkpos'),

      new kernel::Field::Htmlarea(
                name          =>'sortkey',
                label         =>' ',
                uivisible     =>0,
                htmlwidth     =>'50px',
                prepRawValue  =>sub{
                   my $self=shift;
                   my $d=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $c=$app->Context();
                   my ($variant,$lnkpos)=split(/\//,$d);
                   my $businessserviceid=$current->{businessserviceid};
                   $d=~s/^0+//g;
                   $d=~s/\// /g;
                   $d=~s/ 0+/ /g;
                   if ($c->{$businessserviceid}->{lastvariant} ne 
                       $current->{variant}){
                      $d=sprintf("%-2d -->%2d",$variant,$lnkpos);
                   }
                   else{
                      $d=sprintf("%-2s +->%2d","",$lnkpos);
                   }
                   $d="<xmp>".$d."</xmp>";
                   $c->{$businessserviceid}->{lastvariant}=$current->{variant};
                   return($d);
                },
                dataobjattr   =>"concat(LPAD(lnkbscomp.varikey,4,'0'),".
                                "'/',".
                                "LPAD(lnkbscomp.lnkpos,4,'0'))"),

      new kernel::Field::Select(
                name          =>'objtype',
                label         =>'Component type',
                selectfix     =>1,
                default       =>'itil::businessservice',
                getPostibleValues=>sub{
                   my $self=shift;
                   my @l;
                   my @dslist=@$dst;
                   while(my $obj=shift(@dslist)){
                       shift(@dslist);
                       push(@l,$obj,$self->getParent->T($obj,$obj));
                   }
                   return(@l);
                },
                dataobjattr   =>'lnkbscomp.objtype'),

      new kernel::Field::MultiDst (
                name          =>'name',
                htmlwidth     =>'300',
                selectivetyp  =>1,
                dst           =>$dst,
                vjoineditbase =>$vjoineditbase,
                label         =>'Component',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj1id'),

      new kernel::Field::Link(
                name          =>'obj1id',
                label         =>'Object1 ID',
                dataobjattr   =>'lnkbscomp.obj1id'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkbscomp.comments'),

      new kernel::Field::Text(
                name          =>'xcomments',
                label         =>'Comments shorted',
                htmldetail    =>'0',
                uploadable    =>0,
                readonly      =>1,
                depend        =>['comments'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $c;
                   $c.=$current->{comments};
                   return($c);
                }), 

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbscomp.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkbscomp.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbscomp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbscomp.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkbscomp.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbscomp.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbscomp.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                readonly      =>1,
                label         =>'primary sync key',
                dataobjattr   =>"lnkbscomp.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                readonly      =>1,
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkbscomp.id,35,'0')"),


      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkbscomp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkbscomp.realeditor'),
   );
   $self->setDefaultView(qw(id uppername pos name cdate editor));
   $self->setWorktable("lnkbscomp");
   return($self);
}

sub mkFullname
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();

   my $uppernamefld=$app->getField("uppername",$current);
   my $namefld=$app->getField("name",$current);


   my $fullname="";
   my $uppername=$uppernamefld->RawValue($current);
   my $name=$namefld->RawValue($current);
   $fullname.=$uppername;
   $fullname.=" -> " if ($fullname ne "" && $name ne "");
   $fullname.=$name;

   return($fullname);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      if ($newrec->{variant} eq ""){
         $newrec->{variant}=1;
      }
      if ($newrec->{lnkpos} eq ""){
         $newrec->{lnkpos}=999;
      }
   }


   if ($self->isDataInputFromUserFrontend()){
      if (!$self->checkWriteValid($oldrec,$newrec)){
         $self->LastMsg(ERROR,"no access");
         return(0);
      }
   }
   if (effVal($oldrec,$newrec,"obj1id") eq ""){
      $self->LastMsg(ERROR,"no primary element specified");
      return(0);
   }
   my $businessserviceid=effVal($oldrec,$newrec,"businessserviceid");
   my $objtype=effVal($oldrec,$newrec,"objtype");
   if ($objtype eq "itil::businessservice"){
      my $id=effVal($oldrec,$newrec,"obj1id");
      if ($id eq $businessserviceid){
         $self->LastMsg(ERROR,"a business service an not contain herself");
         return(0);
      }
      # recursions check
      my $layer=1;
      my @chkParentList;
      # get Parents of current
      my $op=$self->getPersistentModuleObject("itil::businessservice");
      $op->SetFilter({id=>\$businessserviceid});
      my ($currec)=$op->getOnlyFirst(qw(allparentids));
      if (defined($currec) && defined($currec->{allparentids}) &&
          ref($currec->{allparentids}) eq "ARRAY" &&
          $#{$currec->{allparentids}}!=-1){
         push(@chkParentList,@{$currec->{allparentids}});
      }
      if (!defined($oldrec)){
         if (in_array(\@chkParentList,$id)){
            $self->LastMsg(ERROR,
                           "new child business service already in parents");
            return(0);
         }
         push(@chkParentList,$id);
      }
      push(@chkParentList,$businessserviceid);
      if (!$self->recursionValidate($layer,\@chkParentList)){
         $self->LastMsg(ERROR,"recursion loop detected");
         return(0);
      }
   }
   return(1);
}

sub recursionValidate
{
   my $self=shift;
   my $layer=shift;
   my $searchfor=shift;

   my @searchfor=@{$searchfor};
   if ($layer>10){
      $self->LastMsg(ERROR,"service layer limit reached");
      return(undef);
   }

   my @curtree=@searchfor;
   my $lastid=pop(@curtree);
   if (in_array(\@curtree,$lastid)){
      return(undef);
   }
   my $op=$self->getPersistentModuleObject($self->SelfAsParentObject());
   my %flt=(
      objtype=>\'itil::businessservice',
      businessserviceid=>\$lastid
   );
   $op->SetFilter(\%flt);
   my @l=$op->getHashList(qw(id objtype obj1id));
   foreach my $subrec (@l){
      my @subsearchfor=@searchfor;
      push(@subsearchfor,$subrec->{obj1id});
      if (!$self->recursionValidate($layer+1,\@subsearchfor)){
         return(undef);
      }
   }
   return(1);
}






sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #return(undef);
   return("default") if (!defined($rec));
   return("default") if ($self->checkWriteValid($rec));
   return(undef);
}

sub doRenumComps
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $op=$self->Clone();
   my $businessserviceid=effVal($oldrec,$newrec,"businessserviceid");

   $op->SetFilter({businessserviceid=>\$businessserviceid});
   my @l=$op->getHashList(qw(sortkey -mdate variant lnkpos id));
   my @oplist;

   my @u;
   foreach my $r (@l){
      push(@u,{id=>$r->{id},variant=>$r->{variant},
               lnkpos=>$r->{lnkpos},sortkey=>$r->{sortkey}});
   }

   my $variant=0;
   my $lnkpos=0;


   for(my $c=0;$c<=$#u;$c++){
      if ($u[$c]->{variant}==$variant+1){
         $variant++;
         $lnkpos=0;
      }
      if ($c==0 && $variant==0){
         $variant=1;
      }
      $lnkpos++;
      if ($u[$c]->{variant} ne $variant){
         $u[$c]->{variant}=$variant;
      }
      if ($u[$c]->{lnkpos} ne $lnkpos){
         $u[$c]->{lnkpos}=$lnkpos;
      }
   }
   for(my $c=0;$c<=$#u;$c++){
      #printf STDERR ("lnkpos %s -> %s\n",$l[$c]->{lnkpos},$u[$c]->{lnkpos});
      #printf STDERR ("variant %s -> %s\n",$l[$c]->{variant},$u[$c]->{variant});
      if (($u[$c]->{lnkpos}!=$l[$c]->{lnkpos}) ||
          ($u[$c]->{variant}!=$l[$c]->{variant})){
         my $bk=$op->UpdateRecord({
             variant=>$u[$c]->{variant},
             lnkpos=>$u[$c]->{lnkpos}
         },{id=>\$u[$c]->{id}});
         #msg(INFO,"renum lnkbscom $bk");
      }
   }
#print STDERR Dumper(\@l);
#print STDERR Dumper(\@u);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->doRenumComps($oldrec,undef);
   return($bak);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   $self->doRenumComps($oldrec,$newrec);
   return($bak);
}


sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $bsid=effVal($oldrec,$newrec,"businessserviceid");

   return(undef) if ($bsid eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::businessservice");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$bsid);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^servicecomp$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(0);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkbscomp");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}







1;
