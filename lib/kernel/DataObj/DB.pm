package kernel::DataObj::DB;
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
use Scalar::Util qw(weaken);
use kernel;
use kernel::DataObj;
use kernel::database;
use Time::HiRes qw(gettimeofday tv_interval);
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

sub AddDatabase
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
   my $W5BaseTransactionSave=$self->Config->Param("W5BaseTransactionSave");
   if (lc($W5BaseTransactionSave) eq "yes" ||
       lc($W5BaseTransactionSave) eq "on" ||
       lc($W5BaseTransactionSave) eq "true" ||
       $W5BaseTransactionSave eq "1"){
      $W5BaseTransactionSave=1;
   }
   else{
     $W5BaseTransactionSave=0;
   }
   $self->{W5BaseTransactionSave}=$W5BaseTransactionSave;
   return($dbh);
}  


sub Rows 
{
    my $self=shift;

    if (defined($self->{DB})){
       return($self->{DB}->rows());
    }
    return(undef);
}
# Seems not to work with current DBI Version
#
# Das Problem ist, dass sich Apache::DBI zwar die private_* Attribute
# für einen Datenbank-Handle "merkt" und somit eine Datenbank-Sitzung
# ganz klar als "inTranskation" markierbar verhält - Das Problem ist
# aber, dass Apache DBI einen Aktiven dbh mit einem rollback initialisiert,
# wenn erkannt wird, dass AutoCommit=0 ist.
# das Problem ist also die Methode Apache::DBI::reset_startup_state, die
# einen rollback nur dann durchführen dürfte, wenn keine Acitive
# W5Transaktion vorliegt - für das Problem hab ich bisher keine Lösung (HV)
#
# Die folgenden 3 Funktionen müßten aktiviert werden und im Apache::DBI
# ein Patch eingebaut werden, der erkennt, ob einen offene Objekt-Transkation
# (private_inW5Transaction) vorliegt. Dann könnte man Transkationssicherung
# (vermutlich) ohne Site-Effekte aktvieren.
#
# Die Funktionalität der Transationssicherung sollte derzeit noch
# abgeschalten bleiben W5BaseTransactionSave=no
#
sub StartTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;
   if (defined($self->{DB}) && $self->{W5BaseTransactionSave}){
      $self->{DB}->begin_work;
   }

   return(1);
}

sub RoolbackTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;
   if (defined($self->{DB}) && $self->{W5BaseTransactionSave}){
      $self->{DB}->rollback;
   }

   return(1);
}

sub FinishTransaction
{
   my ($self,$operation,$oldrec,$newrec)=@_;
   if (defined($self->{DB}) && $self->{W5BaseTransactionSave}){
      $self->{DB}->commit;
   }

   return(1);
}




