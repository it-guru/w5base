package kernel::App::Web::Listedit;
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
use kernel::config;
use kernel::App::Web;
use kernel::App::Web::History;
use kernel::App::Web::WorkflowLink;
use kernel::App::Web::InterviewLink;
use kernel::Output;
use kernel::Input;
use kernel::TabSelector;
@ISA    = qw(kernel::App::Web kernel::App::Web::History 
             kernel::App::Web::WorkflowLink);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{IsFrontendInitialized}=0;
   $self->{ResultLineClickHandler}="Detail";
   return($self);
}  

sub ModuleObjectInfo
{
   my $self=shift;
   my $format=Query->Param("FormatAs");
   my $jsonok=0;
   my $json={};
   my $JSON;

   eval("use JSON;\$JSON=new JSON;");
   if ($@ eq ""){
      $jsonok=1;
      $JSON->utf8(1);
   }

   $format="HtmlV01" if ($format eq "");


   if ($format ne "HtmlV01" && 
       (!$jsonok || ($format ne "nativeJSON" && $format ne "JSONP"))){
      print $self->HttpHeader("text/html",'code'=>'404');
      print("<html><h1>404 Not Found</h1></html>");
      return(undef);
   }

   
   if ($format eq "HtmlV01"){ 
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css',
                                      'kernel.App.Web.ModuleObjectInfo.css'],
                              js=>['toolbox.js'],
                              title=>$self->T('Module Object Information'),
                              form=>1);
   }
   else{
      print $self->HttpHeader("application/javascript");

   }
   $self->doInitialize();
   $json->{dataobj}=$self->Self;
   $json->{dataobjtopclass}=$self->SelfAsParentObject;
   $json->{field}=[];
   if ($format eq "HtmlV01"){
      print("<table width=98%>");
      printf("<tr><td valign=top nowrap><b>%s:</b></td>",
             $self->T("Frontend name"));
      printf("<td>%s</td></tr>",$self->T($self->Self,$self->Self));
      printf("<tr><td valign=top nowrap><b>%s:</b></td>",
             $self->T("Internal object name"));
      printf("<td><a href=\"ModuleObjectInfo\">%s</a>".
             "</td></tr>",$self->Self);
      printf("<tr><td valign=top nowrap><b>%s:</b></td>",
             $self->T("Self as parent object"));
      printf("<td>%s</td></tr>",$self->SelfAsParentObject);
      printf("<tr><td valign=top nowrap><b>%s:</b></td>",
             $self->T("Parent classes"));
      printf("<td>%s</td></tr>",join(", ",@ISA));
      printf("<tr><td valign=bottom><b>%s:</b></td>",$self->T("Datafields"));
      printf("<td align=right><span class=sublink>".
             "<img border=0 style=\"margin-bottom:2px\" onclick=doPrint() ".
             "src=\"../../../public/base/load/miniprint.gif\"></span>".
             "</td></tr>");
      printf("<tr><td colspan=2>");
      printf("<div class=fieldlist><center>".
             "<table class=ObjectDefinition>");
      print("<tr>");
      printf("<th><b>%s</b></th>",$self->T("Frontend field"));
      printf("<th class=foname><b>%s</b></th>",$self->T("Internal field"));
      printf("<th class=fotype nowrap><b>%s</b></th>",$self->T("Field type"));
      printf("<th class=foref nowrap><b>%s</b></th>",$self->T("Reference"));
      printf("<th class=fosearch nowrap><b>%s</b></th>",$self->T("Searchable"));
      print("</tr>");
   }
   foreach my $fo ($self->getFieldObjsByView([qw(ALL)])){
      my $jfld={};
      print("<tr>") if ($format eq "HtmlV01");
      my $label=$fo->Label();
      $jfld->{label}=$label;
      $jfld->{name}=$fo->Name();
      $jfld->{type}=$fo->Type();
      $label=~s/\// \/ /g;
      $label=~s/-/ - /g;
      if ($label=~m/^\s*$/){
         $label="<span aria-hidden=\"true\">&nbsp; &nbsp;</span>";
      }
      if ($format eq "HtmlV01"){
         printf("<td valign=top>%s</td>",$label);
         printf("<td valign=top class=foname>%s</td>",$fo->Name());
         printf("<td valign=top class=fotype>%s</td>",$fo->Type());
      }
      my $vjointo=$fo->getNearestVjoinTarget();
      $vjointo=$$vjointo if (ref($vjointo) eq "SCALAR");
      if ($vjointo ne ""){
         my $l=$vjointo;
         $l=~s/::/\//g;
         $l="../../$l/ModuleObjectInfo";
         $jfld->{vjointo}=$vjointo;
         $vjointo="<a href=\"$l\">$vjointo</a>";
         if (exists($fo->{vjoinon})){
            if (ref($fo->{vjoinon}) eq "ARRAY"){
               $vjointo.="<br>".$fo->{vjoinon}->[0]."-&gt;".$fo->{vjoinon}->[1];
               $jfld->{vjoinon}=$fo->{vjoinon};
            }
            else{
               $vjointo.="<br>COMPLEX-LINK";
               $jfld->{vjoinon}="COMPLEX-LINK";
            }
         }
      }
      
      if ($format eq "HtmlV01"){
         printf("<td valign=top class=foref>%s</td>",$vjointo);
         printf("<td valign=top align=center class=fosearch>%s</td>",
                $fo->searchable ? $self->T("yes") : $self->T("no"));
         print("</tr>");
      }
      eval('$jfld->{searchable}=JSON::false;');
      if ($fo->searchable){
         eval('$jfld->{searchable}=JSON::true;');
      }
      push(@{$json->{field}},$jfld);
   }
   if ($format eq "HtmlV01"){
      printf("</table>");
      printf("<br><br><hr>");
      if ($self->IsMemberOf(["admin","support"])){
         printf("</center><div class=OracleReplication>".
                "<b>Oracle-Replication-Schema:</b><br>");
     
         printf("<pre>");
         printf("create table \"%s\" (\n",$self->Self);
         my $form=" %-20s %s,\n";
         foreach my $fo ($self->getFieldObjsByView([qw(ALL)])){
            my $typ=$fo->Type();
            my $name=$fo->Name();
            next if (in_array([qw(lastqcheck secroles sectargetid sectarget
                                  lastqcheck dataissuestate qcresonsearea
                                  attachments additional contacts)],$name));
            if ($typ ne "SubList" && $typ ne "Linenumber" &&
                $name ne "replkeypri" && $name ne "replkeysec"){
               if ($name eq "id"){
                  printf($form,$fo->Name,"Number(*,0) not null");
               }
               elsif ($name eq "cistatusid"){
                  printf($form,$fo->Name,"Number(2,0)");
               }
               elsif (in_array([qw(mandatorid databossid)],$name)){
                  printf($form,$fo->Name,"Number(*,0)");
               }
               elsif ($typ eq "Date" || $typ eq "CDate" || $typ eq "MDate"){
                  printf($form,$fo->Name,"DATE");
               }
               elsif ($typ eq "Boolean"){
                  printf($form,$fo->Name,"Number(1,0)");
               }
               elsif ($typ eq "TextDrop" || $typ eq "Contact" || 
                      $typ eq "Databoss"){
                  printf($form,$fo->Name,"VARCHAR2(128)");
               }
               elsif ($typ eq "Group"){
                  printf($form,$fo->Name,"VARCHAR2(256)");
               }
               else{
                  my $len=40;
                  $len=80   if ($name eq "srcsys");
                  $len=80   if ($name eq "name");
                  $len=20   if ($name eq "cistatus");
                  $len=128  if ($name eq "fullname");
                  $len=4000 if ($name eq "comments");
                  printf($form,$fo->Name,"VARCHAR2($len)");
               }
            }
         }
      #   # this is not longer nessesary, because this state tables are
      #   # automaticly create by W5Replication tool
      #   my @w5repladd=('W5REPLKEY'     =>'CHAR(70) not null',
      #                  'W5REPLKEYPRI'  =>'CHAR(35) not null',
      #                  'W5REPLKEYSEC'  =>'CHAR(35) not null',
      #                  'W5REPLLASTSUCC'=>'DATE not null',
      #                  'W5REPLLASTTRY' =>'DATE not null',
      #                  'W5REPLMDATE'   =>'DATE not null',
      #                  'W5REPLCDATE'   =>'DATE not null',
      #                  'W5REPLFAILCNT' =>'NUMBER(22,0) default 0 not null');
      #   while(my $k=shift(@w5repladd)){
      #       my $v=shift(@w5repladd);
      #       printf($form,$k,$v);
      #   }
         my $idname="?";
         if (my $idobj=$self->IdField()){
            $idname=$idobj->Name();
         }
         printf(" constraint \"%s_pk\" primary key (%s)\n",$self->Self,$idname);
     
         printf(");\n");
         if ($self->getField("name")){          
            printf("CREATE INDEX \"%s_di1\"\n       ON \"%s\"(NAME);\n",
                   $self->Self,$self->Self);    
         }                                      
         if ($self->getField("fullname")){      
            printf("CREATE INDEX \"%s_di2\"\n       ON \"%s\"(FULLNAME);\n",
                   $self->Self,$self->Self);
         }
         printf("</pre>");
         printf("</div>");
      }




      printf("</div>");
      
      printf("</td></tr>");
      print("</table>");
      print(<<EOF);
<script language="JavaScript">
function doPrint()
{
   window.print();
}
</script>
EOF


      print $self->HtmlBottom(form=>1);
   }
   else{
      print $JSON->pretty->encode($json);
   }
}

sub addAttach
{
   my $self=shift;
  
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           js=>['toolbox.js'],
                           title=>$self->T('Add Inline Attachment'),
                           multipart=>1,
                           form=>1);
   if (Query->Param("save")){
      no strict;
      my $f=Query->Param("file");
      msg(INFO,"got filetransfer request ref=$f");
      my $bk=seek($f,0,SEEK_SET);
      (undef,undef,undef,undef,undef,undef,undef,
       $size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($f);
      msg(INFO,"size=$size");
      my $filename=sprintf("%s",$f);
      $filename=~s/^.*[\/\\]//;
      msg(INFO,"filename=$filename");
      if ($size<128 || !($filename=~m/\.(jpg|jpeg|png|gif|xls|pdf)$/i)){
         $self->LastMsg(ERROR,"invalid file or filetype");
      }
      elsif ($size>3145728){
         $self->LastMsg(ERROR,"file is larger then the limit of 3MB");
      }
      else{
         my $newrec={parentobj=>$self->Self(),
                     inheritrights=>0,
                     srcsys=>"W5Base::InlineAttach",
                     name=>$filename,
                     file=>$f};
         my $filemgmt=getModuleObject($self->Config,"base::filemgmt");
         if (my ($id)=$filemgmt->ValidatedInsertRecord($newrec)){
            print "<script language=\"javascript\">";
            print "if (parent.currentObject){";
            print "   insertAtCursor(parent.currentObject,". 
                  "\" [attachment($id)] \");";
            print "}";
            print "else{";
            print "  alert(\"can not find currentObject\");";
            print "}";
            print "parent.hidePopWin(true,false);";
            print "</script>";
            print $self->HtmlBottom(form=>1);
         }
      }
   }
   print $self->getParsedTemplate("tmpl/addTextareaAttachment",
                                  {skinbase=>'base'});
   print $self->HtmlBottom(form=>1);
}


sub recordWriteOperators
{
   my $self=shift;
   my $databoss=$self->getField("databossid");
   my $idobj=$self->IdField();
   my $prim=[];
   my $sec=[];

   foreach my $oprec ($self->getHashList($idobj->Name(),"databossid")){
      if ($oprec->{databossid} ne ""){
         push(@$prim,$oprec->{databossid});
      }
      if (ref($oprec->{contacts}) eq "ARRAY"){
         foreach my $crec (@{$oprec->{contacts}}){
            my $r=$crec->{roles};
            $r=[$r] if (ref($r) ne "ARRAY");
            if (grep(/^write$/,@$r)){
               if ($crec->{target} eq "base::user"){
                  push(@$sec,$crec->{targetid});
               }
               if ($crec->{target} eq "base::grp"){
                  foreach my $uid ($self->getMembersOf($crec->{targetid},
                                   "RMember","down")){
                     push(@$sec,$uid);
                  }
               }
            }
         }
      }
   }

   return($prim,$sec);
}

sub JSPlugin
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(js=>['J5Base.js'],
                           body=>1,
                           title=>'JSPlugin');
   print(<<EOF);
<script language="JavaScript">
(function(window, document, undefined){
   \$(document).ready(function() {
      // \$('#JSPlugin', window.parent.document).html("Hi User!");
   });
})(this,document);
</script>

EOF
   print $self->HtmlBottom();
}



sub getValidWebFunctions
{  
   my ($self)=@_;
   $self->doFrontendInitialize();
   my @l=qw(NativMain JSPlugin Main mobileMain MainWithNew addAttach 
            NativResult Result Upload UploadWelcome UploadFrame
            Welcome Empty Detail Visual HtmlDetail HandleInfoAboSubscribe
            New ModalNew ModalEdit Copy FormatSelect Bookmark startWorkflow
            DeleteRec InitWorkflow AsyncSubListView Modify
            EditProcessor ViewProcessor HandleQualityCheck
            jsExplore
            ViewEditor ById ModuleObjectInfo);
   if ($self->can("HtmlHistory")){
      push(@l,qw(HtmlHistory HistoryResult));
   }
   if ($self->can("HtmlWorkflowLink")){
      push(@l,qw(HtmlWorkflowLink WorkflowLinkResult));
   }
   if ($self->can("HtmlInterviewLink")){
      push(@l,qw(HtmlInterviewLink));
   }
   if ($self->can("generateContextMap")){
      push(@l,"jsonContextMap","ContextMapView","Map");
   }
   return(@l);
}


sub jsonContextMap
{
   my $self=shift;
   my $rec=shift;

   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");

   $self->ResetFilter();
   $self->SecureSetFilter({$idname=>\$val});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader("application/json");

   my $d=$self->generateContextMap($rec);

   my $JSON;
   eval('use JSON;$JSON=new JSON;');
   $JSON->utf8(1);

   print $JSON->encode($d);
}


sub jsExploreLabelFieldname
{
   my $self=shift;
   my $o=$self->getRecordHeaderField();

   if (defined($o)){
      return($o->Name());
   }
   return();
}

