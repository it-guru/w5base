package itil::platform;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(         name          =>'id',
                                     sqlorder      =>'desc',
                                     label         =>'W5BaseID',
                                     dataobjattr   =>'platform.id'),
                                                  
      new kernel::Field::Text(       name          =>'name',
                                     label         =>'Name',
                                     dataobjattr   =>'platform.name'),

      new kernel::Field::Select(     name          =>'cistatus',
                                     htmleditwidth =>'40%',
                                     label         =>'CI-State',
                                     vjoineditbase =>{id=>">0 AND <7"},
                                     vjointo       =>'base::cistatus',
                                     vjoinon       =>['cistatusid'=>'id'],
                                     vjoindisp     =>'name'),

      new kernel::Field::Link(       name          =>'cistatusid',
                                     label         =>'CI-StateID',
                                     dataobjattr   =>'platform.cistatus'),

      new kernel::Field::Select(     name          =>'hwbits',
                                     htmleditwidth =>'40%',
                                     label         =>'HardwareBits',
                                     value         =>['','32Bit','64Bit'],
                                     dataobjattr   =>'platform.hwbits'),
                                                   
      new kernel::Field::Text(       name          =>'srcsys',
                                     group         =>'source',
                                     label         =>'Source-System',
                                     dataobjattr   =>'platform.srcsys'),
                                                   
      new kernel::Field::Text(       name          =>'srcid',
                                     group         =>'source',
                                     label         =>'Source-Id',
                                     dataobjattr   =>'platform.srcid'),
                                                   
      new kernel::Field::Date(       name          =>'srcload',
                                     group         =>'source',
                                     history       =>0,
                                     label         =>'Source-Load',
                                     dataobjattr   =>'platform.srcload'),

      new kernel::Field::CDate(      name          =>'cdate',
                                     group         =>'source',
                                     sqlorder      =>'desc',
                                     label         =>'Creation-Date',
                                     dataobjattr   =>'platform.createdate'),
                                                  
      new kernel::Field::MDate(      name          =>'mdate',
                                     group         =>'source',
                                     sqlorder      =>'desc',
                                     label         =>'Modification-Date',
                                     dataobjattr   =>'platform.modifydate'),

      new kernel::Field::Creator(    name          =>'creator',
                                     group         =>'source',
                                     label         =>'Creator',
                                     dataobjattr   =>'platform.createuser'),

      new kernel::Field::Owner(      name          =>'owner',
                                     group         =>'source',
                                     label         =>'last Editor',
                                     dataobjattr   =>'platform.modifyuser'),

      new kernel::Field::Editor(     name          =>'editor',
                                     group         =>'source',
                                     label         =>'Editor Account',
                                     dataobjattr   =>'platform.editor'),

      new kernel::Field::RealEditor( name          =>'realeditor',
                                     group         =>'source',
                                     label         =>'real Editor Account',
                                     dataobjattr   =>'platform.realeditor'),
   

   );
   $self->setDefaultView(qw(id name cistatus mdate cdate));
   $self->setWorktable("platform");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.itil.platform"],
                         uniquesize=>128};



   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   if (defined($newrec->{cistatusid}) && $newrec->{cistatusid}>4){
      # validate if subdatastructures have a cistauts <=4 
      # if true, the new cistatus isn't alowed
   }

   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/platform.jpg?".$cgi->query_string());
}
         

1;
