package base::ext::InstallCheck;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getMandatoryModules
{
   my $self=shift;


   return qw(RPC::Smart::Server RPC::Smart::Client 
             DBI CGI String::Diff DBD::mysql
             Fcntl Socket File::Temp IO::Select
             Env::C Safe Sys::Hostname);
}

sub getOptionalModules
{
   my $self=shift;
   # Digest/SHA1 for mysql server interface

   return qw(Spreadsheet::WriteExcel::Big 
             Spreadsheet::ParseExcel Spreadsheet::ParseExcel::Utility
             DTP JSON PDF::Reuse Spreadsheet::ParseExcel::Workbook
             Digest::SHA1 HTML::TreeBuilder  HTML::FormatText
             pdflib_pl DTP::pdf Archive::Zip
             Apache::DBI FCGI
             GD DTP::jpg DTP::png
             Proc::ProcessTable);
}

sub doSpecialCheck
{
   my $self=shift;


   return(undef);        # or return a array of ERROR / WARN messages 
}





1;