sub jsExplore
{
   my $self=shift;
   my $dataobj=$self->Self();

   my $recordimageurl=$self->getRecordImageUrl();
   my $fieldnamelabel=$self->jsExploreLabelFieldname();
   my $fieldnameid=$self->IdField->Name();


   my $hideItem=$self->T("hide item");
   my %objectMethods=(
      'm900hideItem'=>"
             label:\"$hideItem\",
             cssicon:\"basket_delete\",
             exec:function(){
                 console.log(\"call hideNode on \",this);
                 var curobj=this.app.node.get(this.id);
                 if (curobj){
                    this.app.node.remove(curobj);
                 }
                 this.app.resetItemSelection();
             }
      "
   );
   $self->jsExploreObjectMethods(\%objectMethods);

   my $objectMethods="this.nodeMethods={\n";
   my $c=0;
   foreach my $k (keys(%objectMethods)){
      if ($c>0){
         $objectMethods.=",\n";
      }
      $objectMethods.="   ".$k.":{".$objectMethods{$k}."}";
      $c++;
   }
   $objectMethods.="};";

   my $formatLabelFunction=$self->jsExploreFormatLabelMethod();

   print $self->HttpHeader("text/javascript",charset=>'UTF-8');

   my $out=(<<EOF);
(function(window, document, undefined) {

   ClassDataObjLib['${dataobj}']=new Object();
   ClassDataObjLib['${dataobj}']=function(id,initialLabel,nodeTempl){
       this.label=initialLabel;
       this.dataobj='${dataobj}';
       this.dataobjid=id;
       ClassDataObj.call(this,W5Explore);
       this.font={
          multi:'md',
          face:'arial'
       };
       this.borderWidth=1;
       this.shapeProperties={
          useBorderWithImage:true
       };
       this.image='${recordimageurl}';
       this.shape='image';
       this.group=this.dataobj;
       \$.extend(this,nodeTempl);
       this.initLevel=0;
       this.fieldnamelabel='${fieldnamelabel}';
       this.fieldnameid='${fieldnameid}';
       this.id=this.app.toObjKey(this.dataobj,this.dataobjid);
       ${objectMethods}
   };
   ClassDataObjLib['${dataobj}'].prototype.formatLabel=function(newlabel){
      ${formatLabelFunction}
      return(newlabel);
   };
   ClassDataObjLib['${dataobj}'].prototype.refreshLabel=function(){
       var that=this;
       setTimeout(function(){
          var p=new Promise(function(ok,reject){
             that.app.Config().then(function(Config){
                var w5obj=getModuleObject(Config,that.dataobj);
                var flt=new Object();
                flt[that.fieldnameid]=that.dataobjid;
                w5obj.SetFilter(flt);
                w5obj.findRecord(that.fieldnamelabel+
                                 ",urlofcurrentrec",function(data){
                   var newlabel="???";
                   if (data[0]){
                      if (data[0][that.fieldnamelabel]){
                         newlabel=data[0][that.fieldnamelabel];
                      }
                      newlabel=that.formatLabel(newlabel);
                      if (data[0]["urlofcurrentrec"]){
                         that.update({
                            urlofcurrentrec:data[0]["urlofcurrentrec"]
                         });
                      }
                      that.update({label:newlabel});
                      ok(1);
                   }
                   else{
                      // that.update({label:that.label+" ?"});
                      reject(that.label+" not found");
                   }
                },function(exception){
                   // that.update({label:'?'});
                   reject(1);
                });
             }).catch(function(){
                console.log("can not get config");
                reject(null);
             });
          });
          p.then(function(){
             var x=1;
          }).catch(function(e){
             console.log("error in validation ",e);
           //  that.app.console.log("ERROR","fail to validated '"+
           //                       initialLabel);  
          });
          that.initLevel++;
       },100);
   };
   \$.extend(ClassDataObjLib['${dataobj}'].prototype,ClassDataObj.prototype);

})(this,document);

EOF
   utf8::encode($out);
   print $out;
}

sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;
}

sub jsExploreFormatLabelMethod
{
   my $self=shift;
   return("");
}


sub ContextMapView   
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TeamView",
                           js=>['toolbox.js','primitives.js','jquery.js'],
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'Output.HtmlDetail.css',
                                   'primitives.css',
                                   'Output.ListeditTabObject.css']);


   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY();

   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   my $winsize="normal";
   if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
      $winsize=$UserCache->{winsize};
   }
   my $winname="_blank";
   if (defined($UserCache->{winhandling}) &&
       $UserCache->{winhandling} eq "winonlyone"){
      $winname="W5BaseDataWindow";
   }
   my $openwinStart="custopenwin(";
   my $openwinEnd="'$winsize',$detailx,$detaily,'$winname')";



   if (defined($rec)){
      my $idfield=$self->IdField();
      my $idname=$idfield->Name();
      my $url="./jsonContextMap/".$rec->{$idname};
print <<EOF;
<script type='text/javascript'>
var ctrl;
var basicMode="Fam";
var dataurl='$url';


function onTemplateRender(event, data) {
   //console.log("onRender:",event,data);
   switch (data.renderingMode) {
      case primitives.RenderingMode.Create:
         /* Initialize template content here */
         break;
      case primitives.RenderingMode.Update:
         /* Update template content here */
         break;
   }

   var itemConfig = data.context;

   var photo = data.element.childNodes[1].firstChild;
   photo.src = itemConfig.image;
   photo.alt = itemConfig.title;

   var titleBackground = data.element.firstChild;
   titleBackground.style.backgroundColor = itemConfig.itemTitleColor || 
                                           primitives.Colors.RoyalBlue;

   var title = data.element.firstChild.firstChild;
   title.firstChild.textContent = itemConfig.title;
   if (itemConfig.titleurl){
      data.element.firstChild.firstChild.style.cursor='pointer';
      data.element.firstChild.firstChild.firstChild.href=itemConfig.titleurl;
      data.element.firstChild.firstChild.firstChild.onclick=
        function(e){
           ${openwinStart}itemConfig.titleurl,${openwinEnd};
           return(false);
        };
   }

   var description = data.element.childNodes[2];
   if (description){
      description.textContent = itemConfig.description;
   }
}

function generateTemplate(tmpl){
   var t=["div",
               {
                  "style": {
                     "width": tmpl.itemSize.width+ + "px",
                     "height": tmpl.itemSize.height + "px"
                  },
                  "class": ["bp-item", "bp-corner-all", "bt-item-frame"]
               },
               ["div",
                  {
                     "name": "titleBackground",
                     "class": ["bp-item", "bp-corner-all", "bt-title-frame"],
                     "style": {
                        top: "2px",
                        left: "2px",
                        width: ""+(tmpl.itemSize.width-5)+"px",
                        height: "18px"
                     }
                  },
                  ["div",
                     {
                        "name": "title",
                        "class": ["bp-item", "bp-title"],
                        "style": {
                           padding: "1px",
                           left: "6px",
                           width: "208px",
                           width: ""+(tmpl.itemSize.width-8)+"px",
                           height: "18px"
                        }
                     },
                    ["a",{
                         "href":"",
                         "class": ["bp-item", "bp-title"],
                       },
                    ]
                  ]
               ],
               ["div",
                  {
                     "class": ["bp-item", "bp-photo-frame"],
                     "style": {
                        top: "26px",
                        left: "2px",
                        width: "50px",
                        height: "60px"
                     }
                  },
                  ["img",
                     {
                        "name": "photo",
                        "class": ["bp-item", "bp-title"],
                        "style": {
                           width: "50px",
                           height: "60px"
                        }
                     }
                  ]
               ],
               ["div",
                  {
                     "name": "description",
                     "class": "bp-item",
                     "style": {
                        top: "25px",
                        left: "56px",
                        width: ""+(tmpl.itemSize.width-55)+"px",
                        height: "56px",
                        fontSize: "10px"
                     }
                  }
               ]
            ];
   return(t);
}

function generateContactTemplate(tmpl){
   var t=["div",
               {
                  "style": {
                     "width": tmpl.itemSize.width+ + "px",
                     "height": tmpl.itemSize.height + "px"
                  },
                  "class": ["bp-item", "bp-corner-all", "bt-item-frame"]
               },
               ["div",
                  {
                     "name": "titleBackground",
                     "class": ["bp-item", "bp-corner-all", "bt-title-frame"],
                     "style": {
                        top: "2px",
                        left: "2px",
                        width: ""+(tmpl.itemSize.width-5)+"px",
                        height: "18px"
                     }
                  },
                  ["div",
                     {
                        "name": "title",
                        "class": ["bp-item", "bp-title"],
                        "style": {
                           padding: "1px",
                           left: "6px",
                           width: "208px",
                           width: ""+(tmpl.itemSize.width-8)+"px",
                           height: "18px"
                        }
                     },
                    ["a",{
                         "href":"",
                         "class": ["bp-item", "bp-title"],
                       },
                    ]
                  ]
               ],
               ["div",
                  {
                     "class": ["bp-item", "bp-photo-frame"],
                     "style": {
                        top: "26px",
                        left: "2px",
                        width: "80px",
                        height: "80px"
                     }
                  },
                  ["img",
                     {
                        "name": "photo",
                        "class": ["bp-item", "bp-title"],
                        "style": {
                           width: "80px",
                           height: "80px"
                        }
                     }
                  ]
               ],
               ["div",
                  {
                     "name": "description",
                     "class": "bp-item",
                     "style": {
                        top: "25px",
                        left: "86px",
                        width: ""+(tmpl.itemSize.width-85)+"px",
                        fontSize: "10px",
                        height: '12px'
                     }
                  }
               ],
               ["div",
                  {
                     "name": "email",
                     "class": "bp-item",
                     "style": {
                        top: "38px",
                        left: "86px",
                        width: ""+(tmpl.itemSize.width-85)+"px",
                        fontSize: "10px",
                        height: '12px'
                     }
                  }
               ]
            ];
   return(t);
}

function updateByZoomLevel(){
   var scale=1-(0.1*ctrl.zoomLevel);
   onScale(scale);
}

function onScale(scale) {
   if (ctrl){
      if (scale != null) {
         ctrl.setOption("scale", scale);
      }
      ctrl.update(primitives.UpdateMode.Refresh);
   }
}


window.addEventListener('wheel', function(event) {
  if (event.ctrlKey == true) {
     event.preventDefault();
     if (ctrl){
        if (event.deltaY>0){
           ctrl.zoomLevel++;
        }
        if (event.deltaY<0){
           ctrl.zoomLevel--;
        }
        if (ctrl.zoomLevel<-9){
           ctrl.zoomLevel=-9;
        }
        if (ctrl.zoomLevel>9){
           ctrl.zoomLevel=9;
        }
        updateByZoomLevel();
     }
  }
}, { passive: false });


function ButtonsRenderer (data) {
   var itemConfig = data.context;
   var element = data.element;
   element.innerHTML = "";
   if (data.context.expandBaseLocation){
      element.appendChild(primitives.JsonML.toHTML(["div",
         {
         class: "btn-group-vertical btn-group-sm"
         },
         ["button", 
            {
               "type": "button",
               "data-buttonname": "expand",
               "style":"cursor:pointer",
               "title":"expand"
            },
            "+"
         ]
      ]));
   }
}

function processDynData(opt,data){
   var items=new Array();
   if (ctrl){
      items=ctrl.getOption("items");
   }
   var addList=new Array();
   var delList=new Array();
   if (data.items.add){
      addList=data.items.add;
   }
   if (data.items.del){
      delList=data.items.del;
   }
   if (!data.items.add && !data.items.del){
      addList=data.items;
   }
   for(var c=0;c<addList.length;c++){
      var item=addList[c];
      var isUpdated=0;
      var newRec;
      if (basicMode=="Org"){
         newRec=new primitives.OrgItemConfig(item);
      }
      if (basicMode=="Fam"){
         newRec=new primitives.FamItemConfig(item);
      }
      for(var cc=0;cc<items.length;cc++){
         if (items[cc].id==item.id){
            isUpdated=1;
            items[cc].parents=item.parents; 
         }
      }
      if (!isUpdated){
         items.push(newRec);
      }
   }
   for(var c=0;c<delList.length;c++){
      for(var cc=0;cc<items.length;cc++){
         if (items[cc].id==delList[cc]){
            items.splice(cc,1);
         }
      }
   }
   
   //console.log("items:",items);
   opt.items = items;

   if (data.cursorItem){
      opt.cursorItem = data.cursorItem;
   }
}


function ButtonHandler(e,data){
   if (e.srcElement.attributes['data-buttonname'].value=='expand'){
      console.log("Expand clicked");
      if (data.context.expandBaseLocation){
         var expandUrl=dataurl+"&OP="+
             e.srcElement.attributes['data-buttonname'].value+
             "&BASE="+data.context.id;
         \$.ajax({
           url: expandUrl,
         }).done(function(expandData) {
            console.log("expand from =",data.context,"expandData=",expandData);
            data.context.expandBaseLocation=0; // expand only allowed once
            var opt=new Object();
            processDynData(opt,expandData);
            if (ctrl){
               ctrl.setOptions(opt);
               ctrl.update(primitives.UpdateMode.Refresh);
            }
         });
      }
   }
}


\$.ajax({
  url: dataurl,
}).done(function(data) {
   console.log("data=",data);
   var opt = new primitives.OrgConfig();
   if (data.items){
      if (data.basicMode){
         if (data.basicMode=="Org"){
            basicMode="Org";
         }
      }
      processDynData(opt,data);


      //opt.alignBranches=true;
      opt.defaultTemplateName= "itemTmpl";

      var tmpl0=new primitives.TemplateConfig();
      tmpl0.name='itemTmpl';
      tmpl0.itemSize=new primitives.Size(100, 95);
      tmpl0.itemTemplate = generateTemplate(tmpl0);

      var tmpl1=new primitives.TemplateConfig();
      tmpl1.name='wideTemplate';
      tmpl1.itemSize=new primitives.Size(150, 95);
      tmpl1.itemTemplate = generateTemplate(tmpl1);

      var tmpl2=new primitives.TemplateConfig();
      tmpl2.name='ultraWideTemplate';
      tmpl2.itemSize=new primitives.Size(250, 95);
      tmpl2.itemTemplate = generateTemplate(tmpl2);

      var tmpl3=new primitives.TemplateConfig();
      tmpl3.name='contactTemplate';
      tmpl3.itemSize=new primitives.Size(210, 115);
      tmpl3.itemTemplate = generateContactTemplate(tmpl3);

      opt.templates = [tmpl0,tmpl1,tmpl2,tmpl3];
      opt.onItemRender = onTemplateRender;

      opt.alignBranches=true;

      opt.enableMatrixLayout=false;
      if (data.enableMatrixLayout){
         opt.enableMatrixLayout=true;
         if (data.minimumMatrixSize){
            opt.minimumMatrixSize=data.minimumMatrixSize;
         }
         else{
            opt.minimumMatrixSize=3;
         }
         if (data.maximumColumnsInMatrix){
            opt.maximumColumnsInMatrix=data.maximumColumnsInMatrix;
         }
         else{
            opt.maximumColumnsInMatrix=5;
         }
      }

      //opt.onButtonsRender = function (data) {
      //   var itemConfig = data.context;
      //   var element = data.element;
      //   console.log("data:",data);
      //   console.log("itemConfig:",itemConfig);
      //   element.innerHTML = "";
      //   element.appendChild(primitives.JsonML.toHTML(["div",
      //      {
      //      class: "btn-group-vertical btn-group-sm"
      //      },
      //      ["button", 
      //         {
      //            "type": "button",
      //            "data-buttonname": "delete",
      //            "class": "btn btn-light"
      //         },
      //         ["i", { "class": "fa fa-minus-circle" }],
      //         "X"
      //      ]
      //   ]));
      //};
      opt.pageFitMode = primitives.PageFitMode.None;
      opt.hasSelectorCheckbox = primitives.Enabled.False;
      //opt.normalItemsInterval = 50;
      opt.lineLevelShift = 50;

      opt.hasButtons = primitives.Enabled.Auto;
      //opt.buttonsPanelSize = 36;
      opt.onButtonsRender=ButtonsRenderer;
      opt.onButtonClick=ButtonHandler;

      opt.arrowsDirection=primitives.GroupByType.Children;
      if (basicMode=="Fam"){
         ctrl=primitives.FamDiagram(
                 document.getElementById("basicdiagram"),opt
         );
      }
      if (basicMode=="Org"){
         ctrl=primitives.OrgDiagram(
                 document.getElementById("basicdiagram"),opt
         );
      }
      ctrl.zoomLevel=0;
      if (data.initialZoomLevel){
         ctrl.zoomLevel=data.initialZoomLevel;
         updateByZoomLevel();
      }
      //console.log("primitives.FamDiagram=",ctrl);
   }
}).fail(function() {
  alert("Ajax failed to fetch data")
})

\$(window).resize(function(){
  if (ctrl){
     ctrl.update(primitives.UpdateMode.Refresh);
  }
});



</script>
<div id="basicdiagram" style="width: 100%; height:100%; border:1;padding:0;margin:0"></div>


EOF
   }
   print $self->HtmlBottom(body=>1,form=>1);

}



