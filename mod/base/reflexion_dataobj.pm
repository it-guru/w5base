package base::reflexion_dataobj;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA $VERSION $DESCRIPTION);
use kernel;
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
use Text::Wrap;
use Class::ISA;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

$VERSION="1.1";
$DESCRIPTION=<<EOF;
Represend all existing dataobject in current
running W5Base application.

To see VERSION and DESCRIPTION, there are need to be the
variables \$VERSION and \$DESCRIPTION in the programmcode.
If not, VERSION=UNKNOWN and DESCRIPTION="??? Beta Module ???".

In the description can be also informations about access
rules and other security informations as documention from
the developer.
EOF


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
                searchable    =>1,
                align         =>'left',
                label         =>'ID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>0,
                searchable    =>1,
                align         =>'left',
                label         =>'fullqualified object'),

      new kernel::Field::Text(
                name          =>'modnamelabel',
                explore       =>100,
                label         =>'Dataobject Label'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description'),

      new kernel::Field::SubList(
                name          =>'fields',
                label         =>'fields',
                readonly      =>1,
                htmldetail    =>0,
                explore       =>200,
                group         =>'fields',
                vjointo       =>'base::reflexion_fields',
                vjoinon       =>['id'=>'modname'],  
                vjoindisp     =>['internalname','type']),

      new kernel::Field::Text(
                name          =>'selfasparent',
                label         =>'top object name'),

      new kernel::Field::Textarea(
                name          =>'pclasses',
                label         =>'parent Classes'),

      new kernel::Field::Textarea(
                name          =>'sqlfrom',
                group         =>'sql',
                label         =>'SQL From Base Defintion'),

      new kernel::Field::Textarea(
                name          =>'sqlfields',
                group         =>'sql',
                label         =>'SQL Field Base Defintion'),

      new kernel::Field::Textarea(
                name          =>'objectdef',
                label         =>'IO-Object Defintion',
                htmlheight    =>'400px',
                group         =>'sql',
                searchable    =>0,
                depend        =>['fullname','modnamelabel',
                                 'sqlfrom','sqlfields'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $n=$current->{fullname};
                   $Text::Wrap::columns=60;
                   if ($n ne $current->{modnamelabel}){
                      $n.="\n(".$current->{modnamelabel}.")";
                   }
                   $n.="\n".("=" x $Text::Wrap::columns)."\n";
                   my $h1="SQL Access to Tables:";
                   $h1.="\n".("-" x length($h1))."\n";
                   $h1.=$current->{sqlfrom}."\n";
                   $h1=wrap('','',$h1);
                   $n.=$h1."\n";
                   my $h1="SQL Access to Fields:";
                   $h1.="\n".("-" x length($h1))."\n";
                   $h1.=$current->{sqlfields}."\n";
                   $h1=wrap('','',$h1);
                   $n.=$h1;
                   $n.=("-" x $Text::Wrap::columns)."\n\n".chr(9)."\n";
                   return($n);
                }),

   );
   $self->{'data'}=\&getData;



   $self->setDefaultView(qw(fullname modnamelabel selfasparent));
   return($self);
}

