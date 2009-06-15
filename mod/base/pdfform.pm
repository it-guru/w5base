package base::pdfform;
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
use LWP::Simple;
use PDF::Reuse;
use File::Temp qw(tempfile);
use kernel;
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

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
                align         =>'left',
                label         =>'Formular ID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Formular description',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $lang=$self->getParent->Lang();
                   return($current->{langname}->{$lang});

                }),
      new kernel::Field::Text(
                name          =>'url',
                label         =>'PDF Source URL'),

      new kernel::Field::Textarea(
                name          =>'code',
                label         =>'Programmcode',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $instdir=$self->getParent->Config->Param("INSTDIR");
                   $id=~s/::/\//g;
                   my $d="?";
                   my $file="$instdir/mod/$id.pm";
                   if (-f $file){
                      if (open(F,"<$file")){
                         $d=join("",<F>);
                         close(F);
                      }
                   }
                   return($d);
                }),

   );
   $self->LoadSubObjs("form","form");
   $self->{'data'}=[];
   foreach my $obj (values(%{$self->{form}})){
      my $name=$obj->Self();
      my $r={id=>$obj->Self,url=>$obj->{url}};
      foreach my $lang ($self->LangTable()){
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
         $r->{langname}->{$lang}=$self->T($name,$name);   
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
      push(@{$self->{'data'}},$r);
   }
   $self->setDefaultView(qw(linenumber id name target));
   return($self);
}

sub getDefaultHtmlDetailPage
{
   return("Form");
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return("Form"=>$self->T("Form fill"),
          $self->SUPER::getHtmlDetailPages($p,$rec));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "Form");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "Form"){
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
            "src=\"Form?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub prAreaText
{
   my ($x1,$y1,$width,$heigh,$border,$text)=@_;

   my $string = "q\n";  # a rectangle
   $string.= "$x1 $y1 $width $heigh re\n";  # a rectangle
   $string.= "0 1 1 rg\n";           # blue (to fill)
   #$string.= "q 0 95 m 700 95 l S Q\n";  # draw a line
   if (!$border){
      $string.= "1 1 1 RG\n";           # border color
   }
   $string.= "1 1 1 rg\n";           # fill color
   $string.= "b\nQ\n";                  # fill and stroke
   prAdd($string);
   prText( $x1+4, $y1+4,$text);
}


sub Form
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my $id=Query->Param("id");
   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($current,$msg)=$self->getOnlyFirst(qw(ALL));
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
   my $o=getModuleObject($self->Config,$id);
   $o->setParent($self);
   delete($self->{'FrontendFieldOrder'});
   delete($self->{'FrontendField'});
   $o->AddFrontendFields();

   my $form={};
   my $formdata=$urec->{formdata};
   if (!ref($urec->{formdata})){
      $formdata={Datafield2Hash($urec->{formdata})};
   }

   if (Query->Param("DOIT") && defined($current)){
      my $F=Query->MultiVars();
      foreach my $n (keys(%$F)){
         if (my ($name)=$n=~m/^Formated_(.*)$/){
            $form->{$name}=trim($F->{$n});
         }
      }
      if ($o->Validate($form)){
         my $url=$current->{url};
         my $pdf=get($url);
         if ($pdf ne "" && ($pdf=~m/^\%PDF/)){
            my $filename=$id.".pdf";
            $filename=~s/::/./g;
            print $self->HttpHeader("application/pdf",attachment=>1,
                                                      filename=>$filename);
            my ($fsrc, $src) = tempfile();
            my ($fdst, $dst) = tempfile();
            print $fsrc ($pdf);
            close($fsrc);
            my $left=1;
            my $pageNumber=0;
            prFile($dst);
            {
               no strict;
               *{$id."::prAreaText"}=\&{"base::pdfform::prAreaText"};
               foreach my $f (qw(prFontSize)){
                  *{$id."::$f"}=\&{"PDF::Reuse::$f"};
               }
            }
            while ($left){   
               $pageNumber++;
               $o->Fill($form,$pageNumber);
               $left = prSinglePage($src);
            }
            prEnd();
            my $needstore=0;
            foreach my $v (keys(%$form)){
               if (!exists($urec->{$v})){
                  if ($formdata->{$v} ne $form->{$v}){
                     $formdata->{$v}=$form->{$v};
                     $needstore++;
                  }
               }
            }
            if ($needstore){
               $user->ValidatedUpdateRecord($urec,{formdata=>$formdata},
                                            {userid=>\$urec->{userid}});
            }
            if (open(F,"<$dst")){
               print join("",<F>);
               close(F);
            }
            return();
         }
         else{
            $self->LastMsg(ERROR,"can not fetch source pdf");
         }
      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"unknown problem");
         }
      }
   }
   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"online form",
                           js=>['toolbox.js'],
                           form=>1,
                           body=>1,
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'Output.HtmlDetail.Simple.css']);
   if (defined($current)){
      my %f=();
      if (!Query->Param("DOIT")){
         foreach my $name (keys(%{$urec})){
            $f{"Formated_".$name}=$urec->{$name} if (!ref($urec->{$name}) &&
                                                     $urec->{$name} ne "");
         }
         my $grp=$self->getInitiatorGroupsOf($userid);
         $f{"Formated_team"}=$grp;
         foreach my $k (keys(%$formdata)){
            $f{"Formated_".$k}=$formdata->{$k};
         }
         $o->InitForm(\%f);
         foreach my $v (keys(%f)){
            Query->Param($v=>$f{$v});
         }
      }
      my $d=$self->T("Form").": <b><a title=\"".
            $self->T("use this link to reference this ".
            "record (f.e. in mail)")."\" ".
            "target=_top href=\"ById/$id\">%name%</a></b><br>";
      $d.="<div style=\"margin:5px\" id=Form>".$o->Form()."</div>";
    
    
      $d.=sprintf("<div id=FormControl>".
                  '%LASTMSG%'.
                  "<center><input name=DOIT type=submit value=\"%s\"></center>".
                  "</div>",
             $self->T("gernerate formular"));
      $d.=$self->HtmlPersistentVariables("id");

      my $fieldbase=$self->getFieldHash();  # add dynamic
      my %localfieldbase=%{$fieldbase};                # local fieldbase
      if (defined($self->{FrontendField})){
         foreach my $fname (keys(%{$self->{FrontendField}})){
            $localfieldbase{$fname}=$self->{FrontendField}->{$fname};
         }
      }
    
      $self->ParseTemplateVars(\$d,{current          =>$current,
                                    mode             =>'workflow',
                                    fieldbase        =>\%localfieldbase,
                                    editgroups       =>['ALL'],
                                    viewgroups       =>['ALL']});
    
      print $d;
      delete($self->{FrontendField});
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(Form));
}





sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  

1;