sub Map
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");
   my %param;
   my $target="../Detail";
   $param{ModeSelectCurrentMode}="ContextMapView";
   $param{$idname}=$val;
   $self->HtmlGoto($target,post=>\%param);
   return();
}



sub ById
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");
   my %param;

   my $FormatAs=Query->Param("FormatAs");
   if (lc($ENV{HTTP_ACCEPT}) eq "application/json" ||
       $FormatAs eq "nativeJSON"){
      $ENV{HTTP_ACCEPT}="application/json";
      my $CurrentView=Query->Param("CurrentView");
      Query->Reset();
      my %flt=($idname=>\$val);
      $self->ResetFilter();
      my %view;
      if ($CurrentView eq "" && $self->SecureSetFilter(\%flt)){
         $self->SetCurrentOrder("NONE");
         my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            if ($self->can("UserReCertHandling")){
               $self->UserReCertHandling($rec);
            }
            my @viewgroups=$self->isViewValid($rec,format=>"nativeJSON");
            my @fieldlist=$self->getFieldObjsByView(
                                   [qw(ALL)],
                                    current=>$rec,
                                    output=>"nativeJSON");
            for(my $c=0;$c<=$#fieldlist;$c++){
               my $fld=$fieldlist[$c];
               my $name=$fld->Name();
               next if (!$fld->UiVisible("HtmlDetail",current=>$rec));
               if (exists($fld->{htmldetail})){
                  if ($fld->{htmldetail} eq "NotEmpty" ||
                      $fld->{htmldetail} eq "NotEmptyOrEdit"){
                     my $v=$fld->RawValue($rec);
                     next if ($v eq "");
                  }
                  my $viewcnt=0;
                  foreach my $currentfieldgroup (@viewgroups){
                     my $group=$fld->{group};
                     $group="default" if (!defined($group));
                     $group=[$group] if (!ref($group) eq "ARRAY");
                     if (in_array($group,$currentfieldgroup)){
                        if ($fld->htmldetail("HtmlDetail", current=>$rec,
                                     currentfieldgroup=>$currentfieldgroup)){
                           $viewcnt++;
                        }
                     }
                  }
                  next if (!$viewcnt);
               }
               $view{$name}++;
            }
         }
      }
         
      $self->ResetFilter();
      $self->SecureSetFilter(\%flt);
      Query->Param("search_".$idname=>$val);
      $view{$idname}++;
      if ($CurrentView ne ""){
         Query->Param("CurrentView"=>$CurrentView);
      }
      else{
         if (keys(%view)){
            Query->Param("CurrentView"=>"(".join(",",sort(keys(%view))).")");
         }
      }
      return($self->Result(ExternalFilter=>1));
   }

   my $target="../Detail";
   while($val=~m/\//){
      if (my ($anker)=$val=~m/\/fieldgroup.([^\/]+)$/){
         $target="../".$target;
         $val=~s/\/fieldgroup.(.+)$//;
         $param{OpenURL}="#fieldgroup_".$anker;
      }
      elsif ($val=~m/\/Interview$/){
         $param{ModeSelectCurrentMode}="HtmlInterviewLink";
         $target="../".$target;
         $val=~s/\/Interview$//;
      }
      elsif ($val=~m/\/FView$/){
         $param{ModeSelectCurrentMode}="FView";
         $target="../".$target;
         $val=~s/\/FView$//;
      }
      else{
         last;
      }
   }
   $param{$idname}=$val;
   $self->HtmlGoto($target,post=>\%param);
   return();
}

sub getAbsolutByIdUrl
{
   my $self=shift;
   my $id=shift;
   my $param=shift;
   my $url;

   my $obj=$param->{dataobj};
   if (!defined($obj)){
      $obj=$self->Self();
   }
   $obj=~s/::/\//g;


   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");

   if ($EventJobBaseUrl ne ""){
      my $baseurl=$EventJobBaseUrl;
      $baseurl.="/" if (!($baseurl=~m/\/$/));
      $url=$baseurl;
      $url.="auth/$obj/ById/".$id;
   }
   else{
      my $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s/\/auth\/.*$//;
      $url=$baseurl;
      $url.="/auth/$obj/ById/".$id;
   }
   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $url=~s/^http:/https:/;
   }
   if ($param->{path} ne ""){
      $url.="/".$param->{path};
   }
   return($url);
}




sub DataObjByIdHandler
{
   my $self=shift;
   return($self->Self());
}

sub allowAnonymousByIdAccess
{
   my $self=shift;
   my $id=shift;
   return(0);
}


sub isUploadValid  # validates if upload functionality is allowed
{
   my $self=shift;

   return(1);
}

sub doFrontendInitialize
{
   my $self=shift;
   if (!$self->{IsFrontendInitialized}){
      $self->{IsFrontendInitialized}=$self->FrontendInitialize();
   }
   return($self->{IsFrontendInitialized});
}


sub FrontendInitialize
{
   my $self=shift;
   $self->{userview}=getModuleObject($self->Config,"base::userview");
   $self->{UseSoftLimit}=1 if (!defined($self->{UseSoftLimit}));
   return(1);
}

sub HandleSubListEdit
{
   my ($self,%param)=@_;
   my $subeditmsk=$param{subeditmsk};
   $subeditmsk="default.subedit" if (!defined($subeditmsk));
   my $idname=$self->IdField->Name();

   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n");
   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n");
   print("<script language=JavaScript ".
         "src=\"../../../public/base/load/sortabletable.js\"></script>\n");

   if (exists($param{forceparam}) && ref($param{forceparam}) eq "HASH"){
      foreach my $v (keys(%{$param{forceparam}})){
         Query->Param($v=>$param{forceparam}->{$v});
      }
   }                                          # die forceparam muessen vor
                                              # UND nach der Modification
   my $op=$self->ProcessDataModificationOP(); # geladen werden, damit diese
                                              # in der Query zur Masken
                                              # vorbelegung verfuegbar sind

   if (exists($param{forceparam}) && ref($param{forceparam}) eq "HASH"){
      foreach my $v (keys(%{$param{forceparam}})){
         Query->Param($v=>$param{forceparam}->{$v});
      }
   }

   {
      # SubList Edit-Mask anzeigen
      my $id=Query->Param("CurrentIdToEdit");
      my ($rec,$msg);
      if (defined($id) && $id ne ""){
         $self->SetFilter({$self->IdField->Name()=>$id});
         $self->SetCurrentView($self->getFieldList());
         ($rec,$msg)=$self->getFirst();
         $self->SetCurrentView();
      }
      my $app=$self->App();
      print <<EOF;
<link rel=stylesheet type="text/css"
      href="../../../public/base/load/kernel.App.Web.css"></link>
<link rel=stylesheet type="text/css"
      href="../../../public/base/load/Output.HtmlSubListEdit.css"></link>
EOF
      if (defined($rec)){
         printf("<script language=\"JavaScript\">".
                "setEnterSubmit(document.forms[0],DoSubListEditSave);".
                "</script>");
      }
      else{
         printf("<script language=\"JavaScript\">".
                "setEnterSubmit(document.forms[0],DoSubListEditAdd);".
                "</script>");
      }
      my $tmplName="tmpl/$app.$subeditmsk";
      my $opt={ current=>$rec };
      print $self->getParsedTemplate($tmplName,$opt);
   }
   print $self->findtemplvar({},"LASTMSG");
   if ($op eq "delete" || $op eq "save"){
      $self->ClearSaveQuery();
   }
}

sub getForceParamForSubedit
{
   my $self=shift;
   my $id=shift;
   my $dfield=shift;

   my %forceparam=();
   #######################################################################
   # forceparameter berechnen, die im SubEdit modus die Verbindung zum
   # Elternobjekt erzeugt/darstellen
   #
   $self->SetFilter({$self->IdField->Name()=>$id});
   $self->SetCurrentView($dfield->{vjoinon}->[0]);
   my ($rec,$msg)=$self->getFirst();
   my $joinf=$self->getField($dfield->{vjoinon}->[0]);
   my $lnk=$joinf->RawValue($rec);

   $forceparam{$dfield->{vjoinon}->[1]}=$lnk;
   if (defined($dfield->{vjoinbase})){
      my @filter=($dfield->{vjoinbase});
      if (ref($dfield->{vjoinbase}) eq "ARRAY"){
         @filter=@{$dfield->{vjoinbase}};
      }
      foreach my $filter (@filter){
         foreach my $var (keys(%$filter)){
            if (ref($filter->{$var}) eq "SCALAR"){
               $forceparam{$var}=${$filter->{$var}};
               $forceparam{"Formated_".$var}=${$filter->{$var}};
            }
         }
      }
   }
   #######################################################################
   return(%forceparam);
}

sub EditProcessor
{
   my ($self)=@_;
   my $id=Query->Param("RefFromId");
   my $seq=Query->Param("Seq");
   my $field=Query->Param("Field");
   my $edtmode="HtmlDetail";
   my $dfield;
   if ($field eq ""){
      my $fp=Query->Param("FunctionPath");
      $fp=~s/^\///;
      my ($mode,$field,$refid,$seq)=split(/\//,$fp);
      if (($mode=~m/^json\./) && $field ne ""){
         $dfield=$self->getField($field);
         return($dfield->EditProcessor($mode,$refid,$field,$seq));
      }
   }
   if ($field ne ""){
      $dfield=$self->getField($field);
   }
   if (defined($dfield)){
      return($dfield->EditProcessor($edtmode,$id,$field,$seq));
   }
   else{

      print $self->HttpHeader("text/html");
      print "ERROR: EditProcessor no access to FunctionPath";
   }
}

sub ViewProcessor
{
   my ($self)=@_;
   my $fp=Query->Param("FunctionPath");
   $fp=~s/^\///;
   my ($mode,$field,$refid,$id,$seq)=split(/\//,$fp);
   my $dfield=$self->getField($field);
   if (defined($dfield)){
      return($dfield->ViewProcessor($mode,$refid,$id,$field,$seq));
   }
   else{
      print $self->HttpHeader("text/html");
      print "ERROR: ViewProcessor no access to FunctionPath";
   }
}

sub AsyncSubListView
{
   my ($self)=@_;
   print $self->HttpHeader("text/html");
   my $id=Query->Param("RefFromId");
   my $seq=Query->Param("Seq");
   my $field=Query->Param("Field");
   printf("<html>");
   printf("<body OnLoad=resizeme()>");
   my $dfield=$self->getField($field);

   $self->SetFilter({$self->IdField->Name()=>$id});
   $self->SetCurrentView($field);
   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      print $dfield->FormatedResult($rec,"HtmlDetail");
   }
   else{
      print (msg(ERROR,"problem msg=$msg rec=$rec id=$rec idfield=%s",
                       $self->IdField->Name()));
   }
   printf("</body>");
print <<EOF;
<script language=JavaScript>
function resizeme()
{
   var p=window.parent.document;
   var dst=p.getElementById('div.sublist.$field.$seq.$id');
   if (dst){
      dst.innerHTML=document.body.innerHTML;
      window.parent.DetailInit();
   }
}
</script>
EOF
   print $self->HtmlBottom();
}

sub initSearchQuery
{
   my $self=shift;
}

sub getParsedSearchTemplate
{
   my $self=shift;
   my %param=@_;
   my $pagelimit=20;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (!$param{nosearch}){      # Search mask needs only to be initialized, if
      $self->initSearchQuery(); # searchmask is realy useable
   }
   if (defined($UserCache->{pagelimit}) && $UserCache->{pagelimit} ne ""){
      $pagelimit=$UserCache->{pagelimit};
   }
   my $AutoSearch;
   if (Query->Param("AutoSearch")){
      $AutoSearch="addEvent(window,\"load\",DoSearch);\n";
   }
   my $name="tmpl/".$self->Self.".search";
   $name=~s/::/./g;

   my $d=<<EOF;
<script language="JavaScript">
function DoSearch()
{
   var d;
   document.forms[0].action='Result';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   document.forms[0].elements['UseLimitStart'].value='0';
   document.forms[0].elements['UseLimit'].value='$pagelimit';
   DisplayLoading(frames['Result'].document);
   window.setTimeout("document.forms[0].submit();",1);
   return;
}
function DoUpload()
{
   var d;
   document.forms[0].action='UploadFrame';
   document.forms[0].target='Result';
   document.forms[0].submit();
   return;
}
setEnterSubmit(document.forms[0],DoSearch);
$AutoSearch
</script>
EOF
   my $defaultsearch="";
   if ($param{nosearch}){
      my %search=$self->getSearchHash();
      foreach my $k (keys(%search)){
         my $val=$search{$k};
         $val=~s/"/&quote;/g;
         $val=~s/</&lt;/g;
         $val=~s/>/&gt;/g;
         $d.="<input type=hidden value=\"$val\" name=search_$k>";
      }
      return($d);
   }
   if ($self->getSkinFile($self->SkinBase()."/".$name)){
      $d.=$self->getParsedTemplate($name);
   }
   else{
      # autogen search template
      my @field=$self->getFieldList("SearchTemplate");
    
      my $searchframe="";
      my $extframe="";
      my $c=0;
      my $mainlines=$self->{MainSearchFieldLines};
      $mainlines=2 if (!defined($mainlines));
      my @searchfields=@field;

      #
      # identify searchable fields and bring them in correct order
      #


      # now we have a temporary order of all searchable fields
      # in @tmpsearchfieldorder
      my @tmpsearchfieldorder=$self->orderSearchMaskFields(\@searchfields);


      while(my $fieldname=shift(@tmpsearchfieldorder)){
         my $fo=$self->getField($fieldname); 
         my $type=$fo->Type();
         $defaultsearch=$fieldname if ($fo->defsearch);
         my $work=\$searchframe;
         $work=\$extframe if ($c>=$mainlines*2);
         last if (!defined($fieldname));
         my $modulus=($c+1)%2;
         if ($modulus ==1){
            $$work.="<tr>";
         }
         my $c1="15%";
         my $c2="35%";
         my $cs="1";
         if ($fo->mainsearch()){
            $c2="95%";
            $cs="3";
         }
         my $label=$fo->Label();
         my $t0="";
         my $t1="";
         if (length($label)>=30){
            $t0="<a title=\"".quoteHtml($label)."\">";
            $t1="</a>";
         }
 
         $$work.="<td class=fname width=$c1>".
                 "${t0}\%$fieldname(searchlabel)\%${t1}:</td>";
         $$work.="<td class=finput width=$c2 colspan=$cs>".
                 "\%$fieldname(search)\%</td>";
         if ($fo->mainsearch()){
            $c++;
         }
         if ($c+1 % 2 ==0){
            $$work.="</tr>";
         }
         $c++;
      }
      $searchframe.="</tr>" if (!($searchframe=~m/<\/tr>$/));

      $d.=$self->arrangeSearchData($searchframe,$extframe,
                                   $defaultsearch,%param);
      $self->ParseTemplateVars(\$d);
   }
   return($d);
}

sub orderSearchMaskFields
{
   my $self=shift;
   my $searchfields=shift;
   my @searchfields=@{$searchfields};

   my $idshifted=0;
   my @tmpsearchfieldorder;

   while(my $fieldname=shift(@searchfields)){
      my $fo=$self->getField($fieldname); 
      my $type=$fo->Type();
      next if (!$fo->UiVisible("SearchMask"));
      if (!$fo->searchable()){
         if ($type eq "Id"){
            if ($#searchfields!=-1){
               push(@searchfields,$fieldname) if (!$idshifted);
               $idshifted++;
               next;
            }
         }
         else{
            next;
         }
      }
      push(@tmpsearchfieldorder,$fieldname);
   }
   return(@tmpsearchfieldorder);
}



sub arrangeSearchData
{
   my $self=shift;
   my $searchframe=shift;
   my $extframe=shift;
   my $defaultsearch=shift;
   my %param=@_;

   my $newbutton="";
   $newbutton="new," if ($param{allowNewButton});
   my $d=<<EOF;
<img width=200 border=0 height=1 src="../../../public/base/load/empty.gif"><div class=searchframe><table id=SearchParamTable class=searchframe>$searchframe</table></div>
%StdButtonBar(search,analytic,$newbutton,defaults,reset,bookmark,print,extended,upload)%
<div style="width:100%;
            border-width:0px;
            margin:0px;
            padding:0px;
            display:none;visibility:hidden" id=ext>
<div class=extsearchframe><table id=ExtSearchParamTable class=extsearchframe>$extframe</table></div>
</div>
<script language="JavaScript">
setFocus("$defaultsearch");
</script>
EOF
   return($d);
}


sub Copy
{
   my ($self)=@_;

   my $copyfromid=Query->Param("CurrentIdToEdit");

   if ($copyfromid ne ""){
      $self->PrepairCopy($copyfromid,1);
      #print STDERR Query->Dumper();
   }
   return($self->New());
}

sub PrepairCopy
{
   my $self=shift;
   my $copyfromid=shift;
   my $firsttry=shift;
   my $copyfromrec={};
   my $copyinit={};

   $self->ResetFilter();
   $self->SecureSetFilter({$self->IdField->Name()=>$copyfromid});
   $self->SetCurrentView(qw(ALL));
   ($copyfromrec)=$self->getFirst();
   if ($self->isCopyValid($copyfromrec)){
      Query->Param("isCopyFromId"=>$copyfromid);
      Query->Delete("CurrentIdToEdit");
      Query->Delete($self->IdField->Name());
      foreach my $fo ($self->getFieldObjsByView([$self->getCurrentView()],
                                                oldrec=>$copyfromrec)){
         my $newval=$fo->copyFrom($copyfromrec);
         if (defined($newval)){
            $copyinit->{"Formated_".$fo->Name()}=$newval;
         }
      }
      $self->InitCopy($copyfromrec,$copyinit);
      foreach my $v (keys(%$copyinit)){
         next if (!defined($copyinit->{$v}));
         if (!defined(Query->Param($v))){
            Query->Param($v,$copyinit->{$v});
         }
      }
      Query->Delete($self->IdField->Name());
      Query->Delete("Formated_".$self->IdField->Name());
   }
   else{
      print($self->noAccess());
      return(undef);
   }
}

sub InitCopy
{
   my ($self,$copyfrom,$newrec)=@_;
}

sub InitNew    # Initialize Web New Form
{
   my ($self)=@_;
}

sub getCloseModalWindowCode
{
   my $self=shift;
   my $isbreaked=shift;
   my $d;
   if ($isbreaked){ 
      $d=<<EOF;
<script language=JavaScript>
parent.hidePopWin(false);
</script>
EOF
   }
   else{
      $d=<<EOF;
<script language=JavaScript>
parent.hidePopWin(true);
</script>
EOF
   }
   return($d);
}

sub getCloseModalWindowCodeFinishDelete
{
   my $self=shift;
   my $isbreaked=shift;
   my $d;
   if ($isbreaked){ 
      $d=<<EOF;
<script language=JavaScript>
parent.hidePopWin(false);
parent.FinishDelete();
</script>
EOF
   }
   else{
      $d=<<EOF;
<script language=JavaScript>
parent.hidePopWin(true);
parent.FinishDelete();
</script>
EOF
   }
   return($d);
}



sub ModalNew
{
   my $self=shift;
   return($self->New(WindowEnviroment=>'modal'));
}


sub New
{
   my $self=shift;
   my %param=@_;
   my $WindowEnviroment=$param{WindowEnviroment};
   $WindowEnviroment="normal" if ($WindowEnviroment eq "");

   my @groups=$self->isWriteValid();
   if ($#groups==-1 || !defined($groups[0])){
      print($self->noAccess());
      return(undef);
   }
   if (!defined(my $op=Query->Param("OP"))){
      $self->InitNew();
   }
   $self->ProcessDataModificationOP();
   if (my $CopyFromId=Query->Param("isCopyFromId")){
      $self->PrepairCopy($CopyFromId);
   }

   my $idfield=$self->IdField();

   if (defined($idfield) && Query->Param($idfield->Name()) ne ""){
      if (Query->Param("ModeSelectCurrentMode") eq "new"){
         Query->Delete("ModeSelectCurrentMode");
      }
      if ($WindowEnviroment eq "modal"){
         print $self->HttpHeader("text/html");
         print $self->HtmlHeader(style=>['default.css'],body=>1,
                                 title=>"Closing ...");
         print $self->getCloseModalWindowCode(0);
         print $self->HtmlBottom(body=>1);
         return();
      }
      return($self->Detail());
   }
   my $output=new kernel::Output($self);
   if (!($output->setFormat("HtmlDetail",
         NewRecord=>1,
         WindowMode=>"New",
         WindowEnviroment=>$WindowEnviroment))){
      msg(ERROR,"can't set output format 'HtmlDetail'");
      return();
   }
   my $page=$output->WriteToScalar(HttpHeader=>0);

   my $title=undef;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css',
                                   'mainwork.css',
                                   'Output.HtmlDetail.css',
                                   'kernel.filemgmt.css',
                                   'kernel.TabSelector.css'],
                           body=>1,form=>1,multipart=>'1');
   print("<style>body{margin:0;overflow:hidden;padding:0;".
         "border-width:0}</style>");
   my %param=(pages=>    [$self->getHtmlDetailPages("new",undef)],
              activpage  =>'new',
              tabwidth    =>"20%",
              page        =>$page,
             );
   print TabSelectorTool("ModeSelect",%param);
   print $self->HtmlBottom(body=>1,form=>1);
}



