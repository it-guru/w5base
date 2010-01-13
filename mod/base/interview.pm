package base::interview;
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
use kernel::InterviewField;
use Text::ParseWhere;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::InterviewField
        kernel::CIStatusTools);

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
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'QuestionID',
                dataobjattr   =>'interview.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'interviewcat',
                label         =>'Interview categorie',
                vjointo       =>'base::interviewcat',
                vjoinon       =>['interviewcatid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'interviewcatid',
                label         =>'Interview categorie id',
                dataobjattr   =>'interview.interviewcat'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Question',
                dataobjattr   =>'interview.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'interview.cistatus'),

      new kernel::Field::Link(
                name          =>'contactid',
                dataobjattr   =>'interview.contact'),

      new kernel::Field::Link(
                name          =>'contact2id',
                dataobjattr   =>'interview.contact2'),

      new kernel::Field::Contact(
                name          =>'contact',
                label         =>'Contact',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   my $userid=$self->getParent->getCurrentUserId();
                   return(0) if ($self->getParent->IsMemberOf("admin"));
                   return(1) if ($userid==$rec->{$self->{name}."id"});
                   return(0);
                },
                vjoinon       =>'contactid'),

      new kernel::Field::Contact(
                name          =>'contact2',
                label         =>'Deputy Contact',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   my $userid=$self->getParent->getCurrentUserId();
                   return(1) if ($userid==$rec->{$self->{name}."id"});
                   return(0);
                },
                vjoinon       =>'contact2id'),

      new kernel::Field::Text(
                name          =>'qtag',
                group         =>'tech',
                label         =>'unique query tag',
                dataobjattr   =>'interview.qtag'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'tech',
                label         =>'parent Ojbect',
                dataobjattr   =>'interview.parentobj'),

      new kernel::Field::Boolean(
                name          =>'effect_on_mttr',
                label         =>'effects on MTTR',
                group         =>'tech',
                htmlhalfwidth =>1,
                dataobjattr   =>'effectonmttr'),

      new kernel::Field::Boolean(
                name          =>'effect_on_mtbf',
                label         =>'effects on MTBF',
                htmlhalfwidth =>1,
                group         =>'tech',
                dataobjattr   =>'effectonmtbf'),

      new kernel::Field::Link(
                name          =>'queryblock',
                label         =>'Questiongroup',
                dataobjattr   =>'interviewcat.fullname'),

      new kernel::Field::Text(
                name          =>'questclust',
                label         =>'Questiongroup',
                dataobjattr   =>'interview.questclust'),

      new kernel::Field::Select(
                name          =>'prio',
                value         =>['', qw(1 2 3)],   # 1-3 are need to answer
                transprefix   =>'QPRIO.',
                htmleditwidth =>'130px',
                label         =>'Question prio',
                dataobjattr   =>'interview.prio'),

      new kernel::Field::Select(
                name          =>'questtyp',
                transprefix   =>'QT.', 
                htmleditwidth =>'250px',
                value         =>['percent','percenta','text',
                                 'boolean','booleana'],
                label         =>'Question Typ',
                dataobjattr   =>'interview.questtyp'),


#
#  answer sufficient = yes         attainment level = 100% if an answer exists
#
#  else
#  questtyp  boolean    0 =   0%
#                       1 = 100%
#
#  questtyp  text       stringlen >  0    = 100%
#                       stringlen == 0    = 0%
#
#  questtyp  percent    answer = percent value
#
#  prio 1     = the same as 10 answers
#  prio 2     = the same as  3 answers
#  prio 3     = 1 answer
#  prio undef = ignored by calc of attainment level
#

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'interview.comments'),

      new kernel::Field::Textarea(
                name          =>'restriction',
                group         =>'tech',
                label         =>'restriction',
                dataobjattr   =>'interview.restriction'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'interview.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'interview.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'interview.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'interview.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'interview.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'interview.realeditor'),

   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(linenumber interviewcat name mdate));
   $self->setWorktable("interview");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec)){
      if (!$self->IsMemberOf("admin")){
         my $userid=$self->getCurrentUserId();
         $newrec->{contactid}=$userid;
      }
   }

   return(1);
}