sub getData
{
   my $self=shift;
   my $c=$self->Context;
   if (!defined($c->{data})){
      my $instdir=$self->Config->Param("INSTDIR");
      my $cachedir=$self->Config->Param("DataObjCacheStore");
      $cachedir.="/" if (!($cachedir=~m/\/$/));
      my $DataObjCacheFile=$cachedir.$self->Self.".cache.db.tmp";
      my $pat="$instdir/mod/*/*.pm";
      my @sublist=glob($pat);
      my $maxmtime=0;
      map({ my $mtime = (stat($_))[9];
               $maxmtime=$mtime if ($maxmtime<$mtime);
      } @sublist);
      if ((stat($DataObjCacheFile))[9]>$maxmtime){
         if (open(F,"<",$DataObjCacheFile)){
            my $VAR1;
            eval(join("",<F>));
            if (defined($VAR1)){
               $c->{data}=$VAR1;
            }
            else{
               msg(ERROR,"read from cache $DataObjCacheFile failed: $@");
            }
            close(F);
         }
      }
      if (!defined($c->{data})){
         my @sublist=$self->globalObjectList();
         my @data=();
         foreach my $modname (@sublist){
            my $o=getModuleObject($self->Config,$modname);
            if (defined($o)){
               my %rec=();
               $rec{id}=$modname;
               my $oldlang;
               if (defined($ENV{HTTP_FORCE_LANGUAGE})) {
                  $oldlang=$ENV{HTTP_FORCE_LANGUAGE};
               }
               $ENV{HTTP_FORCE_LANGUAGE}="en";
               $rec{fullname}=$modname." (".$o->T($modname,$modname).")";
               if (defined($oldlang)){
                  $ENV{HTTP_FORCE_LANGUAGE}=$oldlang;
               }
               else{
                  delete($ENV{HTTP_FORCE_LANGUAGE});
               }
               $rec{modnamelabel}=$o->T($modname,$modname);
               my $sp=join(", ",Class::ISA::super_path($modname));
               $rec{pclasses}=$sp;
               if ($o->can("SelfAsParentObject")){
                  my $po=$o->SelfAsParentObject();
                  if ($po ne $modname){
                     $rec{selfasparent}=$po;
                  }
               }
               if ($modname->can("VERSION")){
                  $rec{version}=$modname->VERSION;
               }
               if ($o->can("getSqlFrom")){
                  my $from=$o->getSqlFrom();
                  $rec{sqlfrom}=$from;
                  if ($o->can("AddDatabase")){
                     my $From;
                     my $inbracket=0;
                     $from=~s/[\n\r]/ /g;
                     $from=~s/ +/ /g;
                     pos($from)=0;
                     while ($from=~m{\G((.*?,)|(.*\(.+\))|([^,]+$))}cmg){
                        my $sub=$1;
                        if ($sub=~m/,\s*$/){
                           $sub.="\n";
                        }
                        $sub=~s/^\s*//;
                        $From.=$sub;
                     }
                     $rec{sqlfrom}=$From;
                  }
               }
               else{
                  $rec{sqlfrom}=undef;
               }
               $rec{description}="\$${modname}::DESCRIPTION";
               $rec{description}=eval($rec{description});
               if ($rec{version} eq ""){
                  $rec{version}="UNKNOWN";
               }
               if ($rec{description} eq ""){
                  $rec{description}="??? Beta Module ???";
               }
               $rec{sqlfields}="";
               my %f=();
               if ($o->can("getFieldObjsByView")){
                  foreach my $fo ($o->getFieldObjsByView([qw(ALL)])){
                     my $d=$fo->{dataobjattr};
                     $d=~s/\n/ /g;
                     $d=~s/ +/ /g;
                     if ($d ne ""){
                        $f{$d}++;
                     }
                  }
                  $rec{sqlfields}=join(",\n",sort(keys(%f)));
               }

               push(@data,\%rec);
            }
            else{
               msg(ERROR,"fail to load reflexion dataobj: $modname");
            }
         }
         if (open(F,">",$DataObjCacheFile)){
            print F (Dumper(\@data));
            close(F);
         }
         else{
            msg(ERROR,"fail to write cache file $DataObjCacheFile");
         }
         $c->{data}=\@data;
       }
   }
   return($c->{data});
}




sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(show),$self->SUPER::getValidWebFunctions());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header history fields);
   
   if (in_array([split(/,\s*/,$rec->{pclasses})],"kernel::DataObj::DB")){
      push(@l,"sql");
   }
   return(@l);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","fields","sql" ,"source");
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  


sub jsExploreFormatLabelMethod
{
   my $self=shift;
   return("newlabel=newlabel.replace(' (','\\n(');");
}

   
sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("extend depth by one");
   $methods->{'m100extDataModeldepth'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m100extDataModeldepth on \",this);
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          var app=this.app;
          var MasterItem=this;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'base::reflexion_fields');
                w5obj.SetFilter({
                   modname:dataobjid
                });
                w5obj.findRecord(\"id,vjointo\",function(data){
                   console.log(\"found:\",data);
                   for(recno=0;recno<data.length;recno++){
                      if (data[recno].vjointo!=\"\"){
                         var curkey=MasterItem.id;
                         var nexkey=app.toObjKey('base::reflexion_dataobj',
                                           data[recno].vjointo);
                         app.addNode('base::reflexion_dataobj',
                                     data[recno].vjointo,
                                     data[recno].vjointo);
                         app.addEdge(curkey,nexkey);
                      }
                  }
               });
               \$(document).ajaxStop(function () {
                   methodDone(\"load of Members done\");
               });
             });
          }));
       }
   ";

}





1;