sub DeleteRec
{
   my ($self)=@_;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'Output.HtmlDetail.css',
                                   'work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("Verification query"));
   my $id=Query->Param("CurrentIdToEdit");
   $self->ResetFilter();
   my $flt=undef;
   if (defined($id)){
      $flt={$self->IdField->Name()=>\$id};
      $self->SetFilter($flt);
   }
   if (defined($flt)){
      $self->SetCurrentView(qw(ALL));
      $self->ForeachFilteredRecord(sub{
                                      $self->ValidateDelete($_);
                                   });
   }
   if (Query->Param("FORCE")){
      my $error=1;
      if (defined($flt)){
         $error=0;
         $self->SetCurrentView(qw(ALL));
         my @recs;
         $self->ForeachFilteredRecord(sub{
                             push(@recs,$_);
                          });
         if (defined($id) && $#recs!=0){
            $error=1;
            $self->LastMsg(ERROR,"delete destination notfound or not unique");
         }
         else{
            foreach my $rec (@recs){
               if (!$self->SecureValidatedDeleteRecord($rec)){
                  $error=1;
               }
            }
         }
      }
      if (!$error){
         print $self->getCloseModalWindowCodeFinishDelete();
         return();
      }
   }
   printf("<form method=post><center>");
   printf("<table border=0 height=80%>");
   printf("<tr height=1%>");
   printf("<td align=center><br><br>");
   if (!grep(/^ERROR/,$self->LastMsg())){
      printf($self->T("Do you realy want delete record id %s ?"),$id);
   }
   printf("</td>");
   printf("</tr>");
   if ($self->LastMsg()!=0){
      printf("<tr height=1%>");
      printf("<td align=center>".
             "<div style=\"text-align:left;border-style:solid;".
             "border-width:1px;padding:3px;".
             "overflow:auto;height:50px;width:400px\">");
      print join("<br>",map({
                             if ($_=~m/^ERROR/){
                                $_="<font style=\"color:red;\">".$_.
                                   "</font>";
                             }
                             $_;
                            } $self->LastMsg()));
      printf("</div></td>");
      printf("</tr>");
   }
   printf("<tr>");
   printf("<td align=center valign=center>");
   printf("<table border=0>");
   printf("<tr>");
   if (!grep(/^ERROR/,$self->LastMsg())){
      printf("<td>");
      printf("<input type=submit name=FORCE ".
             " value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("yes"));
      printf("</td>");
      printf("<td>");
      printf("<input type=button ".
             "onclick=\"parent.hidePopWin(false);\" value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("no"));
      printf("</td>");
   }
   else{
      printf("<td>");
      printf("<input type=button ".
             "onclick=\"parent.hidePopWin(false);\" value=\" %s \" ".
             "style=\"margin-left:20px;margin-right:20px;width:150px\">",
             $self->T("cancel"));
      printf("</td>");
   }
   printf("</tr>");
   printf("</table>");
   printf("</td>");
   printf("</tr>");
   printf("</table>");
   print ($self->HtmlPersistentVariables(qw(CurrentIdToEdit)));
   printf("</from>");

}

sub NativMain
{
   my ($self)=@_;
   return($self->Main(nohead=>1,allowNewButton=>1));
}

sub NativResult
{
   my ($self)=@_;
   return($self->Main(nohead=>1,nosearch=>1));
}

sub MainWithNew
{
   my ($self)=@_;
   return($self->Main(allowNewButton=>1));
}

sub mobileMain
{
   my $self=shift;
   my $sitename=$self->Config->Param("SITENAME");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['jquery.mobile-1.1.1.min.css'],
                           js=>['jquery-1.7.1.min.js',
                                'jquery.mobile.1.1.1.min.js'],
                           title=>"Mobile - $sitename");

   my $bak="<a data-role=\"button\" data-inline=\"true\" ".
           "data-rel=\"back\" data-icon=\"arrow-u\" data-iconpos=\"left\">".
           "Back".
           "</a>";

   my $mainp="<div data-role=\"page\" id=\"mainpage\">";
   $mainp.="<div data-theme=\"a\" data-role=\"header\">";
   $mainp.=$bak;
   $mainp.="<h3>".$self->T($self->Self,$self->Self)."</h3>";
   $mainp.="</div>";
   $mainp.=<<EOF;
<form action="" method="POST">
     <div data-role="fieldcontain"  data-mini="true" >
         <fieldset data-role="controlgroup">
             <label for="textinput1">
                 Name
             </label>
             <input name="" id="textinput1" placeholder="" value="" type="text" />
         </fieldset>
     </div>
     <div data-role="fieldcontain" data-mini="true">
         <fieldset data-role="controlgroup">
             <label for="textinput2">
                 Fullname
             </label>
             <input name="" id="textinput2" placeholder="" value="" type="text" />
         </fieldset>
     </div>
     <div data-role="fieldcontain" data-mini="true">
         <fieldset data-role="controlgroup">
             <label for="textinput2">
                 ApplicationID
             </label>
             <input name="" id="textinput2" placeholder="" value="" type="text" />
         </fieldset>
     </div>
     <div align=right>
     <input  data-mini="true" type="submit" data-inline="true" data-icon="search" data-iconpos="right" value="Submit" />
     </div>
 </form>

EOF

   $mainp.="</div>";
   print($mainp."</body></html>");
}




sub Main
{
   my ($self,%param)=@_;

   if (!$self->isViewValid()){
      print($self->noAccess());
      return(undef);
   }
   my $CurrentView=Query->Param("CurrentView");
   print $self->HttpHeader("text/html");
   my $startcmd="document.getElementById('MainStartup').style.display='block';";
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           submodal=>1, body=>1,form=>1, onload=>$startcmd,
                           title=>$self->T($self->Self,$self->Self));
   print ("<style>body{overflow:hidden}</style>");
   if ($param{nohead}){
      print <<EOF;
<script language=JavaScript src="../../../public/base/load/toolbox.js">
</script>
<script language=JavaScript src="../../../public/base/load/kernel.App.Web.js">
</script>
EOF
   }
   
   print("<div id=MainStartup style='display:none'>".
         "<table id=MainTable ".
         "style=\"border-collapse:collapse;width:100%;height:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   if (!$param{nohead}){
      printf("<tr><td height=1%% ".
             "valign=top>%s</td></tr>",$self->getAppTitleBar());
   }
   printf("<tr><td height=1%%>%s</td></tr>",
          $self->getParsedSearchTemplate(%param));
   print <<EOF;
<script>
addEvent(window, "resize", genericResponsiveMainHandler);
addEvent(window, "load", genericResponsiveMainHandler);
</script>
EOF
   my $welcomeurl="Welcome";
   if (!$self->can("Welcome")){
      my $mod=$self->Module();
      my $app=$self->App();
      if ($self->getSkinFile("$mod/tmpl/welcome.$app")){
         $welcomeurl="../load/tmpl/welcome.$app"; 
      }
      elsif ($self->getSkinFile("$mod/tmpl/welcome")){
         $welcomeurl="../load/tmpl/welcome"; 
      }
   }
   my $BookmarkName=Query->Param("BookmarkName");
   my $ForceOrder=Query->Param("ForceOrder");

   my $iframe="<iframe class=result id=result ".
              "name=\"Result\" src=\"$welcomeurl\"></iframe>";
   print("<tr><td>$iframe</td></tr></table><div>");

   my $selfname=$self->Self();
   my $persistentVari=
      "<input type=\"hidden\" name=\"UseLimit\" value=\"10\">".
      "<input type=\"hidden\" name=\"UseLimitStart\" value=\"0\">".
      "<input type=\"hidden\" name=\"FormatAs\" value=\"HtmlV01\">".
      "<input type=\"hidden\" name=\"BookmarkName\" value=\"$BookmarkName\">".
      "<input type=\"hidden\" name=\"CurrentView\" value=\"$CurrentView\">".
      "<input type=\"hidden\" name=\"ForceOrder\" value=\"$ForceOrder\">".
      "<input type=\"hidden\" name=\"DataObj\" value=\".$selfname.\">";

   print($persistentVari);
   print($self->HtmlBottom(body=>1,form=>1));
}


sub getSearchHash
{
   my $self=shift;
   my %h=();
   %h=Query->MultiVars();

   my $idobj=$self->IdField();
   if (defined($idobj)){
      my $idname=$idobj->Name();
      if (defined($h{$idname})){
         return($idname=>[$h{$idname}]);
      }
   }
  # if (defined(Query->Param($idname))){
  #    my $idval=Query->Param($idname);
  #    $idval=~s/&quote;/"/g;
  #    return($idname=>[$idval]);
  # }
   foreach my $v (keys(%h)){
      if ($v=~m/^search_/ && $h{$v} ne ""){
         my $v2=$v;
         $v2=~s/^search_//;
         if (ref($h{$v}) eq "ARRAY"){
            $h{$v2}=$h{$v};
         }
         else{
            $h{$v2}=trim($h{$v});
         }
         if (my ($webclip)=$h{$v2}=~m/\[\@(WebClip.*)\@\]/){
            my $nobj=getModuleObject($self->Config(),"base::note");
            my $userid=$self->getCurrentUserId();
            $nobj->SetFilter({creatorid=>\$userid,name=>\$webclip});
            $nobj->SetCurrentView(qw(comments));
            $h{$v2}=[];

            my ($cliprec,$msg)=$nobj->getFirst();
            if (defined($cliprec)){
               do{
                  push(@{$h{$v2}},$cliprec->{comments});
                  ($cliprec,$msg)=$nobj->getNext();
               } until(!defined($cliprec));
            }
         }
      }
      delete($h{$v});
   }
   return(%h);
}