sub isCopyValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   if ($self->isWriteValid()){
      return(1);
   }
   return(0);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if (length($name)<10 || ($name=~m/^\s*$/i)){
      $self->LastMsg(ERROR,"invalid question specified"); 
      return(undef);
   }
   my $qtag=effVal($oldrec,$newrec,"qtag");
   if (($qtag=~m/\s/i) || length($qtag)<3){
      $self->LastMsg(ERROR,"invalid unique query tag specified"); 
      return(undef);
   }
  # my $questclust=trim(effVal($oldrec,$newrec,"questclust"));
  # if ($questclust=~m/^\s*$/i){
  #    $self->LastMsg(ERROR,"invalid question group specified"); 
  #    return(undef);
  # }
   my $rest=effVal($oldrec,$newrec,"restriction");
   if ($rest ne ""){
      my $p=new Text::ParseWhere();
      if (!defined($p->compileExpression($rest))){
         $self->LastMsg(ERROR,"invalid restriction expression"); 
         return(undef);
      }
   }
   my $prio=effVal($oldrec,$newrec,"prio");
   if ($prio eq ""){
      $newrec->{prio}=undef;
   }

   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   if (!($parentobj=~m/^\S+::\S+/)){
      $self->LastMsg(ERROR,"invalid name of parentobj"); 
      return(undef);
   }
   my $chk=getModuleObject($self->Config,$parentobj);
   if (!defined($chk)){
      $self->LastMsg(ERROR,"parentobj not found"); 
      return(undef);
   }
   my $io=$chk->getField("interview");
   if (!defined($io)){
      $self->LastMsg(ERROR,"parentobj not prepaired for interview handling"); 
      return(undef);
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"qtag"));
   return(1);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join interviewcat ".
          "on $worktable.interviewcat=interviewcat.id ");
}



sub prepUploadRecord
{
   my $self=shift;
   my $newrec=shift;

   if (!exists($newrec->{id}) || $newrec->{id} eq ""){
      if (exists($newrec->{qtag}) && $newrec->{qtag} ne ""){
         my $i=getModuleObject($self->Config,"base::interview");
         $i->SetFilter({qtag=>\$newrec->{qtag}});
         my ($rec,$msg)=$i->getOnlyFirst(qw(id));
         if (defined($rec)){
            $newrec->{id}=$rec->{id};
         }
      }
   }


   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","tech") if (!defined($rec));
   return("ALL");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return($self->isWriteValid($rec)) if ($self->IsMemberOf("admin"));
   return(undef); 
}
sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
  
   my $userid=$self->getCurrentUserId();
   if (!defined($rec)){
      return("default","tech") if ($self->IsMemberOf("admin"));
      my $o=$self->Clone();
      $o->SetFilter({contactid=>\$userid});
      my ($rec,$msg)=$o->getOnlyFirst(qw(id));
      if (defined($rec)){
         return("default","tech");
      }
     
      return(undef);
   }


   return("default","tech") if ($rec->{contactid}==$userid ||
                                $rec->{contact2id}==$userid ||
                                $self->IsMemberOf("admin"));
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}


sub checkParentWrite
{
   my $self=shift;
   my $pobj=shift;
   my $prec=shift;

   my @rw=$pobj->isWriteValid($prec);
   my $rw=0;
   $rw=1 if (grep(/^interview$/,@rw));
   return($rw);
}

sub checkAnserWrite
{
   my $self=shift;
   my $parentrw=shift;
   my $irec=shift;
   my $pobj=shift;
   my $prec=shift;

   my $userid=$self->getCurrentUserId();
   #printf STDERR ("fifi w=%s\n",Dumper($irec));
   if ($irec->{contactid}==$userid ||
       $irec->{contact2id}==$userid){  # allow always the contact to answer
      return(1);
   }


   return($parentrw);
}

