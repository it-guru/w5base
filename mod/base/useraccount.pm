package base::useraccount;
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
                name          =>'account',
                label         =>'User-Account',
                readonly      =>0,
                searchable    =>1,
                align         =>'left',
                htmlwidth     =>'250',
                dataobjattr   =>'useraccount.account'),
                                  
      new kernel::Field::Password(
                name          =>'password',
                uivisible     =>\&passwordVisible,
                label         =>'Password',
                dataobjattr   =>'useraccount.password'),
                                  
      new kernel::Field::TextDrop(
                name          =>'contactfullname',
                label         =>'Contact',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),
                                  
      new kernel::Field::Link(
                name          =>'userid',
                label         =>'UserID',
                dataobjattr   =>'useraccount.userid'),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                label         =>'Surname',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'surname'),
                                  
      new kernel::Field::Text(
                name          =>'givenname',
                label         =>'Givenname',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'givenname'),
                                  
      new kernel::Field::Email(
                name          =>'requestemail',
                label         =>'requested E-Mail',
                uivisible     =>sub{
                   my $self=shift;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                group         =>'control',
                dataobjattr   =>'useraccount.requestemail'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'control',
                label         =>'Creation-Date',
                dataobjattr   =>'useraccount.createdate'),
                                  
      new kernel::Field::Date(
                name          =>'lastlogon',
                group         =>'control',
                depend        =>["account"],
                onRawValue    =>\&getLastLogon,
                label         =>'Last-Logon'),

      new kernel::Field::Link(
                name          =>'requestemailwf',
                label         =>'request E-Mail Workflow',
                dataobjattr   =>'useraccount.requestemailwf'),
                                  
      new kernel::Field::Link(
                name          =>'posturi',
                label         =>'post uri',
                dataobjattr   =>'useraccount.posturi'),
                                  
      new kernel::Field::Link(
                name          =>'requestcode',
                label         =>'requestcode',
                dataobjattr   =>'useraccount.requestcode'),
                                  
      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'email'),

   );
   $self->setWorktable("useraccount");
   $self->setDefaultView(qw(account contactfullname surname givenname));
   return($self);
}

sub getLastLogon
{
   my $self=shift;
   my $current=shift;
   my $account=$current->{account};
   return(undef) if ($account eq "");
   my $ul=$self->getParent->getPersistentModuleObject("ul","base::userlogon");
   $ul->SetFilter({account=>\$account});
   $ul->Limit(1);
   my ($ulrec,$msg)=$ul->getOnlyFirst(qw(logondate));
   return($ulrec->{logondate});

   return(undef);
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




sub passwordVisible
{
   my $self=shift;
   my $mode=shift;
   my $app=$self->getParent;
   my %param=@_;
   my $account=$param{current}->{account};

   return(1) if (($account=~m/^service\/.*$/ ||
                  $account=~m/^w5base\/.*$/ ) && $app->IsMemberOf("admin"));
   return(0);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   my @f=($self->T("DetailChangePassword")=>'DetailChangePassword',
         );
   if ((!($self->IsMemberOf("admin")) &&
       !($userid==$rec->{userid})) || !(($rec->{account}=~m/^service\/.*$/) ||
       ($rec->{account}=~m/^w5base\/.*$/))){
      return($self->SUPER::getDetailFunctions($rec));
   }
   return(@f,$self->SUPER::getDetailFunctions($rec));
}

sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $idname=$self->IdField->Name();
   my $id=$rec->{$idname};
   my $d=<<EOF;
function DetailChangePassword(id)
{
   showPopWin('ChangePassword?account=$id',null,240,FinishChangePassword);
}
function FinishChangePassword()
{
}

EOF
   return($d.$self->SUPER::getDetailFunctionsCode($rec));
}

sub ChangePassword
{
   my $self=shift;

   my $pw1=Query->Param("pw1");
   my $pw2=Query->Param("pw2");
   my $account=Query->Param("account");
   my $userid=$self->getCurrentUserId();
   my $ua=getModuleObject($self->Config,"base::useraccount");
   $ua->SetFilter({account=>\$account});
   my ($rec,$msg)=$ua->getOnlyFirst(qw(userid));
   if (!defined($rec) || (!($self->IsMemberOf("admin")) &&
       !($userid==$rec->{userid}))){
      return($self->noAccess());
   }
   
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("DetailChangePassword"));
   my $winclose;
   my $dis;


   if (Query->Param("SAVE")){ 
      my $fail=0;
      if ($pw1 ne $pw2){
         $self->LastMsg(ERROR,"password repeat is not identical");
         $fail=1;
      }
      if (length($pw1)<5){
         $self->LastMsg(ERROR,"password is to short");
         $fail=1;
      }
      if (!$fail){
         if ($ua->ValidatedUpdateRecord({account=>$account},
                                        {password=>\"password('$pw1')"},
                                        {account=>\$account})){ 
            $self->LastMsg(OK,"password changed");
            $dis="disabled";
            $winclose=<<EOF;
<script language="JavaScript">
function hideWin()
{
   parent.hidePopWin();
}
window.setTimeout("hideWin();", 1500);
</script>
EOF
         }
      }
   }

   my $tmpl=<<EOF;
<table width="100%" height="100%">
<tr>
<td valign=center align=center>
<table border=0 width=50% cellspacing=0 cellpadding=5>
<tr>
<td colspan=2 align=center style="background:silver">Password change for useraccount $account
<input type=hidden $dis name=account value="$account">
</tr>
<tr>
<td width=20% nowrap>Neues Passwort:</td>
<td><input type=password $dis name=pw1 value="$pw1"></td>
</tr>
<tr>
<td width=20% nowrap>Neues Passwort wiederholen:</td>
<td><input type=password $dis name=pw2 value="$pw2"></td>
</tr>
<tr>
<td colspan=2 align=center>&nbsp;%LASTMSG%
</tr>
<tr>
<td colspan=2 align=center><input $dis type=submit name=SAVE value=" neues Passwort speichern ">
</tr>
</table>
</td>
</tr>
</table>
$winclose
EOF
   $self->ParseTemplateVars(\$tmpl);
   print($tmpl);

   print $self->HtmlBottom(body=>1,form=>1);

}

sub getValidWebFunctions
{  
   my $self=shift;
   return("ChangePassword",$self->SUPER::getValidWebFunctions());
}
   

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"account"));
   if ((!($name=~m/^[a-z0-9_\-\.\/\@]+$/i)) || ($name=~m/^\d+$/)){
      $self->LastMsg(ERROR,"invalid account name '%s' specified",$name);
      return(0);
   }
   $newrec->{account}=$name;
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
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