#sub Welcome
#{
#   my $self=shift;
#   print $self->HttpHeader("text/html");
#   print $self->HtmlHeader(style=>['default.css','work.css'],
#                           body=>1,form=>1);
#   my $module=$self->Module();
#   my $appname=$self->App();
#   my $tmpl="tmpl/$appname.welcome";
#   my @detaillist=$self->getSkinFile("$module/".$tmpl);
#   if ($#detaillist!=-1){
#      print $self->getParsedTemplate($tmpl,{});
#   }
#   print $self->HtmlBottom(body=>1,form=>1);
#   return(0);
#}

sub Bookmark
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           title=>$self->T("... add a bookmark"),
                           onload=>'onLoad();',
                           body=>1,form=>1);
   my $autosearch=Query->Param("AutoSearch");
   my $replace=Query->Param("ReplaceBookmark");
   Query->Delete("ReplaceBookmark");
   my $bookmarkname=Query->Param("BookmarkName");
   if ($bookmarkname eq ""){
      $bookmarkname=$self->T($self->Self,$self->Self());
      $bookmarkname.=": ".$self->T("my search");
   }
   my $closewin="";
   my $dosave=0;

   if (Query->Param("SAVE")){
      Query->Delete("SAVE");
      $dosave=1;
   }

   Query->Delete("AutoSearch");
   my %qu=Query->MultiVars();
  # foreach my $sv (keys(%qu)){    # just do no cleaning - i think it's better
  #    next if ($qu{$sv} ne "" || $sv eq "search_cistatus");
  #    delete($qu{$sv});
  # }
   my $querystring=kernel::cgi::Hash2QueryString(%qu);
   $querystring="?".$querystring;
   my $srclink=$self->Self();
   $srclink=~s/::/\//g;
   my $bmsrclink="../../".$srclink."/Main$querystring&AutoSearch=$autosearch";
   my $clipsrclink=$ENV{SCRIPT_URI}."/../../../".$srclink."/Main$querystring";

   if ($dosave){
      my $bm=getModuleObject($self->Config,"base::userbookmark");
      my $target="_self";
      if ($replace){
         my $userid=$self->getCurrentUserId();
         $bm->SetFilter({name=>\$bookmarkname,userid=>\$userid});
         $bm->SetCurrentView(qw(ALL));
         $bm->ForeachFilteredRecord(sub{
                            $bm->ValidatedDeleteRecord($_);
                         });
      }
      if ($bm->SecureValidatedInsertRecord({name=>$bookmarkname,
                                            srclink=>$bmsrclink,
                                            target=>$target})){
         $closewin="parent.hidePopWin();";
      }
   }


   my $quest=$self->T("please copy this URL to your clipboard:");
   print(<<EOF);
<script language="JavaScript">
$closewin
function onLoad(){
   document.forms[0].elements['BookmarkName'].focus();
}
function showUrl()
{
   var x;
   if (document.forms[0].elements['AutoSearch'].value==1){
       x=prompt("$quest:","$clipsrclink&AutoSearch=1");
   }
   else{
       x=prompt("$quest:","$clipsrclink");
   }
   if (x){
      parent.hidePopWin();
   }
}
</script>
EOF
   my $auto="<select name=AutoSearch>";
   $auto.="<option value=\"0\">".$self->T("no")."</option>";
   $auto.="<option value=\"1\"";
   $auto.=" selected" if ($autosearch);
   $auto.=">".$self->T("yes")."</option>";
   $auto.="</select>";
   my $repl="<select name=ReplaceBookmark>";
   $repl.="<option value=\"0\">".$self->T("no")."</option>";
   $repl.="<option value=\"1\"";
   $repl.=" selected" if ($replace);
   $repl.=">".$self->T("yes")."</option>";
   $repl.="</select>";
   my $BOOKM="<input type=text style=\"width:100%\" name=BookmarkName ".
             "value=\"$bookmarkname\">";

   print $self->getParsedTemplate("tmpl/kernel.bookmarkform",{skinbase=>'base',
                                    static=>{AUTOS=>$auto,BOOKM=>$BOOKM,
                                             REPL=>$repl}});
   #printf("Bookmark Handler");
   print("<input type=hidden name=SAVE value=\"1\">");
   Query->Delete("BookmarkName");
   print $self->HtmlPersistentVariables(qw(ALL));
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub ClearSaveQuery
{
   my $self=shift;
   my @var=Query->Param();
   my $id=$self->IdField->Name();

   foreach my $var (@var){
      if ((($var=~m/^Formated_.*$/ ||
            lc($var) eq $var) &&
           $var ne $id) || 
           $var eq "NewRecSelected" || 
           $var eq "CurrentFieldGroupToEdit"){
         Query->Delete($var);
      }
   }
}

sub finishCopy
{
   my $self=shift;
   my $oldid=shift;
   my $newid=shift;
   msg(INFO,"finishCopy: oldid=$oldid newid=$newid");
}

sub HandleSave
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=undef;
   my $id=Query->Param("CurrentIdToEdit");
   my $idobj=$self->IdField();
   my $idname;
   my $flt=undef;

   if (defined($idobj)){
      $idname=$idobj->Name();
   }

   if (defined($idname) && $mode eq "Modify"){  # Ajax Operaton
      $id=Query->Param($idname);
   }
   if (defined($id) && $id ne ""){
      $id=~s/&quote;/"/g;
      $flt={$idname=>\$id};
      $self->SecureSetFilter($flt);
      $self->SetCurrentView(qw(ALL));
      my $msg;
      $self->SetCurrentOrder("NONE");
      ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (!defined($oldrec)){
         $self->LastMsg(ERROR,
                        "save request to invalid or not existing record id");
      }
      #$self->SetCurrentView();
   }
   my $HistoryComments=Query->Param("HistoryComments");
   if (trim($HistoryComments) ne ""){
      $W5V2::HistoryComments=$HistoryComments;
      Query->Delete("HistoryComments");
   }
   my $newrec=$self->getWriteRequestHash($mode,$oldrec);
   if ($self->LastMsg()==0){
      if (!defined($oldrec) && defined($newrec->{$idname})){
         # after prepUploadRecord an old record id could be found
         Query->Param($idname=>$newrec->{$idname});
         $flt={$idname=>\$newrec->{$idname}};
         $self->ResetFilter();
         $self->SecureSetFilter($flt);
         $self->SetCurrentView(qw(ALL));
         my $msg;
         $self->SetCurrentOrder("NONE");
         ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));
      }
   }


   if ($self->LastMsg()!=0){
      return(undef);
   }
   if (defined($oldrec) && defined($newrec) && defined($newrec->{$idname})){
      if (!defined($self->{UseSqlReplace}) || $self->{UseSqlReplace}==0){
         delete($newrec->{$idname});
      }
   }

   if (!defined($newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ".
                              "${self}::getWriteRequestHash()");
      }
      return(undef);
   }
   #
   # Delta save (for later storeing in Delta-Tab)
   #
   my $writeok=0;
   if (defined($oldrec)){
      if ($self->SecureValidatedUpdateRecord($oldrec,$newrec,$flt)){
         $writeok=1;
         if (ref($idobj->{dataobjattr}) eq "ARRAY"){ # id is a contact from 
                     # data fields - so the  id must be new calculated
                     # - the definition of each array field as datafield
                     # is needed
            my @newid;
            my @fobj=$self->getFieldObjsByView([qw(ALL)]);
            foreach my $field (@{$idobj->{dataobjattr}}){
               foreach my $fobj (@fobj){
                  if (defined($fobj->{dataobjattr}) &&
                      $field eq $fobj->{dataobjattr}){
                     push(@newid,'"'.effVal($oldrec,$newrec,$fobj->Name).'"');
                  }
               }
            }
            my $newid=join("-",@newid);
            Query->Param($self->IdField->Name()=>$newid);
         }
      }
   }
   else{
      my $newid=$self->SecureValidatedInsertRecord($newrec);
      if ($newid){
         $writeok=1;
         Query->Param($self->IdField->Name()=>$newid);
         if (Query->Param("isCopyFromId") ne ""){
            my $oldid=Query->Param("isCopyFromId");
            $self->finishCopy($oldid,$newid);
            Query->Delete("isCopyFromId");
         }
      }
   }
   if ($writeok){
      $self->ClearSaveQuery(); 
      Query->Delete("CurrentIdToEdit");
   }
   else{
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"unknown error in ${self}::Validate()");
      }
   }
}

sub HandleDelete
{
   my $self=shift;
   my $mode=shift;

   my $id;

   if ($mode eq "Modify"){
      my $idfield=$self->IdField();
      if (defined($idfield)){
         $id=Query->Param($idfield->Name());
      }
   }
   else{
      $id=Query->Param("CurrentIdToEdit");
   }


   my $flt=undef;
   if (defined($id)){
      $flt={$self->IdField->Name()=>\$id};
      $self->SetFilter($flt);
   }
   if (defined($flt)){
      $self->SetCurrentView(qw(ALL));
      my $cnt=0;
      $self->ForeachFilteredRecord(sub{
                               my $rec=$_;
                               $cnt++;
                               if ($self->SecureValidatedDeleteRecord($rec)){
                                  if ($rec->{$self->IdField->Name()} eq $id){
                                     Query->Delete("CurrentIdToEdit");
                                  } 
                               }
                               else{
                                  if (!$self->LastMsg()){
                                     $self->LastMsg(ERROR,
                                           "SecureValidatedDeleteRecord error");
                                  }
                               }
                            });
     if ($cnt==0 && $mode eq "Modify"){
        $self->LastMsg(ERROR,"delete operation on invalid record");
     }
   }
   else{
      $self->LastMsg(ERROR,"HandleDelete with no filter informations");
      return(0);
   }
   return(1);
}

sub ProcessDataModificationOP
{
   my $self=shift;
   my $mode=shift;
   $mode="web" if ($mode eq "");

   my $op=Query->Param("OP");
   if (Query->Param("NewRecSelected")==1){
      $self->ClearSaveQuery
   }
   if ($op eq "cancel"){
      Query->Delete("OP");
      $self->ClearSaveQuery(); 
   }
   if ($op eq "save"){
      Query->Delete("OP");
      $self->HandleSave($mode);
   }
   if ($op eq "delete"){
      Query->Delete("OP");
      $self->HandleDelete($mode);
   }
   return($op);
}

sub HtmlPublicDetail   # for display record in QuickFinder or with no access
{
   my $self=shift;
   my $rec=shift;
   my $header=shift;   # create a header with fullname or name
   my $htmlresult="";

   if ($header){
      $htmlresult.="<table width=\"100%\" style='margin:5px'>\n";
    
      my $fo=$self->getRecordHeaderField();
    
      if (defined($fo)){
         $htmlresult.="<tr><td colspan=2 align=center><h2>";
         $htmlresult.=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                         $fo->Name(),"formated");
         $htmlresult.="</h2></td></tr>";
      }
   }
   else{
      $htmlresult.="<table width=\"100%\">\n";
   }
   $htmlresult.="<tr><td colspan=2 align=center>";
   $htmlresult.="ERROR: ".
                $self->T("You have not the necessary rights ".
                         "to view this record");
   $htmlresult.="</td></tr>";
   $htmlresult.="</table>";

   return($htmlresult);



}


sub Visual
{
   my $self=shift;
   my %param=@_;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   if ($self->SecureSetFilter(\%flt)){
      my $output=new kernel::Output($self);
      $self->SetCurrentView(qw(ALL));
      print $self->HttpHeader("text/html");
      print("No Visual View avalable");
   }
   else{
      print($self->noAccess());
      return(undef);
   }

}

sub HtmlDetail
{
   my $self=shift;
   my %param=@_;

   $self->ProcessDataModificationOP();
   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   if ($self->SecureSetFilter(\%flt)){
      my $output=new kernel::Output($self);
      $self->SetCurrentView(qw(ALL));
      $param{WindowMode}="Detail";
      $self->SetCurrentOrder("NONE");
      if (!($output->setFormat("HtmlDetail",%param))){
         msg(ERROR,"can't set output format 'HtmlDetail'");
         return();
      }
      $output->WriteToStdout(HttpHeader=>1);
   }
   else{
      print($self->noAccess());
      return(undef);
   }

}


sub Modify
{
   my $self=shift;
   my %param=@_;

   my $idfield=$self->IdField();
   my $id;
   my $op=Query->Param("OP");

   if ($ENV{REQUEST_METHOD} ne "POST"){
      $self->LastMsg(ERROR,"Modify operations are only alowed by Method POST");
   }
   else{
      if (!defined($idfield)){
         $self->LastMsg(ERROR,"Modify operations only allowed on ".
                              "dataobjects with IdField");
      }
      elsif($op ne "save" && $op ne "delete"){
         $self->LastMsg(ERROR,"no valid OP specified in Modify-call");
      }
      else{
         $id=Query->Param($idfield->Name());
         if ($id eq "" && $op eq "delete"){
            $self->LastMsg(ERROR,"delete OP only allowed with specific id");
         }
         else{
            $op=$self->ProcessDataModificationOP("Modify");
            $id=Query->Param($idfield->Name());
            if ($id eq ""){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"unexpected id after $op operation");
               }
            }
         }
      }
   }


   my $format=Query->Param("FormatAs");
   if (!defined($format)){
      Query->Param("FormatAs"=>"nativeJSON");
   }
   my $CurrentView=Query->Param("CurrentView");
   if ($CurrentView eq ""){
      Query->Param("CurrentView"=>"(".$idfield->Name().")");
   }

   if ($self->LastMsg()>0){   # first try to handle dynamic Foramted Error docs
      my $output=new kernel::Output($self);
      my $format=Query->Param("FormatAs");
      if (defined($param{FormatAs})){
         Query->Param("FormatAs"=>$param{FormatAs});
         $format=$param{FormatAs};
      }
      if ((!defined($format) || $format eq "")){
         Query->Param("FormatAs"=>"nativeJSON");
         $self->Limit(1);
      }
      my $format=Query->Param("FormatAs");
      $param{WindowMode}="Modify";
      if (!($output->setFormat($format,%param))){
         return();
      }
      $output->WriteToStdoutErrorDocument(HttpHeader=>1);
   }
   else{
      $self->ResetFilter();
      $self->SetFilter($idfield->Name=>\$id);
      $self->Result(ExternalFilter=>1); 
   }
   return(0);
}

sub ModalEdit
{
   my $self=shift;
   my %param=@_;

   my $oprunning=0;
   $oprunning=1 if (Query->Param("OP") ne "");
   $self->ProcessDataModificationOP();
   

   if (Query->Param("CurrentFieldGroupToEdit") eq ""){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css'],body=>1,
                              title=>"Closing ...");
      if ($oprunning){
         print $self->getCloseModalWindowCode(0);
      }
      else{
         print $self->getCloseModalWindowCode(1);
      }
      print $self->HtmlBottom(body=>1);
      return();
   }

   my %flt=$self->getSearchHash();
   $self->ResetFilter();

   if ($self->SecureSetFilter(\%flt)){
      my $output=new kernel::Output($self);
      $self->SetCurrentView(qw(ALL));
      $param{WindowMode}="Detail";
      $param{WindowEnviroment}="modal";
      $self->SetCurrentOrder("NONE");
      if (!($output->setFormat("HtmlDetail",%param))){
         msg(ERROR,"can't set output format 'HtmlDetail'");
         return();
      }
      $output->WriteToStdout(HttpHeader=>1);
   }
   else{
      print($self->noAccess());
      return(undef);
   }

}