sub getSqlFields
{
   my $self=shift;
   my @view=$self->getCurrentView();
   my @flist=();
   my $drivername=defined($self->{DB}) ? $self->{DB}->DriverName():undef;
   my $distinct;
   if ($view[0] eq "VDISTINCT"){
      $distinct=" distinct ";
      shift(@view);
   }
   if (!$distinct){
      my $idfield=$self->IdField();
      my $idfieldname;
      $idfieldname=$idfield->Name() if (defined($idfield));
      if (!($#view==0 && ($view[0] eq $idfieldname || 
                          $view[0] eq "srcload" || 
                          $view[0] eq "srcsys" || 
                          $view[0] eq "srcid" || 
                          $view[0] eq "mdate" || 
                          $view[0] eq "cdate"))){
         my @selectfix=();
         foreach my $fname (@{$self->{'FieldOrder'}}){
            my $fobj=$self->{'Field'}->{$fname};
            if ($fobj->selectfix()){
               push(@selectfix,$fname);
            }
         }
         foreach my $selectfix (@selectfix){
            push(@view,$selectfix) if (!grep(/^$selectfix$/,@view));
         }
      }
   }
   $distinct=" distinct " if ($self->{use_distinct}==1);
   foreach my $fullfieldname (@view){
      my ($container,$fieldname)=(undef,$fullfieldname);
      if ($fullfieldname=~m/^\S+\.\S+$/){
         ($container,$fieldname)=split(/\./,$fullfieldname);
      }
      my $field=$self->getField($fieldname);
      if (defined($field->{vjoinon})){
         my $fchk=$field;
         my $loop=0;
         while(defined($fchk->{vjoinon})){
            $fchk=$self->getField($fchk->{vjoinon}->[0]);
            $loop++;
            last if (!defined($fchk) || $loop<10);
            push(@view,$fchk->Name()) if (!in_array(\@view,$fchk->Name()));
            if (defined($fchk->{container})){
               if (!in_array(\@view,$fchk->{container})){
                  push(@view,$fchk->{container});
               }
            }
         } 
      }
      if (defined($field->{depend})){
         if (ref($field->{depend}) ne "ARRAY"){
            $field->{depend}=[$field->{depend}];
         }
         foreach my $field (@{$field->{depend}}){
            push(@view,$field) if (!grep(/^$field$/,@view));
         }
      }
   }
   foreach my $fullfieldname (@view){
      my ($container,$fieldname)=(undef,$fullfieldname);
      my $field;
      if ($fullfieldname=~m/^\S+\.\S+$/){
         ($container,$fieldname)=split(/\./,$fullfieldname);
         $field=$self->getField($container);
      }
      else{
         $field=$self->getField($fieldname);
      }
      next if (!defined($field));
      next if (!$field->selectable());
      my $selectfield=$field->getBackendName("select",$self->{DB});
      if ($field->Type() eq "Container"){
         $fieldname="w5___raw_container___".$field->Name();
      }
      if (defined($selectfield)){
         # ToDo: u.U. muss $drivername noch berücksichtig werden, beim
         #       einfügen von " as "
         push(@flist,"$selectfield as $fieldname");
      }
      #
      # dependencies solution on vjoins
      #
      if (defined($field->{alias})){
         my $alias=$self->getField($field->{alias});
         $field=$alias if (defined($alias)); 
      }
      if (defined($field->{vjoinon})){
         my $joinon=$field->{vjoinon}->[0];
         my $joinonfield=$self->getField($joinon);
         if (!defined($joinonfield)){
            die("vjoinon not correct in field $field->{name}");
         }
         if (!grep(/^$joinon$/,@view)){
            my $selectfield=$joinonfield->getBackendName("select",$self->{DB});
            if (defined($selectfield)){
               $selectfield.=" ".$joinon;
               if (!grep(/^$selectfield$/,@flist)){
                  push(@flist,$selectfield);
               }
            }
         }
      }
      #
      # dependencies solution on container
      #
      elsif (defined($field->{container})){
         my $contfield=$self->getField($field->{container});
         if (defined($contfield->{dataobjattr})){
            my $newfield=$contfield->{dataobjattr}." ".$field->{container}; 
            if (!grep(/^$newfield$/,@flist)){
               push(@flist,$newfield);
            }
         }
      }
   }
   return($distinct,@flist);
}



sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return($worktable);
}

sub getSqlOrder
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my @order=$self->initSqlOrder;

   my @rawview=$self->getCurrentView(1);
   my @view=$self->getFieldObjsByView([$self->getCurrentView()]);
   my @o=$self->GetCurrentOrder();

   if (!($#o==0 && uc($o[0]) eq "NONE")){
      if ($#o==-1 || ($#o==0 && $o[0] eq "")){
         @o=@rawview;
      }
      {
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
         return(join(", ",@order));
      }
      return("");
   }
   return("");
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $filter=shift;

   return("");
}


sub initSqlOrder
{
   my $self=shift;
   return;
}


sub processFilterHash
{
   my $self=shift;
   my $wheremode=shift;
   my $where=shift;
   my $filter=shift;

   foreach my $fieldname (keys(%{$filter})){
      my %sqlparam=(orgfieldname=>$fieldname);
      my $fo=$self->getField($fieldname);
      if (!defined($fo)){
         msg(ERROR,"invalid filter request on unknown field '$fieldname'");
         next;
      }
      my $fotype=$fo->Type();
      $fo->preparseSearch(\$filter->{$fieldname});
      my $preparedFilter=$fo->prepareToSearch($filter->{$fieldname});
      if (defined($preparedFilter)){
         if ($fotype eq "Fulltext"){
            $sqlparam{datatype}="FULLTEXT";
            $sqlparam{listmode}=0;
            $sqlparam{wildcards}=0;
            $sqlparam{logicalop}=0;
         }
         if ($fotype=~m/Date$/){
            $sqlparam{datatype}="DATE";
            $sqlparam{timezone}=$fo->timezone();
         }
         if (defined($fo->{container})){
            my $containername=$fo->{container};
            my $cont=$self->getField($containername);
            if (defined($cont) && $cont->{dataobjattr} ne ""){
               $containername=$cont->{dataobjattr};
            }
            $sqlparam{containermode}=$containername;
         }
         if (defined($fo->{uppersearch})){
            $sqlparam{uppersearch}=1;
         }
         if (defined($fo->{lowersearch})){
            $sqlparam{lowersearch}=1;
         }
         if (defined($fo->{ignorecase}) && !ref($filter->{$fieldname})){
            $sqlparam{ignorecase}=1;
         }
         $sqlparam{sqldbh}=$self->{DB};
         my $sqlfieldname=$fo->getBackendName("where.$wheremode",$self->{DB});
         if ($wheremode eq "update" || $wheremode eq "delete"){
            $sqlfieldname=~s/^.*\.//; # test to make update/delete shorter
         }
         next if (!defined($sqlfieldname));
         my $bk=$self->Data2SQLwhere($where,$sqlfieldname,$preparedFilter,
                                     %sqlparam);
         return(undef) if (!$bk);
      }
   }
   return(1);
}



