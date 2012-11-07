package itil::lnkapplappl;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'lnkapplappl.id'),

      new kernel::Field::TextDrop(
                name          =>'fromappl',
                htmlwidth     =>'250px',
                label         =>'from Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['fromapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'toappl',
                htmlwidth     =>'150px',
                label         =>'to Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['toapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'contype',
                label         =>'Interfacetype',
                htmlwidth     =>'250px',
                transprefix   =>'contype.',
                value         =>[qw(0 1 2 3 4 5)],
                default       =>'0',
                htmleditwidth =>'350px',
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Select(
                name          =>'conmode',
                label         =>'Interfacemode',
                value         =>[qw(online batch manuell)],
                default       =>'online',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conmode'),

      new kernel::Field::Select(
                name          =>'conproto',
                label         =>'Interfaceprotocol',
                value         =>[qw( unknown 
                     BCV CAPI Corba DB-Connection DB-Link dce DCOM DSO 
                     ftp html http https IMAP IMAPS IMAP4 
                     jdbc ldap LDIF MAPI 
                     MFT MQSeries Netegrity NFS ODBC OSI openFT
                     papier pkix-cmp POP3 POP3S 
                     rcp rfc RMI RPC rsh sftp sldap smtp snmp
                     ssh tuxedo TCP UC4 UCP/SMS utm X.31 XAPI xml
                     OTHER)],
                default       =>'online',
                htmlwidth     =>'50px',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conprotocol'),


      new kernel::Field::Htmlarea(
                name          =>'htmldescription',
                searchable    =>0,
                group         =>'desc',
                label         =>'Interface description',
                dataobjattr   =>'lnkapplappl.description'),

      new kernel::Field::SubList(
                name          =>'interfacescomp',
                label         =>'Interface components',
                group         =>'interfacescomp',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplapplcomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'lnkapplappl'],
                vjoindisp     =>['name','namealt1','namealt2',"comments"]),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplappl.comments'),

      new kernel::Field::Text(
                name          =>'fromurl',
                group         =>'comdetails',
                label         =>'from URL',
                dataobjattr   =>'lnkapplappl.fromurl'),

      new kernel::Field::Text(
                name          =>'fromservice',
                group         =>'comdetails',
                label         =>'from Servicename',
                dataobjattr   =>'lnkapplappl.fromservice'),

      new kernel::Field::Text(
                name          =>'tourl',
                group         =>'comdetails',
                label         =>'to URL',
                dataobjattr   =>'lnkapplappl.tourl'),

      new kernel::Field::Text(
                name          =>'toservice',
                group         =>'comdetails',
                label         =>'to Servicename',
                dataobjattr   =>'lnkapplappl.toservice'),

      new kernel::Field::Select(
                name          =>'monitor',
                group         =>'comdetails',
                label         =>'Interface Monitoring',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitor'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitor',
                group         =>'comdetails',
                label         =>'raw Interface Monitoring',
                dataobjattr   =>'lnkapplappl.monitor'),

      new kernel::Field::Select(
                name          =>'monitortool',
                group         =>'comdetails',
                label         =>'Interface Monitoring Tool',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitortool'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitortool',
                group         =>'comdetails',
                label         =>'raw Interface Monitoring Tool',
                dataobjattr   =>'lnkapplappl.monitortool'),

      new kernel::Field::Select(
                name          =>'monitorinterval',
                group         =>'comdetails',
                label         =>'Interface Monitoring Interval',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitorinterval'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitorinterval',
                group         =>'comdetails',
                label         =>'raw Interface Monitoring Interval',
                dataobjattr   =>'lnkapplappl.monitorinterval'),

      new kernel::Field::Text(
                name          =>'implapplversion',
                group         =>'impl',
                label         =>'implemented since "from"-application release',
                dataobjattr   =>'lnkapplappl.implapplversion'),

      new kernel::Field::Text(
                name          =>'implproject',
                group         =>'impl',
                label         =>'implementation project name',
                dataobjattr   =>'lnkapplappl.implproject'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkapplappl.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappl.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappl.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappl.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappl.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappl.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkapplappl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkapplappl.realeditor'),

      new kernel::Field::Link(
                name          =>'fromapplid',
                label         =>'from ApplID',
                dataobjattr   =>'lnkapplappl.fromappl'),

      new kernel::Field::Link(
                name          =>'lnktoapplid',
                label         =>'to ApplicationID',
                dataobjattr   =>'toappl.applid'),

      new kernel::Field::Link(
                name          =>'toapplid',
                label         =>'to ApplID',
                dataobjattr   =>'lnkapplappl.toappl'),

      new kernel::Field::Link(
                name          =>'toapplcistatus',
                label         =>'to Appl CI-Status',
                dataobjattr   =>'toappl.cistatus'),

      new kernel::Field::Link(
                name          =>'fromapplcistatus',
                label         =>'from Appl CI-Status',
                dataobjattr   =>'fromappl.cistatus'),

   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(id fromappl toappl cdate editor));
   $self->setWorktable("lnkapplappl");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplappl ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id ".
            "left outer join appl as fromappl ".
            "on lnkapplappl.fromappl=fromappl.id";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
   if ($fromapplid==0){
      $self->LastMsg(ERROR,"invalid from application");
      return(0);
   }
   my $toapplid=effVal($oldrec,$newrec,"toapplid");
   if ($toapplid==0){
      $self->LastMsg(ERROR,"invalid to application");
      return(0);
   }
   my $fromservice=effVal($oldrec,$newrec,"fromservice");
   if ($fromservice ne "" &&
       ($fromservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in from service name");
      return(0);
   }

   my $toservice=effVal($oldrec,$newrec,"toservice");
   if ($toservice ne "" &&
       ($toservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in to service name");
      return(0);
   }
   my $fromurl=effVal($oldrec,$newrec,"fromurl");
   if ($fromurl ne "" &&
       !(($fromurl=~m/^[a-z]+:\/\/\S+?\/.*$/) &&
         ($fromurl=~m/^[a-z]+:\/\/\S+\/\S+\@\S+\/.*$/))){
      $self->LastMsg(ERROR,"invalid notation of the from URL");
      return(0);
   }
   my $tourl=effVal($oldrec,$newrec,"tourl");
   if ($tourl ne "" &&
       !($tourl=~m/^[a-z]+:\/\/\S+\/.*$/) &&
       !($tourl=~m/^[a-z]+:\/\/\S+\/\S+\@\S+\/.*$/)){
      $self->LastMsg(ERROR,"invalid notation of the to URL");
      return(0);
   }



   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $oldrec->{toapplid}!=$toapplid)){
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(cistatusid));
      if (!defined($applrec) || 
          $applrec->{cistatusid}>4 || $applrec->{cistatusid}==0){
         $self->LastMsg(ERROR,"selected application is currently unuseable");
         return(0);
      }
   }

   my $applid=effVal($oldrec,$newrec,"fromapplid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"interfaces")){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }
   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default desc comdetails impl interfacescomp source));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applid=effVal($oldrec,$newrec,"fromapplid");
   my @editgroup=("default","interfacescomp","desc","comdetails","impl");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnApplValid($applid,"interfaces"));
   return(@editgroup) if (!$self->isDataInputFromUserFrontend());

   return(undef);
}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $viewgroups=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist=$self->SUPER::getRecordHtmlIndex($rec,$id,$viewgroups,
                                                  $grouplist,$grouplabel);
   push(@indexlist,{label=>$self->T('Interface agreement'),
           href=>"InterfaceAgreement?id=$id",
           target=>"_blank"
          });

   return(@indexlist);
}

