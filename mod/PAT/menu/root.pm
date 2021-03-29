package PAT::menu::root;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::MenuRegistry;
@ISA=qw(kernel::MenuRegistry);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterObj("Tools.PAT",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.PAT.businessseg",
                      "PAT::businessseg",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.businessseg.new",
                      "PAT::businessseg",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.subprocess",
                      "PAT::subprocess",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.subprocess.new",
                      "PAT::subprocess",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.subprocess.lnkictname",
                      "PAT::lnksubprocessictname",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.ictname",
                      "PAT::ictname",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.ictname.new",
                      "PAT::ictname",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source",
                      "tmpl/welcome",
                      prio=>9999,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.PAT.source.List",
                      "PAT::srcList",
                      prio=>10,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source.BusinessSeg",
                      "PAT::srcBusinessSeg",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source.SubProcess",
                      "PAT::srcSubProcess",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source.ICTname",
                      "PAT::srcICTname",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source.Times",
                      "PAT::srcTimes",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.PAT.source.Threshold",
                      "PAT::srcThreshold",
                      defaultacl=>['valid_user']);

   return($self);
}



1;
