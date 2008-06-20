package base::w5stat;
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
use kernel::date;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use DateTime;
use DateTime::Span;
use DateTime::SpanSet;
use POSIX qw(floor);
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'w5stat.id'),
                                                  
      new kernel::Field::Select(
                name          =>'sgroup',
                label         =>'Statistic Group',
                value         =>['Group','Application','Location','User',
                                 'Contract'],
                dataobjattr   =>'w5stat.statgroup'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Statistic Name',
                dataobjattr   =>'w5stat.name'),

      new kernel::Field::Link(
                name          =>'nameid',
                label         =>'Statistic Name last ID',
                dataobjattr   =>'w5stat.nameid'),

      new kernel::Field::Text(
                name          =>'month',
                label         =>'Month',
                dataobjattr   =>'w5stat.month'),


      new kernel::Field::Container(
                name          =>'stats',
                group         =>'stats',
                desccolwidth  =>'200',
                uivisible     =>1,
                selectfix     =>1,
                label         =>'Statistic Data',
                dataobjattr   =>'w5stat.stats'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'w5stat.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'w5stat.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'w5stat.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'w5stat.srcload'),

      new kernel::Field::Link(
                name          =>'nameid',
                group         =>'source',
                label         =>'NameID',
                dataobjattr   =>'w5stat.nameid'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'w5stat.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'w5stat.modifydate'),


   );
   $self->LoadSubObjs("ext/w5stat","w5stat");
   $self->LoadSubObjs("ext/w5workflowstat","w5workflowstat");
   $self->setDefaultView(qw(linenumber month sgroup fullname mdate));
   $self->setWorktable("w5stat");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","stats","source");
}


sub recreateStats
{
   my $self=shift;
   my $mode=shift;
   my $monthstamp=shift;
   my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
   my $currentmonth=sprintf("%04d%02d",$year,$mon);
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;


   $self->{stats}={};
   msg(INFO,"processData handler Status:");
   msg(INFO,"===========================");
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processData")){
         msg(INFO,"found processData handler in %s",$obj->Self);
      }
   }
   msg(INFO,"processRecord handler Status:");
   msg(INFO,"=============================");
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processRecord")){
         msg(INFO,"found processRecord handler in %s",$obj->Self);
      }
   }
   foreach my $obj (values(%{$self->{$mode}})){
      if ($obj->can("processData")){
         $obj->processData($monthstamp,$currentmonth);
      }
   }

   my $d1=new DateTime(year=>$year, month=>$month, day=>1,
                       hour=>0, minute=>0, second=>0);
   my $dm=DateTime::Duration->new( months=>1);
   my $d2=$d1+$dm;
   my $basespan;
   eval('$basespan=DateTime::Span->from_datetimes(start=>$d1,end=>$d2);');
   my $baseduration=CalcDateDuration($d1,$d2);
   foreach my $group (keys(%{$self->{stats}})){
      foreach my $name (keys(%{$self->{stats}->{$group}})){
         foreach my $v (keys(%{$self->{stats}->{$group}->{$name}})){
            if (ref($self->{stats}->{$group}->{$name}->{$v})){
               my $spanobj=$self->{stats}->{$group}->{$name}->{$v};
               $spanobj=$spanobj->intersection($basespan);
               my $vv=$v.".count";
               my @splist=$spanobj->as_list();
               $self->{stats}->{$group}->{$name}->{$vv}=$#splist+1;
               my $minsum=0;
               my $minmax=0;
               foreach my $span (@splist){ 
                  my $d=CalcDateDuration($span->start,$span->end);
                  $minsum+=$d->{totalminutes};
                  $minmax=$d->{totalminutes} if ($minmax<$d->{totalminutes});
               }
               my $vv=$v.".total";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',$minsum);
               my $vv=$v.".max";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',$minmax);
               my $vv=$v.".base";
               $self->{stats}->{$group}->{$name}->{$vv}=sprintf('%.4f',
                                                $baseduration->{totalminutes});
               delete($self->{stats}->{$group}->{$name}->{$v});
            }
         }
         my $nameid;
         if (defined($self->{stats}->{$group}->{$name}->{nameid})){
            $nameid=$self->{stats}->{$group}->{$name}->{nameid};
            delete($self->{stats}->{$group}->{$name}->{nameid});
         }
         my $statrec={stats=>$self->{stats}->{$group}->{$name},
                      sgroup=>$group,
                      month=>$monthstamp,
                      nameid=>$nameid,
                      fullname=>$name};
         $self->ValidatedInsertOrUpdateRecord($statrec,
                                            {sgroup=>\$statrec->{sgroup},
                                             month=>\$monthstamp,
                                             fullname=>\$statrec->{fullname}});
      }
   }
}

sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;

   foreach my $obj (values(%{$self->{w5stat}}),
                    values(%{$self->{w5workflowstat}})){
      if ($obj->can("processRecord")){
         $obj->processRecord($module,$month,$rec,$self->{stats}); 
      }
   }
}

sub storeStatVar
{
   my $self=shift;
   my $group=shift;
   my $key=shift;
   my $param=shift;
   my $var=shift;
   my @val=@_;
   my $method=$param->{method};
   my $maxlevel=$param->{maxlevel};
   my $nameid=$param->{nameid};
   $method="count" if (!defined($method));

   my @key=($key);
   @key=@$key if (ref($key) eq "ARRAY");
   my %key=();
   foreach my $k (@key){  # make all keys unique
     if ($k ne ""){
        $key{$k}=1;
     }
   }
   @key=keys(%key);

   my %isAlreadyCounted=(); 
   foreach my $key (@key){
      my $level=0;
      if ($var ne ""){
         while(1){
            if ($key ne "" && !defined($isAlreadyCounted{$key})){
               if (defined($nameid) && $level==0){
                  $self->{stats}->{$group}->{$key}->{nameid}=$nameid;
               }
               if (lc($method) eq "count"){
                  $self->{stats}->{$group}->{$key}->{$var}+=$val[0];
               }
               if (lc($method) eq "concat"){
                  if ($self->{stats}->{$group}->{$key}->{$var} ne ""){
                     $self->{stats}->{$group}->{$key}->{$var}.=", ";
                  }
                  $self->{stats}->{$group}->{$key}->{$var}.=$val[0];
               }
               elsif (lc($method) eq "tspan.union"){

                  if ((my ($Y1,$M1,$D1,$h1,$m1,$s1)=$val[0]=~
                       m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) &&
                      (my ($Y2,$M2,$D2,$h2,$m2,$s2)=$val[1]=~
                       m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)){
                     my $d1=new DateTime(year=>$Y1, month=>$M1, day=>$D1,
                                         hour=>$h1, minute=>$m1, second=>$s1);
                     my $d2=new DateTime(year=>$Y2, month=>$M2, day=>$D2,
                                         hour=>$h2, minute=>$m2, second=>$s2);
                     my $span;
                     eval('$span=DateTime::Span->from_datetimes(start=>$d1,
                                                                end=>$d2);');
                     if ($@ eq ""){
                        my $v=$var.".tspan.union";
                        if (!defined($self->{stats}->{$group}->{$key}->{$v})){
                           $self->{stats}->{$group}->{$key}->{$v}=
                               DateTime::SpanSet->from_spans(spans=>[$span]);
                        }
                        else{
                           $self->{stats}->{$group}->{$key}->{$v}=
                           $self->{stats}->{$group}->{$key}->{$v}->union($span);
                        }
                     }
                     else{
                        printf STDERR ("ERROR: %s\n",$@);
                        printf STDERR ("ERROR: eventstart=$val[0]\n");
                        printf STDERR ("ERROR: eventend  =$val[1]\n");
                        printf STDERR ("ERROR: key       =$key\n");
                        printf STDERR ("ERROR: group     =$group\n");
                       # exit(1);
                     }
                  }
               }
               $isAlreadyCounted{$key}++;
            }
            if ((!$param->{nosplit}) && $key=~m/\.[^\.]+$/){
               $key=~s/\.[^\.]+$//;
               $level++;
            }
            else{
               last;
            }
            last if (defined($maxlevel) && $level>$maxlevel);
         }
      }
   }
}