sub getSqlWhere
{
   my $self=shift;
   my $wheremode=shift;
   my @filter=@_;
   my $where=$self->initSqlWhere($wheremode,\@filter);

   foreach my $filter (@filter){
      if (ref($filter) eq "HASH"){
         my $bk=$self->processFilterHash($wheremode,\$where,$filter);
         return(undef) if (!$bk);
      }
      if (ref($filter) eq "ARRAY"){
         my $orwhere="";
         foreach my $flt (@{$filter}){
            my $subwhere="";
            my $bk=$self->processFilterHash($wheremode,\$subwhere,$flt);
            return(undef) if (!$bk);
            if ($subwhere ne ""){
               if ($orwhere ne ""){
                  $orwhere="($orwhere) or ($subwhere)";
               }
               else{
                  $orwhere="($subwhere)";
               }
            }
         }
         if ($orwhere ne ""){
            if ($where eq ""){
               $where="($orwhere)";
            }
            else{
               $where="($where) and ($orwhere)";
            }
         }
      }
   } 
   #printf STDERR ("DUMP:filter:%s\n",Dumper(\@filter));
   #printf STDERR ("DUMP:where:%s\n",$where);
   return($where);
}

sub getSqlGroup
{
   my $self=shift;
   return(undef);
}

sub getSqlSelect
{
   my $self=shift;

   my ($distinct,@fields)=$self->getSqlFields();
   my @filter=$self->getFilterSet();
   my $where=$self->getSqlWhere("select",@filter);
   my $group=$self->getSqlGroup("select",@filter);
   my $order=$self->getSqlOrder("select",@filter);
   my @from=$self->getSqlFrom("select",@filter);
   my $limitnum=$self->{_Limit};
   my $drivername=defined($self->{DB}) ? $self->{DB}->DriverName():undef;
   my @cmd;
   #return(undef) if ($#from==-1 || $from[0] eq "");
   my $dropLimitStart=0;
   foreach my $from (@from){
      my $cmd="select "; 
      if ($#fields!=-1){
         $cmd.=$distinct.join(",",@fields);
      }
      else{
         $cmd.=$distinct." '1' ";
      }
      if ($from ne ""){
         $cmd.=" from $from";
      }
      else{
         if ($drivername eq "oracle"){
            $cmd.=" from dual";
         }
      }
      $cmd.=" where ".$where if ($where ne "");
      $cmd.=" group by ".$group if ($group ne "");
      $cmd.=" order by ".$order if ($order ne "");
      #
      # Limit Handling
      #
      if ($limitnum>0 && !$self->{_UseSoftLimit}){
         my $limitstart=$self->{_LimitStart};
         $limitstart=1 if ($limitstart eq "");
         $limitstart=1 if ($limitstart<1);
         # LimitStart=1 means starting with the 1st record
         if ($drivername eq "mysql"){
            $limitstart--;    # MySQL starts with record 0
            my $limitstring=$limitstart.",".$limitnum;
            $cmd.=" limit $limitstring";
            $dropLimitStart++;
         }
         if ($drivername eq "oracle"){
            my $limitstring="ROWNUM>=$limitstart AND ROWNUM<=$limitnum";
            $dropLimitStart++;
            $cmd="select * from ($cmd) where $limitstring";
         }
      }
      my $disp=$cmd;
      $disp=~tr/\n/ /;
      if (!defined($where)){
         msg(ERROR,"ilegal filter for '%s'\n%s",$cmd,Dumper(\@filter));
         return(undef);
      }
      if ($drivername eq "db2"){
         $cmd.=" with ur" if ($self->{use_dirtyread}==1);
      }
      push(@cmd,$cmd);
   }
   if ($dropLimitStart){
      delete($self->{_LimitStart});
   }
   if ($#cmd>0){
      map({$_="(".$_.")"} @cmd);
      if ($drivername eq "mysql"){
         my $cmd=join(" union ",@cmd);
         $cmd.=" limit $limitnum" if ($limitnum>0 && !$self->{_UseSoftLimit});
         return($cmd);
      }
   }

   return(join(" UNION ",@cmd));
}


