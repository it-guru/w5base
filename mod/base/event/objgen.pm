package base::event::objgen;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub genFieldname
{
   my $rec=shift;

   my $w5name=lc($rec->{fieldname});
   $w5name=~s/_//g;
   my $fieldname=$rec->{fieldname};
   my $tablename=$rec->{tablename};
   my $fieldlabel=$rec->{fieldname};
   $fieldlabel=lc($fieldlabel);
   $fieldlabel=~s/^([a-z])/\u$1/;
   $fieldlabel=~s/_([a-z])/ \u$1/g;

   return($w5name,$fieldname,$tablename,$fieldlabel);
}

#
# Generic tool to create dataobjects from oracle tables
#
sub objgen
{
   my $self=shift;
   my $modbase=shift;
   my $table=shift;
   my $objname=shift;

   if ($self->Config->Param("W5BaseOperationMode") ne "dev"){
      return({exitcode=>1,msg=>
        msg(ERROR,'objgen event can only be used in W5BaseOperationMode=dev')
      });
   }

   if ($table eq ""){
      return({exitcode=>1,msg=>msg(ERROR,'no table name specified')});
   }
   if ($objname eq ""){
      $objname=lc($table);
   }
   my $instdir=$self->getParent->Config->Param("INSTDIR");

   if ( ! -d "$instdir/mod/$modbase" ){
      return({exitcode=>1,msg=>
        msg(ERROR,"modbase directory $instdir/mod/$modbase not found")
      });
   }
   my $targetfile="$instdir/mod/$modbase/$objname.pm";
   if ( -f $targetfile ){
      return({exitcode=>1,msg=>
        msg(ERROR,"targetfile $targetfile already exists")
      });
   }
   my $skindir="$instdir/skin/default/$modbase";
   my $langdir="$instdir/skin/default/$modbase/lang";
   my $langfile="$instdir/skin/default/$modbase/lang/${modbase}.$objname";

   my $TARGET;
   if (!open($TARGET,">",$targetfile)){
      return({exitcode=>1,msg=>
        msg(ERROR,"can not create targetfile $targetfile")
      });
   }

   my $dictonary="${modbase}::DBDataDiconary";

   my $dbd=getModuleObject($self->Config,$dictonary);
   if (!defined($dbd)){
      msg(ERROR,"a working DBDataDiconary $dictonary must exists");
      return({exitcode=>100,msg=>'error creating object '.$dictonary});
   }


   $dbd->SetFilter({tablename=>$table});
   $dbd->SetCurrentOrder(qw(colid));

   my @l=$dbd->getHashList(qw(ALL));

   #print Dumper(\@l);

   my $dbname=$dbd->{DB}->{dbname};
   my $year=(localtime(time()))[5];

   print $TARGET <<EOF;
package ${modbase}::${objname};
#  W5Base Framework
#  Copyright (C) ${year}  Hartmut Vogler (it\@guru.de)
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
use vars qw(\@ISA);
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
\@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my \$type=shift;
   my %param=\@_;
   \$param{MainSearchFieldLines}=3;

   my \$self=bless(\$type->SUPER::new(\%param),\$type);
   \$self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),
EOF
   my $idname;
   if (!defined($idname)){
      for(my $c=0;$c<$#l;$c++){
         if ($l[$c]->{fieldname}=~m/_id$/i){
            $idname=$l[$c]->{fieldname};
            last;
         }
      }
   }
   if (!defined($idname)){
      for(my $c=0;$c<=$#l;$c++){
         if ($l[$c]->{fieldname}=~m/id$/i){
            $idname=$l[$c]->{fieldname};
            last;
         }
      }
   }
   my @devview=qw(linenumber);
   for(my $c=0;$c<=$#l;$c++){
      if (!$l[$c]->{done}){
         my ($w5name,$fldname,$tablename,$fieldlabel)=genFieldname($l[$c]);
         my $w5type="kernel::Field::Text";
         if ($l[$c]->{datatype} eq "DATE"){
            $w5type="kernel::Field::Date";
            $w5name="d${w5name}";
         }
         if ($l[$c]->{datatype} eq "VARCHAR2" &&
             $l[$c]->{datalenght} > 1999){
            $w5type="kernel::Field::Textarea";
         }
         if ($idname eq $fldname){
            $w5type="kernel::Field::Id";
            $w5name="id";
         }
         if ($c<3){
            push(@devview,$w5name);
         }
         print $TARGET ("\n".
            "      new ${w5type}(\n".
            "                name          =>'$w5name',\n".
            "                label         =>\"${fieldlabel}\",\n".
            "                dataobjattr   =>\"\\\"${tablename}\\\".\\\"${fldname}\\\"\"),\n"
         );
      }
   }

   



   my $view=join(" ",@devview);

   print $TARGET (<<EOF);
   );
   \$self->{use_distinct}=1;
   \$self->{workflowlink}={ };
   \$self->setDefaultView(qw(${view}));
   \$self->setWorktable("\\\"${table}\\\"");
   return(\$self);
}



sub Initialize
{
   my \$self=shift;

   my \@result=\$self->AddDatabase(DB=>new kernel::database(\$self,"${dbname}"));
   return(\@result) if (defined(\$result[0]) eq "InitERROR");
   return(1) if (defined(\$self->{DB}));
   return(0);
}




sub isQualityCheckValid
{
   my \$self=shift;
   my \$rec=shift;
   return(0);
}



sub getRecordImageUrl
{
   my \$self=shift;
   my \$cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>\$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".\$cgi->query_string());
}



sub initSearchQuery
{
   my \$self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".\$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub isViewValid
{
   my \$self=shift;
   my \$rec=shift;

   return("ALL");
}


1;

EOF

   close($TARGET);

   if (! -f $langfile){
      if (! -d $skindir ){
         mkdir($skindir);
      }
      if (! -d $langdir ){
         mkdir($langdir);
      }
      if (open($TARGET,">",$langfile)){
         print $TARGET ("'${modbase}::${objname}'=>{\n");
         print $TARGET ("  en=>'${modbase}__${objname}',\n");
         print $TARGET ("  de=>'${modbase}__${objname}'\n");
         print $TARGET ("},\n");
         close($TARGET);
      } 


   }
   return({exitcode=>0,msg=>'ok'});
}





1;