sub Detail
{
   my $self=shift;
   my %param=@_;

   if ($ENV{REQUEST_METHOD} eq "GET"){  # try to convert GET to POST
      my %param=Query->MultiVars();
      delete($param{MOD});  # MOD and FUNC are genered from W5Base-Kernel - this
      delete($param{FUNC}); # makes no sense to forward them.
      $self->HtmlGoto("Detail",post=>\%param);
      return();
   }
   my %flt=$self->getSearchHash();

   if (!%flt) {
      print($self->queryError($self->T('Query parameter missing')));
      return(undef);
   }

   $self->ResetFilter();
   if ($self->SecureSetFilter(\%flt)){
      $self->SetCurrentOrder("NONE");
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

      my $p=Query->Param("ModeSelectCurrentMode");
      $p=$self->getDefaultHtmlDetailPage() if ($p eq "");



   #   print $self->HttpHeader("text/html",
   #                           cookies=>Query->Cookie(-name=>$cookievar,
   #                                                  -path=>"/",
   #                                                  -value=>$p));
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.TabSelector.css',
                                      '../../../static/lytebox/lytebox.css'],
                              js=>['toolbox.js','kernel.App.Web.js'],
                              body=>1,form=>1);
      if (!defined($rec)){       # fix to check, if record exists
         $self->ResetFilter();   # but current user have not sufficient rights
         if ($self->SetFilter(\%flt)){
            $self->SetCurrentOrder("NONE");
            my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
            if (!defined($rec)){
               print $self->getParsedTemplate(
                         "tmpl/kernel.notfound",{skinbase=>'base'});
               print $self->HtmlBottom(body=>1,form=>1);
               return();
            }
            else{
               if ($self->can("HtmlPublicDetail")){
                  print($self->T("Short information summary ".
                                 "for config-item from inaccessable mandator").
                        ":<br><hr><center>".
                        "<div style='width:600px;text-align:left'>".
                        $self->HtmlPublicDetail($rec,1).
                        "</div></center>");
               }
               else{
                  print "<center>ERROR: Record exists, ".
                        "but you have not rights to view it!</center>";
               }
               print $self->HtmlBottom(body=>1,form=>1);
               return();
            }
         }
      }
      my $idobj=$self->IdField();
      my $parentid;
      if (defined($idobj) && defined($rec)){
         $parentid=$idobj->RawValue($rec);
      }
      print($self->HtmlSubModalDiv());
      print("<script language=\"JavaScript\" ".
            "src=\"../../../public/base/load/toolbox.js\"></script>\n".
            "<script language=\"JavaScript\" ".
            "src=\"../../../public/base/load/subModal.js\"></script>\n");
#      my $UserJavaScript=$self->getUserJavaScriptDiv($self->Self,$parentid);
#      if ($UserJavaScript ne ""){
#         print "<script language=\"JavaScript\" ".
#               "src=\"../../../public/base/load/jquery.js\"></script>\n";
#      }
      print(<<EOF);
<script language="JavaScript" type="text/javascript">
addEvent(document,'keydown',function(e){
   e=e || window.event;
   globalKeyHandling(document,e);
});

function globalKeyHandling(doc,e){
   if (e.key=="F1" && !e.ctrlKey && !e.altKey){
      var dFrame=document.getElementById("HtmlDetailPage");
      if (dFrame){
         var dWin=dFrame.contentWindow;
         var dDoc=dFrame.contentDocument;
         if (dDoc && dWin){
            var allSpecs=dDoc.getElementsByClassName("detailfieldspec");
            var specs=new Array();
            for(var c=0;c<allSpecs.length;c++){
               if (allSpecs[c].tagName.toLowerCase()=="div"){
                  specs.push(allSpecs[c]);
               }
            }
            
            var visiPoint=-1;
            for(var c=0;c<specs.length;c++){
               if (specs[c].style.display=="block"){
                  visiPoint=c;
                  specs[c].style.visibility="hidden";
                  specs[c].style.display="none";
                  break;
               }
            }
            if (visiPoint==-1){ // nothin visible
               if (specs.length>0){
                  specs[0].style.visibility="visible";
                  specs[0].style.display="block";
                  specs[0].scrollIntoView();
                  dWin.scrollBy(0,-20);
               }
            }
            else{
               visiPoint++;
               if (visiPoint<specs.length){
                  specs[visiPoint].style.visibility="visible";
                  specs[visiPoint].style.display="block";
                  specs[visiPoint].scrollIntoView();
                  dWin.scrollBy(0,-20);
               }
            }
         }
      }
      e.preventDefault();
   }
   if (e.altKey){
      if (directTabKeyHandling){
         directTabKeyHandling(doc,e);
         e.preventDefault();
      }
   }
}

function setEditMode(m)
{
   this.SubFrameEditMode=m;
}
function TabChangeCheck()
{
if (this.SubFrameEditMode==1){return(DataLoseWarn());}
return(true);
}
function setCookie(c_name,value,exdays)
{
   var exdate=new Date();
   exdate.setDate(exdate.getDate() + exdays);
   var c_value=escape(value) + 
               ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
   document.cookie=c_name + "=" + c_value;
}

window.onresize = function (evt) {
   var width = window.innerWidth || 
      (window.document.documentElement.clientWidth || 
       window.document.body.clientWidth);
   var height = window.innerHeight || 
      (window.document.documentElement.clientHeight || 
       window.document.body.clientHeight);
   setCookie("W5WINSIZE",width+";"+height,10000);
}
</script>
EOF
      $p="StandardDetail" if ($p eq "");

      my $page=$self->getHtmlDetailPageContent($p,$rec);

      my @WfFunctions=$self->getDetailFunctions($rec);
      my @HtmlDetailPages=$self->getHtmlDetailPages($p,$rec);
      if (defined($rec) && 
          exists($rec->{cistatusid}) && $rec->{cistatusid}==7){
         @WfFunctions=($self->T("DetailClose")=>'DetailClose');
      }

      my %param=(functions   =>\@WfFunctions,
                 pages       =>\@HtmlDetailPages,
                 activpage  =>$p,
                 page        =>$page,
                 actionbox   =>
"<div id=JSPlugin style='margin-top:3px;float:right'></div>
 <div id=JSPluginLoader style='float:right'></div>
 <script language=JavaScript>
function createJSPluginLoader(){
  var i = document.createElement('iframe');
  i.src='JSPlugin';i.frameborder='0';i.width='0';i.height='0';
  i.style.display='none';
  document.getElementById('JSPluginLoader').appendChild(i);
};
if (window.addEventListener)
   window.addEventListener('load', createJSPluginLoader, false);
else if (window.attachEvent)
   window.attachEvent('onload', createJSPluginLoader);
else window.onload = createJSPluginLoader;
</script><div id=IssueState aria-hidden=true>&nbsp;</div>"
                );


      if (($#{$param{pages}})/2<4){  # if there less then 5 pages, expand them
         $param{tabwidth}="20%"; # as mutch as it looks good
      }
      print(TabSelectorTool("ModeSelect",%param));
      print("<script language=\"JavaScript\">".
            $self->getDetailFunctionsCode($rec).
             "</script>");

    #  print($UserJavaScript);
      print $self->HtmlBottom(body=>1,form=>1);
   }
   else{
      print($self->noAccess());
      return(undef);
   }
}

#sub getUserJavaScript
#{
#   my $self=shift;
#   my $parentobj=shift;
#   my $parentid=shift;
#
#   my $userid=$self->getCurrentUserId();
#   my $precode="";
#   my @flt;
#   my $code;
#   if ($parentobj ne ""){
#      $precode.="var ParentObj=\"$parentobj\";\n";
#      push(@flt,{creatorid=>\$userid,
#                 parentobj=>[$parentobj,''],
#                 name=>'UserJavaScript*'});
#   }
#   if ($parentobj ne "" && $parentid ne ""){
#      $precode.="var ParentId=\"$parentid\";\n";
#      push(@flt,{creatorid=>\$userid,
#                 parentobj=>\$parentobj,
#                 parentid=>\$parentid,
#                 name=>'UserJavaScript*'});
#   }
#
#   my $code="";
#   if ($#flt!=-1){
#      my $note=getModuleObject($self->Config,"base::note");
#      $note->ResetFilter();
#      $note->SetFilter(\@flt);
#      foreach my $rec ($note->getHashList(qw( name comments))){
#         $code.=$rec->{comments};
#      }
#      $code=trim($code);
#   }
#   my $v=<<EOF;
#
#function myFAQ(){
#   \$("textarea[name=note]").val("Ich habe Sie der Gruppe \\"uploader\\" hinzugefügt. Bitte befolgen Sie in jedem Fall die Hinweise im FAQ Artikel ...\\n http://xxxx/xxxxxxxxxxxxxxx/xxx.\\n\\n\\n I have add you to the group \\"uploader\\". Please read the instructions at ...\\nhttp://xfjhdsfas/xxxxxxx");
#
#}
#
#addToMenu({label:"- default FAQ für Upload guppen",func:myFAQ});
#addToMenu({label:"- xxxxxxxxxxxxxxxxxxload guppen",func:myFAQ});
#addToMenu({label:"- default Fxxxxxxxxxxxxxxxxxxen",func:myFAQ});
#addToMenu({label:"- defxxxxxxxxxxxxxxxxxxd guppen",func:myFAQ});
#
#EOF
##   $code.=$v;
#   return($code);
#}

#sub getUserJavaScriptDiv
#{
#   my $self=shift;
#   my $parentobj=shift;
#   my $parentid=shift;
#
#   my $d;
#   my $code=$self->getUserJavaScript($parentobj,$parentid);
#   if ($code ne ""){
#      $d=<<EOF;
#<div id=UserJavaScriptActivator>
#</div>
#<div id=UserJavaScript>
#</div>
#<script>
#function addToMenu(m){
#   var h=20;
#   var o=document.createElement("span");
#   \$(o).addClass("sublink");
#   \$(o).html(m.label);
#   \$(o).height(h);
#   if (m.func){
#      \$(o).click(m.func)
#   }
#   \$("#UserJavaScript").append(\$(o));
#   \$("#UserJavaScript").height(\$("#UserJavaScript").height()+h);
#   \$("#UserJavaScript").append(\$(document.createElement("br")));
#}
#
#\$(document).ready(function (){$code});
#\$("#UserJavaScriptActivator").mouseover(function (){
#   \$("#UserJavaScript").show("slow");
#   \$("#UserJavaScript").mouseout(function (){
#     setTimeout(function (){
#        \$("#UserJavaScript").hide("slow");
#        \$("#UserJavaScript").unbind("mouseout");
#     },2000);
#   });
#});
#</script>
#
#EOF
#   }
#   return($d);
#}


sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $idname=$self->IdField->Name();
   my $id=$rec->{$idname};
   my $sname=$self->Self();

   my $detailx=$self->DetailX();
   my $detaily=$self->DetailY();
   my $copyo="";
   my $UserCache=$self->Cache->{User}->{Cache};
   my $loginurl="../../../auth/".$self->Self."/Detail";
   $loginurl=~s/::/\//g;
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   my $winsize="";
   if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
      $winsize=$UserCache->{winsize};
   }
   my $winname="_blank";
   if (defined($UserCache->{winhandling}) && 
       $UserCache->{winhandling} eq "winonlyone"){
      $winname="W5BaseDataWindow";
   }
   if (defined($UserCache->{winhandling}) 
       && $UserCache->{winhandling} eq "winminimal"){
      $winname="W5B_".$self->Self."_".$id;
      $winname=~s/[^a-z0-9]/_/gi;
   }
   if ($winsize eq ""){
      $copyo="openwin(\"Copy?CurrentIdToEdit=$id\",\"$winname\",".
          "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
          "resizable=yes,scrollbars=auto\")";
   }
   else{
      $copyo="custopenwin(\"Copy?CurrentIdToEdit=$id\",\"$winsize\",".
             "$detailx,$detaily,\"$winname\")";
   }

   my $d=<<EOF;
function DetailPrint(){
   window.frames['HtmlDetailPage'].focus();
   window.frames['HtmlDetailPage'].print();
}
function DetailClose(){
   if (window.name=="work"){
      document.location.href="Welcome";
   }
   else{
//      if (this.SubFrameEditMode==1){
//         if (!DataLoseWarn()){
//            return;
//         }
//      }
      window.opener=self;
      window.open('','_parent','');
      window.close();
      if (!window.closed){
         document.location.href="Welcome";
      }
   }
}

function DetailDelete(id)
{
   showPopWin('DeleteRec?CurrentIdToEdit=$id',500,180,FinishDelete);
}
function DetailCopy(id)
{
   $copyo;
}
function DetailLogin()
{
   document.forms[0].action="$loginurl";
   document.forms[0].submit(); 
}
function FinishDelete(returnVal,isbreak)
{
   if (!isbreak){
      if (window.name=="work"){
         document.location.href="Welcome";
      }
      else{
         window.close();
      }
   }
}
function DetailHandleInfoAboSubscribe()
{
   showPopWin('HandleInfoAboSubscribe?CurrentIdToEdit=$id',590,300,
              FinishHandleInfoAboSubscribe);
}
function DetailHandleQualityCheck()
{
   openwin('HandleQualityCheck?CurrentIdToEdit=$id',"qc$id",
           "height=240,width=$detailx,toolbar=no,status=no,"+
           "resizable=yes,scrollbars=auto");
}
function FinishHandleInfoAboSubscribe(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}

function HistoryCommentedSave(commentfld)
{
   var HtmlDetailPage=document.getElementById("HtmlDetailPage");
   if (HtmlDetailPage){
      if (HtmlDetailPage.contentWindow.HistoryCommentedDetailEditSave){
         HtmlDetailPage.contentWindow.HistoryCommentedDetailEditSave(
            commentfld.value);
      }
   }
   hidePopWin();
}

function checkEditmode(e) // this handling prevents klick on X in window
{
   if (window.SubFrameEditMode==1){
      window.SubFrameEditMode=0;
      e.returnValue=DataLoseQuestion();
   }
}
addEvent(window, "beforeunload",   checkEditmode);


EOF
   return($d);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f=($self->T("DetailPrint")=>'DetailPrint');
   if ($ENV{REMOTE_USER} eq "anonymous"){
      push(@f,$self->T("DetailLogin")=>'DetailLogin');
   }
   push(@f,$self->T("DetailClose")=>'DetailClose');
   if (defined($rec) && $self->isDeleteValid($rec)){
     # my $idname=$self->IdField->Name();
     # my $id=$rec->{$idname};
      if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
         unshift(@f,$self->T("DetailDelete")=>"DetailDelete");
      }
   }
   if (defined($rec) && $self->isCopyValid($rec)){
     # my $idname=$self->IdField->Name();
     # my $id=$rec->{$idname};
      unshift(@f,$self->T("DetailCopy")=>"DetailCopy");
   }
   if (defined($rec) && $self->can("HandleInfoAboSubscribe") && 
       $ENV{REMOTE_USER} ne "anonymous"){
      unshift(@f,$self->T("InfoAbo")=>"DetailHandleInfoAboSubscribe");
   }
   if (defined($rec) && $self->can("HandleQualityCheck") &&
       $ENV{REMOTE_USER} ne "anonymous" &&
       $self->isQualityCheckValid($rec)){
      if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
         unshift(@f,$self->T("QualityCheck")=>"DetailHandleQualityCheck");
      }
   }
   return(@f);
}

########################################################################
#
# quality check methods
#

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   my $mandator=$rec->{mandatorid};
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   my $compatible=$self->getQualityCheckCompat($rec);
   my $qc=$self->getPersistentModuleObject("base::qrule");
   $qc->SetFilter({target=>$compatible});
   my @reclist=$qc->getHashList(qw(id));
   my @idl=map({$_->{id}} @reclist);
   if ($#idl!=-1){
      my $qc=$self->getPersistentModuleObject("base::lnkqrulemandator");
      $qc->SetFilter({mandatorid=>$mandator,qruleid=>\@idl});
      my @reclist=$qc->getHashList(qw(id dataobj));
      return(1) if ($#reclist!=-1 && $self->Self() ne "base::workflow");
      my $found=0;
      foreach my $qrec (@reclist){
         if ($self->Self() eq "base::workflow"){
            if ($rec->{class} eq $qrec->{dataobj} ||
                $rec->{class} eq "base::workflow"){
               $found++;
               last;
            }
         }
      }

      return($found);
   }

   return(0);
}