sub getSqlCount
{
   my $self=shift;

   my @filter=$self->getFilterSet();
   my $where=$self->getSqlWhere("select",@filter);
   my $group=$self->getSqlGroup("select",@filter);
   my @from=$self->getSqlFrom("select",@filter);
   my @cmd;
   my $limitnum=$self->{_Limit};
   

   my $cntfield="*";

   my $fobj=$self->IdField();

   if (defined($fobj)){
      my ($worktable,$workdb)=$self->getWorktable();
      $workdb=$self->{DB} if (!defined($workdb));
      my $dataobjattr=$fobj->getBackendName("select",$workdb);
      if ($dataobjattr ne ""){     
         $cntfield=$dataobjattr;
         if ($self->{use_distinct}==1){     # distinct handling only posible, if
            $cntfield="distinct $cntfield"; # an idfield exists
         }
      }
   }


   foreach my $from (@from){
      my $cmd="select  count(".$cntfield.") from ".$from;
      $cmd.=" where ".$where if ($where ne "");
      $cmd.=" group by ".$group if ($group ne "");

      #
      # Limit Handling
      #
      if ($limitnum>0 && !$self->{_UseSoftLimit}){
         if (defined($self->{DB}->{db}) &&
             lc($self->{DB}->{db}->{Driver}->{Name}) eq "mysql"){
            $cmd.=" limit $limitnum";
         }
         if (defined($self->{DB}->{db}) &&
             lc($self->{DB}->{db}->{Driver}->{Name}) eq "oracle"){
            $cmd="select * from ($cmd) where ROWNUM<=$limitnum";
         }
      }

      my $disp=$cmd;
      $disp=~tr/\n/ /;
      if (!defined($where)){
         msg(ERROR,"ilegal filter for '%s'\n%s",$cmd,Dumper(\@filter));
         return(undef);
      }
      push(@cmd,$cmd);
   }
   if ($#cmd>0){
      map({$_="(".$_.")"} @cmd);
   }
   my $sqlcmd=join(" UNION ",@cmd);


   return($sqlcmd);
}




sub QuoteHashData
{
   my $self=shift;
   my $mode=shift;
   my $workdb=shift;
   my %param=@_;
   my $newdata=$param{current};
   my %raw;

   foreach my $fobj ($self->getFieldObjsByView(["ALL"],%param)){
      my $field=$fobj->Name();
      next if (!exists($newdata->{$field}));
      if (defined($fobj->{alias})){
         $fobj=$self->getField($fobj->{alias});
      }
      if (!defined($fobj)){
         printf STDERR ("ERROR: can't getField $field in $self\n");
   #      exit(1);
   #      return(undef);
      }
      my $dataobjattr=$fobj->getBackendName($mode,$workdb);
      if (defined($dataobjattr)){
         my $rawname=$dataobjattr;
         $rawname=~s/^.*\.//;               # this is a test to make update
         if (!defined($newdata->{$field})){ # and insert statements shorter
            $raw{$rawname}="NULL";
         }elsif (ref($newdata->{$field}) eq "SCALAR"){
            $raw{$rawname}=${$newdata->{$field}};
         }
         else{
            $raw{$rawname}=$workdb->quotemeta($newdata->{$field});
         }
      }
      else{
         if (!defined($fobj->{container}) && !defined($fobj->{onFinishWrite})
             && $fobj->Type() ne "KeyText" 
             && $fobj->Type() ne "KeyHandler" &&
                $fobj->Type() ne "File"){
            msg(ERROR,"can not quote '".$newdata->{$field}.
                      "' for field '".$field."' in ".$self->Self." $self - ".
                      "no dataobjattr");
         }
      }
   }
   return(%raw);
}

