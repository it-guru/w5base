package AL_TCom::smatrix;
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
                dataobjattr   =>'AL_TCom_smatrix.id'),

      new kernel::Field::TextDrop(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                searchable    =>0,
                name          =>'applname',
                readonly      =>1,
                group         =>"appl",
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'cistatus',
                readonly      =>1,
                group         =>"appl",
                label         =>'CI-Status',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'cistatus'),

      new kernel::Field::TextDrop(
                name          =>'conumber',
                readonly      =>1,
                group         =>"appl",
                label         =>'CO-Number',
                vjointo       =>'itil::costcenter',
                vjoinon       =>['colink'=>'name'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'colink',
                label         =>'CO-Number',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'conumber'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                readonly      =>1,
                htmlwidth     =>'250px',
                group         =>"appl",
                label         =>'Delivery Manager',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                label         =>'DeM ID',
                vjointo       =>'itil::costcenter',
                vjoinon       =>['colink'=>'name'],
                vjoindisp     =>'delmgrid'),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'AL_TCom_smatrix.appl'),

      new kernel::Field::Select(
                name          =>'splattform',
                label         =>'Service-Plattform',
                selectwidth   =>'200px',
                value         =>["",
                                 "SUN Solaris",
                                 "AIX",
                                 "HP-UX",
                                 "Linux",
                                 "Windows",
                                 "AppCom",
                                 "Storage",
                                 "Backup and Restore",
                                 "ICS/Network",
                                 "ICS/DCI-Infra (DeM)",
                                 "GCC/SeP (Standort)"],
                dataobjattr   =>'AL_TCom_smatrix.splattform'),

                                                   
      new kernel::Field::TextDrop(
                name          =>'tgu',
                htmlwidth     =>'250px',
                label         =>'TGU Contact',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserID',
                dataobjattr   =>'AL_TCom_smatrix.userid'),
                                                   
      new kernel::Field::Link(
                name          =>'tel',
                label         =>'Tel',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'AL_TCom_smatrix.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'AL_TCom_smatrix.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'AL_TCom_smatrix.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'AL_TCom_smatrix.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'AL_TCom_smatrix.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'AL_TCom_smatrix.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name conumber splattform tgu delmgr));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("AL_TCom_smatrix");
   return(1);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ($newrec->{splattform}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid service plattform");
      return(0);
   }
   if ($newrec->{applid}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid application specified");
      return(0);
   }
   if ($newrec->{userid}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid contact specified");
      return(0);
   }

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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Overview),$self->SUPER::getValidWebFunctions());
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_; 
   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "Overview"=>$self->T("Overview"));
}

sub Overview
{
   my $self=shift;
   my %param=@_;

   $self->ProcessDataModificationOP();
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my $output=new kernel::Output($self);
   $self->SetCurrentView(qw(ALL));
   $param{WindowMode}="Detail";
   if (!($output->setFormat("HtmlGraphics",%param))){
      msg(ERROR,"can't set output format 'HtmlDetail'");
      return();
   }
   $output->WriteToStdout(HttpHeader=>1);
}



sub HtmlGraphics
{
   my $self=shift;
   my ($rec,$jid,$viewgroups,$fieldbase,$WindowMode)=@_;
   my $srec=$self->getPersistentModuleObject("DeRec","AL_TCom::smatrix");
   my $code="";
   
   my @pos=(
              { x=>10,  y=>0,   width=>180, height=>80 },
              { x=>210, y=>0,   width=>180, height=>80 },
              { x=>410, y=>0,   width=>180, height=>80 },
              { x=>0,   y=>105, width=>160, height=>80 },
              { x=>440, y=>105, width=>160, height=>80 },
              { x=>10,  y=>210, width=>180, height=>80 },
              { x=>210, y=>210, width=>180, height=>80 },
              { x=>410, y=>210, width=>180, height=>80 },
              { x=>10,  y=>310, width=>180, height=>80 },
              { x=>210, y=>310, width=>180, height=>80 },
              { x=>410, y=>310, width=>180, height=>80 },
           );
   $srec->ResetFilter();
   $srec->SetFilter({applid=>\$rec->{applid}});
   my @l=$srec->getHashList(qw(ALL));
   my @rank=(0,1,2,3,4,5,6,7,8,9,10);
   @rank=(5,7,8,10,6,9) if ($#l<6);
   @rank=(0,2,5,7) if ($#l<4);
   my $jslines="";

   foreach my $rec (@l){
      my $rank=shift(@rank);
      my $pos=$pos[$rank];
      my $color="#99CCFF";
      $color="#66CC99" if ($rec->{splattform}=~m/ICS/);
      $color="#FFFF99" if ($rec->{splattform}=~m/Storage/);
      $color="#FFFF99" if ($rec->{splattform}=~m/Backup/);
      next if (!defined($rank) || !defined($pos));
      my $tgu=$rec->{tgu};
      $tgu=~s/\(/<br>(/;
      $code.=<<EOF;
<div style="position:absolute;width:$pos->{width}px;
            padding:1px;overflow:hidden;z-index:4;
            height:$pos->{height}px;left:$pos->{x}px;top:$pos->{y}px;
            background:$color;
            border-style:solid;border-width:1px;">
<table width=100%>
<tr><td align=left colspan=2><b>$rec->{splattform}</b></td></tr>
<tr><td valign=top width=1% nowrap>$tgu</td></tr>
<tr><td valign=top width=1%>$rec->{tel}</td></tr>
</table>
</div>
EOF
      my $x=$pos->{x}+0.5*$pos->{width};
      my $y=$pos->{y}+0.5*$pos->{height};
      $jslines.="jg.setColor(\"$color\");\n";
      $jslines.="jg.drawLine(300,150,$x,$y);\n";
   }
   $code.=<<EOF;
<div style="position:absolute;width:250px;
            padding:3px;z-index:4;
            height:90px;left:175px;top:100px;
            background:white;
            border-style:solid;border-width:1px;">
<table width=100%>
<tr><td align=center colspan=2><b><u>$rec->{name}</u></b></td></tr>
<tr><td valign=top width=1% nowrap>CO-Nummer:</td><td>$rec->{conumber}</td></tr>
<tr><td valign=top width=1% nowrap>Del. Mgr.:</td><td>$rec->{delmgr}</td></tr>
</table>
</div>

<script language="JavaScript">
function Draw$jid(){
var $jid = document.getElementById("$jid");
var jg = new jsGraphics($jid);
jg.setPrintable(true);
jg.setStroke(3);
$jslines
jg.paint();
}
addEvent(window,"load",Draw$jid);
</script>
EOF
   return(600,400,$code);
}
   
sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   my $page="";
   if ($p eq "Overview"){
      my $idname=$self->IdField->Name();
      my $idval=$rec->{$idname};
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"Overview?$urlparam\"></iframe>";
      return($page);
   }

   return($page.$self->SUPER::getHtmlDetailPageContent($p,$rec));
}  






1;