sub InterfaceAgreement
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'public/itil/load/lnkapplappl.css'],
                           body=>1,form=>1,
                           title=>$self->T("Interface agreement"));
   print("<div class=lnkdocument>");
   my $id=Query->Param("id");
   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($masterrec,$msg)=$self->getOnlyFirst(qw(fromapplid toapplid));
   if (defined($masterrec)){
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{fromapplid}});
      my ($ag1,$msg)=$appl->getOnlyFirst(qw(name id tsm));
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{toapplid}});
      my ($ag2,$msg)=$appl->getOnlyFirst(qw(name id tsm));
      my @l=($ag1,$ag2);
      @l=sort({$a->{name} cmp $b->{cmp}} @l);
      my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
      my $n="../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string();

      print("<table width=100% border=0 cellspacing=0 cellpadding=0><tr>");
      print("<td width=20% align=left><img class=logo src='$n'></td>");
      print("<td>");
      print ("<h1>Schnittstellenvereinbarungen zwischenden Anwendungen<br> ".
             $l[0]->{name}." und ".$l[1]->{name}."</h1>");
      print("</td>");
      print("<td width=20% align=right>&nbsp;</td>");
      print("</tr></table>");
      print("<div class=doc>");
      print("<div class=disclaimer>");
      print("Dieses Dokument beschreibt die im Config-Management hinterlegten ".
            "Kommunikationsbeziehnungen zwischen den o.g. Anwendungen. ".
            "Das Modul zur automatischen Generierung einer ".
            "Schnittstellenvereinbarung ist akuell nur in deutscher ".
            "Sprache vorhanden. Sollte die Notwendigkeit für ein ".
            "englischsprachiges Schnittstellendokument vorliegen, ".
            "so muß dies als Entwicklerrequest angefordert werden.");
      print("</div>");
      $l[0]->{targetid}=$l[1]->{id};
      $l[1]->{targetid}=$l[0]->{id};
      $l[0]->{targetname}=$l[1]->{name};
      $l[1]->{targetname}=$l[0]->{name};
      $self->ResetFilter();
      $self->SetFilter([{fromapplid=>\$l[0]->{id},
                         toapplid=>\$l[0]->{targetid}},
                        {fromapplid=>\$l[1]->{id},
                         toapplid=>\$l[1]->{targetid}}]);
      my @iflist=$self->getHashList(qw(cdate mdate 
                                       fromapplid toapplid contype 
                                       conmode conproto
                                       htmldescription comments));
      my %com=();
      foreach my $ifrec (@iflist){
         $ifrec->{key}=$ifrec->{fromapplid}."_".$ifrec->{toapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $ifrec->{revkey}=$ifrec->{toapplid}."_".$ifrec->{fromapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $com{$ifrec->{key}}++;
      }
      foreach my $ifrec (@iflist){
         $ifrec->{partnerok}=0;
         if (exists($com{$ifrec->{revkey}})){
            $ifrec->{partnerok}=1;
         }
      }
      foreach my $ctrl (@l){
         $ctrl->{interface}=[];
         foreach my $ifrec (@iflist){
            if ($ifrec->{fromapplid} eq $ctrl->{id}){
               push(@{$ctrl->{interface}},$ifrec);
            }
         }
      }
      print("<ol type='I' class=appl>");
      foreach my $ctrl (@l){
         printf("<li><b>Definition der Schnittstelle aus Sicht '%s'</b><br>",
                 $ctrl->{name});
         printf("<p class=applheader>".
                "Für die Anwendung '%s' ist der Technical Solution Manager ".
                "'%s' für die Vereinbarungen der Kommunikationsbeziehungen ".
                "verantwortlich. In den folgenden Absätzen wird die ".
                "die Sichtweise der Schnittstellen und die Rahmenbedinungen ".
                "für dessen Funktion aus Sicht des Betreibers der Anwendung ".
                "xxx beschrieben.<br><br></p>",$ctrl->{name},$ctrl->{tsm});
         printf("<p>Die Verbindungen in Richtung '%s' im Einzelnen:</p>",
               $ctrl->{targetname});
        # print "<xmp>".Dumper($ctrl)."</xmp>";
         if ($#{$ctrl->{interface}}!=-1){
            print("<ol class=lnkapplappl type='a'>");
            foreach my $ifrec (@{$ctrl->{interface}}){
               printf("<li><b>%s-Kommunikation mittels <u>%s</u> zur ".
                     "Anwendung '%s'</b><br>",
                     $ifrec->{conmode},$ifrec->{conproto},$ctrl->{targetname});
               if ($ifrec->{comments} ne ""){
                  printf("<div class=comments>%s</div>",$ifrec->{comments});
               }
               if ($ifrec->{htmldescription} ne ""){
                  printf("<div class=htmldescription>%s</div>",
                         $ifrec->{htmldescription});
               }
               if (!($ifrec->{partnerok})){
                  print("<p class=attention>"); 
                  printf("<b>ACHTUNG:</b> Für diese ".
                         "Kommunikationsbeziehung ".
                         "liegen auf Seiten der Anwendung '%s' keine ".
                         "Dokumentationen vor!",
                         $ctrl->{targetname});
                  print("</p>"); 
               }
            }
            print("</ol>");
         }
         else{
            printf("<p class=attention>".
                   "Es liegen keine Schnittstellendefinitionen bei der ".
                   "Anwendung '%s' für die Kommunikation mit der ".
                   "Anwendung '%s' vor.</p>",$ctrl->{name},$ctrl->{targetname});
         }
         print("</li>");
      }
      print("</ol>");
      print("</div>");
      print("<div class=disclaimer>");
      printf("Alle Informationen dieses Dokumentes entsprechen dem Stand %s ".
             "im ITIL-Configuration-Management.",NowStamp("en")); 
      print("</div>");
      print("<div class=subscriber>");
      print("<table class=subscriber width=100%>");
      print("<tr height=50>");
      print("<td width=50%>&nbsp;</td>");
      print("<td width=50%>&nbsp;</td>");
      print("</tr>");
      print("<tr>");
      printf("<td width=50% align=center>Datum, Unterschrift TSM '%s'</td>",$l[0]->{name});
      printf("<td width=50% align=center>Datum, Unterschrift TSM '%s'</td>",$l[1]->{name});
      print("</tr>");
      print("</table>");
      print("</div>");
   }
   print("</div>");
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(InterfaceAgreement));
}







1;
