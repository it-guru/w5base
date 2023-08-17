package FLEXERAatW5W::softwareevidence;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use FLEXERAatW5W::lib::Listedit;
use kernel::Field;
@ISA=qw(FLEXERAatW5W::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->{use_dirtyread}=1;


   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'id',
                label         =>'Installation ID',
                dataobjattr   =>'FLEXERA_instsoftwareraw.id'),

      new kernel::Field::Text(
                name          =>'file_evidence',
                label         =>'file_evidence',
                dataobjattr   =>'FLEXERA_instsoftwareraw.file_evidence'),

      new kernel::Field::Text(
                name          =>'file_evidence_file_version',
                label         =>'file_evidence_file_version',
                dataobjattr   =>'FLEXERA_instsoftwareraw.'.
                                'file_evidence_file_version'),

      new kernel::Field::Text(
                name          =>'installer_evidence',
                label         =>'installer_evidence',
                dataobjattr   =>'FLEXERA_instsoftwareraw.installer_evidence'),


   );
   $self->setWorktable("FLEXERA_instsoftwareraw");
   $self->setDefaultView(qw(id 
                            file_evidence file_evidence_file_version 
                            installer_evidence));
   return($self);
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my $mode=shift;
#   my @flt=@_;
#   my ($worktable,$workdb)=$self->getWorktable();
#   my $from="";
#
#   $from.="$worktable  ".
#          "join FLEXERA_system ".
#          "on $worktable.FLEXERASYSTEMID=FLEXERA_system.FLEXERASYSTEMID ";
#
#   return($from);
#}

sub initSqlWhere
{
   my $self=shift;
   my $where=<<EOF;
(
FLEXERA_instsoftwareraw.installer_evidence is not null 
or
FLEXERA_instsoftwareraw.file_evidence_file_version is not null
or 
FLEXERA_instsoftwareraw.file_evidence is not null
)
EOF
   return($where);
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default));
}  

1;