sub getQualityCheckCompat
{
   my $self=shift;
   my $rec=shift;
   my $s=$self->Self;
   if ($s eq "base::workflow"){
      return([$rec->{class}]);
   }
   return([$self->Self,$self->SelfAsParentObject()]);
}

sub HandleQualityCheck
{
   my $self=shift;

   my $id=Query->Param("CurrentIdToEdit");
   my $qc=$self->getPersistentModuleObject("base::qrule");
   my $idname=$self->IdField->Name();
   if ($id ne "" && $idname ne ""){
      $self->ResetFilter();
      $self->SetFilter({$idname=>\$id});
      $self->SetCurrentOrder("NONE");
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      $qc->setParent($self);
      if (defined($rec)){
         print($qc->WinHandleQualityCheck($self->getQualityCheckCompat($rec),
                                          $rec));
      }
      else{
         print($qc->WinHandleQualityCheck([],undef));
      }
   }
   else{
      print($self->noAccess());
   }
}
########################################################################





sub validateSearchQuery
{
   return(1);
}


sub UploadWelcome
{
   my $self=shift;
   my %param=@_;

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'upload.css',
                                    ],
                           body=>1,form=>1,
                           title=>'W5BaseV2-Upload');

   printf("<table width=\"100%\" height=\"100%\">".
          "<tr><td valign=center align=center>".
          "%s</td></tr></table>",
          $self->T("Please select file and start upload"));

   print $self->HtmlBottom(body=>1,form=>1);
}

sub Welcome
{
   my $self=shift;

   if ($self->isSuspended()){
      if (!$self->LastMsg()){
         $self->LastMsg(ERROR,"access to this object is currently suspended")
      }
      print($self->notAvailable($self->T($self->Self,$self->Self)));
      return(undef);
   }
   if (!$self->Ping()){
      print($self->notAvailable($self->T($self->Self,$self->Self)));
      return(undef);
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           body=>1,form=>1);
   if ($self->T("WELCOME",$self->Self) ne "WELCOME"){
      my $recordimg=$self->getRecordImageUrl();
      my $welcome=$self->T("WELCOME",$self->Self);
      print(<<EOF);
<table width="100%" height="60%">
<tr>
<td align=center valign=center>
<table border=0 cellspacing=5 cellpadding=5>
<tr>
<td valign=top>
<img src="$recordimg"
      style="border-width:1px;border-style:solid;solid;border-color:black">
</td>
<td valign=center>
<div style="border-width:1px;border-top-style:solid;border-bottom-style:solid;border-color:black;padding:3px;width:250px">$welcome</div>
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
EOF
   }
   else{
      my $module=$self->Module();
      my $appname=$self->App();
      my $tmpl="tmpl/$appname.welcome";
      my @detaillist=$self->getSkinFile("$module/".$tmpl);
      if ($#detaillist!=-1){
         print $self->getParsedTemplate($tmpl,{});
      }
   }
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}



sub preUpload                              # pre processing interface
{
   my $self=shift;
   my $inp=shift;
   return(1);
}

sub postUpload
{
   my $self=shift;
   my $inp=shift;
   return(1);
}

sub prepUploadFilterRecord
{
   my $self=shift;
   my $newrec=shift;

   foreach my $k (keys(%$newrec)){
      delete($newrec->{$k}) if ($newrec->{$k} eq "-");

   }
}

sub prepUploadRecord                       # pre processing interface
{
   my $self=shift;
   my $newrec=shift;

   my $idobj=$self->IdField();
   my $idname;

   if (defined($idobj)){
      $idname=$idobj->Name();
      if (!exists($newrec->{$idname}) || $newrec->{$idname} eq ""){
         if (exists($newrec->{srcid}) && $newrec->{srcid} ne ""){
            my $i=$self->Clone();
            $i->SetFilter({srcid=>\$newrec->{srcid},
                           srcsys=>'upload:'.$ENV{REMOTE_USER}});
            my ($rec,$msg)=$i->getOnlyFirst($idname);
            if (defined($rec)){
               $newrec->{$idname}=$rec->{$idname};
               delete($newrec->{srcid});
            }
         }
      }
      # Allow Admins to modify srcsys and srcid without write access
      if (exists($newrec->{srcid}) && exists($newrec->{srcsys}) &&
          exists($newrec->{$idname}) && $newrec->{$idname} ne "" &&
          $self->IsMemberOf("admin")){
         my $i=$self->Clone();
         $i->SetFilter({$idname=>$newrec->{$idname}});
         my ($oldrec,$msg)=$i->getOnlyFirst(qw(ALL));
         if (defined($oldrec)){
            my $nr={srcsys=>$newrec->{srcsys},srcid=>$newrec->{srcid}};
            if ($nr->{srcsys} eq ""){
               $nr->{srcsys}=undef;
            }
            if ($nr->{srcid} eq ""){
               $nr->{srcid}=undef;
            }
            $i->ValidatedUpdateRecord($oldrec,$nr,
                                      {$idname=>\$newrec->{$idname}});
         }
         delete($newrec->{srcid});
         delete($newrec->{srcsys});
      }
   }
   return(1);
}



sub translateUploadFieldnames              # translation interface
{
   my $self=shift;
   my @flistorg=@_;
   my @flistnew;

   my @fl=$self->getFieldObjsByView([qw(ALL)]);
   foreach my $fo (@fl){
      for(my $c=0;$c<=$#flistorg;$c++){
         if ($fo->Name eq $flistorg[$c]){
            $flistnew[$c]=$fo->Name;
         }
      }
   }
   for(my $c=0;$c<=$#flistorg;$c++){
      if (!defined($flistnew[$c])){
         foreach my $fo (@fl){
            my $label=$fo->Label;
            my $fieldHeader="";
            $fo->extendFieldHeader("Upload",{},\$fieldHeader,$self->Self);
            $label.=$fieldHeader;
            if ($label eq $flistorg[$c]){
               $flistnew[$c]=$fo->Name;
            }
         }
      }
   }
   return(@flistnew);
}

sub CachedTranslateUploadFieldnames
{
   my $self=shift;
   my @flistorg=@_;
   my $C=$self->Context;
   $C->{UploadFieldTrans}={} if (!defined($C->{UploadFieldTrans}));
   my @flistnew=@flistorg;
   my %notr;
   for(my $c=0;$c<=$#flistorg;$c++){
      if (exists($C->{UploadFieldTrans}->{$flistorg[$c]})){
         $flistnew[$c]=$C->{UploadFieldTrans}->{$flistorg[$c]};
      }
      else{
         $notr{$flistorg[$c]}=$c;
      }
   }
   if (keys(%notr)){
      my @reqtr=keys(%notr);
      my @newtr=$self->translateUploadFieldnames(@reqtr);
      for(my $cc=0;$cc<=$#reqtr;$cc++){
         $flistnew[$notr{$reqtr[$cc]}]=$newtr[$cc];
         $C->{UploadFieldTrans}->{$reqtr[$cc]}=$newtr[$cc];
      }
   }
   return(@flistnew);
}

sub ProcessUploadRecord
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;

   if ($param{debug}){
      foreach my $key (keys(%$rec)){
         my $val=$rec->{$key};
         $val=~s/\n/\\n/g;
         if (length($val) > 20){
            $val=substr($val,0,19)."...";
         }
         print msg(INFO,"  %-15s = %s","'".$key."'","'".$val."'");
      }
   }

   my $oldrec;
   my $flt;
   my $id;
   my $idobj=$self->IdField();
   if (defined($idobj)){
      my $idname=$idobj->Name();
      if (defined($rec->{$idname}) && !($rec->{$idname}=~m/^\s*$/)){
         $self->ResetFilter();
         $id=$rec->{$idname};
         $self->SetFilter({$idname=>\$id});
         $self->SetCurrentOrder("NONE");
         my ($chkoldrec,$msg)=$self->getOnlyFirst(qw(ALL));
         if (defined($chkoldrec)){
            $oldrec=$chkoldrec;
            $flt={$idname=>\$id};
            if ($param{debug}){
               print msg(INFO,"found current record ".
                              "and use this as oldrec");
            }
         }
         else{
            ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
            printf(msg(ERROR,$self->T("record id '%s' invalid - ".
                                      "no existing record with this id")),
                   $rec->{$idname});
            return(1);
         }
      }
      delete($rec->{$idname}); # id field isn't valid in Write-Request!
   }
   my $newrec=$self->getWriteRequestHash("upload",$oldrec,$rec);
   if (!defined($newrec)){
      if ($self->LastMsg()){
         print join("\n",$self->LastMsg());
      }
      else{
         print msg(ERROR,$self->T("record data mismatch"));
      }
      ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      return(1);
   }
   if (defined($oldrec)){
      my %origrec;
      foreach my $k (keys(%$newrec)){
         $origrec{$k}=$oldrec->{$k};
      }
      if ($self->SecureValidatedUpdateRecord($oldrec,$newrec,$flt)){
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,$self->T("record not update or update incomplete"));
            ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
         }
         if ($param{debug}){
            print msg(INFO,"update record with id $id");
         }
         ${$param{countok}}++ if (ref($param{countok}) eq "SCALAR");
         if ($param{infomail}){
            $self->SendUploadInfoMail2Databoss(\%param,\%origrec,$newrec,$id);
         }
      }
      else{
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,$self->T("record not updated"));
         }
         ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      }
   }
   else{
      my $newid=$self->SecureValidatedInsertRecord($newrec);
      if (!defined($newid)){
         if (!$self->LastMsg()){
            print msg(ERROR,"record not inserted - unknown error");
         }
         else{
            print join("\n",$self->LastMsg());
         }
         ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
      }
      else{
         if ($self->LastMsg()){
            print join("\n",$self->LastMsg());
            print msg(ERROR,"record not inserted or insert incomplete");
            ${$param{countfail}}++ if (ref($param{countfail}) eq "SCALAR");
         }
         else{
            if ($param{debug}){
               print msg(INFO,"insert record at id $newid");
            }
            ${$param{countok}}++ if (ref($param{countok}) eq "SCALAR");
         }
         if ($param{infomail}){
            $self->SendUploadInfoMail2Databoss(\%param,undef,$newrec,$newid);
         }
      }
   }
   $self->LastMsg("");
   return(1);
}


sub SendUploadInfoMail2Databoss
{
   my $self=shift;
   my $param=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $id=shift;
   my $infomailtext=$param->{infomailtext};
   return() if ($infomailtext=~m/^\s*$/);

   $self->ResetFilter();
   my $idname=$self->IdField()->Name();
   $self->SetFilter({$idname=>\$id});
   my ($current)=$self->getOnlyFirst(qw(ALL));

   my $cilabel=$self->getRecordHeader($current);
   my $lang=$self->Lang();
   my $userid=$self->getCurrentUserId();
   my $databossname;
   my $salutation="";


   my $databossid=$current->{databossid};
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$databossid});
   my ($databossrec)=$user->getOnlyFirst(qw(purename lastlang salutation));
   if (defined($databossrec)){
      $lang=$databossrec->{lastlang} if ($databossrec->{lastlang} ne "");
      $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      $databossname=$databossrec->{purename};
      my $fld=$user->getField("salutation");
      if ($databossrec->{salutation} ne ""){
         $salutation.=$fld->FormatedResult($databossrec,"HtmlMail")." ";
      }
   }
   if ($databossname eq ""){
      $databossname=$self->T("Databoss");
   }
   my $deltalog="";
   foreach my $k (sort(keys(%{$newrec}))){
      if (!defined($oldrec) ||
           $current->{$k} ne $oldrec->{$k}){
         my $fld=$self->getField($k,$current);
         my $oldval="";
         $oldval=$oldrec->{$k} if (defined($oldrec));
         my $newval=$fld->FormatedResult($current,"Csv01");
         $oldval=limitlen($oldval,15,1);
         $newval=limitlen($newval,15,1);
         my $label=$fld->Label();
         $label=limitlen($label,20,1);
         
         if (!($oldval eq "" && $newval eq "")){    
            $deltalog.="<b>$label:</b>\n ".
                       "&bull; \"".$oldval."\" -&gt; \"".$newval."\"\n\n"; 
         }
      }
   }
   if ($deltalog ne ""){
      my $itext=extractLangEntry($infomailtext,$lang,8192,1);
      $self->ParseTemplateVars(\$itext,{current=>$current,
                                        static=>{
                                           SALUTATION=>$salutation,
                                           CILABEL=>$cilabel,
                                           DELTALOG=>$deltalog,
                                           DATABOSSNAME=>$databossname
                                        }});
      
      print msg(INFO,"sending infomail to $databossname ($lang)");
      my $wfa=$self->getPersistentModuleObject("InfoMailSender",
                                               "base::workflowaction");
      $wfa->Notify("INFO",$self->T("centralized data upload to").
                          " ".$cilabel,$itext,
                   dataobj=>$self->Self(),
                   dataobjid=>$id,
                   emailfrom=>$userid,
                   emailto=>$databossid,
                   emailbcc=>$userid);
   }
   else{
      print msg(INFO,"sending NO infomail - no changes detected");
   }
   delete($ENV{HTTP_FORCE_LANGUAGE});
}



