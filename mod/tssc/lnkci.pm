package tssc::lnkci;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use tssc::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lnkid',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'LinkID',
                dataobjattr   =>'screlationm1.ROWID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'relation name',
                uppersearch   =>1,
                dataobjattr   =>"concat(screlationm1.source,".
                                "concat('-',screlationm1.depend))"),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                label         =>'Modification-Date',
                dataobjattr   =>'screlationm1.sysmodtime'),

      new kernel::Field::Interface(
                name          =>'description',
                dataobjattr   =>'screlationm1.descprgn'),

      new kernel::Field::Text(
                name          =>'src',
                group         =>'src',
                label         =>'Source-ID',
                uppersearch   =>1,
                dataobjattr   =>'screlationm1.source'),

      new kernel::Field::Text(
                name          =>'srcfilename',
                group         =>'src',
                label         =>'Source-filename',
                dataobjattr   =>'screlationm1.source_filename'),

      new kernel::Field::Text(
                name          =>'dst',
                group         =>'dst',
                label         =>'System-ID',
                uppersearch   =>1,
                dataobjattr   =>'screlationm1.depend'),

      new kernel::Field::Text(
                name          =>'dstname',
                group         =>'dst',
                label         =>'Name',
                depend        =>['description'],
                onRawValue    =>sub {
                   my $self   =shift;
                   my $current=shift;
                   return (split "\n",$current->{description})[4];
                }),

      new kernel::Field::Boolean(
                name          =>'civalid',
                group         =>'dst',
                label         =>'Valid',
                translation   =>'tssc::lnk',
                htmlwidth     =>'50',
                dataobjattr   =>"decode(screlationm1.valid_ci,'t',1,'f',0,NULL)"),

      new kernel::Field::Boolean(
                name          =>'primary',
                group         =>'dst',
                label         =>'Primary',
                markempty     =>1,
                dataobjattr   =>"decode(screlationm1.primary_ci,'true',1,'false',0,NULL)"),

      new kernel::Field::Text (
                name          =>'dststatus',
                group         =>'dst',
                label         =>'Status',
                htmlwidth     =>'100',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my $status = (split "\n",$current->{description})[2];
                    return lc $status;
                 }),

      new kernel::Field::Text (
                name          =>'dstcriticality',
                group         =>'dst',
                label         =>'Criticality',
                htmlwidth     =>'80',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    return (split "\n",$current->{description})[0];
                 }),

      new kernel::Field::Text(
                name          =>'dstmodel',
                group         =>'dst',
                label         =>'Model',
                htmlwidth     =>'150',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    return (split "\n",$current->{description})[1];
                 }),

      new kernel::Field::Text (
                name          =>'dstcustomer',
                group         =>'dst',
                label         =>'Customer',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    return (split "\n",$current->{description})[3];
                 }),

      new kernel::Field::Text(
                name          =>'dstfilename',
                group         =>'dst',
                label         =>'Destination-filename',
                dataobjattr   =>'screlationm1.depend_filename'),

      new kernel::Field::Textarea(
                name          =>'furtherciinfo',
                label         =>'further ci informations',
                depend        =>['dst','dstmodel'],
                weblinkto     =>sub{
                    my $self   =shift;
                    my $d      =shift;
                    my $current=shift;
                    my $p=$self->getParent();

                    my $dstmodel=$p->getField("dstmodel")->RawValue($current);
                    my $dst=$p->getField("dst")->RawValue($current);

                    my $weblinkto=undef;
                    my $weblinkon=undef;
                    if ($dstmodel eq "APPLICATION"){
                       $weblinkto="itil::appl";   
                       $weblinkon=['dst'=>'applid'];
                    }
                    if ($dstmodel eq "LOGICAL SYSTEM"){
                       $weblinkto="itil::system";   
                       $weblinkon=['dst'=>'systemid'];
                    }
                    return($weblinkto,$weblinkon);
                },
                onRawValue    =>sub{
                    my $self   =shift;
                    my $current=shift;
                    my $mode=shift;
                    my $p=$self->getParent();

                    my $d="unknown";

                    my $dstmodel=$p->getField("dstmodel")->RawValue($current);
                    my $dst=$p->getField("dst")->RawValue($current);

                    if ($dstmodel eq "APPLICATION" && $dst ne ""){
                       my $o=getModuleObject($self->Config,"itil::appl");
                       $o->SetFilter({applid=>\$dst});
                       my ($rec)=$o->getOnlyFirst(qw(mandator opmode));
                       my @v;
                       foreach my $var (qw(mandator opmode)){
                          my $fld=$o->getField($var,$rec);
                          if (defined($fld)){
                             push(@v,$fld->Label($rec).": ".
                                     $fld->FormatedDetail($rec));
                          }
                       }
                       
                       $d=join("\n",@v);
                    }
                    
                    if ($dstmodel eq "LOGICAL SYSTEM" && $dst ne ""){
                   #    my $o=getModuleObject($self->Config,"itil::system");
                   #    $o->SetFilter({systemid=>\$dst});
                   #    my ($rec)=$o->getOnlyFirst(qw(mandator shortdesc));
                   #    my @v;
                   #    foreach my $var (qw(mandator shortdesc)){
                   #       my $fld=$o->getField($var,$rec);
                   #       if (defined($fld)){
                   #          push(@v,$fld->Label($rec).": ".
                   #                  $fld->FormatedDetail($rec));
                   #       }
                   #    }
                   #    
                   #    $d=join("\n",@v);
                        $d="";
                    }
                   return($d);
                }),
                    


      new kernel::Field::Textarea(
                name          =>'probableapps',
                label         =>'probable W5Base application',
                depend        =>['dst','dstmodel'],
                onRawValue    =>sub{
                    my $self   =shift;
                    my $current=shift;
                    my $mode=shift;
                    my $p=$self->getParent();

                    my %d;

                    my $dstmodel=$p->getField("dstmodel")->RawValue($current);
                    my $dst=$p->getField("dst")->RawValue($current);

#                    if ($dstmodel eq "APPLICATION" && $dst ne ""){
#                       my $o=getModuleObject($self->Config,"itil::appl");
#                       $o->SetFilter({applid=>\$dst});
#                       my ($rec)=$o->getOnlyFirst(qw(systems));
#                    }
                    
                    if ($dstmodel eq "LOGICAL SYSTEM" && $dst ne ""){
                       my $o=getModuleObject($self->Config,"itil::system");
                       $o->SetFilter({systemid=>\$dst});
                       my ($rec)=$o->getOnlyFirst(qw(applications));
                       if (ref($rec->{applications}) eq "ARRAY"){
                          foreach my $app (@{$rec->{applications}}){
                             $d{$app->{appl}}++;
                          }
                       }
                    }
                    



                   return([sort(keys(%d))]);
                }),
   );
   
   $self->{use_distinct}=1;
   $self->setWorktable("screlationm1");

   $self->setDefaultView(qw(linenumber dst dstname probableapps));

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(src dst status w5base));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   return(0);
}




sub getSqlFrom
{
   my $self=shift;
   my $from="scadm1.screlationm1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="screlationm1.depend_filename='device'";
   return($where);
}


1;
