package base::useremail;
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
                label         =>'E-Mail ID',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0) if (!defined($param{current}));
                   return(1);
                },
                align         =>'left',
                htmlwidth     =>'250',
                dataobjattr   =>'contact.userid'),
                                  
      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                readonly      =>0,
                searchable    =>1,
                align         =>'left',
                htmlwidth     =>'250',
                dataobjattr   =>'contact.email'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0 AND <7"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'contactfullname',
                label         =>'Contact',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),
                                  
      new kernel::Field::Interface(
                name          =>'userid',
                label         =>'UserID',
                wrdataobjattr =>'contact.pcontact',
                dataobjattr   =>"contact.pcontact"),
                                  
      new kernel::Field::Text(
                name          =>'emailtyp',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(0) if (!defined($param{current}));
                   return(1);
                },
                label         =>'Type',
                dataobjattr   =>"contact.usertyp"),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                label         =>'Surname',
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'surname'),
                                  
      new kernel::Field::Link(
                name          =>'usertyp',
                dataobjattr   =>"contact.usertyp"),
                                  
      new kernel::Field::Link(
                name          =>'fullname',
                dataobjattr   =>"contact.fullname"),
                                  
      new kernel::Field::Text(
                name          =>'givenname',
                label         =>'Givenname',
                htmldetail    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'givenname'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'contact.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'contact.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'contact.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'contact.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>'contact.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'contact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'contact.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'contact.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'contact.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"contact.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(contact.userid,35,'0')"),
                                  
   );
   $self->setWorktable("contact");
   $self->setDefaultView(qw(email cistatus emailtyp contactfullname));
   return($self);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
}


sub allowHtmlFullList
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}

sub allowFurtherOutput
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();

   my $precision0="";
   my $precision1="";
   my $precision2="";
   my $precision3="";
   if ($mode eq "select"){
      my ($worktable,$workdb)=$self->getWorktable();
      $workdb=$self->{DB} if (!defined($workdb));
      foreach my $filter (@filter){
         if (ref($filter) eq "HASH" && defined($filter->{userid})){
            if (!ref($filter->{userid})){
               $precision0.="and pcontact='$filter->{userid}' ";
               $precision1.="and userid='$filter->{userid}' ";
               $precision2.="and lnkcontact.targetid='$filter->{userid}' ";
               $precision3.="and baseuser.userid='$filter->{userid}' ";
            }
         }
         if (ref($filter) eq "HASH" && defined($filter->{email})){
            if (!ref($filter->{email}) &&
                !($filter->{email}=~m/[\*\?\s]/)){
               my $e="email=".$workdb->quotemeta(lc($filter->{email}))." ";
               $precision0.="and a.$e ";
               $precision1.="and b.$e ";
               $precision2.="and c.$e ";
               $precision3.="and d.$e ";
            }
            if (ref($filter->{email}) eq "ARRAY"){
               if ($#{$filter->{email}}==0){
                  my $e="email=".$workdb->quotemeta(lc($filter->{email}))." ";
                  $precision1.="and a.$e ";
                  $precision1.="and b.$e ";
                  $precision2.="and c.$e ";
                  $precision3.="and d.$e ";
               }
            }
         }
      }
   }

   my $from="(".
            "select  a.email, a.cistatus, a.userid,a.pcontact, ".
                    "'alternate' usertyp,".
                    "a.fullname, a.createdate, a.modifydate,".
                    "a.createuser, a.modifyuser,".
                    "a.editor, a.realeditor,a.srcsys,a.srcload,a.srcid ".
            "from contact as a where usertyp='altemail' ".$precision0.
            " union ".
            "select  b.email, b.cistatus, b.userid,b.userid pcontact, ".
                    "'primary' usertyp,".
                    "b.fullname, b.createdate, b.modifydate,".
                    "b.createuser, b.modifyuser,".
                    "b.editor, b.realeditor,b.srcsys,b.srcload,b.srcid ".
            "from contact as b where usertyp<>'altemail' ".$precision1.
            " union ".
            "select  c.email, c.cistatus, c.userid,".
                    "lnkcontact.targetid pcontact,".
                    "'alternatefrom' usertyp,".
                    "c.fullname, c.createdate, c.modifydate, c.createuser,".
                    "c.modifyuser,".
                    "c.editor, c.realeditor,c.srcsys,c.srcload,c.srcid ".
            "from contact as c join lnkcontact ".
                 "on c.userid=lnkcontact.refid and ".
                 "lnkcontact.parentobj='base::user' and ".
                 "(lnkcontact.expiration is null or ".
                  "lnkcontact.expiration<now()) and ".
                 "lnkcontact.croles like \"\%roles='useasfrom'=roles\%\" ".
            " where c.cistatus in ('4') ".$precision2.
            " union ".
            "select  d.email, d.cistatus, d.userid,".
                    "baseuser.userid pcontact,".
                    "'alternatefrom' usertyp,".
                    "d.fullname, d.createdate, d.modifydate, d.createuser,".
                    "d.modifyuser,".
                    "d.editor, d.realeditor,d.srcsys,d.srcload,d.srcid ".
            "from contact baseuser ".
            " join lnkgrpuser on baseuser.userid=lnkgrpuser.userid ".
                                " and (lnkgrpuser.expiration is null ".
                                "   or lnkgrpuser.expiration<now()) ".
            " join grp on grp.grpid=lnkgrpuser.grpid ".
            " join lnkcontact on grp.grpid=lnkcontact.targetid ".
                 " and lnkcontact.parentobj='base::user' ".
                 " and lnkcontact.target='base::grp' ".
                 " and (lnkcontact.expiration is null or ".
                       "lnkcontact.expiration<now()) ".
                 " and lnkcontact.croles like \"\%roles='useasfrom'=roles\%\" ".
            " join contact as d  ".
                 "on d.userid=lnkcontact.refid  ".
            " where d.cistatus in ('4') ".$precision3.
            ") as contact";

   return($from);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   $newrec->{fullname}='- ('.effVal($oldrec,$newrec,"email").")";
   $newrec->{usertyp}='altemail';
   if (effVal($oldrec,$newrec,"userid") eq ""){
      $self->LastMsg(ERROR,"none or invalid contact specified");
      return(0);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(default header)) if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if ($rec->{emailtyp} eq "primary");
   return(undef) if ($rec->{emailtyp} eq "alternatefrom");
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
