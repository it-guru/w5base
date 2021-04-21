package tssiem::secscan;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use tssiem::lib::Listedit;
use kernel::Field;
@ISA=qw(tssiem::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'ID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>"ref"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Link(
                name          =>'qref',
                label         =>'Qualys Ref',
                group         =>'source',
                dataobjattr   =>"ref"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                ignorecase    =>1,
                label         =>'Title',
                dataobjattr   =>"title"),

      new kernel::Field::Text(                  
                name          =>'applid',             # primär Zuordnung
                label         =>'Application W5BaseID',
                group         =>'source',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"w5baseid_appl"),

      new kernel::Field::Text(
                name          =>'ictono',   # sek Zuordnung (falls keine applid)
                label         =>'ICTO-ID',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"ictoid"),  
                                           
      new kernel::Field::Text(                  
                name          =>'appl',  
                label         =>'Application',
                htmldetail    =>'NotEmpty',
                vjointo       =>\'itil::appl',
                vjoindisp     =>'name',
                vjoinon       =>['applid'=>'id'],
                weblinkto     =>'none'),

      new kernel::Field::Text(
                name          =>'itscanobjectid',
                htmldetail    =>'NotEmpty',
                group         =>'source',
                searchable    =>0,
                label         =>'IT-ScanObjectID',
                dataobjattr   =>"decode(w5baseid_appl,NULL,".
                                "ictoid,w5baseid_appl)"), 

      new kernel::Field::Text(
                name          =>'stype',
                htmlwidth     =>'200px',
                label         =>'Scan type',
                dataobjattr   =>"type"),

      new kernel::Field::Boolean(
                name          =>'islatest',
                htmldetail    =>0,
                label         =>'latest scan',
                dataobjattr   =>"islatest"),

      new kernel::Field::Text(
                name          =>'perspective',
                htmldetail    =>0,
                label         =>'perspective',
                dataobjattr   =>"scanperspective"),

      new kernel::Field::Date(
                name          =>'sdate',
                label         =>'Scan date',
                dataobjattr   =>'launch_datetime'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'DB creation date',
                dataobjattr   =>'creationdate'),

      new kernel::Field::Text(
                name          =>'sduration',
                label         =>'Scan duration',
                group         =>'results',
                sqlorder      =>'ASC',
                dataobjattr   =>"to_char(duration,'HH24:MI')"),

      new kernel::Field::SubList(
                name          =>'secents',
                label         =>'Security Entries',
                group         =>'results',
                vjointo       =>'tssiem::secent',
                htmllimit     =>30,
                forwardSearch =>1,
                vjoinbase     =>[{pci_vuln=>'yes',severity=>[4,5]}],
                vjoinon       =>['qref'=>'qref'],
                vjoindisp     =>['ipaddress','port','name']),

      new kernel::Field::Number(
                name          =>'secentcnt',
                label         =>'SecEnt count',
                readonly      =>1,
                group         =>'results',
                htmldetail    =>0,
                uploadable    =>0,
                dataobjattr   =>"(select count(*) from W5SIEM_secent ".
                                "where secscan.ref=W5SIEM_secent.ref ".
                                " and W5SIEM_secent.pci_vuln='yes' and ".
                                "  W5SIEM_secent.severity in (4,5))"),

      new kernel::Field::Textarea(
                name          =>'starget',
                label         =>'Scan Target',
                dataobjattr   =>"target"),

      new kernel::Field::File(
                name          =>'pdfstdfull',
                label         =>'PDF Report Standard Full',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{pdfstdfull_valid}){
                      return(1);
                   }
                   return(0);
                },
                types         =>['pdf'],
                mimetype      =>'pdfstdfull_mime',
                filename      =>'pdfstdfull_name',
                group         =>'results',
                dataobjattr   =>'pdfstdfull'),

      new kernel::Field::Link(
                name          =>'pdfstdfull_mime',
                label         =>'PDF Standard Full mime',
                group         =>'results',
                dataobjattr   =>"'application/pdf'"),

      new kernel::Field::Boolean(
                name          =>'pdfstdfull_valid',
                selectfix     =>'1',
                htmldetail    =>0,
                group         =>'results',
                label         =>'PDF Standard Full valid',
                dataobjattr   =>"decode(pdfstdfull_level,'2',1,0)"),

      new kernel::Field::Link(
                name          =>'pdfstdfull_name',
                label         =>'PDF Standard Full name',
                group         =>'results',
                dataobjattr   =>"('Qualys_'||ictoid||".
                                "'_'||".
                                "to_char(launch_datetime,'YYYYMMDDHH24MISS')||".
                                "'_standard_full'||'.pdf')"),

      new kernel::Field::File(
                name          =>'pdfstddelta',
                label         =>'PDF Report Standard Delta',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{pdfstddelta_valid}){
                      return(1);
                   }
                   return(0);
                },
                types         =>['pdf'],
                mimetype      =>'pdfstddelta_mime',
                filename      =>'pdfstddelta_name',
                group         =>'results',
                dataobjattr   =>'pdfstddelta'),

      new kernel::Field::Link(
                name          =>'pdfstddelta_mime',
                label         =>'PDF Standard Delta mime',
                group         =>'results',
                dataobjattr   =>"'application/pdf'"),

      new kernel::Field::Boolean(
                name          =>'pdfstddelta_valid',
                selectfix     =>'1',
                htmldetail    =>0,
                group         =>'results',
                label         =>'PDF Standard Delta valid',
                dataobjattr   =>"decode(pdfstddelta_level,'2',1,0)"),

      new kernel::Field::Link(
                name          =>'pdfstddelta_name',
                label         =>'PDF Standard Delta name',
                group         =>'results',
                dataobjattr   =>"('Qualys_'||ictoid||".
                                "'_'||".
                                "to_char(launch_datetime,'YYYYMMDDHH24MISS')||".
                                "'_standard_delta'||'.pdf')"),

      new kernel::Field::File(
                name          =>'pdfvfwifull',
                label         =>'PDF Report SmiplifiedFW Full',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{pdfvfwifull_valid}){
                      return(1);
                   }
                   return(0);
                },
                types         =>['pdf'],
                mimetype      =>'pdfvfwifull_mime',
                filename      =>'pdfvfwifull_name',
                group         =>'results',
                dataobjattr   =>'pdfvfwifull'),

      new kernel::Field::Link(
                name          =>'pdfvfwifull_mime',
                label         =>'PDF SmiplifiedFW Full mime',
                group         =>'results',
                dataobjattr   =>"'application/pdf'"),

      new kernel::Field::Boolean(
                name          =>'pdfvfwifull_valid',
                selectfix     =>'1',
                htmldetail    =>0,
                group         =>'results',
                label         =>'PDF SmiplifiedFW Full valid',
                dataobjattr   =>"decode(pdfvfwifull_level,'2',1,0)"),

      new kernel::Field::Link(
                name          =>'pdfvfwifull_name',
                label         =>'PDF SmiplifiedFW Full name',
                group         =>'results',
                dataobjattr   =>"('Qualys_'||ictoid||".
                                "'_'||".
                                "to_char(launch_datetime,'YYYYMMDDHH24MISS')||".
                                "'_SmiplifiedFW_full'||'.pdf')"),

      new kernel::Field::File(
                name          =>'pdfvfwidelta',
                label         =>'PDF Report SmiplifiedFW Delta',
                searchable    =>0,
                uploadable    =>0,
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{pdfvfwidelta_valid}){
                      return(1);
                   }
                   return(0);
                },
                types         =>['pdf'],
                mimetype      =>'pdfvfwidelta_mime',
                filename      =>'pdfvfwidelta_name',
                group         =>'results',
                dataobjattr   =>'pdfvfwidelta'),

      new kernel::Field::Link(
                name          =>'pdfvfwidelta_mime',
                label         =>'PDF SmiplifiedFW Delta mime',
                group         =>'results',
                dataobjattr   =>"'application/pdf'"),

      new kernel::Field::Boolean(
                name          =>'pdfvfwidelta_valid',
                selectfix     =>'1',
                htmldetail    =>0,
                group         =>'results',
                label         =>'PDF SmiplifiedFW Delta valid',
                dataobjattr   =>"decode(pdfvfwidelta_level,'2',1,0)"),

      new kernel::Field::Link(
                name          =>'pdfvfwidelta_name',
                label         =>'PDF SmiplifiedFW Delta name',
                group         =>'results',
                dataobjattr   =>"('Qualys_'||ictoid||".
                                "'_'||".
                                "to_char(launch_datetime,'YYYYMMDDHH24MISS')||".
                                "'_SmiplifiedFW_delta'||'.pdf')"),

      new kernel::Field::TextDrop(
                name          =>'applmgr',
                group         =>'contact',
                label         =>'ApplicationManager',
                vjointo       =>'TS::appl',
                weblinkto     =>'NONE',
                vjoinbase     =>{cistatusid=>"<6",applmgrid=>'!""'},
                vjoinon       =>['itscanobjectid'=>'id'],
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my @flt=($flt);
                   if ($current->{applid} eq "" &&
                       $current->{ictono} ne ""){
                      @flt=({ictono=>\$current->{ictono}});
                   }
                   return(@flt);
                },
                vjoindisp     =>'applmgr'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"'Qualys'"),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'ref'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'importdate'),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(sdate ictono appl name sduration secentcnt));
   $self->setWorktable("secscan");
   $self->BackendSessionName("W5SIEM_secscan_LongRead");  # try to force dedicated Session
                                                          # because lonReadLen and 
                                                          # cursor_sharing=force
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;

   my $secscansql=$self->getSecscanFromSQL();
   my $from="($secscansql) secscan";

   return($from);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_islatest"))){
     Query->Param("search_islatest"=>$self->T("yes"));
   }
   #if (!defined(Query->Param("search_sdate"))){
   #  Query->Param("search_sdate"=>">now-3M");
   #}
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.tssiem.secscan.read)],
                          "RMember")){
      my @addflt;
      $self->addICTOSecureFilter(\@addflt);
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}







sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default",'contact',"results","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tssiem/load/qualys_secscan.jpg?".$cgi->query_string());
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
