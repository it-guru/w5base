package passx::entry;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'passxentry.entryid'),

      new kernel::Field::Select(
                name          =>'entrytype',
                default       =>'1',
                label         =>'account type',
                transprefix   =>'actype.',
                value         =>['1',
                                 '5',
                                 '4',
                                 '2',
                                 '3',
                                 '10',
                                 '11'],
                dataobjattr   =>'passxentry.entrytype'),

      new kernel::Field::Link(
                name          =>'entrytypeid',
                label         =>'entrytypeid',
                dataobjattr   =>'passxentry.entrytype'),

      new kernel::Field::Link(
                name          =>'uniqueflag',
                label         =>'uniqueflag',
                dataobjattr   =>'passxentry.uniqueflag'),

      new kernel::Field::Text(
                name        =>'name',
                label       =>'Systemname',
                dataobjattr =>'passxentry.systemname'),

      new kernel::Field::Text(
                name        =>'account',
                label       =>'Account',
                dataobjattr =>'passxentry.username'),

      new kernel::Field::Link(
                name          =>'scriptkey',
                label         =>'ScriptKey',
                dataobjattr   =>'passxentry.scriptkey'),

      new kernel::Field::Text(
                name        =>'quickpath',
                label       =>'Quick-Path',
                dataobjattr =>'passxentry.quickpath'),

      new kernel::Field::Text(
                name        =>'comments',
                label       =>'Comments',
                dataobjattr =>'passxentry.comments'),


      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.entry',
                depend        =>['entrytype'],
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if ($rec->{entrytype}>10){
                      return(0);
                   }
                   return(1);
                },
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'passx::acl',
                vjoinbase     =>[{'aclparentobj'=>\'passx::entry'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Text(
                name          =>'srcsys',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'passxentry.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'passxentry.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                htmldetail    =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'passxentry.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'passxentry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'passxentry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'passxentry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Link(
                name          =>'modifyuser',
                group         =>'source',
                label         =>'ModifyUserID',
                dataobjattr   =>'passxentry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'passxentry.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'passxentry.realeditor'),

      new kernel::Field::ListWebLink( 
                name          =>'listweblink',
                webjs         =>'function o(id){'.
                                ' parent.parent.location.href="../mgr/Workspace?ModeSelectCurrentMode=pstore&id="+id;'.
                                '}',
                webtarget     =>'_self',
                weblink       =>\&DirectLink,
                webtitle      =>'access Password Store',
                label         =>'Link'),

      new kernel::Field::Link(
                name          =>'aclmode',
                selectable    =>0,
                dataobjattr   =>'passxacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'acltarget',
                selectable    =>0,
                dataobjattr   =>'passxacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'acltargetid',
                selectable    =>0,
                dataobjattr   =>'passxacl.acltargetid'),

   );
   $self->setDefaultView(qw(entrytype name account listweblink comments mdate));
   return($self);
}

sub InitRequest
{
   my $self=shift;
   my $bk=$self->SUPER::InitRequest(@_);

   if ($ENV{REMOTE_USER} eq "" || $ENV{REMOTE_USER} eq "anonymous"){
      print($self->noAccess());
      return(undef);
   }
   return($bk);
}

sub mkContextMenu
{
   my $self=shift;
   my $rec=shift;


   my $onclick="openwin('../entry/Detail?".
               "AllowClose=1&search_id=$rec->{id}',".
               "'_blank',".
               "'height=480,width=640,toolbar=no,status=no,".
               "resizable=yes,scrollbars=no')";
   my @ml=($self->T("Detail")=>$onclick);


   return(\@ml);
}

sub mkConnectorURL
{
   my $rec=shift;
   my $ho;
   if ($rec->{entrytype}==1){
      $ho="ssh://$rec->{account}\@$rec->{name}";
   }
   elsif ($rec->{entrytype}==5){
      $ho="rdesktop://$rec->{account}\@$rec->{name}";
   }
   elsif($rec->{entrytype}==3){
      $ho="telnet://$rec->{account}\@$rec->{name}";
   }
   else{
      $ho="connect://$rec->{account}\@$rec->{name}";
   }
   return($ho);
}

sub generateMenuTree
{
   my $self=shift;
   my $mode=shift;
   my $userid=shift;
   my $flt=shift;
   my $curpath=shift;
   my $d;

   $self->ResetFilter();
   if ($flt ne ""){
      my %groups=$self->getGroupsOf($userid,'RMember','both');
      $self->SecureSetFilter([
                             {modifyuser=>\$userid,
                              name=>"*$flt*"},
                             {modifyuser=>\$userid,
                              comments=>"*$flt*"},
                             {modifyuser=>\$userid,
                              quickpath=>"*$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::user',
                              acltargetid=>[$userid],
                              entrytypeid=>'<=10',
                              name=>"*$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::user',
                              acltargetid=>[$userid],
                              entrytypeid=>'<=10',
                              quickpath=>"*$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::user',
                              acltargetid=>[$userid],
                              entrytypeid=>'<=10',
                              comments=>"*$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::user',
                              acltargetid=>[$userid],
                              entrytypeid=>'<=10',
                              account=>"*$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::grp',
                              acltargetid=>[keys(%groups)],
                              entrytypeid=>'<=10',
                              name=>"$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::grp',
                              acltargetid=>[keys(%groups)],
                              entrytypeid=>'<=10',
                              comments=>"$flt*"},
                             {aclmode=>['write','read'],
                              acltarget=>\'base::grp',
                              acltargetid=>[keys(%groups)],
                              entrytypeid=>'<=10',
                              account=>"*$flt*"},
                             ]);
   }
   else{
      $self->FrontendSetFilter($userid);
   }
   $self->SetCurrentView(qw(quickpath name entrytype account id comments));
   my ($rec,$msg)=$self->getFirst();
   my $simplem;
   my @ml;
   my $mid=1;
   my %padd;
   my $targetml=\@ml;
   if (defined($rec)){
      $simplem.="<table width=100%>";
      my $line=1;
      do{
        if ($rec->{quickpath} ne "" || $mode ne "fvwm"){
           my $onclick="javascript:showCryptoOut($rec->{id})";
           if ($mode eq "connector"){
              $onclick=mkConnectorURL($rec);
           }
           if ($rec->{quickpath} ne "" && $flt eq ""){
              foreach my $subquickpath (split(/;/,$rec->{quickpath})){
                 my @quickpath=split(/\./,$subquickpath);
                 my @curpath=split(/\./,$curpath);
                 my $pathdepth=$#curpath+1;
                 if ($mode ne "web" && $mode ne "connector"){
                    $pathdepth=$#quickpath+1;
                 }
                 for(my $chkpathdepth=0;$chkpathdepth<=$pathdepth;
                     $chkpathdepth++){
                    if ($chkpathdepth<$#quickpath+1){
                       my $chkpath=join(".",@quickpath[0..$chkpathdepth]);
                       if (!defined($padd{$chkpath})){
                          $targetml=\@ml if ($chkpathdepth==0);
                          if (($mode ne "web" && $mode ne "connector") || 
                              ($chkpathdepth==0 ||
                               join(".",@quickpath[0..$chkpathdepth-1]) eq
                               join(".",@curpath[0..$chkpathdepth-1]))){
                             my %mrec;
                             $mrec{tree}=[];
                             $mrec{label}=$quickpath[$chkpathdepth];
                             $mrec{href}="javascript:setCurPath(\"$chkpath\")";
                             $mrec{menuid}=$mid++;
                             if ($mode ne "web" && $mode ne "connector"){
                                delete($mrec{href});
                             }
                             push(@$targetml,\%mrec);
                             $padd{$chkpath}=\%mrec;
                          }
                       }
                       $targetml=$padd{$chkpath}->{tree};
                    }
                 }
                 if ((($mode ne "web" && $mode ne "connector") && 
                      $rec->{entrytype}<=10) || 
                     join(".",@curpath) eq join(".",@quickpath)){
                    my %mrec;
                    $mrec{label}=$rec->{account}.'@'.$rec->{name};
                    if ($rec->{comments} ne ""){
                       if ($mode eq "connector"){
                          $mrec{label}.="</a>";
                          $mrec{label}.=" (".$rec->{comments}.")";
                       }
                    }
                    $mrec{contextMenu}=$self->mkContextMenu($rec);
                    #$mrec{menuid}=$rec->{id};
                    $mrec{menuid}=$mid++;
                    $mrec{entrytype}=$rec->{entrytype};
                    $mrec{name}=$rec->{name};
                    $mrec{account}=$rec->{account};
                    $mrec{comments}=$rec->{comments};
                    if ($mode eq "web" || $mode eq "connector"){
                       $mrec{parent}=$padd{join(".",@quickpath)};
                    }
                    $mrec{href}="$onclick";
                    if ($mode ne "web" && $mode ne "connector"){
                       delete($mrec{href});
                    }
                    push(@$targetml,\%mrec);
                 }
              }
           }
           if ($rec->{quickpath} eq "" || $flt ne ""){
              if ($mode eq "connector" && $flt ne ""){
                 my %mrec;
                 if ($rec->{entrytype}==1 ||
                     $rec->{entrytype}==3 ||
                     $rec->{entrytype}==5){
                    $mrec{label}=$rec->{account}.'@'.$rec->{name};
                    if ($rec->{comments} ne ""){
                       if ($mode eq "connector"){ 
                          $mrec{label}.="</a>";
                          $mrec{label}.=" (".$rec->{comments}.")";
                       }
                    }
                    #$mrec{menuid}=$rec->{id};
                    $mrec{menuid}=$mid++;
                    $mrec{entrytype}=$rec->{entrytype};
                    $mrec{name}=$rec->{name};
                    $mrec{account}=$rec->{account};
                    $mrec{comments}=$rec->{comments};
                    #   $mrec{parent}=$padd{join(".",@quickpath)};
                    $mrec{href}=mkConnectorURL($rec);
                    $mrec{contextMenu}=$self->mkContextMenu($rec);
                    push(@$targetml,\%mrec);
                 }
              }
              if ($mode eq "web"){
                 my $lineclass="line$line";
                 my $dispname=$rec->{name};
                 if (length($dispname)>20){
                    $dispname=substr($dispname,0,15)."...".
                              substr($dispname,length($dispname)-5,5);
                 }
                 $simplem.="<tr class=$lineclass ".
                     "onMouseOver=\"this.className='linehighlight'\" ".
                     "onMouseOut=\"this.className='$lineclass'\">\n";
                 my $onclicktag=$onclick;
                 $onclicktag=~s/^javascript://;
                 $onclicktag=" onclick=$onclicktag ";
                 my $connecturl=mkConnectorURL($rec);
                 my $ho;
                 my $hc;
                 $ho="<a href=\"$connecturl\">" if ($connecturl ne "");
                 $hc="</a>" if ($ho ne "");
                 $simplem.="<td $onclicktag width=1%>".
                     "$ho<img border=0 src=\"../../../public/passx/load/".
                     "actype.$rec->{entrytype}.gif\">$hc</td>";
                 $simplem.="<td $onclicktag>$dispname</td>";
                 $simplem.="<td $onclicktag>$rec->{account}</td>";
                 $simplem.="</td>";
                 $simplem.="</tr>";
                 $line++;
                 $line=1 if ($line>2);
              }
              if (($mode ne "web" && $mode ne "connector") 
                  && $rec->{entrytype}<=10){
                 my %mrec;
                 $mrec{label}=$rec->{account}.'@'.$rec->{name};
                 $mrec{menuid}=$rec->{id};
                 $mrec{entrytype}=$rec->{entrytype};
                 $mrec{comments}=$rec->{comments};
                 $mrec{name}=$rec->{name};
                 $mrec{account}=$rec->{account};
                 $targetml=\@ml;
                 push(@$targetml,\%mrec);
              }
           }
        }
        ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
      $simplem.="</table>";
   }
   sub sortTree
   {
      my $mlist=shift;
      $mlist=[sort({ my $s1=$a->{label};
                     my $s2=$b->{label};
                     if (exists($a->{account})){
                        $s1=$a->{name}.'@'.$a->{account};
                     }
                     if (exists($b->{account})){
                        $s2=$b->{name}.'@'.$b->{account};
                     }
                     lc($s1) cmp lc($s2);
                   } @$mlist)];
      foreach my $mrec (@$mlist){
         if (ref($mrec->{tree}) eq "ARRAY" && $#{$mrec->{tree}}!=-1){
            $mrec->{tree}=sortTree($mrec->{tree});
         }
      }
      return($mlist);
   }
   @ml=@{sortTree(\@ml)};
   if ($#ml!=-1){
      if ($mode eq "web" || $mode eq "connector"){
         $d.=kernel::MenuTree::BuildHtmlTree(tree=>\@ml, 
                                             hrefclass=>'menulink',
                                             rootpath=>'./',
                                            );
      }
      if ($mode eq "xml"){
         $d=hash2xml({menu=>{entry=>\@ml}},{header=>1});
      }
      if ($mode eq "fvwm" || $mode eq "dynfvwm"){
         my $mainmenu={W5BaseFvwmLoginMenu=>{label=>'System Login',
                       cmdentrys=>[],mentrys=>[]}};
         sub processEntry
         {
            my $ml=shift;
            my $mainmenu=shift;
            my $targetm=shift;
            foreach my $m (@$ml){
               if (exists($m->{entrytype})){
                  if ($m->{entrytype}==1 || $m->{entrytype}==5){
                     my $fvwmcmd="FvwmConnectCommand";
                     my $label=$m->{label};
                     my $cmd;
                     my $icon;
                     if ($m->{entrytype}==1){
                        $fvwmcmd="FvwmSSHLogin";
                        $label.=" SSH";
                        $cmd="Exec \$[HOME]/bin/$fvwmcmd \"".$m->{label}.
                                "\" \"$m->{label}\"";
                        $icon="mini.W5BasePassX.ssh.xpm";
                     }
                     elsif ($m->{entrytype}==5){
                        $fvwmcmd="FvwmRDesktopLogin";
                        $label.=" RDesk";
                        $cmd="Exec \$[HOME]/bin/$fvwmcmd \"".$m->{name}.
                                "\" \"$m->{label}\"";
                        $icon="mini.W5BasePassX.rdesk.xpm";
                     }
                     $label.=" ($m->{comments})" if ($m->{comments} ne "");
                     push(@{$targetm->{cmdentrys}},
                          {label=>$label,
                           hostname=>$m->{name},
                           icon=>$icon,
                           cmd=>$cmd});
                  }
               }
               else{
                  my $mkey='W5BaseFvwmLoginMenu'.$m->{menuid};
                  push(@{$targetm->{mentrys}},
                       {label=>$m->{label},
                        cmd=>"Popup ".$mkey});
                  $mainmenu->{$mkey}={label=>$m->{label},
                              cmdentrys=>[],mentrys=>[]};
                  if (exists($m->{tree})){
                     processEntry($m->{tree},$mainmenu,$mainmenu->{$mkey});
                  }
               }
            }
         }
         processEntry(\@ml,$mainmenu,$mainmenu->{W5BaseFvwmLoginMenu});
         foreach my $mkey (keys(%$mainmenu)){
            $d.="AddToMenu $mkey ".
                "\"$mainmenu->{$mkey}->{label}\" Title\n";
            my $lasthost;
            foreach my $entry (@{$mainmenu->{$mkey}->{mentrys}},
                               @{$mainmenu->{$mkey}->{cmdentrys}}){
               if (defined($lasthost) && $lasthost ne $entry->{hostname}){
                  $d.="+ \"\" Nop\n";
               }
               $d.="+ \"$entry->{label}";
               $d.=' %'.$entry->{icon}.'% ' if ($entry->{icon} ne "");
               $d.="\" $entry->{cmd}\n";
               $lasthost=$entry->{hostname};
            }
            $d.="\n\n\n";
            $d.="AddToFunc ResetW5BaseFvwmLoginMenu  ".
                "I DestroyMenu recreate $mkey\n\n";
         }
         $d.="AddToMenu W5BaseFvwmLoginMenu \"\"      Nop\n";
         $d.="AddToMenu W5BaseFvwmLoginMenu \"Reload Menu\" ".
             "recreateW5BaseFvwmLoginMenu\n";
         #$d=Dumper($mainmenu);
      }
      if ($mode eq "enlightenment"){
         $d=Dumper(\@ml);
      }
      if ($mode eq "perl"){
         $d=Dumper(\@ml);
      }
   }
   if ($mode eq "web" || $mode eq "connector"){
      $d.=$simplem;
   }

   return($d);
}


sub DirectLink
{
   my $self=shift;
   my $current=shift;
   my $mgr=$self->getParent->getPersistentModuleObject("passx::mgr");
   my $userid=$self->getParent->getCurrentUserId();
   $mgr->SetFilter({userid=>\$userid,entryid=>\$current->{id}});
   my ($erec,$msg)=$mgr->getOnlyFirst(qw(id));
   if (!defined($erec)){
      return(undef);
   }
   
   return("JavaScript:o($current->{id})");
}

sub Initialize
{
   my $self=shift;

   $self->setWorktable("passxentry");
   return($self->SUPER::Initialize());
}



sub FrontendSetFilter
{
   my $self=shift;
   my $userid=shift;
   my %groups=$self->getGroupsOf($userid,'RMember','both');
   return($self->SUPER::SecureSetFilter([{modifyuser=>\$userid},
                                         {aclmode=>['write','read'],
                                          acltarget=>\'base::user',
                                          acltargetid=>[$userid],
                                          entrytypeid=>'<=10'},
                                         {aclmode=>['write','read'],
                                          acltarget=>\'base::grp',
                                          acltargetid=>[keys(%groups)],
                                          entrytypeid=>'<=10'},
                                         ],@_));
   return($self->SUPER::SecureSetFilter(@_));
}

sub SecureSetFilter
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();

   return($self->SUPER::SecureSetFilter([{modifyuser=>\$userid},
                                         {entrytypeid=>'<=10'},
                                         ],@_));

}



sub getSqlFrom
{
   my $self=shift;
   my $from="passxentry left outer join passxacl ".
            "on passxentry.entryid=passxacl.refid and ".
            "passxacl.aclparentobj='passx::entry'";
   return($from);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($newrec->{name})){
      $newrec->{scriptkey}=undef;
   }
   $newrec->{userid}=$self->getCurrentUserId();
   my $entrytype=effVal($oldrec,$newrec,"entrytype");
   if ($entrytype<10){

      my $name=lc(trim(effVal($oldrec,$newrec,"name")));
      if ($name eq "" || !($name=~m/^[^\.][a-z0-9_\.:-]+[^\.]$/)){
         $self->LastMsg(ERROR,
              sprintf($self->T("invalid systemname '%s' specified"),$name));
         return(0);
      }
      $newrec->{name}=$name;
   }
   else{
      my $name=trim(effVal($oldrec,$newrec,"name"));
      if ($name eq "" || $name=~m/[\s;]/){
         $self->LastMsg(ERROR,
              sprintf($self->T("invalid systemname '%s' specified"),$name));
         return(0);
      }
      $newrec->{name}=$name;
   }
   my $quickpath=trim(effVal($oldrec,$newrec,"quickpath"));
   $newrec->{quickpath}=$quickpath if (exists($newrec->{quickpath}));
   #if ($entrytype==1){
   #   my $sys=$self->getPersistentModuleObject("itil::system");
   #   my $ok=0;
   #   if (defined($sys)){
   #      my $searchname=$newrec->{name};
   #      $searchname=~s/[\*\?]//g;
   #      $sys->SetFilter({name=>$searchname});
   #      my ($rec,$msg)=$sys->getOnlyFirst(qw(name));
   #      if (defined($rec)){
   #         $ok=1;
   #         $newrec->{name}=$rec->{name};
   #      }
   #   }
   #   if (!$ok){
   #      $self->LastMsg(ERROR,"systemname not found in inventar");
   #      return(0);
   #   }
   #}
   if ($entrytype==4){
      my $appl=$self->getPersistentModuleObject("itil::appl");
      my $ok=0;
      if (defined($appl)){
         my $searchname=$newrec->{name};
         $searchname=~s/[\*\?]//g;
         $appl->SetFilter({name=>$searchname});
         my ($rec,$msg)=$appl->getOnlyFirst(qw(name));
         if (defined($rec)){
            $ok=1;
            $newrec->{name}=$rec->{name};
         }
      }
      if (!$ok){
         $self->LastMsg(ERROR,"application not found in inventar");
         return(0);
      }
   }

   my $account=trim(effVal($oldrec,$newrec,"account"));
   if ($account eq "" || !($account=~m/^[a-zA-Z0-9_\.\-]+$/)){
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid account '%s' specified"),
                   $account));
      return(0);
   }
   $newrec->{account}=$account;
   if ($entrytype<10){
      $newrec->{uniqueflag}=$entrytype;
   }
   else{
      $newrec->{uniqueflag}=$self->getCurrentUserId();
   }


   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @fieldgroup=("default");
   return(@fieldgroup) if (!defined($rec));

   push(@fieldgroup,"acl");
   my $userid=$self->getCurrentUserId();

   return(@fieldgroup) if ($userid==$rec->{modifyuser});

   my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{acls});
   return(@fieldgroup) if ($rec->{owner}==$userid ||
                           $self->IsMemberOf("admin") ||
                           grep(/^write$/,@acl));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

1;
