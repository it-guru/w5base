package base::menu::default;
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

   $self->RegisterObj("MyW5Base",
                      "base::MyW5Base",
                      prio=>'1',
                      func=>'Main',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("MyW5Base.userenv",
                      "base::user",
                      func=>'MyDetail',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm",
                      "tmpl/sysadm.welcome",
                      prio=>2,
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv",
                      "base::user",
                      func=>'MyDetail',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.userenv.userview",
                      "base::userview",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.infoabo",
                      "base::infoabo",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.bookmarks",
                      "base::userbookmark",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.bookmarks.new",
                      "base::userbookmark",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.userenv.note",
                      "base::note",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user",
                      "base::user");
   
   $self->RegisterObj("sysadm.user.new",
                      "base::user",
                      func=>'New');
   
   $self->RegisterObj("sysadm.user.subst",
                      "base::usersubst",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.user.mailsig",
                      "base::mailsignatur",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.user.mailsig.new",
                      "base::mailsignatur",
                      defaultacl=>['admin'],
                      func=>'New');
   
   $self->RegisterObj("sysadm.user.userview",
                      "base::userview",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.infoabo",
                      "base::infoabo",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.email",
                      "base::useremail",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.querybreak",
                      "base::userquerybreak",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.import",
                      "base::user",
                      func=>'ImportUser',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.grp.import",
                      "base::grp",
                      func=>'ImportOrgarea',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.grp.grpindivfld",
                      "base::grpindivfld",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.lnkcontact",
                      "base::lnkcontact",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.lnkuserinteranswer",
                      "base::lnkuserinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.blacklist",
                      "base::userblacklist",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.advice",
                      "base::useradvice",
                      func=>'Main',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.user.plug",
                      "base::w5plug",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.user.plug.lnkuser",
                      "base::lnkuserw5plug",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.useraccount",
                      "base::useraccount",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.useraccount.new",
                      "base::useraccount",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.useraccount.logon",
                      "base::userlogon",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.grp",
                      "base::grp");
   
   $self->RegisterObj("sysadm.grp.new",
                      "base::grp",
                      func=>'New');
   
   $self->RegisterObj("sysadm.grp.treecreate",
                      "base::grp",
                      func=>'TreeCreate');
   
   $self->RegisterObj("sysadm.grp.rel",
                      "base::lnkgrpuser",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.grp.rel.role",
                      "base::lnkgrpuserrole",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu",
                      "base::menu",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu.new",
                      "base::menu",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.menu.acl",
                      "base::menuacl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.mandator",
                      "base::mandator");
   
   $self->RegisterObj("sysadm.mandator.new",
                      "base::mandator",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.mandator.lnkmandatorcontact",
                      "base::lnkmandatorcontact",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.mandator.dataacl",
                      "base::mandatordataacl");

   $self->RegisterObj("sysadm.mandator.dataacl.new",
                      "base::mandatordataacl",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location",
                      "base::location");
   
   $self->RegisterObj("sysadm.location.new",
                      "base::location",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.lnklocationcontact",
                      "base::lnklocationcontact",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.lnklocationinteranswer",
                      "base::lnklocationinteranswer",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.location.lnklocationgrp",
                      "base::lnklocationgrp",
                      func=>'MainWithNew',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.country",
                      "base::isocountry",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.country.new",
                      "base::isocountry",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.currency",
                      "base::isocurrency",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.currency.new",
                      "base::isocurrency",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.googlekeys",
                      "base::googlekeys",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.googlekeys.new",
                      "base::googlekeys",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.location.campus",
                      "base::campus",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.location.campus.new",
                      "base::campus",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.filesig",
                      "base::filesig",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.filesig.signedfile",
                      "base::signedfile",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.history",
                      "base::history",
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.blacklist",
                      "base::blacklist",
                      func=>'Main',
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.blacklist.new",
                      "base::blacklist",
                      func=>'New',
                      defaultacl=>['admin']);

   $self->RegisterObj("Tools",
                      "tmpl/welcome",
                      prio=>10,
                      param=>'MSG=Hallo%20dies%20ist%20die%20Nachricht',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.explore",
                      "base::Explore",
                      prio=>1,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow",
                      "base::workflow",
                      prio=>1,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflownew",
                      "base::workflow",
                      func=>'New',
                      prio=>2,
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.itemizedlist",
                      "base::itemizedlist",
                      func=>'MainWithNew',
                      prio=>4000,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.action",
                      "base::workflowaction",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.action.x",
                      "base::workflowxaction",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.repjob",
                      "base::workflowrepjob",
                      prio=>2000,
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.repjob.new",
                      "base::workflowrepjob",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.relation",
                      "base::workflowrelation",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.relation.new",
                      "base::workflowrelation",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.key",
                      "base::workflowkey",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.ws",
                      "base::workflowws",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workflow.ws.new",
                      "base::workflowws",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workproc",
                      "base::workprocess",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.workproc.new",
                      "base::workprocess",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.workproc.item",
                      "base::workprocessitem",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.teamtools",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.webnotify",
                      "base::WebNotify",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.teamtools.forms",
                      "base::pdfform",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.projectroom",
                      "base::projectroom",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.projectroom.new",
                      "base::projectroom",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.filemgmt",
                      "base::filemgmt",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.filemgmt.new",
                      "base::filemgmt",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.filemgmt.acl",
                      "base::fileacl",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.filebrowser",
                      "base::filemgmt",
                      func=>'browser');
   
   $self->RegisterObj("sysadm.qmgmt",
                      "tmpl/welcome.qmgmt",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.qmgmt.qrule",
                      "base::qrule",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.qmgmt.interview",
                      "base::interview",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.qmgmt.interview.new",
                      "base::interview",
                      func=>'New',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.qmgmt.interview.cat",
                      "base::interviewcat",
                      func=>'MainWithNew',
                      defaultacl=>['valid_user']);

   $self->RegisterObj("sysadm.qmgmt.interview.todocache",
                      "base::interviewtodocache",
                      defaultacl=>['admin']);

   $self->RegisterObj("sysadm.qmgmt.interanswer",
                      "base::interanswer",
                      defaultacl=>['admin']);
   
   
   $self->RegisterObj("sysadm.qmgmt.qrule.lnkmandator",
                      "base::lnkqrulemandator",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.qmgmt.qrule.lnkmandator.new",
                      "base::lnkqrulemandator",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.qmgmt.iomap",
                      "base::iomap",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.qmgmt.iomap.new",
                      "base::iomap",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.analytics",
                      "tmpl/welcome",
                      defaultacl=>['valid_user']);

   $self->RegisterObj("Tools.analytics.w5stat",
                      "base::w5stat",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.analytics.w5stat.master",
                      "base::w5statmaster",
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.analytics.w5stat.master.new",
                      "base::w5statmaster",
                      func=>'New',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("Tools.analytics.fields",
                      "base::reflexion_fields",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.analytics.dataobj",
                      "base::reflexion_dataobj",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.analytics.translation",
                      "base::reflexion_translation",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.XLSExpand",
                      "base::XLSExpand",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.translation",
                      "base::TextTranslation",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("Tools.translation.acronym",
                      "base::TextTranslation",
                      func=>'Text2Acronym',
                      defaultacl=>['valid_user']);
   
   $self->RegisterObj("sysadm.eventhandling",
                      "base::joblog",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.eventhandling.joblog",
                      "base::joblog",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.eventhandling.router",
                      "base::eventrouter",
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.eventhandling.router.net",
                      "base::eventrouter",
                      func=>'New',
                      defaultacl=>['admin']);
   
   $self->RegisterObj("sysadm.mailreqspool",
                      "base::mailreqspool",
                      defaultacl=>['admin']);
   
   $self->RegisterObj('base::workflow::interflow$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=base::workflow::interflow',
                      defaultacl=>['admin']);

   $self->RegisterObj('base::workflow::diary$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=base::workflow::diary',
                      defaultacl=>['admin']);

   $self->RegisterObj('base::workflow::task$',
                      "base::workflow",
                      func=>'New',
                      param=>'WorkflowClass=base::workflow::task',
                      defaultacl=>['admin']);

   $self->RegisterObj("Reporting",
                      "base::w5stat",
                      func=>'Presenter/Main',
                      prio=>'9999999',
                      defaultacl=>['valid_user']);
   
   return(1);
}





1;