sub getValidWebFunctions
{
   my $self=shift;
   return("Presenter","ShowEntry",
          $self->SUPER::getValidWebFunctions());
}


sub ShowEntry
{
   my $self=shift;
   my $requestid=Query->Param("id");
   my $requesttag=Query->Param("tag");
   my ($rmod,$rtag)=$requesttag=~m/^(.*)::([^:]+)$/;
   my $title=$self->T("W5Base Statistic Presenter");
   my $subtitle=$self->T($requesttag,$rmod);
   $title.=" - ".$subtitle;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','w5stat.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1,
                           title=>$title);

   my ($primrec,$hist)=$self->LoadStatSet(id=>$requestid);

   if (defined($primrec)){
      my $load=$self->findtemplvar({current=>$primrec,mode=>"HtmlV01"},"mdate","formated");
      my $month=$primrec->{month};
      my $condition=$self->T("condition");
      my ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/;
      print(<<EOF);
<div style="margin:10px;padding:15px;width:600px;background:#ffffff;
            border-color:black;border-style:solid;border-width:1px;">
<div class=chartlabel>
Quality Report $M/$Y - $primrec->{fullname}
</div>
<div class=chartsublabel>
$subtitle
</div>
<script type="text/javascript" src="../../../static/open-flash-chart/js/swfobject.js"></script>
EOF
      if ($requesttag ne ""){
     
         foreach my $obj (values(%{$self->{w5stat}})){
            if ($obj->Self() eq $rmod){
               if ($obj->can("getPresenter")){
                  my %P=$obj->getPresenter();
                  if (defined($P{$rtag})){
                     print &{$P{$rtag}->{opcode}}($obj,$primrec,$hist);
                  }
               }
            }
         }
      }
     
      print(<<EOF);
<div class=condition>$condition: $load</div>
</div>

EOF
   }
   print $self->HtmlBottom(body=>1,form=>1);
}


sub LoadStatSet
{
   my $self=shift;
   my $type=shift;
   my $id=shift;
   my $month=shift;

   $self->ResetFilter();
   if ($type eq "id"){
      $self->SecureSetFilter({id=>\$id});
   }
   if ($type eq "grpid"){
      $self->SecureSetFilter({sgroup=>\'Group',nameid=>\$id,month=>\$month});
   }
   my ($primrec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($primrec)){
      if (ref($primrec->{stats}) ne "HASH"){
         $primrec->{stats}={Datafield2Hash($primrec->{stats})};
      }
      $self->ResetFilter();
      $self->SecureSetFilter({fullname=>\$primrec->{fullname},
                              sgroup=>\$primrec->{sgroup}});
      my $month=$primrec->{month};
      my ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/;
      $M--;
      if ($M<=0){
         $M=12;
         $Y--;
      }
      my $lastmonth=sprintf("%04d%02d",$Y,$M);
      my $hist={area=>[]};
      foreach my $srec ($self->getHashList(qw(ALL))){
         if (ref($srec->{stats}) ne "HASH"){
            $srec->{stats}={Datafield2Hash($srec->{stats})};
         }
         push(@{$hist->{area}},$srec);
         if ($lastmonth eq $srec->{month}){
            $hist->{lastmonth}=$srec;
         }
      }
      return($primrec,$hist);

   }
   return($primrec,[]);
}


