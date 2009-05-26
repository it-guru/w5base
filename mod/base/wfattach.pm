package base::wfattach;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'wfattach.wfattachid'),
                                                  
      new kernel::Field::Text(
                name          =>'wfheadid',
                label         =>'WorkflowID',
                dataobjattr   =>'wfattach.wfheadid'),

      new kernel::Field::File(
                name          =>'data',
                label         =>'Data',
                dataobjattr   =>'wfattach.data'),

      new kernel::Field::Text(
                name          =>'wfactionid',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   if ($current->{wfactionid} ne ""){
                      return(1);
                   }
                   return(0);
                },
                group         =>'source',
                label         =>'ActionID',
                dataobjattr   =>'wfattach.wfdataid'),

      new kernel::Field::Text(
                name          =>'name',
                group         =>'source',
                label         =>'Filename',
                dataobjattr   =>'wfattach.filename'),

      new kernel::Field::Text(
                name          =>'contenttype',
                group         =>'source',
                label         =>'Content-Type',
                dataobjattr   =>'wfattach.mimetype'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'wfattach.createdate'),
                                                  
      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wfattach.createuser'),

   );
   $self->setDefaultView(qw(linenumber name groupname cistatus cdate mdate));
   $self->setWorktable("wfattach");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{data})){
      my $fname=$newrec->{data};
      my $ui=CGI::uploadInfo($fname);
      #printf STDERR ("fifi uploadInfo=%s\n",Dumper(CGI::uploadInfo($fname)));
      if (defined($ui)){
         if (!defined($newrec->{name})){
            $newrec->{name}=$fname;
         }
         if ($ui->{'Content-Type'} ne ""){
            $newrec->{contenttype}=$ui->{'Content-Type'};
         }
         no strict;
         my $f=$newrec->{data};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>5242880){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{data}=$pic;
      }
      else{
         msg(INFO,"no upload info found");
      }
   }


   my $name=trim(effVal($oldrec,$newrec,"name"));
   $name=~s/^.*[\/\\]//;
   if ($name=~m/^\s*$/i){
      $self->LastMsg(ERROR,"invalid filename '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (!defined($rec)){
      return("default") if ($self->IsMemberOf("admin"));
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1);
}





1;
