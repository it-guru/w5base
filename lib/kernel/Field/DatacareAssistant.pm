package kernel::Field::DatacareAssistant;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self={@_};
   $self->{group}='source'                  if (!defined($self->{group}));
   $self->{name}='datacareassistant'        if (!defined($self->{name}));
   $self->{label}='Data care Assistant'     if (!defined($self->{label}));


   my $self=bless($type->SUPER::new(%$self),$type);
   $self->{searchable}=0;
   $self->{uploadable}=0;
   $self->{htmldetail}=0;
   
   return($self);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;    # ATTENTION! - This is not always set! (at now 03/2013)
   delete($self->{LastDisplayText});
   return(undef) if (!defined($current));
   my $parent=$self->getParent->Clone();
   my $idfield=$parent->IdField();
   my $html=0;
   if ($mode eq "HtmlV01" || $mode eq "HtmlDetail"){
      $html=1;
   }
   my $msg;
   my $code;
   my $wrok=0;

   if (defined($idfield)){
      my $idname=$idfield->Name();
      if (exists($current->{$idname}) && $current->{$idname} ne ""){
         $self->loadDatacareAssistant($parent,$current);


         $parent->SetFilter({$idname=>\$current->{$idname}});
         my $id=$current->{$idname};
         my ($prec)=$parent->getOnlyFirst(qw(ALL));
         if (defined($prec)){
            my @g=$parent->isWriteValid($prec);
            if ($#g!=-1){
               $wrok=1;
            }

            $code.=<<EOF;

var id=Add('base::user',{xxx=>'xxx',yyy=>'xxx'});
if (!id) break;
var id=Upd('base::user',{xxx=>'xxx',yyy=>'xxx'},{id=>'xxx'});
if (!id) break;
var id=Del('base::user',{id=>'xxx'});
if (!id) break;

EOF
            $msg.=$html ? "<div id=sg1ba$id style='border-width:thin;border-style:solid;border-color:black;padding:4px'><b>Problem:</b><br>Laut DINA AutoDiscovery ist Oracle auf dem System installiert, es wurde aber keine dokumentierte Oracle Installation gefunden.<br><div style='margin-left:10px;margin-top:15px'><b>Solution1:</b><br>Eine Möglichkeit wäre es, eine Software-Installation <input type=button value='Oracle_Enterprise_Edition hinzuzfügen'>. Bitte stellen Sie zusammen mit dem Lizenzmanagement dann sicher, dass diese Installation auch korrekt lizenziert wird.<hr><b>Solution2:</b><br>Eine weitere Möglichkeit wäre es, eine Software-Installation <input type=button value='Oracle_Standard_Edition hinzuzfügen'>. Die weitere Pflege der neuen Software-Installation muß dann manuell erfolgen.</div></div>" :
                          "Hallo Welt ($mode)\nZ2";
            $msg=undef if ($prec->{name} eq "q8nwr");
         }
      }
   }
   if ($wrok){
      $self->{LastDisplayText}=$msg;
   }
   else{
      $self->{LastDisplayText}="-";
   }
   return($code);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $care=$self->RawValue($current,$mode);
   my $name=$self->Name();
   my $C=$self->getParent->Cache();
   my $lang=$self->getParent->Lang();
   my $address;
   my $marker;
   my $apikey;
   my $site=$ENV{SCRIPT_URI};
   my $idname=$self->getParent->IdField->Name();
   my $id=$current->{$idname};
   my $d=$self->{LastDisplayText};

   if ($mode=~m/^Html.*$/){
      my $text=$self->{LastDisplayText};
      $d="";
      if ($text ne ""){
         $d=<<EOF;
<script language="JavaScript">

function DatacareAssi$id() {
   var id='$id'; 
}
addEvent(window, "load", DatacareAssi$id);
</script>
<div id="DatacareAssistent$id" style="width: 700px; border-style:solid;border-color:black">
$text
</div>
EOF
      }
   }
   return($d);
}


sub loadDatacareAssistant
{
   my $self=shift;
   my $parent=shift;
   my $current=shift;
   my $name=$self->Name();
   my $context=$parent->Context();
   my $idobj=$parent->IdField();
   my $idname=$idobj->Name();

   return(undef) if (!exists($current->{$idname}));
   my $id=$current->{$idname};
   if (!defined($context->{DatacareResult}->{$id})){
      my $obj=getModuleObject($parent->Config,$parent->Self);
      $obj->SetFilter({$idname=>\$id});
      my ($chkrec,$msg)=$obj->getOnlyFirst(qw(ALL));
      my $result={};
      if (defined($chkrec)){
         my $qc=getModuleObject($parent->Config,"base::qrule");
         $qc->setParent($parent);
         my $compat=$parent->getQualityCheckCompat($chkrec);
         my %checksession=(checkstart=>time(),checkmode=>'field');
         $result=$qc->nativDatacareAssistant($compat,$chkrec,\%checksession);
         printf STDERR ("nativloadDatacareAssistant=%s\n",Dumper($result));
      }
      $context->{DatacareResult}->{$id}=$result;
   }
   return($context->{DatacareResult}->{$id});
}










1;