sub Presenter
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1,action=>'../ShowEntry',
                           prefix=>$rootpath,
                           title=>"W5Base Statistik Presenter");
   print $self->HtmlSubModalDiv(prefix=>$rootpath);
   print("<style>body{overflow:hidden}</style>");


   my $requestid=$p;
   $requestid=~s/[^\d]//g;

   my ($primrec,$hist)=$self->LoadStatSet(id=>$requestid);


   if (!defined($primrec) && $requestid ne ""){
      print "Requested Record '$requestid' not found";
      print $self->HtmlBottom(body=>1,form=>1);
      return();
   }

   print("<table width=100% height=100% border=0>");

   printf("<tr height=1%><td>");
   print $self->getAppTitleBar(prefix=>$rootpath,
                               title=>'W5Base Statistik Presenter');
   printf("</td></tr>");


   my %histid;
   my @ol;
   my ($Y,$M,$month);
   if (defined($primrec)){
      push(@ol,$primrec->{id},$primrec->{fullname});
      foreach my $h (@{$hist->{area}}){
         $histid{$h->{month}}=$h->{id};
      }
      $month=$primrec->{month};
      ($Y,$M)=$month=~m/^(\d{4})(\d{2})$/;
   }
   else{
      my ($year,$mon,$day, $hour,$min,$sec) = Today_and_Now("GMT");
      push(@ol,"-","- select a statistic -");
      $Y=$year;
      $M=$mon;
      $month=sprintf("%04d%02d",$year,$mon);
   }
   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                    ['REmployee','RBoss','RReportReceive'],"both");
   my @grpnames;
   my @grpids;
   foreach my $id (keys(%grps)){
      push(@grpids,$id);
   }
   foreach my $g (values(%grps)){
      push(@grpnames,$g->{fullname});
   }

   $self->ResetFilter();
   $self->SecureSetFilter([
                           {month=>\$month,sgroup=>\'Group',
                            fullname=>\@grpnames},
                           {month=>\$month,sgroup=>\'Group',
                            nameid=>\@grpids},
                          ]);

   foreach my $r (sort({$b->{fullname} cmp $a->{fullname}}
                            $self->getHashList(qw(fullname id)))){
      push(@ol,$r->{id},$r->{fullname});
   }



   print("<tr height=1%><td>");
   print("<table width=100%><tr>\n");
   print("<td width=1%><select name=selid onchange=\"changeid(this);\" ".
         "style=\"width:300px\">");
   while(my $k=shift(@ol)){
      my $label=shift(@ol);
      printf("<option value=\"%s\">%s</option>",$k,$label);
   }
   print("</select></td>");
   
   my $mstr="";
   my ($Y1,$M1)=($Y,$M);
   sub getLabelString
   {
      my $histid=shift;
      my $M1=shift;
      my $Y1=shift;
      my $k=sprintf("%04d%02d",$Y1,$M1);
      if (defined($histid->{$k})){
         return(sprintf("<td align=center>".
                        "<a href=javascript:refreshTag($histid->{$k})>".
                        "%02d<br>%4d</a></td>",$M1,$Y1));
      }
      return(sprintf("<td align=center>%02d<br>%4d</td>",$M1,$Y1));
      
   }
   for(my $c=0;$c<=7;$c++){
      $mstr.=getLabelString(\%histid,$M1,$Y1);
      $M1++;
      if ($M1>12){
         $Y1++;
         $M1=1;
      }
   }
   my ($Y1,$M1)=($Y,$M);
   for(my $c=0;$c<7;$c++){
      $M1--;
      if ($M1<1){
         $Y1--;
         $M1=12;
      }
      $mstr=getLabelString(\%histid,$M1,$Y1).$mstr;
   }

   print($mstr."</tr></table>\n");
   printf("</td></tr>");


   printf("<tr><td valign=top>");

   print("<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>");
   printf("<tr>");
   printf("<td width=150 valign=top>");

   my @Presenter;
   my $oldtag=Query->Param("tag");
   if (defined($primrec)){
      foreach my $obj (values(%{$self->{w5stat}})){
         if ($obj->can("getPresenter")){
            my %P=$obj->getPresenter();
            foreach my $p (values(%P)){
               $p->{module}=$obj->Self();
            }
            push(@Presenter,%P);
         }
      }
      $oldtag="base::ext::w5stat::overview" if ($oldtag eq "");
      my %P=@Presenter;
      print("<ul>");
      foreach my $p (sort({$P{$a}->{prio} <=> $P{$b}->{prio}} keys(%P))){
         my $prec=$P{$p};
         my $tag=$prec->{module}."::".$p;
         my $label=$self->T($tag,$prec->{module});
         my $link="javascript:setTag($requestid,\"$tag\")";
         print "<li><a href=$link>".$label."</a></li>";
         if ($p eq "overview"){
            print "</ul><br><u>".$self->T("Details").":</u><ul>";
         }
      }
      printf("</ul>");
   }

   printf("</td>");
   print("<td valign=top style=\"padding-right:5px\">".
        "<iframe name=entry width=100% height=100% ".
        "src=\"../ShowEntry?id=$requestid&tag=$oldtag\">".
        "</iframe></td>");
   print ("</tr></table>");
   print ("</td></tr>");
   print ("</table>");
   print(<<EOF);