sub UpdateRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my @updfilter=@_;   # update filter
   my $where=$self->getSqlWhere("update",@updfilter);
   my %raw=();

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no Worktable");
      return(undef);
   }
   if (!defined($workdb)){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no workdb");
      return(undef);
   }
   my %raw=$self->QuoteHashData("update",$workdb,
                                oldrec=>undef,current=>$newdata);
   my $cmd;
   my $logcmd;
   {
      $cmd="update $worktable set ".
           join(",",map({
                           $_."=".$raw{$_};
	                } keys(%raw)));
      $cmd.=" where ".$where if ($where ne "");
      $logcmd="update $worktable set ".
           join(",",map({
                           my $d=$raw{$_};
                           $d=substr($d,0,100)."...(BIN)'" if ($d=~m/\E/);
                           $d=~s/[^a-zA-Z 0-9\.'\-,\(\)]/_/g;
                           $_."=".$d;
	                } keys(%raw)));
      $logcmd.=" where ".$where if ($where ne "");
   }
   #msg(INFO,"fifi UpdateRecord data=%s\n",Dumper($newdata));
   my $t0=[gettimeofday()];
   my $rows=$workdb->do($cmd);
   if (!defined($rows)){
      my $retrycnt=0;
      while(my $retryErrorNo=_checkCommonRetryErrors($workdb->getErrorMsg())){
        $retrycnt++;
        if ($retrycnt>1){
           if ($retryErrorNo==1){
              msg(ERROR,"found Deadlock - retry $retrycnt");
           }
        }
        sleep($retrycnt); # increase the sleep
        $rows=$workdb->do($cmd);
        last if ($rows);
        if ($retryErrorNo==1 && $retrycnt>4){
           msg(ERROR,"Deadlock problem - giving up");
           last;
        }
        if ($retryErrorNo==2 && $retrycnt>4){
           msg(ERROR,"readonly problem - giving up");
           last;
        }
        {
           msg(INFO,"do sleep for $retryErrorNo with $retrycnt*$retrycnt for:".
                    $cmd);
           sleep($retrycnt*$retrycnt); # 1 4 9 16 sleeps (in sum 30sec)
        }
      }
   }

   if ($rows){
      if ($rows eq "0E0" && $self->{UseSqlReplace}==1){
         my @flist=keys(%raw);
         $cmd="insert into $worktable (".
              join(",",@flist).") ".
              "values(".join(",",map({$raw{$_}} @flist)).")";
         if (!($workdb->do($cmd))){
            $self->LastMsg(ERROR,
                           $self->preProcessDBmsg($workdb->getErrorMsg()));
            return(undef);
         }
      }
      my $t=tv_interval($t0,[gettimeofday()]);
      my $p=$self->Self();
      my $msg=sprintf("%s:time=%0.4fsec;mod=$p",NowStamp(),$t);
      $msg.=";user=$ENV{REMOTE_USER}" if ($ENV{REMOTE_USER} ne "");
      $self->Log(INFO,"sqlwrite",$logcmd." ($msg)");


      return(1);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub DeleteRecord
{
   my $self=shift;
   my $oldrec=shift;
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});

   my @flt;
   if (!(@flt=$self->getDeleteRecordFilter($oldrec))){
      $self->LastMsg(ERROR,"can't create delete filter in $self");
      return;
   }
   my $where=$self->getSqlWhere("delete",@flt);

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no Worktable");
      return(undef);
   }
   my $cmd="delete from $worktable";
   $cmd.=" where ".$where if ($where ne "");
   #my $cmd="delete from ta_application_data where ta_application_data.id=13";
   if ($workdb->do($cmd)){
      $self->Log(INFO,"sqlwrite",$cmd);
      return(1);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub Ping
{
   my $self=shift;
   my $errors;
   # Ping is for checking backend connect, without any error displaying ...
   {
      open local(*STDERR), '>', \$errors;
      $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   }
   # ... so STDERR outputs from this method are redirected to $errors
   if ($errors){
      foreach my $emsg (split(/[\n\r]+/,$errors)){
         $self->SilentLastMsg(ERROR,$emsg);
      }
   }

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));
   return(0) if (!defined($workdb));
   if (exists($self->{use_CountRecordPing}) && $self->{use_CountRecordPing}){
      my $errors;
      my $nRec;
      {
         open local(*STDERR), '>', \$errors;
         $self->ResetFilter();
         $nRec=$self->CountRecords();
      }
      if ($nRec<$self->{use_CountRecordPing}){
         $self->SilentLastMsg(ERROR,"minimum record count ".
              $self->{use_CountRecordPing}." not reached in ".$self->Self);
         if ($errors){
            foreach my $emsg (split(/[\n\r]+/,$errors)){
               $emsg=~s/^ERROR[: ]*//;
               $self->SilentLastMsg(ERROR,$emsg);
            }
         }
         return(0);
      }
   }  # CountRecordPing=10 means min. 10 Records needs to be found to Ping=OK

   return($workdb->Ping());
}

sub BulkDeleteRecord
{
   my $self=shift;
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my @delfilter=@_;   # delete filter
   my $where=$self->getSqlWhere("delete",@delfilter);

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't updateRecord in $self - no Worktable");
      return(undef);
   }
   my $cmd="delete from $worktable";
   $cmd.=" where ".$where if ($where ne "");
   #my $cmd="delete from ta_application_data where ta_application_data.id=13";
   msg(INFO,"delcmd=%s",$cmd);
   if ($workdb->do($cmd)){
      $self->Log(INFO,"sqlwrite",$cmd);
      return(1);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));

   return(undef);
}


sub _checkCommonRetryErrors
{
   my $emsg=shift;

   if ($emsg=~m/^Deadlock found when trying to get lock/){
      return(1);
   }
   if ($emsg=~m/^The MariaDB server is running .*--read-only option/){
      return(2);
   }

   return(0);
}


