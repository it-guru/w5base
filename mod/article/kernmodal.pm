package article::kernmodal;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>'artkernmodal.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'internal name',
                dataobjattr   =>'artkernmodal.name'),

      new kernel::Field::Text(
                name          =>'displaylabel',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                readonly      =>1,
                uploadable    =>0,
                group         =>'icontrol',
                depend        =>['labeldata'],
                onPreProcessFilter=>sub {
                   my $self=shift;   # if there is a need, to implement a
                   my $hflt=shift;   # language specific search, this must
                   my $changed=0;    # be implemented at this point
                   my $err;
                   if (exists($hflt->{$self->Name})){
                      $hflt->{labeldata}=$hflt->{$self->Name};
                      delete($hflt->{$self->Name});
                      $changed++;
                   }
                   return($changed,$err);
                },
                onRawValue    =>sub{
                   my ($self,$current)=@_;
                   my $lang=$self->getParent->Lang();
                   return(extractLangEntry($current->{labeldata},$lang));
                },
                label         =>'full name'),

     # new kernel::Field::Text(
     #           name          =>'fullname',
     #           searchable    =>0,
     #           uploadable    =>0,
     #           readonly      =>1,
     #           htmldetail    =>0,
     #           group         =>'icontrol',
     #           label         =>'item entry fullname',
     #           dataobjattr   =>"concat(artkernmodal.selectlabel,".
     #                           "'-',artkernmodal.name)"),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                default       =>'4',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'artkernmodal.cistatus'),


      new kernel::Field::Textarea(
                name          =>'labeldata',
                selectfix     =>1,
                label         =>'label data',
                dataobjattr   =>'artkernmodal.labeldata'),

      new kernel::Field::Text(
                name          =>'en_fullname',
                searchable    =>0,
                uploadable    =>0,
                group         =>'icontrol',
                depend        =>['labeldata'], 
                label         =>'en fullname',
                onRawValue    =>sub{
                   my ($self,$current)=@_;
                   my $lang=$self->getParent->Lang();
                   return(extractLangEntry($current->{labeldata},"en"));
                }),

      new kernel::Field::Text(
                name          =>'de_fullname',
                searchable    =>0,
                uploadable    =>0,
                group         =>'icontrol',
                label         =>'de fullname',
                depend        =>['labeldata'], 
                onRawValue    =>sub{
                   my ($self,$current)=@_;
                   return(extractLangEntry($current->{labeldata},"de"));
                }),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'artkernmodal.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artkernmodal.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artkernmodal.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artkernmodal.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artkernmodal.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artkernmodal.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artkernmodal.realeditor'),

   );
   $self->setDefaultView(qw(linenumber displaylabel cistatus mdate));
   $self->setWorktable("artkernmodal");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default icontrol source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((my $v=effVal($oldrec,$newrec,"name"))=~m/(^\s*$|\s)/){
      $self->LastMsg(ERROR,"invalid internal name");
      return(undef);
   }
   if ((my $v=effVal($oldrec,$newrec,"labeldata"))=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid english name");
      return(undef);
   }



   return(1);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}






1;
