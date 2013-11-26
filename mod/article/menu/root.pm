package article::menu::root;
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

   $self->RegisterObj("article",
                      "tmpl/welcome",
                      prio=>100,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("article.catalog",
                      "article::catalog",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("article.catalog.new",
                      "article::catalog",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.catalog.category",
                      "article::category",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("article.catalog.category.new",
                      "article::category",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.product",
                      "article::product",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("article.product.new",
                      "article::product",
                      func=>'New',
                      defaultacl=>['valid_user']);

#   $self->RegisterObj("article.product.lnkelement",
#                      "article::lnkelementprod",
#                      defaultacl=>['valid_user']);
#
#   $self->RegisterObj("article.product.lnkelement.new",
#                      "article::lnkelementprod",
#                      func=>'New',
#                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.product.subproduct",
                      "article::lnkprodprod",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.product.subproduct.new",
                      "article::lnkprodprod",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.delivprovider",
                      "article::delivprovider",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("article.delivprovider.new",
                      "article::delivprovider",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.kern",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("article.kern.kpi",
                      "article::kernkpi",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("article.kern.modal",
                      "article::kernmodal",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

#   $self->RegisterObj("article.delivprovider.element",
#                      "article::delivelement",
#                      defaultacl=>['valid_user']);
#
#   $self->RegisterObj("article.delivprovider.element.new",
#                      "article::delivelement",
#                      func=>'New',
#                      defaultacl=>['valid_user']);

   return($self);
}



1;
