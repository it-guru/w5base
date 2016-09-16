package itil::applwallet;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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

use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use itil::lib::Listedit;
use Date::Parse;
use DateTime;
use File::Temp ();
use Net::SSLeay qw(XN_FLAG_MULTILINE XN_FLAG_RFC2253);

use vars qw(@ISA);

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'wallet.id'),

      new kernel::Field::Text(
                name          =>'shortdesc',
                htmlwidth     =>'150px',
                label         =>'Brief description',
                dataobjattr   =>'wallet.shortdesc'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'name'),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'Application ID',
                dataobjattr   =>'wallet.applid'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),
                
      new kernel::Field::File(
                name          =>'sslcert',
                label         =>'Certificate file',
                types         =>['crt','cer','pem','der'],
                mimetype      =>'sslcertdoctype',
                filename      =>'sslcertdocname',
                uploaddate    =>'sslcertdocdate',
                maxsize       =>65533,
                searchable    =>0,
                uploadable    =>0,
                dataobjattr   =>'wallet.sslcert'),

      new kernel::Field::Text(
                name          =>'sslcertdocname',
                label         =>'SSL-Certificate-Document Name',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'wallet.sslcertdocname'),

      new kernel::Field::Date(
                name          =>'sslcertdocdate',
                label         =>'SSL-Certificate-Document Date',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'wallet.sslcertdocdate'),

      new kernel::Field::Text(
                name          =>'sslcertdoctype',
                label         =>'SSL-Certificate-Document Type',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'wallet.sslcertdoctype'),

      new kernel::Field::Date(
                name          =>'sslexpnotify1',
                history       =>0,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'Notification of Certificate Expiration',
                dataobjattr   =>'wallet.exp_notify1'),

      new kernel::Field::Date(
                name          =>'startdate',
                label         =>'Certificate begin',
                group         =>'detail',
                readonly      =>1,
                dataobjattr   =>'wallet.startdate'),

      new kernel::Field::Date(
                name          =>'enddate',
                label         =>'Certificate end',
                group         =>'detail',
                readonly      =>1,
                dataobjattr   =>'wallet.enddate'),

      new kernel::Field::Textarea(
                name          =>'subject',
                label         =>'Owner',
                group         =>'detail',
                readonly      =>1,
                dataobjattr   =>'wallet.subject'),

      new kernel::Field::Textarea(
                name          =>'issuer',
                label         =>'Issuer',
                group         =>'detail',
                readonly      =>1,
                dataobjattr   =>'wallet.issuer'),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serial Nr.',
                group         =>'detail',
                readonly      =>1,
                dataobjattr   =>'wallet.serialno'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'wallet.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'wallet.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'wallet.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'wallet.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'wallet.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'wallet.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'wallet.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(wallet.id,35,'0')"),

   );
   $self->setDefaultView(qw(linenumber shortdesc enddate appl name));
   $self->setWorktable('wallet');
   return($self);
}

sub parseCertDate
{
   my $self=shift;
   my $certdate=shift;

   my $timestamp=(str2time($certdate)); # convert to Unix timestamp
   return(undef) if(!defined($timestamp));

   my $dt=DateTime->from_epoch(epoch=>$timestamp);
   return($dt->ymd.' '.$dt->hms); # valid mySQL datetime format
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my @secappl;
   my $userid=$self->getCurrentUserId();

   my $lnkcontactobj=getModuleObject($self->Config,'base::lnkcontact');
   $lnkcontactobj->SetFilter({target=>\'base::user',
                              targetid=>\$userid,
                              parentobj=>\'itil::appl',
                              croles=>"*roles=?write?=roles* ".
                                      "*roles=?privread?=roles*"});
   my @authcontacts=$lnkcontactobj->getHashList(qw(refid));
   
   foreach my $lnkcontact (@authcontacts) {
      push(@secappl,$lnkcontact->{refid});
   }
   push(@flt,{applid=>\@secappl});

   return($self->SetFilter(@flt));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->itil::lib::Listedit::isWriteOnApplValid(
                                       $rec->{applid},"technical")) {
      return("default");
   }

   return(undef);
}


sub isUploadValid
{
   return(0);
}


sub isQualityCheckValid
{
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,'shortdesc') eq '') {
      $self->LastMsg(ERROR,"No brief description specified");
      return(0);
   }

   if (effVal($oldrec,$newrec,'applid') eq '') {
      $self->LastMsg(ERROR,"No application specified");
      return(0);
   }

   if (effVal($oldrec,$newrec,'sslcert') eq '') {
      $self->LastMsg(ERROR,"No certificate file selected");
      return(0);
   }

   if (!$self->itil::lib::Listedit::isWriteOnApplValid(
                                       $newrec->{applid},"technical")) {
      $self->LastMsg(ERROR,"No write access on specified application");
      return(0);
   }

   if (effChangedVal($oldrec,$newrec,'sslcert')) {
      # generate tmpfile from sslcert; needed by Net::SSLeay
      my $tmpfile=new File::Temp(UNLINK=>1);
      print $tmpfile ($newrec->{sslcert});
      seek($tmpfile,0,0); # reset file position
      my $bio=Net::SSLeay::BIO_new_file($tmpfile,'rb');
      my $x509=Net::SSLeay::PEM_read_bio_X509($bio);
   
      # Startdate / Enddate
      my $date=Net::SSLeay::X509_get_notBefore($x509);
      my $notBefore=Net::SSLeay::P_ASN1_TIME_get_isotime($date);
      $newrec->{startdate}=$self->parseCertDate($notBefore);

      $date=Net::SSLeay::X509_get_notAfter($x509);
      my $notAfter=Net::SSLeay::P_ASN1_TIME_get_isotime($date);
      $newrec->{enddate}=$self->parseCertDate($notAfter);

      if (!defined($newrec->{startdate}) ||
          !defined($newrec->{enddate})) {
         $self->LastMsg(ERROR,"Validity date is not interpretable");
         return(0);
      }

      # Subject
      my $subject=Net::SSLeay::X509_get_subject_name($x509);
      $newrec->{subject}=Net::SSLeay::X509_NAME_print_ex($subject,
                                                         XN_FLAG_MULTILINE);
      # Issuer
      my $issuer_name=Net::SSLeay::X509_get_issuer_name($x509);
      $newrec->{issuer}=Net::SSLeay::X509_NAME_print_ex($issuer_name,
                                                        XN_FLAG_MULTILINE);
      # SerialNr. (hex format)
      my $serial=Net::SSLeay::X509_get_serialNumber($x509);
      $newrec->{serialno}=Net::SSLeay::P_ASN1_INTEGER_get_hex($serial);

      # Name
      my $nameoneline=Net::SSLeay::X509_NAME_print_ex($issuer_name,
                                               XN_FLAG_RFC2253);
      my %nameelements=split(/[=,]/,$nameoneline);
      $newrec->{name}=$nameelements{CN}.' - '.$newrec->{serialno};

      # check if already expired
      my $duration=CalcDateDuration(NowStamp('en'),$newrec->{enddate});

      if ($duration->{days}<7) {
         my $msg='Certificate expires soon';
         if ($duration->{totalseconds}<0) {
            $msg='Certificate has already expired';
         }
         $self->LastMsg(ERROR,$msg);

         return(0);
      }
   }

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default detail source));
}



1;
