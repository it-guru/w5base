package W5Warehouse::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{use_distinct}=0 if (!defined($param{use_distinct}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();
   return($self);
}

sub AddAllFieldsFromWorktable
{
   my $self=shift;

   if (!defined($self->{FieldGenerationTime}) ||
        $self->{FieldGenerationTime}+600<time()){   # field cache for 10min
      $self->{FieldGenerationTime}=time();
      $self->ResetFields();
      #msg(INFO,"new generation of field list in ".$self->Self);
      my ($worktable,$workdb)=$self->getWorktable();
      my @l;
      push(@l,new kernel::Field::Linenumber(
                   name          =>'linenumber',
                   label         =>'No.'));
      
      my $dict=getModuleObject($self->Config,"W5Warehouse::ufield");
      $dict->SetFilter({aliasowner=>\'W5I',alias=>\$worktable});
      foreach my $fld ($dict->getHashList(qw(fieldname fieldtype))){
         my $name=lc($fld->{fieldname});
         $name=~s/[\s\.-]/_/g;
         my $label=$fld->{fieldname};
         if (!($label=~m/[ ,a-z]/)){
            $label=~s/_/ /g; 
         }
         if ($fld->{fieldtype} eq "VARCHAR2"){
            push(@l,new kernel::Field::Text(
                          name          =>$name,
                          searchable    =>1,
                          ignorecase    =>1,
                          label         =>$label,
                          dataobjattr   =>"\"$fld->{fieldname}\""));
         }
         elsif ($fld->{fieldtype} eq "CLOB"){
            push(@l,new kernel::Field::Textarea(
                          name          =>$name,
                          searchable    =>1,
                          sqlorder      =>'none',
                          label         =>$label,
                          dataobjattr   =>"\"$fld->{fieldname}\""));
         }
         elsif ($fld->{fieldtype} eq "NUMBER"){
            push(@l,new kernel::Field::Number(
                          name          =>$name,
                          searchable    =>1,
                          label         =>$label,
                          dataobjattr   =>"\"$fld->{fieldname}\""));
         }
         elsif ($fld->{fieldtype} eq "DATE"){
            push(@l,new kernel::Field::Date(
                          name          =>"d_".$name,
                          searchable    =>0,
                          label         =>$label,
                          dataobjattr   =>"\"$fld->{fieldname}\""));
         }
        #
        # Solange "Oracle Total Recall noch nicht so arbeitet, wie es soll
        #
        # if ($#l==1){
        #    push(@l,new kernel::Field::Date(
        #                  name          =>'as_of_Timestamp',
        #                  searchable    =>1,
        #                  onPreProcessFilter=>sub{
        #                    my $self=shift;
        #                    my $hflt=shift;
        #                    my $p=$self->getParent;
        #                    delete($p->Context()->{as_of_Timestamp});
        #                    if (defined($hflt->{as_of_Timestamp})){
        #                       $self->getParent->Context()->{as_of_Timestamp}=
        #                          $hflt->{as_of_Timestamp};
        #                       delete($hflt->{as_of_Timestamp});
        #                    }
        #                    return(0);
        #                  },
        #                  sqlorder      =>'NONE',
        #                  label         =>"as of timestamp",
        #                  dataobjattr   =>"'1'"));
        # }
      }
      $self->AddFields(@l);
   }
}

#######################################################################
#                                                                     #
# Trigger regeneration of field list                                  #
#                                                                     #
sub doInitialize                                                      
{
   my $self=shift;
   my $back=$self->SUPER::doInitialize();
   $self->AddAllFieldsFromWorktable();
   return($back);
}

sub getFieldList
{
   my $self=shift;
   $self->AddAllFieldsFromWorktable();
   return($self->SUPER::getFieldList(@_));
}

sub ModuleObjectInfo
{
   my $self=shift;
   $self->AddAllFieldsFromWorktable();
   return($self->SUPER::ModuleObjectInfo(@_));
}

sub SetFilter
{
   my $self=shift;
   $self->AddAllFieldsFromWorktable();
   return($self->SUPER::SetFilter(@_));
}

#######################################################################


sub Welcome 
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'W5Warehouse Archive access');

   my $module=$self->Module();
   my $appname=$self->App();
   my $tmpl="tmpl/$appname.welcome";
   my @detaillist=$self->getSkinFile("$module/".$tmpl);
   if ($#detaillist!=-1){
      print $self->getParsedTemplate($tmpl,{});
   }
   else{
      my $tmpl="tmpl/legend";
      my @detaillist=$self->getSkinFile("$module/".$tmpl);
      if ($#detaillist!=-1){
         print $self->getParsedTemplate($tmpl,{});
      }
   }
   print $self->HtmlBottom(body=>1,form=>1);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   if (defined($self->{DB})){
      $self->{DB}->{db}->{LongReadLen}=1024*1024*15;    #15MB
   }
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_as_of_Timestamp"))){
     Query->Param("search_as_of_Timestamp"=>$self->T("now"));
   }
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();

   my $append="";

   my $ts=$self->Context()->{as_of_Timestamp};

   if ($ts ne ""){
      my $t=$self->ExpandTimeExpression($ts,"en",undef,"GMT");
      my $now=NowStamp("en");
      if (!defined($t)){
         return(undef);
      }
      if ($t ne $now){
         $append=" AS OF TIMESTAMP TO_TIMESTAMP('$t','YYYY-MM-DD HH24:MI:SS')";
      }
   }
   return($worktable.$append);
}


sub preProcessDBmsg
{
   my $self=shift;
   my $msg=shift;

   if ($msg=~m/ORA-01031:/){
      $msg=~s/ \(//g;
      return("ERROR: ".$msg);
   }
   return($self->SUPER::preProcessDBmsg($msg));
}






1;
