package kernel::DataObj::LDAP;
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
use kernel::DataObj;
use kernel::ldapdriver;
use Time::HiRes qw(gettimeofday tv_interval);
use Text::ParseWords;
use Data::Dumper;
use UNIVERSAL;
@ISA    = qw(kernel::DataObj UNIVERSAL);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}

sub AddDirectory
{
   my $self=shift;
   my $db=shift;
   my $obj=shift;

   my ($dbh,$msg)=$obj->Connect();
   if (!$dbh){
      if ($msg ne ""){
         return("InitERROR",$msg);
      }
      return("InitERROR",msg(ERROR,"can't connect to database '%s'",$db));
   }
   $self->{$db}=$obj;
   return($dbh);
}  

sub getSqlFields
{
   my $self=shift;
   my @view=$self->getCurrentView();
   my @flist=();
   my $idfield=$self->IdField();

   if (defined($idfield)){
      my $idname=$self->IdField->Name();
    
      if (!grep(/^$idname$/,@view)){ # unique id
         push(@view,$idname);        # should always
      }                              # be selected
   }
   foreach my $fieldname (@view){
      my $field=$self->getField($fieldname);
      if (defined($field->{depend})){
         if (ref($field->{depend}) ne "ARRAY"){
            $field->{depend}=[$field->{depend}];
         }
         foreach my $field (@{$field->{depend}}){
            push(@view,$field) if (!grep(/^$field$/,@view));
         }
      }
   }
   foreach my $fieldname (@view){
      my $field=$self->getField($fieldname);
      next if (!defined($field));
      my $selectfield=$field->getBackendName($self->{LDAP});
      if (defined($selectfield)){
         push(@flist,"$selectfield $fieldname");
      }
      #
      # dependencies solution on vjoins
      #
      if (defined($field->{vjoinon})){
         my $joinon=$field->{vjoinon}->[0];
         my $joinonfield=$self->getField($joinon);
         if (defined($joinonfield->{dataobjattr})){
            my $newfield=$joinonfield->{dataobjattr}." ".$joinon;
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
      #
      # dependencies solution on container
      #
      if (defined($field->{container})){
         my $contfield=$self->getField($field->{container});
         if (defined($contfield->{dataobjattr})){
            my $newfield=$contfield->{dataobjattr}." ".$field->{container}; 
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
   }
   return(@flist);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getBase();
   return($worktable);
}

sub getLdapOrder
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getBase();
   my @order=();
   my @view=$self->getFieldObjsByView([$self->getCurrentView()]);


   my @o=$self->GetCurrentOrder();
   if (!($#o==0 && uc($o[0]) eq "NONE")){
      if ($#o==-1 || ($#o==0 && $o[0] eq "")){
         foreach my $field (@view){
            my $orderstring=$field->getBackendName("order",$self->{DB});
            if (!defined($orderstring)){
               if (defined($field->{vjoinon}) &&
                   ref($field->{vjoinon}) eq "ARRAY"){
                  my $jfld=$self->getField($field->{vjoinon}->[0]);
                  if (defined($jfld)){
                     my $orderstring=$jfld->getBackendName("order",
                                      $self->{DB});
                     if (defined($orderstring) &&
                         !in_array(\@order,$orderstring)){
                        push(@order,$orderstring);
                     }
                  }
               }
            }
            else{
               if (!in_array(\@order,$orderstring)){
                  push(@order,$orderstring);
               }
            }
         }
         return(join(" ",@order));
      }
      else{
         foreach my $ofield (@o){
            my $fieldname=$ofield;
            $fieldname=~s/^[+-]//;
            my $field=$self->getField($fieldname);
            next if (!defined($field));
            my $orderstring=$field->getBackendName("order",$self->{DB},$ofield);
            next if (!defined($orderstring));
            if (!in_array(\@order,$orderstring)){
               push(@order,$orderstring);
            }
         }
         return(join(" ",@order));
      }
      return("");
   }
   return("");
}

sub initSqlWhere
{
   my $self=shift;

   return("");
}


# local functions for getFinalLdapFilter

   sub dbQuote
   {
      return("NULL") if (!defined($_[0]));
      return("'".$_[0]."'");
   }

   sub MakeLikeList
   {
      my $sqlfield=shift;
      my $fo=shift;
      my @sub=();
      foreach my $subval (@_){
         my @vallist=$fo->prepareToSearch($subval);
         foreach my $val (@vallist){
            push(@sub,"($sqlfield=$val)");
         }
      }
      my $sub=join("",@sub);
      $sub="(|".$sub.")" if ($#sub>0);
      return($sub);
   }

   sub AddOrList
   {
      my $where=shift;
      my $fieldobject=shift;
      my $sqlfield=shift;
      my $param=shift;
      my @list=@_;

      if ($#list==-1){
         $$where="($$where) and " if ($$where ne "");
         $$where.="(1=0)";
         return($where);
      }
      if ($param->{wildcards}){
         my $sub="";
         my @orlist=();
         my @norlist=();
         foreach my $val (@list){
            $val=~s/\(/\\28/g;
            $val=~s/\)/\\29/g;
            if ($val=~m/^!/){
               $val=~s/^!//;
               push(@norlist,$val);
            }
            else{
               push(@orlist,$val);
            }
         }
         my $orlist=MakeLikeList($sqlfield,$fieldobject,@orlist);
         my $norlist=MakeLikeList($sqlfield,$fieldobject,@norlist);
         $norlist="(!".$norlist.")" if ($norlist ne "");
         #msg(INFO,"orlist  ($sqlfield)=$orlist");
         #msg(INFO,"norlist ($sqlfield)=$norlist");
         if ($orlist ne "" || $norlist ne ""){ 
            my $notempty=0;
            $notempty=1 if ($$where ne "");
            $$where="(& ".$$where if ($notempty);
            $$where.=$orlist  if ($orlist ne "");
            $$where.="  )" if ($notempty);

            my $notempty=0;
            $notempty=1 if ($$where ne "");
            $$where="(& ".$$where if ($notempty);
            $$where.=$norlist  if ($norlist ne "");
            $$where.="  )" if ($notempty);

         }
      }
      elsif($param->{onlyextprocessing}){
         my $orlist=MakeLikeList($sqlfield,$fieldobject,join(" ",@list));
         $$where.=" and " if ($$where ne "");
         if ($orlist ne ""){
            $$where.=$orlist;
         }
         else{
            $$where.="2=3";
         }
      }
      else{
         
         my $fname=$fieldobject->Name();
         foreach my $q (@list){
            $q=$q;
            $q=~s/\\/\\5c/g;
            $q=~s/\(/\\28/g;
            $q=~s/\)/\\29/g;
            $q=~s/\*/\\2a/g;
            my $notempty=0;
            $notempty=1 if ($$where ne "");
            $$where="(& ".$$where if ($notempty);  # damit Arrays geodert werden
            $$where.="($sqlfield=$q)";
            $$where.="  )" if ($notempty);
         }
      }
      #msg(INFO,"AddOrList=$$where");
   }

sub objectGUID2LDAP
{
   my $objectGUID=shift;

   if (my @o=$objectGUID
              =~m/^([0-9a-f]+)-([0-9a-f]+)-
                   ([0-9a-f]+)-([0-9a-f]+)-([0-9a-f]+)$/ix){
      my @o0=reverse(unpack("(A2)*",$o[0])); 
      my @o1=reverse(unpack("(A2)*",$o[1])); 
      my @o2=reverse(unpack("(A2)*",$o[2])); 
      my @o3=unpack("(A2)*",$o[3]); 
      my @o4=unpack("(A2)*",$o[4]); 
      return(join("",map({'\\'.$_} @o0,@o1,@o2,@o3,@o4)));
   }
   return(undef);
}


sub getFinalLdapFilter
{
   my $self=shift;
   my @filter=@_;
#   my $where=$self->initSqlWhere();
   my $where="";


   my @l1where=();
   foreach my $filter (@filter){
      #msg(INFO,"getSqlWhere: interpret %s",Dumper($filter));
      my @subflt=$filter;
      @subflt=@$filter if (ref($filter) eq "ARRAY");
      my @l0where=();
      foreach my $filter (@subflt){
         my $subwhere="";
         foreach my $field (keys(%{$filter})){
            #msg(INFO,"getFinalLdapFilter: process field '$field'");
            my $fo=$self->getField($field);
            if (!defined($fo)){
               msg(ERROR,"getFinalLdapFilter: can't process unknown ".
                         "field '$field' - ignorring it");
               next;
            }
            if (defined($fo->{dataobjattr})){
               my $dataobjattr=$fo->{dataobjattr};
               #msg(INFO,"getFinalLdapFilter: process field '$field' ".
               #         "dataobjattr=$dataobjattr");
               if ($dataobjattr eq "objectGUID"){
                  if (ref($filter->{$field}) eq "ARRAY"){
                    for(my $c=0;$c<=$#{$filter->{$field}};$c++){
                       if (my $lfmt=objectGUID2LDAP($filter->{$field}->[$c])){
                          $filter->{$field}->[$c]=$lfmt;
                       }
                    }
                  }
                  elsif(ref($filter->{$field}) eq "SCALAR"){
                     if (my $lfmt=objectGUID2LDAP(${$filter->{$field}})){
                        $filter->{$field}=\$lfmt;
                     }
                  }
                  else{
                    my @l=grep(!/^\s*$/,split(/\s+/,$filter->{$field}));
                    my $mapped=0;
                    for(my $c=0;$c<=$#l;$c++){
                       if (my $lfmt=objectGUID2LDAP($l[$c])){
                          $l[$c]=$lfmt;
                          $mapped++;
                       }
                              
                    }
                    if ($#l!=-1 && $mapped){
                       @l=map({$_=~s/\\/\\\\/g;$_;} @l);
                       $filter->{$field}=join(" ",@l);
                    }
                  }
               }

               if (ref($filter->{$field}) eq "ARRAY"){
                  AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>0},
                            @{$filter->{$field}});
                  # fix processing - no wildcards
               }
               elsif (ref($filter->{$field}) eq "SCALAR"){
                  AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>0},
                            ${$filter->{$field}});
               }
               elsif ($fo->Type()=~m/^.{0,1}Date$/){
                  AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>0,
                                                 onlyextprocessing=>1},
                            $filter->{$field});
               }
               elsif (ref($filter->{$field}) eq "HASH"){
                  # spezial processing - not implemented at this time
                  msg(ERROR,"getSqlWhere: can't process HASH filter ".
                            "for '$field'");
               }
               elsif (!defined($filter->{$field})){
                  AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>0},undef);
               }
               else{
                  # scalar processing - lists an wildcards
                  my @words=parse_line(',{0,1}\s+',0,$filter->{$field});
                  AddOrList(\$subwhere,$fo,$dataobjattr,{wildcards=>1},@words);
               }
            }
         }
         #printf STDERR ("SUBDUMP:$subwhere\n");
        # $l0where="(|".$l0where.$subwhere.")" if ($subwhere ne "");
         push(@l0where,$subwhere) if ($subwhere ne "");
      }
      push(@l1where,"(|".$where.join("",@l0where).")") if ($#l0where!=-1);
   } 
   $where="(&".join("",@l1where).")";
   $where="objectClass=*" if ($where eq "(&)");  # handle empty filters
   #printf STDERR ("DUMP:$where\n");
   return($where);
}