<input type=hidden name=id value="$requestid">
<input type=hidden name=tag value="$oldtag">
<script language="JavaScript">
function setTag(id,tag)
{
   document.forms[0].elements['id'].value=id;
   if (tag){
      document.forms[0].elements['tag'].value=tag;
   }
   document.forms[0].target="entry";
   document.forms[0].submit();
}
function refreshTag(id)
{
   document.forms[0].elements['id'].value=id;
   document.forms[0].action=id;
   document.forms[0].target="_self";
   document.forms[0].submit();
}
function changeid(bo)
{
   refreshTag(bo.value);
}
</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


sub buildChart
{
   my $self=shift;
   my $name=shift;
   my $data=shift;
   my %param=@_;
   my $d="";
   $param{width}=540            if (!defined($param{width}));
   $param{height}=300           if (!defined($param{height}));
   $param{mode}="line_dot"      if (!defined($param{mode}));
   $param{legend}=$param{label} if (!defined($param{legend}));
   my $w=$param{width};
   my $h=$param{height};
   my $swfobjcode="static/open-flash-chart/actionscript/open-flash-chart.swf";
   my $so="SO_$name";


   my $vstring="";
   my $ymax=9;
   foreach my $d (@$data){
      $vstring.="," if ($vstring ne "");
      if (defined($d)){
         $vstring.=$d;
         $ymax=$d if ($ymax<$d);
      }
      else{
         $vstring.="null";
      }
   }
   $ymax=int($ymax*1.15);
  
   
   my $datacode;
  
   my $maxdataset; 
   if (defined($param{greenline})){
      my @grline;
      for(my $c=0;$c<12;$c++){
         push(@grline,$param{greenline});
      }
      my $grline=join(",",@grline);
      $datacode="$so.addVariable(\"values\",\"$grline\");\n".
                "$so.addVariable(\"line\",\"1,0x00ff00\");\n".
                "$so.addVariable(\"values_2\",\"$vstring\");\n".
                "$so.addVariable(\"$param{mode}_2\",\"3,0xff0000,".
                $param{legend}.",10,4\");\n";
      $maxdataset=2;
   }
   else{
      $datacode="$so.addVariable(\"values\",\"$vstring\");\n".
                "$so.addVariable(\"$param{mode}\",\"3,0xff0000,".
                $param{legend}.",10,4\");\n";
      $maxdataset=1;
   }
   if (defined($param{avg})){
      $maxdataset++;
      $datacode.="$so.addVariable(\"values_$maxdataset\",\"".
                 join(",",@{$param{avg}})."\");\n".
                 "$so.addVariable(\"line_$maxdataset\",\"1,0x86B34B,".
                 $self->T("averange").",10,4\");\n";
   }
   if (defined($param{employees})){
      $maxdataset++;
      my $y2max=19;
      my $vstring;
      foreach my $d (@{$param{employees}}){
         $vstring.="," if ($vstring ne "");
         if (defined($d)){
            $vstring.=$d;
            $y2max=$d if ($y2max<$d);
         }
         else{
            $vstring.="null";
         }
      }
      $y2max=int($y2max*1.15);
      $datacode.="$so.addVariable(\"values_$maxdataset\",\"$vstring\");\n".
                 "$so.addVariable(\"line_$maxdataset\",\"1,0x0000ff,".
                 $self->T("count of employees").",10,4\");\n".
                 "$so.addVariable(\"y2_lines\",\"$maxdataset\");\n".
                 "$so.addVariable(\"y2_max\",\"$y2max\");\n".
                 "$so.addVariable(\"y2_legend\",\"".
                 $self->T("employees").",10,4\");\n".
                 "$so.addVariable(\"show_y2\",\"true\");\n";
   }
   if (defined($param{ymax})){
     $datacode.="$so.addVariable(\"y_max\",\"$param{ymax}\");\n";
   }
   else{
     $datacode.="$so.addVariable(\"y_max\",\"$ymax\");\n";
   }


   $d=<<EOF;
<div id="$name" style="padding:0px;margin:10px;border:1px solid #30579f;
                       width:${w}px;height:${h}px;"></div>
<script language="JavaScript">
function buildChart$name()
{
   var $so=new SWFObject("../../../$swfobjcode","$name",
                         "$w","$h","9","#FFFFFF");
   $so.addVariable("variables","true");
   $so.addVariable("title","$param{label},{font-size: 15;}");
   $so.addVariable("bg_colour","#f4f4f4");
   $so.addVariable("y_label_size","15");
   $so.addVariable("y_ticks","5,10,4");
   $datacode
   $so.addVariable("x_labels","Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Okt,Nov,Dez");
   //$so.addVariable("x_axis_steps","2");
   $so.addParam("allowScriptAccess", "always" );//"sameDomain");
   //$so.addParam("onmouseout", "onrollout2();" );
   $so.write("$name");
}
addEvent(window,"load",buildChart$name);
</script>
EOF




   return($d);
}