sub InsertRecord
{
   my $self=shift;
   my $newdata=shift;  # hash ref
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $idobj=$self->IdField();
   my $idfield=$idobj->Name();
   my $id;

   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));

   if (!defined($worktable) || $worktable eq ""){
      $self->LastMsg(ERROR,"can't InsertRecord in $self - no Worktable");
      return(undef);
   }
   if (!defined($workdb)){
      $self->LastMsg(ERROR,"can't InsertRecord in $self - no workdb");
      return(undef);
   }
   if (!defined($newdata->{$idfield})){
      if ($idobj->autogen==1){
         my $res=$self->W5ServerCall("rpcGetUniqueId");
         my $retry=30;
         while(!defined($res=$self->W5ServerCall("rpcGetUniqueId"))){
            sleep(1);
            last if ($retry--<=0);
            # next lines are a test, to handle break of W5Server better
            if (getppid()==1){  # parent (W5Server) killed in event context
               msg(ERROR,"Parent Process is killed - not good in DB.pm !");
               return();
            }
            msg(WARN,"W5Server problem for user $ENV{REMOTE_USER} ($retry)");
         }
         if (defined($res) && $res->{exitcode}==0){
            $id=$res->{id};
         }
         else{
            msg(ERROR,"InsertRecord: W5ServerCall returend %s",Dumper($res));
            $self->LastMsg(ERROR,"W5Server unavailable ".
                          "- can't get unique id - ".
                          "please try later or contact the admin");
            return(undef);
         }
         $newdata->{$idfield}=$id;
      }
   }
   else{
      $id=$newdata->{$idfield};
   }
   my %raw=$self->QuoteHashData("insert",$workdb,oldrec=>undef,
                                current=>$newdata);
   my $cmd;
   #   if ($self->{UseSqlReplace}==1){  # bisher kein alternatives Verhalten
   #                                    # im SQL Replace modus !!!
   #   }                                # Kann ansonsten probleme im Arikel
   {                                    # Katalog geben
      my @flist=keys(%raw);
      $cmd="insert into $worktable (".
           join(",",@flist).") ".
           "values(".join(",",map({$raw{$_}} @flist)).")";
   }
   #msg(INFO,"fifi InsertRecord data=%s into '$worktable'\n",Dumper($newdata));
   if (length($cmd)<65535){
      $self->Log(INFO,"sqlwrite",$cmd);
   }
   else{
      $self->Log(INFO,"sqlwrite","(long insert >64k)");
   }
   $workdb->{deadlockHandler}=1;
   my $bk=$workdb->do($cmd);
   if (!$bk){
      my $retrycnt=0;
      while(my $retryErrorNo=_checkCommonRetryErrors($workdb->getErrorMsg())){
        $retrycnt++;
        if ($retrycnt>1){
           if ($retryErrorNo==1){
              msg(ERROR,"found Deadlock - retry $retrycnt");
           }
        }
        sleep($retrycnt); # increase the sleep
        $bk=$workdb->do($cmd);
        last if ($bk);
        if ($retryErrorNo==1 && $retrycnt>4){
           msg(ERROR,"Deadlock problem - giving up");
           last;
        }
        if ($retryErrorNo==2 && $retrycnt>4){
           msg(ERROR,"readonly problem - giving up");
           last;
        }
        {
           msg(INFO,"do sleep for $retryErrorNo with $retrycnt*$retrycnt for:".
                    $cmd);
           sleep($retrycnt*$retrycnt); # 1 4 9 16 sleeps (in sum 30sec)
        }
      }
   }
   delete($workdb->{deadlockHandler});
   if ($bk){
      $workdb->finish();
      if (!defined($id)){
         # id was not created by w5base, soo we need to read it from the
         # table
         # getHashList
         my $cmd;
         my %q=();
         my @fieldlist=$self->getFieldList();
         foreach my $field (@fieldlist){
            my $fo=$self->getField($field);
            if ($fo->{id} && defined($fo->{dataobjattr})){
               if (defined($newdata->{$fo->{name}})){
                  $q{$fo->{dataobjattr}}=$workdb->quotemeta(
                                      $newdata->{$fo->{name}});
               }
               else{
                  $q{$fo->{dataobjattr}}="NULL";
               }
            }
         }
         if (defined($idobj->{dataobjattr}) &&          # id is automatic gen
             ref($idobj->{dataobjattr}) ne "ARRAY"){    # by the database 
            if (keys(%q)==0){     # SCOPE_IDENTIY should work on ODBC databases
               my @l;
               if (lc($self->{DB}->{db}->{Driver}->{Name}) eq "mysql"){
                  @l=$workdb->getArrayList("select LAST_INSERT_ID()");
               }
               else{
                  @l=$workdb->getArrayList("select SCOPE_IDENTITY()");
               }
               my $rec=pop(@l);
               if (defined($rec)){
                  $id=$rec->[0];
               }
            }
            else{
               $cmd="select $idobj->{dataobjattr} from $worktable ".
                    "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
               msg(INFO,"reading id by=%s",$cmd);
               my @l=$workdb->getArrayList($cmd);
               my $rec=pop(@l);
               if (defined($rec)){
                  $id=$rec->[0];
               }
            }
         }
         if (defined($idobj->{dataobjattr}) &&          # no one simple unique
             ref($idobj->{dataobjattr}) eq "ARRAY"){    # ... id more fields
          #  $cmd="select $idobj->{dataobjattr} from $worktable ".
          #       "where ".join(" and ",map({$_.="=".$q{$_}} keys(%q)));
          #  msg(INFO,"reading id by=%s",$cmd);
#
#            my @l=$workdb->getArrayList($cmd);
#            my $rec=pop(@l);
#            if (defined($rec)){
#               $id=$rec->[0];
#            }
         }
         if (!defined($id)){
            $self->LastMsg(ERROR,"no record identifier returned by insert");
         }
      }
      return($id);
   }
   $self->LastMsg(ERROR,$self->preProcessDBmsg($workdb->getErrorMsg()));
   return(undef);
}