sub Upload
{
   my $self=shift;
   my %param=@_;

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   my $infomail=0;
   my $infomailtext;
   if (Query->Param("INFOMAIL") ne ""){
      $infomail=1;
      $infomailtext=Query->Param("INFOMAILTEXT");
   }
   my $file=Query->Param("file");
   my $HistoryComments=Query->Param("HistoryComments");
   if (trim($HistoryComments) ne ""){
      $W5V2::HistoryComments=$HistoryComments;
   }
   my $countcallback=0;
   my $countok=0;
   my $countfail=0;
   if (defined($file) && $file ne "" && (ref($file) eq "Fh" ||
                                         ref($file) eq "CGI::File::Temp")){
      my @stat=stat($file);
      if ($stat[7]<=0){
         print $self->HttpHeader("text/plain");
         print msg(ERROR,"nix drin");
      }
      else{
         my $debug=0;
         $debug=1 if (defined(Query->Param("DEBUG") &&
                      (Query->Param("DEBUG") ne "")));
         print $self->HttpHeader("text/plain");
         $|=1;
         my $inp=new kernel::Input($self,debug=>$debug);
         $inp->SetInput($file);
         if ($inp->isFormatUseable()){
            my $lang=$self->Lang();
            my $p=$self->Self();
            $p=~s/::/\//g;
            print msg(INFO,"start upload processing width lang=%s at %s",
                           $lang,$p);
            if ($self->preUpload($inp)){
               $inp->SetCallback(sub{
                                   $self->FullContextReset();
                                   $countcallback++;
                                   my $prec=shift;
                                   my $ptyp=shift;
                                   $ptyp=$p if (!defined($ptyp));
                                   $ptyp=~s/\//::/g;
                                   if ($ptyp eq $self->Self()){
                                      $self->prepUploadFilterRecord($prec);

                                      my $fldchk=1;
                                      foreach my $fieldname (keys(%$prec)){
                                         my $fobj=$self->getField($fieldname);
                                         if (!defined($fobj) || 
                                             !($fobj->Uploadable())){
                                            my $label=$fieldname;
                                            if (defined($fobj)){
                                               $label=$fobj->Label();
                                               my $fieldHeader="";
                                               $fobj->extendFieldHeader(
                                                   "Upload",{},\$fieldHeader,
                                                   $self->Self);
                                                   $label.=$fieldHeader;
                                            }
                                            if (!defined($fobj)){
                                               $self->LastMsg(ERROR,
                                                  'field "%s" is not '.
                                                  'allowed to be '.
                                                  'uploaded',
                                                  $fieldname);
                                               $fldchk=0;
                                               last;
                                            }
                                            if ($fobj->Name() ne "srcid" &&
                                                $fobj->Name() ne "srcsys"){
                                               $self->LastMsg(ERROR,
                                                  'field "%s" is not '.
                                                  'allowed to be '.
                                                  'uploaded',
                                                  $label."($fieldname)");
                                               $fldchk=0;
                                               last;
                                            }
                                         }
                                      }
                                      if ($fldchk &&
                                          $self->prepUploadRecord($prec)){
                                         $self->ProcessUploadRecord($prec,
                                                  debug=>$debug,
                                                  countok=>\$countok,
                                                  countfail=>\$countfail,
                                                  infomail=>$infomail,
                                                  infomailtext=>$infomailtext);
                                      }
                                      else{
                                         $countfail++;
                                         print join("",$self->LastMsg());
                                      }
                                   }
                                   else{
                                      print msg(INFO,"unsupported record ".
                                                     "typ '%s'",$ptyp);
                                      $countfail++;
                                      return(undef);
                                   }
                                   return(1); 
                                 });
               $inp->Process();
               if ($countcallback>0){
                  print msg(INFO,"end upload processing ".
                                 "user $ENV{REMOTE_USER} ".
                                 "(result: ok=$countok;fail=$countfail)");
               }
               else{
                  print msg(INFO,"end upload processing ".
                                 "user $ENV{REMOTE_USER} ".
                                 "(Process only load)");
               }
            }
            $self->postUpload($inp);
         }
         else{
            print msg(ERROR,$self->T("can't interpret input format"));
         }
      }
   }
   else{
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css',
                                      'kernel.App.Web.css',
                                      'upload.css',
                                       ],
                              body=>1,form=>1,
                              title=>'W5BaseV2-Upload');
     
      print("... gib hal a dadai o!");
     
      print $self->HtmlBottom(body=>1,form=>1);
   }
}


sub UploadFrame
{
   my $self=shift;
   my %param=@_;
   my $infomailmode=0;

   my $databossidfld=$self->getField("databossid");
   if (defined($databossidfld)){
      $infomailmode=1;
   }

   if (!$self->isUploadValid()){
      print($self->noAccess()); 
      return(undef); 
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'upload.css',
                                    ],
                           js=>['OutputHtml.js'],
                           target=>'uploadresult',body=>1,
                           title=>'W5BaseV2-Upload');
   print("<form action=\"Upload\" enctype=\"multipart/form-data\" ".
         "method=POST onsubmit=\"PreventDoublePost();\">");
   my @fnames=();
   foreach my $field ($self->getFieldList()){
      my $fobj=$self->getField($field);
      next if (!$fobj->Uploadable());
      push(@fnames,$fobj->Name());
   }
   my $fnames=join(",",@fnames);

   print(<<EOF);
<script language=JavaScript>
function DownloadTemplate(format)
{
   parent.document.forms[0].elements['CurrentView'].value="($fnames)";
   var bk=DirectDownload(this,format,"uploadresult");
   parent.document.forms[0].elements['CurrentView'].value="";
   return(bk);
}
var isloading=1;
var oldscroll=0;
function SetButtonState(flag)
{
   var d=window.document;
   for(c=0;c<d.forms.length;c++){
      var f=d.forms[c];
      for(cc=0;cc<f.elements.length;cc++){
         if (f.elements[cc].type=="submit"){
            f.elements[cc].disabled=flag;
         }
      }
   }
}
function isLoaded()
{
   isloading=0;
   window.setTimeout('SetButtonState(false);',500);
}

function PreventDoublePost()
{
   var d=window.document;

   frames['uploadresult'].document.open();
   frames['uploadresult'].document.write("<pre>loading ...</pre>");
   isloading=1;
   SetButtonState(true);
   oldscroll=frames['uploadresult'].document.body.scrollTop;
   window.setTimeout('ScrollDown();',5);
   return(true);
}
function ScrollDown()
{ 
   frames['uploadresult'].document.
         getElementsByTagName("pre")[0].style.fontSize="11px";
   if (oldscroll==frames['uploadresult'].document.body.scrollTop){
      var o=frames['uploadresult'].document.body.scrollTop;
      frames['uploadresult'].scrollBy(0,5);
      if ((frames['uploadresult'].document.body.scrollTop!=o &&
          isloading==0) ||
          isloading==1){
         window.setTimeout('ScrollDown();',5);
      }
   }
   else{
      window.setTimeout('ScrollDown();',3000);
   }
   oldscroll=frames['uploadresult'].document.body.scrollTop;
}
</script>
EOF
   print("<center><table border=0 ".
         "width=\"100%\" height=\"100%\" cellpadding=5>");
   print("<tr><td align=center valign=top>");
   print("<table width=\"70%\" class=uploadframe border=0>");
   print("<tr><td>");
   print("<table  border=0 width=\"100%\" cellspacing=0 cellpadding=0>");
   print("<tr><td><table border=0 width=\"100%\" border=0 ".
         "cellspacing=0 cellpadding=0><tr><td valign=top width=1%>");


   printf("<table border=0><tr><td><b><u>%s:</u></b></td></tr>",$self->T("Upload Templates"));
   print("<tr><td align=center>");
   my @formats=(icon_xls=>'XlsV01',
                icon_xml=>'XMLV01');
               # icon_csv=>'CsvV01');
   while(my $ico=shift(@formats)){
      my $f=shift(@formats);
      print("<a target=_self href=JavaScript:DownloadTemplate(\"$f\")>");
      print("<img style=\"margin-left:20px;margin-right:20px\" ".
            "border=0 src=\"../../base/load/$ico.gif\">");
      print("</a>");
   }
   print("</td></tr></table>");
   my $w=20;
   if (!$self->IsMemberOf("admin")){
      $w=50;
   }

#   print("</td><td width=$w% valign=bottom>"); ##############################


   print("</td>");
   #if ($self->IsMemberOf("admin")){  # laut Carina sind die HistoryComments
                                 # für alle sinnvoll
   # siehe: 
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/13817467940005
                                   
   print("<td valign=bottom>"); ################################
   print("<table border=0 width=\"100%\" cellspacing=0 cellpadding=0>");
   print("<tr><td><u><b>History note:</b></ul></td></tr><td>".
         "<textarea style=\"width:100%\" ".
         "name=HistoryComments wrap=off rows=3 cols=10></textarea>");
   print("</td><tr></table>");
   print("</td>");
   #}
   print("</tr>");
   print("</table></td>");
   print("</td></tr>");
   print("<tr><td>");
   print("<hr>");


   print("<table border=0 width=\"100%\">");
   printf("<tr><td width=100 nowrap><b><u>%s:</u></b></td>",
          $self->T("Upload File"));
   print("<td align=left><input size=55 type=file name=file></td></tr>");
   print("</tr></table><hr>");

   if ($infomailmode){
      my $infomailtemplate=$self->getTemplate("tmpl/uploadinfomail","base");

      printf("<div id=info style=\"visibility:hidden;display:none\">");
      print("<table border=0 width=\"100%\" cellspacing=0 cellpadding=0>");
      print("<tr><td><u><b>".$self->T("Info mail to databoss").
            ":</b></ul></td></tr><td>".
            "<textarea style=\"width:100%\" ".
            "name=INFOMAILTEXT  rows=5 cols=10>".$infomailtemplate.
            "</textarea>");
      print("</td><tr></table>");
      printf("</div>");
   }


   printf("<table border=0 width=100%>");
   print("<tr>");
   print("<td width=25% align=center aria-hidden=true>&nbsp;</td>");


   print("<td align=center>");
   printf("<input class=uploadbutton style=\"width:250px\" ".
          "type=submit value=\"%s\" ".
         "></td>",$self->T("start upload"));

   print("<td width=25% align=center>");
   print("<input type=checkbox class=checkbox name=DEBUG>Debug");
   if ($infomailmode){
      print("&nbsp;&nbsp;");
      print("<input type=checkbox class=checkbox name=INFOMAIL ".
            "onclick=\"document.getElementById('info').style.visibility=".
                        "(this.checked)?'visible':'hidden';".
                     "document.getElementById('info').style.display=".
                        "(this.checked)?'block':'none';\">InfoMail");
   }
   print("</td>");

   print("</tr></table><hr>");

   print("<table border=0 width=\"100%\">");
   printf("<tr><td><b><u>%s:</u></b></td></tr>",$self->T("Upload Result"));
   print("<tr><td>");
   print("<iframe onload=\"isLoaded(self);\" ".
         "id=uploadresult src=\"UploadWelcome\" name=uploadresult ".
         "style=\"width:100%\"></iframe>");
   print("</td></tr>");
   print("</table>");
 #  print("</td></tr>");
 #  print("</table>");


   print("</td></tr>");
   print("</table></center>");
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Result
{
   my $self=shift;
   my %param=@_;
   $self->doFrontendInitialize();
   my $output=new kernel::Output($self);
   if ($self->validateSearchQuery()){
      if (!$param{ExternalFilter}){
         $self->ResetFilter();
         my %q=$self->getSearchHash();
         $self->SecureSetFilter(\%q);
         if ($self->LastMsg()>0){
            print $self->queryError();
            return();
         }
         $param{'currentFrontendFilter'}=\%q;
      }

      my $view=Query->Param("CurrentView");

      if (defined($param{ForceOrder})){
         my @o=split(/\s*,\s*/,$param{ForceOrder});
         $self->setCurrentOrder(@o);
         $param{'currentFrontendOrder'}=\@o;
      }
      else{
         my $order=Query->Param("ForceOrder");
         if ($order ne ""){
            my @o=split(/\s*,\s*/,$order);
            $self->setCurrentOrder(@o);
            $param{'currentFrontendOrder'}=\@o;
         }
      }

      my $format=Query->Param("FormatAs");
      if (!defined($format)){
         if (lc($ENV{HTTP_ACCEPT}) eq "application/json"){
            Query->Param("FormatAs"=>"nativeJSON");
            $format="nativeJSON";
         }
      }
      #msg(INFO,"FormatAs from query: $format");
      if (defined($param{FormatAs})){
         Query->Param("FormatAs"=>$param{FormatAs});
         $format=$param{FormatAs};
      }
      $format=~s/;-*//;  # this is a hack, to allow enveloped formats


      if ((!defined($format) || $format eq "")){
         Query->Param("FormatAs"=>"HtmlFormatSelector");
         $self->Limit(1);
      }
      my $format=Query->Param("FormatAs");
      #msg(INFO,"----------------------------- Format: $format ".
      #         "-----------------------------\n");
      $param{WindowMode}="Result";
      
      if (!($output->setFormat($format,%param))){
         # can't set format
         return();
      }
      my $uselimit=Query->Param("UseLimit");
      my $uselimitstart=Query->Param("UseLimitStart");
      $uselimitstart=0 if (!defined($uselimitstart));
      if (defined($param{Limit}) && $uselimit eq ''){
         $uselimit=$param{Limit};
      }
      if ($format eq "JSONP" || $format eq "nativeJSONP" ||
          $format eq "nativeJSON"){
         $self->Limit($uselimit,$uselimitstart,0);
      }
      else{
         if (!defined($uselimit) || $uselimit==0 || $format ne "HtmlV01"){
            $self->Limit(0);
         }
         else{
            $self->Limit($uselimit,$uselimitstart,$self->{UseSoftLimit});
         }
      }
      if (defined($param{CurrentView})){
         $self->SetCurrentView(@{$param{CurrentView}});
      }
      else{
         if ((!defined($view) || $view eq "" || $view eq "default")){
            Query->Param("CurrentView"=>"default");
         }
         $self->SetCurrentView($self->getDefaultView());
         my $currentview=Query->Param("CurrentView");
         $self->SetCurrentView($self->getFieldListFromUserview($currentview));
      }
      my @view=$self->GetCurrentView();
      $self->Log(INFO,"viewreq","$ENV{REMOTE_USER} ".
                                $self->Self." ".join(",",@view)); 
      if ($format eq "MONI"){
         $self->doInitialize(1); # Init with errors to LastMsg
      }
      $output->WriteToStdout(HttpHeader=>1);
   }
   else{
      if ($self->LastMsg()){
         print($self->noAccess());
      }
   }
   return(0);
}

sub ListeditTabObjectSearch
{
   my $self=shift;
   my $resultname=shift;
   my $searchmask=shift;

   my $idname=$self->IdField()->Name();
   my $id=Query->Param($idname);
   my $CurrentView=Query->Param("CurrentView");
   if ($id eq ""){
      print $self->HttpHeader("text/plain");
      print ("ERROR: no id");
      return();
   }
   $self->ResetFilter();
   $self->SetFilter({$idname=>\$id}); 
   $self->SetCurrentOrder("NONE");
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (!$self->isViewValid($rec,resultname=>$resultname)){
      print($self->noAccess());
      return(undef);
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'Output.ListeditTabObject.css',
                                   'kernel.App.Web.css',
                                    ],
                           js=>['toolbox.js','kernel.App.Web.js'],
                           submodal=>1,
                           body=>1,form=>1,
                           title=>'W5BaseV1-System');
   print("<table class=HtmlWorkflowLink width=\"100%\" height=\"100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   printf("<tr><td height=1%%>%s</td></tr>",$searchmask);
   my $welcomeurl="../../base/load/tmpl/empty";
   my $s=$self->Self();  # to allow individual views
   my $d=<<EOF;
<tr><td><iframe class=result name="Result" src="$welcomeurl"></iframe></td></tr>
</table>
<input type=hidden name=UseLimit value="50">
<input type=hidden name=UseLimitStart value="0">
<input type=hidden name=FormatAs value="HtmlV01">
<input type=hidden name=CurrentView value="$CurrentView">
<input type=hidden name=MyW5BaseSUBMOD value="$s">
<script language="JavaScript">
addEvent(window, "load", DoSearch);
function DoRemoteSearch(action,target,FormatAs,CurrentView,DisplayLoadingSet)
{
   var d;
   if (action){
      document.forms[0].action=action;
      document.forms[0].action="$resultname";
   }
   if (target){
      document.forms[0].target=target;
   }
   if (FormatAs){
      document.forms[0].elements['FormatAs'].value=FormatAs;
   }
   if (CurrentView){
      document.forms[0].elements['CurrentView'].value=CurrentView;
   }
   if (DisplayLoadingSet){
      DisplayLoading(frames['Result'].document);
   }
   document.forms[0].submit();
   return;
}
function DoSearch()
{
   var d;
   document.forms[0].action='$resultname';
   document.forms[0].target='Result';
   document.forms[0].elements['FormatAs'].value='HtmlV01';
   document.forms[0].elements['UseLimitStart'].value='0';
   document.forms[0].elements['UseLimit'].value='50';
  // DisplayLoading(frames['Result'].document);
   document.forms[0].submit();
   return;
}

</script>
EOF
   Query->Param("CurrentId"=>$id);
   $d.=$self->HtmlPersistentVariables(qw(CurrentId));
   $self->ParseTemplateVars(\$d);
   print $d;
   print $self->HtmlBottom(body=>1,form=>1);

}


sub findtemplvar
{
   my $self=shift;
   my ($opt,$vari,@param)=@_;

   return($self->SUPER::findtemplvar(@_));
}



######################################################################

1;
