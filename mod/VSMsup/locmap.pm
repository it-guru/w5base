package VSMsup::locmap;
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();
   $self->{use_distinct}=0;

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                history       =>0,
                dataobjattr   =>"ab.id",
                wrdataobjattr =>'"am_standort"'),

      new kernel::Field::Text(
                name          =>'amloc',
                label         =>'AM Location',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'ab."am_standort"'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'ab.of_id'),


      new kernel::Field::Text(
                name          =>'vsmloc',
                label         =>'VSM Location',
                ignorecase    =>1,
                dataobjattr   =>'ab."vsm_standort"',
                wrdataobjattr =>'"vsm_standort"'),
   );

   $self->setWorktable("VSMsup__locmap_of");
   $self->setDefaultView(qw(amloc vsmloc));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from=
     "(select b.am_location id,".
     "b.am_location,VSMsup__locmap_of.\"am_standort\" of_id,".
     "VSMsup__locmap_of.\"vsm_standort\",".
     "VSMsup__locmap_of.\"am_standort\" ".
     "from (select distinct am_location from VSMsup__system) ".
     "b left outer join VSMsup__locmap_of on ".
     "b.am_location=VSMsup__locmap_of.\"am_standort\") ab";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   if (!defined($oldrec->{ofid})){     # flexerasystemid verwenden
      $newrec->{id}=$oldrec->{id};  # als Referenz in der Overflow die 
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   if (effChanged($oldrec,$newrec,"vsmloc")){
      $newrec->{"vsmloc"}=~s/\s+/_/g;
   }
   return(1);
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
           "\"K001YT5ATS_ES.K001YT5A_DTIT\" \"K001YT5ATS_ES.K001YT5A_DTIT.*\" ".
           "\"YT5ATS_ES.YT5A_DTIT\" \"YT5ATS_ES.YT5A_DTIT.*\" ".
           "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
#   if (!defined(Query->Param("search_inflexera"))){
#      Query->Param("search_inflexera"=>$self->T("no"));
#   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);


#   if (in_array(\@l,["ALL","default"])){
#      my $sys=$self->getPersistentModuleObject("w5sys","itil::system");
#      if (defined($sys) && $rec->{systemid} ne ""){
#         $sys->SecureSetFilter({systemid=>\$rec->{systemid}});
#         my ($rec,$msg)=$sys->getOnlyFirst(qw(id)); 
#         if (defined($rec)){
#            return(@l);
#         }
#      }
#
#      return(qw(header default source));
#   }
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));

   return("default");

   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