sub preProcessDBmsg
{
   my $self=shift;
   my $msg=shift;

   if (my ($fld,$key)=$msg=~m/^Duplicate entry '(.+)' for key (\S+)\s*$/){
      return(sprintf($self->T("Duplicate entry '%s'"),$fld));
   }
   
   if (my ($fld,$key)=$msg=~m/^Cannot delete or update a parent row: a foreign key constraint fails \(`[^`]+`, CONSTRAINT `[^`]+` FOREIGN KEY \(`[^`]+`\) REFERENCES `[^`]+` \(`[^`]+`\)\)\s*$/){
      return(sprintf($self->T('Delete not possible '.
            'due to existing relations(s)'),$fld));
   }
   
   return($msg);
}



sub tieRec
{
   my $self=shift;
   my $rec=shift;

   if (ref($rec) ne "HASH"){
      msg(ERROR,"tieRec on none HASH ref is invalid");
      Stacktrace();
   }

   $self->preProcessReadedRecord($rec);

   my %rec;
   my $view=[$self->getFieldObjsByView([$self->getCurrentView()],
                                       current=>$rec)];
   tie(%rec,'kernel::DataObj::DB::rec',$self,$rec,$view);
   return(\%rec);
   return(undef);
   
}  

sub getFirst
{
   my $self=shift;
   my %attr=@_;

   if (!defined($self->{DB})){
      $self->{isInitalized}=0;
      my $msg=$self->T("no database connection or invalid database handle");
      if ($self->isSuspended()){
         if ($self->isDataInputFromUserFrontend()){
            $msg=$self->T("database connection temporary suspended");
         }
         else{
            return(undef);
         }
      }
      $self->LastMsg(ERROR,$msg);
      return(undef,msg(ERROR,$msg));
   }
   $self->{DB}->finish();
   my @sqlcmd=($self->getSqlSelect());
   if (!defined($sqlcmd[0])){
      return(undef,join("\n",$self->LastMsg()));
   }
   my $baselimit=$self->Limit();
   $self->Context->{CurrentLimit}=$baselimit if ($baselimit>0);
   my $t0=[gettimeofday()];
   #
   # remove Workaround, because now the DBI reconnect should handle all
   # in the better and correct way.
   #
   #if ((!defined($Apache::DBI::VERSION)) && (!$self->{DB}->{db}->ping())){
   #   printf STDERR ("try to reconnect MySQL (HV-Workaround)\n");
   #   my $newdbh=$self->{DB}->{db}->clone();
   #   if ($newdbh->ping()){
   #      $self->{DB}->{db}=$newdbh;
   #   }
   #}
   if ($self->{DB}->execute($sqlcmd[0],\%attr)){
      my $t=tv_interval($t0,[gettimeofday()]);
      my $p=$self->Self();
      my $msg=sprintf("%s:time=%0.4fsec;mod=$p",NowStamp(),$t);
      $msg.=";user=$ENV{REMOTE_USER}" if ($ENV{REMOTE_USER} ne "");
      $self->Log(INFO,"sqlread",$sqlcmd[0]." ($msg)");
      my $limitreached=0;
      if ($self->{_LimitStart}>1){
         for(my $c=0;$c<$self->{_LimitStart};$c++){
            my ($temprec,$error)=$self->{DB}->fetchrow();
            if (!defined($temprec)){
               $limitreached++;
            }
         }
      }
      my ($temprec,$error);
      if (!$limitreached){
         ($temprec,$error)=$self->{DB}->fetchrow();
      }
      if ($error){
         $self->LastMsg(ERROR,$self->{DB}->getErrorMsg());
         return(undef,$self->{DB}->getErrorMsg());
      }
      if ($temprec){
         $temprec=$self->tieRec($temprec);
      }
      return($temprec);
   }
   $self->LastMsg(ERROR,$self->{DB}->getErrorMsg());
   return(undef,$self->{DB}->getErrorMsg());
}

sub CountRecords
{
   my $self=shift;

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   if (!defined($self->{DB})){
      $self->{isInitalized}=0;
      return(undef,
             msg(ERROR,
             $self->T("no database connection or invalid database handle")));
   }
   $self->{DB}->finish();
   my @sqlcmd=($self->getSqlCount());
   if (!defined($sqlcmd[0])){
      return(undef,join("\n",$self->LastMsg()));
   }
   my $t0=[gettimeofday()];
   my @res=$self->{DB}->getArrayList($sqlcmd[0]);
   my $n=undef;
   foreach my $rec (@res){
      $n=0 if (!defined($n));
      $n+=$rec->[0];
   }
   $self->Log(INFO,"sqlread",$sqlcmd[0]);
   return($n);
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
   my @res=$self->getFirst(unbuffered=>1);
   if (defined($self->{DB})){
      $self->{DB}->finish();
   }
   else{
      return(undef,"DB Error");
   }
   return(@res);
}

sub finish
{
   my $self=shift;

   if (defined($self->{sth})){
      $self->{sth}->finish();
   }
   return();
}


sub getNext
{
   my $self=shift;
   if (defined($self->Context->{CurrentLimit})){
      $self->Context->{CurrentLimit}--;
      if ($self->Context->{CurrentLimit}<=0){
         if (lc($self->{DB}->{db}->{Driver}->{Name}) ne "mysql"){
            while(my ($temprec,$dberr)=$self->{DB}->fetchrow()){ 
               last if (!defined($temprec));      # on oracle DBD
            }                                     # we must read to the end
         }                                        # of request to count rows
         $self->{DB}->finish();
         return(undef,"Limit reached");
      }
   }
   if (defined($self->{DB})){
      my ($temprec,$dberr)=$self->{DB}->fetchrow();
      if (defined($temprec)){
         $temprec=$self->tieRec($temprec);
         return($temprec);
      }
      $self->{DB}->finish();
   }
   return(undef,undef);
}

sub ResolvFieldValue
{
   my $self=shift;
   my $name=shift;

   my $current=$self->{'DB'}->getCurrent();
   return($current->{$name});
}

sub setWorktable
{
   my $self=shift;
   $self->{Worktable}=$_[0];
   return($self->{Worktable},$self->{DB});
}

sub getWorktable
{
   my $self=shift;
   return($self->{Worktable},$self->{DB});
}


sub lockWorktable
{
   my $self=shift;
   my $tables=shift;
   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));
   my $locktables;
   if (defined($tables)){
      if (ref($tables) eq "ARRAY"){
         $locktables=join(",",map({$_." write"} @$tables));
      }
      else{
         $locktables=$tables;
      }
   }
   else{
      $locktables=$worktable." write,history write";
   }
   msg(DEBUG,"lock $locktables");
   if (exists($self->{locktables})){
      $locktables=$self->{locktables};
   }
   $workdb->do("lock tables $locktables");
   my $lockFail=$workdb->getErrorMsg();
   if ($lockFail eq ""){
      return(undef);
   }
   return($lockFail);
}

sub unlockWorktable
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   $workdb=$self->{DB} if (!defined($workdb));
   $workdb->do("unlock tables");
}




package kernel::DataObj::DB::rec;
use strict;
use kernel;
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
   my %HashView;
   map({$HashView{$_->Name()}=$_} @{$view});
   my $self=bless({Rec=>$rec,View=>\%HashView},$type);
   $self->setParent($parent);
   return($self);
}

sub FIRSTKEY
{
   my $self=shift;

   my %k=();
   map({$k{$_}=1;} keys(%{$self->{View}}));
   $self->{'keylist'}=[keys(%k)];
 
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;

   return(grep(/^$key$/,keys(%{$self->{View}}),keys(%{$self->{Rec}})) ? 1:0);
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

   if (exists($self->{Rec}) && defined($self->{Rec}) &&
       ref($self->{Rec}) ne "HASH"){
      msg(ERROR,"invalid internal data structure in self->Rec");
      Stacktrace(1);
      return("- internal FETCH error -");
   }
   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $p=$self->getParent();
   if (defined($p)){
      my $fobj;
      if (!defined($self->{View}->{$key})){
         $fobj=$p->getField($key,$self->{Rec});
      }
      else{
         $fobj=$self->{View}->{$key};
      }
      return($p->RawValue($key,$self->{Rec},$fobj,$mode));
   }
   return("- unknown parent for '$key' - DataObj isn't valid at now -");
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{View}->{$key}=undef if (!exists($self->{View}->{$key}));
   $self->{Rec}->{$key}=$val; 
}

sub DELETE
{
   my $self=shift;
   my $key=shift;

   delete($self->{View}->{$key});
   delete($self->{Rec}->{$key});
}
1;
