package base::history;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'history.id'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'internal Fieldname',
                selectfix     =>1,
                dataobjattr   =>'history.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fieldname',
                searchable    =>0,
                depend        =>['dataobject','dataobjectid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $o=getModuleObject($self->getParent->Config,
                                         $current->{dataobject});
                   if (defined($o)){
                      my $f=$o->getField($current->{name});
                      if (defined($f)){
                         return($f->Label());
                      }
                      else{
                         if ($current->{dataobject} ne "" &&
                             $current->{dataobjectid} ne ""){
                            my $idfield=$o->IdField();
                            if (defined($idfield)){
                               $o->SetFilter({$idfield->Name()=>
                                              \$current->{dataobjectid}});
                               my ($rec)=$o->getOnlyFirst(qw(ALL));
                               if (defined($rec)){
                                  my $f=$o->getField($current->{name},$rec);
                                  if (!defined($f) &&
                                    $current->{dataobject} eq "base::workflow"){
                                     $f=$o->getField("wffields.".
                                                     $current->{name},$rec);
                                  }
                                  if (defined($f)){
                                     return($f->Label());
                                  }
                               }
                            }
                         }
                      }
                   }
                   return("[".$current->{name}."]");



                }),

      new kernel::Field::Text(
                name          =>'dataobject',
                selectfix     =>1,
                label         =>'Dataobject',
                dataobjattr   =>'history.dataobject'),

      new kernel::Field::Text(
                name          =>'dataobjectid',
                label         =>'DataobjectID',
                dataobjattr   =>'history.dataobjectid'),

      new kernel::Field::Text(
                name          =>'operation',
                label         =>'Operation',
                dataobjattr   =>'history.operation'),

      new kernel::Field::Text(
                name          =>'dataname',
                label         =>'source data record name',
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['dataobject','dataobjectid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent;
                   my $dataobj=$current->{dataobject};
                   my $dataobjid=$current->{dataobjectid};
                   my $o=$app->getPersistentModuleObject($dataobj);
                   if (defined($o)){
                      my @fields=();
                      my $idobj=$o->IdField();
                      if (defined($idobj)){
                         if ($o->getField("fullname")){
                            push(@fields,"fullname");
                         }
                         elsif ($o->getField("name")){
                            push(@fields,"name");
                         }
                         else{
                            return("-can not idefinify record name field-");
                         }
                         $o->SetFilter({$idobj->Name()=>\$dataobjid});
                         my ($rec)=$o->getOnlyFirst(@fields);
                         if (defined($rec)){
                            return($rec->{$fields[0]});
                         }
                         else{
                            return("-record already deleted-");
                         }
                      }
                   }
                   return(undef);
                }),

      new kernel::Field::Htmlarea(
                name          =>'delta',
                label         =>'Delta',
                searchable    =>0,
                depend        =>['oldstate','newstate'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $oldstate=quoteSOAP($current->{oldstate});
                   my $newstate=quoteSOAP($current->{newstate});
                   my $diff;
                   my %diffopt=(remove_open => "<font color=darkred>",
                                remove_close => "</font>",
                                append_open => "<font color=darkgreen>",
                                append_close => "</font>");

                   eval(' 
                      use String::Diff;
                      $diff=String::Diff::diff($oldstate,$newstate,%diffopt);
                   ');
                   my $a=$diff->[0];
                   my $b=$diff->[1];
                   $a=~s/\n/<br>/g;
                   $b=~s/\n/<br>/g;


                  
                   return("<table width=\"100%\">".
                          "<tr><th align=left width=\"50%\">old:</th>".
                          "<th align=left width=\"50%\">new:</th></tr>".
                          "<tr><td>$a</td><td>$b</td></tr>".
                          "</table>");

                }),

      new kernel::Field::Textarea(
                name          =>'oldstate',
                label         =>'Old State',
                dataobjattr   =>'history.oldstate'),

      new kernel::Field::Textarea(
                name          =>'newstate',
                label         =>'New State',
                dataobjattr   =>'history.newstate'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'history.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                label         =>'Creator',
                dataobjattr   =>'history.createuser'),

      new kernel::Field::CDate(
                name          =>'cdate',
                sqlorder      =>'desc',
                label         =>'Inscription-Date',
                dataobjattr   =>'history.createdate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor',
                dataobjattr   =>'history.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'RealEditor',
                dataobjattr   =>'history.realeditor'),

   );
   $self->{dontSendRemoteEvent}=1;
   $self->setDefaultView(qw(cdate editor operation fullname newstate));
   $self->setWorktable("history");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   return(1);
}

1;