sub getHtmlEditElements
{
   my $self=shift;
   my $write=shift;
   my $irec=shift;
   my $answer=shift;
   my $iid=$irec->{id};
   my ($HTMLanswer,$HTMLrelevant,$HTMLcomments);

   if ($write){
      $HTMLrelevant="<select name=relevant onchange=submitChange(this) >".
                    "<option value=\"1\">Ja</option>";
      if (defined($answer) && !($answer->{relevant})){
         $HTMLrelevant.="<option selected value=\"0\">Nein</option>";
      }
      else{
         $HTMLrelevant.="<option value=\"0\">Nein</option>";
      }
      $HTMLrelevant.="</select>";
   }
   else{
      if (defined($answer) && $answer->{relevant}){
         $HTMLrelevant="Ja";
      }
      elsif (defined($answer) && !($answer->{relevant})){
         $HTMLrelevant="Nein";
      }
      else{
         $HTMLrelevant="?";
      }
   }
   $HTMLcomments="<textarea name=comments onchange=submitChange(this) ".
                 "rows=2 style=\"width:100%\">$answer->{comments}</textarea>";
   $HTMLanswer=" - ? - ";
   if ($irec->{questtyp} eq "boolean" ||
       $irec->{questtyp} eq "booleana"){
      my $a=$answer->{answer};
      my $sel="<select name=answer onchange=submitChange(this) ".
              "style=\"width:80px\">";
      
      $sel.="<option ";
      $sel.="value=\"\"></option>";

      $sel.="<option ";
      $sel.="selected " if ($a==1);
      $sel.="value=\"1\">".$self->T("yes")."</option>";

      $sel.="<option ";
      $sel.="selected " if ($a!=1 && $a ne "");
      $sel.="value=\"0\">".$self->T("no")."</option>";

      $sel.="</select>";
      my $p="<table class=Panswer><tr><td align=center>$sel</td></tr></table>";
      $HTMLanswer="<div style=\"width:100%;padding:1px;margin:0\">$p</div>";
   }
   if ($irec->{questtyp} eq "percent" ||
       $irec->{questtyp} eq "percenta"){
      my $a=int($answer->{answer}/10);
      my $p="";
      my $sel="<select name=answer onchange=submitChange(this) ".
              "style=\"width:55px\">";
      for(my $c=0;$c<11;$c++){
         $sel.="<option ";
         $sel.="selected " if ($c==$a);
         $sel.="value=\"".($c*10)."\">".($c*10)."%</option>";
         my $class="class=Pseg1";
         $class="class=Pseg0" if ($c>$a|| $a==0);
         my $tdclass="class=Panswer";
         if ($c==0){
            $tdclass.=" style=\"width:5%\"";
         }
         
         $p.="<td $tdclass><div onclick=setA('$iid',".($c*10).
             ") $class></div></td>";
      }
      $sel.="</select>";
      $p="<table class=Panswer><tr><td>$sel</td>$p</tr></table>";
      $HTMLanswer="<div style=\"width:100%;padding:1px;margin:0\">$p</div>";
   }
   elsif ($irec->{questtyp} eq "text"){
      my $p="<input style=\"width:100%\" ".
            "type=text onchange=submitChange(this) name=answer ".
            "value=\"$answer->{answer}\">";
      $HTMLanswer="<div style=\"width:100%;padding:1px;margin:0\">$p</div>";
   }

   return($HTMLanswer,$HTMLrelevant,$HTMLcomments);
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"Question");
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;
   if (!defined($rec)){ 
      return($self->SUPER::getHtmlDetailPages($p,$rec));
   }
   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "Question"=>$self->T("Question-Info"));
}

sub Question
{
   my $self=shift;
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader();
   print $self->HtmlHeader(body=>1,
                           js=>'toolbox.js',
                           style=>['default.css',
                                   'kernel.App.Web.css',
                                   'kernel.App.Web.DetailPage.css']);
   printf("<div style=\"margin-left:5px\">");
   printf("<h2>%s:</h2>",$self->T("Interview Question Details"));
   printf("<h3 style=\"margin-top:20px\">%s</h3>",$rec->{name});

   printf("<div style=\"border-width:1px;border-style:solid;".
          "border-color:silver;margin-top:20px;".
          "padding-bottom:10px;margin-right:10px\">");
   my $c=quoteHtml($rec->{comments});
   $c=~s/\n/<br>\n/g;
   printf("<div style=\"margin:5px;margin-top:5px\">".
          "<b>%s:</b><br>%s</div>",$self->T("explanation"),$c);


   my $contact=$self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                   "contact","formated");
   if ($rec->{contact} ne ""){
      printf("<div style=\"margin:5px;margin-top:20px\">".
             "<b>%s:</b><br>%s</div>",
             $self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                 "contact","label"),$contact);
   }

   my $contact2=$self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                   "contact2","formated");
   if ($rec->{contact2} ne ""){
      printf("<div style=\"margin:5px;margin-top:20px\">".
             "<b>%s:</b><br>%s</div>",
             $self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                 "contact2","label"),$contact2);
   }
   print("</div>");


   print $self->HtmlBottom(body=>1);


}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "Question");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "Question"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"Question?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","tech","source");
}











1;