sub extractYear
{
   my $self=shift;
   my $primrec=shift;
   my $hist=shift;
   my $name=shift;
   my %param=@_;

   my ($Y,$M)=$primrec->{month}=~m/^(\d{4})(\d{2})$/;

   my %p;
   foreach my $hrec (@{$hist->{area}}){
      if ($hrec->{month}=~m/^$Y/){
         $p{$hrec->{month}}=$hrec;
      }
   }
   my @d;
   for(my $m=1;$m<=12;$m++){
      my $k=sprintf("%04d%02d",$Y,$m);
      if ($m<=$M){
         if (defined($p{$k}) && ref($p{$k}->{stats}->{$name}) eq "ARRAY" &&
             $p{$k}->{stats}->{$name}->[0] ne ""){
            push(@d,$p{$k}->{stats}->{$name}->[0]);
         }
         else{
            if ($param{setUndefZero}){
               push(@d,0);
               
            }
            else{
               push(@d,undef);
            }
         }
      }
      else{
         push(@d,undef);
      }
   }
   return(\@d);
}

sub calcPOffset
{
   my $self=shift;
   my ($primrec,$hist,$name)=@_;
   my $delta;

   if (defined($hist->{lastmonth}) && 
       $hist->{lastmonth}->{stats}->{$name}->[0]>0){
      my $cur=$primrec->{stats}->{$name}->[0];
      my $lst=$hist->{lastmonth}->{stats}->{$name}->[0];
      $delta=floor(($cur-$lst)*100.0/$lst);
      if ($delta!=0){
         if ($delta<0){
            $delta="$delta".'%'; 
         }
         else{
            $delta="+$delta".'%';
         }
      }
      else{
         $delta=undef;
      }
   }
   return($delta);
}






1;