sub getLdapFilter
{
   my $self=shift;

   my $where=$self->getFinalLdapFilter($self->getFilterSet());
   return($where);
}


sub UpdateRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   my @updfilter=@_;   # update filter
   $self->LastMsg(ERROR,"LDAP:UpdateRecord not implemented");
   return(undef);
}

sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $dropid=$oldrec->{$self->IdField->Name()};
   $self->LastMsg(ERROR,"LDAP:DeleteRecord not implemented");
   return(undef);
}

sub InsertRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   my $idfield=$self->IdField->Name();
   $self->LastMsg(ERROR,"LDAP:InsertRecord not implemented");
   return(undef);
}



sub tieRec
{
   my $self=shift;
   my $rec=shift;
   
   my %rec;
   my $view=[$self->getCurrentView()];

   my $idfield=$self->IdField();

   if (defined($idfield)){
      my $idname=$self->IdField->Name();
      if (!grep(/^$idname$/,@$view)){ # unique id
         push(@$view,$idname);        # should always
      }                              # be selected
   }

   my $trrec={};
   foreach my $fname (@{$view}){
      my $fobj=$self->getField($fname);
      next if (!defined($fobj));
      if (exists($fobj->{dataobjattr}) && exists($rec->{$fobj->{dataobjattr}})){
         if ($fobj->Type()=~m/^.{0,1}Date$/){
            my $d=$rec->{$fobj->{dataobjattr}};
            my $stamp=$self->ExpandTimeExpression($d,"en","GMT","GMT");
            $trrec->{$fname}=$stamp;
         }
         else{
            $trrec->{$fname}=$rec->{$fobj->{dataobjattr}};
         }
      }
      if (defined($fobj->{depend})){
         if (ref($fobj->{depend}) ne "ARRAY"){
            $fobj->{depend}=[$fobj->{depend}];
         }
         foreach my $field (@{$fobj->{depend}}){
            my $dfobj=$self->getField($field);
            if (defined($dfobj->{dataobjattr})){
               $trrec->{$field}=$rec->{$dfobj->{dataobjattr}};
            }
         }
      }
   }




   tie(%rec,'kernel::DataObj::LDAP::rec',$self,$trrec,$view);
   return(\%rec);
   return(undef);
   
}  

