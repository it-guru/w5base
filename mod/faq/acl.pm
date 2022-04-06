package faq::acl;
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
use kernel::App::Web::AclControl;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::AclControl kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{acltable}="faqacl";
   my $self=bless($type->SUPER::new(%param),$type);
   $self->getField("refid")->{label}="Article-No";
   $self->getField("refid")->{translation}="faq::article";

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'article',
                uploadable    =>0,
                readonly      =>1,
                vjoinon       =>['refid'=>'faqid'],
                vjoindisp     =>'name',
                vjointo       =>'faq::article',
                label         =>'FAQ Shortdescription'),
      insertafter=>['aclparentobj']
   );
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'fullname',
                uploadable    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fo=$self->getParent->getField("refid");
                   my $refid=$fo->RawValue($current);
                   my $fo=$self->getParent->getField("article");
                   my $a=$fo->RawValue($current);
                   $a=TextShorter($a,40,["INDICATED"]);
                   return("FAQ:$refid ACL(".$current->{aclid}."):".$a);
                },
                label         =>'FAQ ACL Shortdescription'),
      insertafter=>['aclparentobj']
   );


   return($self);
}



1;
