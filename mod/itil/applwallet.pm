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
use Crypt::OpenSSL::X509 qw(FORMAT_PEM FORMAT_ASN1);

use vars qw(@ISA);

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
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

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'wallet.comments'),

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
                filename      =>'sslcertdocname',
                maxsize       =>65533,
                searchable    =>0,
                uploadable    =>0,
                allowempty    =>0,
                allowdirect   =>1,
                dataobjattr   =>'wallet.sslcert'),

      new kernel::Field::Text(
                name          =>'sslcertdocname',
                label         =>'SSL-Certificate-Document Name',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'wallet.sslcertdocname'),

      new kernel::Field::Select(
                name          =>'expnotifyleaddays',
                htmleditwidth =>'280px',
                default       =>'56',
                label         =>'Expiration notify lead time',
                value         =>['14','21','28','56','70'],
                transprefix   =>'EXPNOTIFYLEAD.',
                translation   =>'itil::applwallet',
                dataobjattr   =>'wallet.expnotifyleaddays'),

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
                name          =>'issuerdn',
                label         =>'Issuer DN',
                group         =>'detail',
                htmldetail    =>1,
                readonly      =>1,
                dataobjattr   =>'wallet.issuerdn'),

      new kernel::Field::Text(
                name          =>'altname',
                label         =>'alternate Names',
                group         =>'detail',
                htmldetail    =>"notEmpty",
                readonly      =>1,
                dataobjattr   =>'wallet.altname'),

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


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/certificate.jpg?".$cgi->query_string());
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin support w5base.itil.applwallet.read)])) {
      my $userid=$self->getCurrentUserId();
      my %grps=$self->getGroupsOf($userid,"RMember","up");
      my @grpids=keys(%grps);

      my $applobj=getModuleObject($self->Config,'itil::appl');
      $applobj->SetFilter([{sectarget=>\'base::user',
                            sectargetid=>\$userid,
                            secroles=>"*roles=?write?=roles* ".
                                      "*roles=?privread?=roles*"},
                           {sectarget=>\'base::grp',
                            sectargetid=>\@grpids,
                            secroles=>"*roles=?write?=roles* ".
                                      "*roles=?privread?=roles*"},
                           {databossid=>\$userid},
                           {applmgrid=>\$userid},
                           {tsmid=>\$userid},
                           {tsm2id=>\$userid},
                           {opmid=>\$userid},
                           {opm2id=>\$userid},
                           {semid=>\$userid},
                           {sem2id=>\$userid},
                           {delmgrid=>\$userid},
                           {delmgr2id=>\$userid}]);
      my @secappl=map($_->{id},$applobj->getHashList(qw(id)));

      push(@flt,{applid=>\@secappl});
   }

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


sub parseCertDate
{
   my $self=shift;
   my $certdate=shift;

   my $timestamp=(str2time($certdate)); # convert to Unix timestamp
   return(undef) if(!defined($timestamp));

   my $dt=DateTime->from_epoch(epoch=>$timestamp);
   return($dt->ymd.' '.$dt->hms); # valid mySQL datetime format
}


sub formatedMultiline
{
   my $self=shift;
   my $entryobjs=shift;
   my %elements;
   my $multiline='';

   foreach my $entry (@$entryobjs) {
      my ($key,$val)=split(/=/,$entry->as_string(1));
      $elements{$key}=$val;
   }

   my @keylen=sort({$b<=>$a} map({length} keys(%elements)));

   foreach my $l (sort(keys(%elements))) {
      $multiline.=sprintf("%-*s = %s\n",$keylen[0],$l,$elements{$l});
   }

   return($multiline);
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

   if (effChanged($oldrec,$newrec,"expnotifyleaddays")){
      $newrec->{sslexpnotify1}=undef;
   }


   if (effChangedVal($oldrec,$newrec,'sslcert')) {
      my $sslcertfile=effVal($oldrec,$newrec,"sslcert");
      my $x509;
      # try multiple file formats
      eval('$x509=Crypt::OpenSSL::X509->new_from_string($sslcertfile,
                                                        FORMAT_PEM);');
      if ($@ ne "") {
         eval('$x509=Crypt::OpenSSL::X509->new_from_string($sslcertfile,
                                                           FORMAT_ASN1);');
      }

      if ($@ ne "") {
         $self->LastMsg(ERROR,"Unknown file format");
         return(0);      
      }
   
      # Startdate / Enddate
      my $startdate=$x509->notBefore();
      $newrec->{startdate}=$self->parseCertDate($startdate);

      my $enddate=$x509->notAfter();
      $newrec->{enddate}=$self->parseCertDate($enddate);

      if (!defined($newrec->{startdate}) ||
          !defined($newrec->{enddate})) {
         $self->LastMsg(ERROR,"Validity date is not interpretable");
         return(0);
      }

      # Subject
      my $sobjs=$x509->subject_name->entries();
      $newrec->{subject}=$self->formatedMultiline($sobjs);

      # Issuer
      my $iobjs=$x509->issuer_name->entries();
      $newrec->{issuer}=$self->formatedMultiline($iobjs);

      $newrec->{issuerdn}=$x509->issuer();

      # SerialNr. (hex format)
      $newrec->{serialno}=$x509->serial();


      # Name
      my ($cn)=grep({$_->type() eq 'CN'} @$iobjs);
      if (defined($cn)){
         $newrec->{name}=$cn->value().' - '.$newrec->{serialno};
      }
      else{
         $newrec->{name}="Common Nameless - ".$newrec->{serialno};
      }

      # "Alternative Name" analyse
      my $alternativeNames;

      my $exts;

      eval('$exts=$x509->extensions_by_oid();');
      if ($@){
         msg(WARN,"x509::extensions_by_oid crashed with $@");
      }
      if (ref($exts) eq "HASH"){
         foreach my $oid (keys(%$exts)){
           my $ext=$exts->{$oid};
           if ($oid eq "2.5.29.17"){
              my $val=$ext->value(); 
              if ($ext->can("to_string")){
                 $val=$ext->to_string();
              }
              elsif ($ext->can("as_string")){
                 $val=$ext->as_string();
              }
              $alternativeNames=$val;
           }
         }
      }
      if (defined($alternativeNames)){
         if (!defined($oldrec)){
            $newrec->{altname}=$alternativeNames;
         }
         else{
            if ($oldrec->{altname} ne $alternativeNames){
               $newrec->{altname}=$alternativeNames;
            }
         }
      }
      msg(INFO,"alternativeNames=$alternativeNames");

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


sub isUploadValid
{
   return(0);
}


sub isQualityCheckValid
{
   return(0);
}



1;