sub Rows 
{
    my $self=shift;

    if (defined($self->{LDAP})){
       return($self->{LDAP}->rows());
    }
    return(undef);
}


sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   if (defined($self->{LDAP})){
      $self->{LDAP}->finish();
   }
   return(@res);
}

sub getFirst
{
   my $self=shift;
   my @fieldlist=$self->getFieldList();
   my @attr=();

   my ($sth,$mesg);
   my $baselimit;
   my $base;
   my @attr;
   my $t0=[gettimeofday()];
   for(my $try=1;$try<3;$try++){
      if ($try>1){
         msg(INFO,"LDAP Initialize - $self - $try try");
      }
      $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
     
      if (!defined($self->{LDAP})){
         $self->{isInitalized}=0;
         my $msg=$self->T("no LDAP connection or invalid LDAP handle");
         if ($self->isSuspended()){
            $msg=$self->T("LDAP connection temporary suspended");
         }
         $self->LastMsg(ERROR,$msg);
         return(undef,msg(ERROR,$msg));
      }
     
      my $baselimit=$self->Limit();
      $self->Context->{CurrentLimit}=$baselimit if ($baselimit>0);
     
     
      my @view=$self->getCurrentView();
     
      foreach my $fullfieldname (@view){
         my ($container,$fieldname)=(undef,$fullfieldname);
         if ($fullfieldname=~m/^\S+\.\S+$/){
            ($container,$fieldname)=split(/\./,$fullfieldname);
         }
         my $field=$self->getField($fieldname);
         if (defined($field->{depend})){
            if (ref($field->{depend}) ne "ARRAY"){
               $field->{depend}=[$field->{depend}];
            }
            foreach my $field (@{$field->{depend}}){
               push(@view,$field) if (!grep(/^$field$/,@view));
            }
         }
      }
     
      my @attrview=@view;
      my $idfield=$self->IdField();
      if (defined($idfield)){
         my $idname=$self->IdField->Name();
     
         if (!grep(/^$idname$/,@attrview)){ # unique id
            push(@attrview,$idname);        # should always
         }                              # be selected
      }
     
      #printf STDERR ("fifi --------- %s\n",join(",",@attrview));
      foreach my $field (@attrview){
         my $fobj=$self->getField($field);
         next if (!defined($fobj));
         if (defined($fobj->{dataobjattr})){
            push(@attr,$fobj->{dataobjattr});
         }
      }
     
      my $ldapfilter=$self->getLdapFilter();
      my $base=$self->getBase;
      my $control=[];

      if (defined($self->{LdapQueryPageSize})){
         my $p=new Net::LDAP::Control::Paged(size=>$self->{LdapQueryPageSize});
         push(@$control,$p);
      }

      ($sth,$mesg)=$self->{LDAP}->execute(filter=>latin1($ldapfilter)->utf8,
                                          base=>$base,
                                          control=>$control,
                                          attrs=>\@attr);
      if (!defined($sth) &&
          ($mesg=~m/ldap-search:Can't contact LDAP server/)){
         delete($self->{LDAP});
         $self->{isInitalized}=0;
      }
      else{
         last;
      }
   }






   my $t=tv_interval($t0,[gettimeofday()]);
   my $p=$self->Self();
   my $msg=sprintf("time=%0.4fsec;mod=$p",$t);
   $msg.=";user=$ENV{REMOTE_USER}" if ($ENV{REMOTE_USER} ne "");
   #msg(INFO,"LDAP Time of=%s attrs=%s base=\"%s\" ($msg)",
   #         $ldapfilter,join(",",@attr),$base);
   if ($sth){
      if ($self->{_LimitStart}>0){
         for(my $c=0;$c<$self->{_LimitStart}-1;$c++){
            my ($temprec,$error)=$self->{LDAP}->fetchrow();
            last if (!defined($temprec));
         }
      }
      my ($temprec,$error)=$self->{LDAP}->fetchrow();
      if ($temprec){
         $temprec=$self->tieRec($temprec);
      }
      return($temprec);
   }
   else{
      $self->LastMsg(ERROR,"LDAP search execute failed");
      return($sth,$mesg);
   }
}

sub getNext
{
   my $self=shift;

   if (defined($self->Context->{CurrentLimit})){
      $self->Context->{CurrentLimit}--;
      if ($self->Context->{CurrentLimit}<=0){
         while(my $temprec=$self->{LDAP}->fetchrow()){
         }
         return(undef,"Limit reached");
      }
   }
   my $temprec=$self->{LDAP}->fetchrow();
   if ($temprec){
      $temprec=$self->tieRec($temprec);
   }
   return($temprec);
}

sub ResolvFieldValue
{
   my $self=shift;
   my $name=shift;

   my $current=$self->{'LDAP'}->getCurrent();
   return($current->{$name});
}

sub setBase
{
   my $self=shift;
   $self->{Base}=$_[0];
   delete($self->{WorkDIR});
   $self->{WorkDIR}=$_[1] if (defined($self->{WorkDIR}));
   return($self->{Base},$self->{WorkDIR});
}

sub setLdapQueryPageSize
{
   my $self=shift;
   my $sz=shift;

   if (defined($sz)){
      if ($sz ne ""){
         $self->{LdapQueryPageSize}=$sz;
      }
      else{
         $self->{LdapQueryPageSize}=undef;
      }
   }
   return($self->{LdapQueryPageSize});
}

sub getBase
{
   my $self=shift;
   return($self->{Base});
}




package kernel::DataObj::LDAP::rec;
use strict;
use kernel::Universal;
use vars qw(@ISA);
use Tie::Hash;

@ISA=qw(Tie::Hash kernel::Universal);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   my $view=shift;
   my $self=bless({Parent=>$parent,Rec=>$rec,View=>$view},$type);
   $self->setParent($parent);
   return($self);
}

sub FIRSTKEY
{
   my $self=shift;


   $self->{'keylist'}=[@{$self->{View}}];
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;

   return(grep(/^$key$/,@{$self->{View}}) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{
   my $self=shift;
   my $key=shift;
   my $mode=shift;

   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $field=$self->getParent->getField($key);
   return(undef) if (!defined($field));
   return($field->RawValue($self->{Rec},$mode));
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{Rec}->{$key}=$val; 
}
1;
