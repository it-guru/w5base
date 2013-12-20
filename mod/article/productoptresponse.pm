package article::productoptresponse;
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
use article::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
   $self->{UseSqlReplace}=1,

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                searchable    =>0,
                dataobjattr   =>'artprodoptresponse.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'parentproduct',
                htmlwidth     =>'80px',
                readonly      =>1,
                label         =>'relevant standard Product',
                vjointo       =>'article::product',
                vjoinon       =>['parentproductid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'parentproductid',
                readonly      =>1,
                label         =>'Delivery-ProductID',
                dataobjattr   =>'artprodoptresponse.partproduct'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'part',
                htmlwidth     =>'120px',
                dataobjattr   =>'artprodoptresponse.name'),

      new kernel::Field::Text(
                name          =>'response',
                label         =>'Responsible',
                htmlwidth     =>'100px',
                dataobjattr   =>
                   "concat('C:',artprodoptresponse.raci_contactor,".
                   "' - S:',artprodoptresponse.raci_orderer)"),

      new kernel::Field::Text(
                name          =>'raci_supplier',
                label         =>'RACI:Supplier',
                htmlwidth     =>'130px',
                dataobjattr   =>'artprodoptresponse.raci_contactor'),

      new kernel::Field::Text(
                name          =>'raci_customer',
                label         =>'RACI:Customer',
                htmlwidth     =>'130px',
                dataobjattr   =>'artprodoptresponse.raci_orderer'),

      new kernel::Field::Textarea(
                name          =>'description',
                searchable    =>0,
                htmlwidth     =>'300px',
                label         =>'Explanation',
                dataobjattr   =>'artprodoptresponse.description'),

      new kernel::Field::Select(
                name          =>'frequency',
                label         =>'Frequency',
                transprefix   =>'F.',
                value         =>['perm',
                                 'day',
                                 'week',
                                 'month',
                                 'anno',
                                 'once',
                                 'req'],
                htmlwidth     =>'100px',
                dataobjattr   =>'artprodoptresponse.frequency'),


      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'artprodoptresponse.comments'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artprodoptresponse.modifyuser'),
                                   
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'artprodoptresponse.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artprodoptresponse.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artprodoptresponse.realeditor'),

   );
   $self->setDefaultView(qw(product delivelement cdate));
   $self->setWorktable("artprodoptresponse");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/artprodopttoken.jpg?".$cgi->query_string());
#}
         


sub getDetailBlockPriority
{  
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default liccontractinfo source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/^\s*$/ || length($name)<5){
      $self->LastMsg(ERROR,"invalid part '%s' specified",$name);
      return(undef);
   }
   $newrec->{'name'}=$name if (exists($newrec->{'name'}));
   my $pid=effVal($oldrec,$newrec,"parentproductid");
   if (!$self->article::lib::Listedit::isWriteOnProductValid($pid,"response")){
      $self->LastMsg(ERROR,"no write access to product");
      return(undef);
   }
   return(1);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   
   return("default") if (!defined($oldrec));

   my $pid=$oldrec->{parentproductid};
   if ($self->article::lib::Listedit::isWriteOnProductValid($pid,"response")){
      return("default");
   }
   return(undef);
}





1;
