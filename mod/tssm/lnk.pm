package tssm::lnk;
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
use tssm::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lnkid',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'LinkID',
                dataobjattr   =>SELpref.'screlationm1.ROWID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'relation name',
                uppersearch   =>1,
                dataobjattr   =>"concat(".SELpref."screlationm1.source,".
                                "concat('-',".SELpref."screlationm1.depend))"),

      new kernel::Field::MultiDst (
                name          =>'srcname',
                group         =>'src',
                label         =>'Source name',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                dst           =>['tssm::chm' =>'name',
                                 'tssm::inm'=>'name',
                                 'tsacinv::system'=>'systemname',
                                 'tsacinv::appl'=>'name',
                                 'tssm::prm'=>'name'],
                dsttypfield   =>'srcobj',
                dstidfield    =>'src'),

      new kernel::Field::Text(
                name          =>'src',
                group         =>'src',
                label         =>'Source-ID',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'screlationm1.source'),

      new kernel::Field::Text(
                name          =>'srcfilename',
                group         =>'src',
                label         =>'Source-filename',
                dataobjattr   =>SELpref.'screlationm1.source_filename'),

      new kernel::Field::Text(
                name          =>'srcobj',
                group         =>'src',
                label         =>'Source-obj',
                dataobjattr   =>getSrcDecode(
                                  SELpref."screlationm1.source_filename")
                                ),

      new kernel::Field::MultiDst (
                name          =>'dstname',
                group         =>'dst',
                label         =>'Destination name',
                altnamestore  =>'dstraw',
                htmlwidth     =>'200',
                dst           =>[
                                 'tssm::chm' =>'name',
                                 'tssm::chmtask'=>'name',
                                 'tssm::inm'=>'name',
                                 'tssm::dev'=>'fullname',
                                 'tsacinv::system'=>'systemname',
                                 'tsacinv::appl'=>'name',
                                 'tssm::prm'=>'name'
                                ],
                dsttypfield   =>'dstsmobj',
                dstidfield    =>'dstsmid'),

      new kernel::Field::Text(
                name          =>'dstraw',
                selectfix     =>1,
                group         =>'dst',
                label         =>'Destination SM Title',
                dataobjattr   =>SELpref.'screlationm1.depend'),

      new kernel::Field::Text(
                name          =>'dstfilename',
                group         =>'dst',
                label         =>'Destination SM Filename',
                dataobjattr   =>SELpref.'screlationm1.depend_filename'),

      new kernel::Field::MultiDst (
                name          =>'dstamname',
                group         =>'amdst',
                label         =>'Destination SACM Item',
                altnamestore  =>'dstraw',
                dst           =>[
                                 'tsacinv::system'=>'fullname',
                                 'tsacinv::appl'=>'fullname',
                                 'tsacinv::asset'=>'name',
                                ],
                dsttypfield   =>'dstobj',
                dstidfield    =>'dstid'),

      new kernel::Field::Text(
                name          =>'dstobj',
                group         =>'amdst',
                label         =>'Destination-AMObj',
                dataobjattr   =>getAMObjDecode(getAMIDfromDesc(),
                                               getSMIDfromDesc())),

      new kernel::Field::Text(
                name          =>'dstid',
                group         =>'amdst',
                label         =>'Destination-AMID',
                dataobjattr   =>getAMIDfromDesc()),

      new kernel::Field::Text(
                name          =>'dstsmobj',
                group         =>'dst',
                label         =>'Destination-SMObj',
                dataobjattr   =>getSMObjDecode(getSMIDfromDesc())),

      new kernel::Field::Text(
                name          =>'dstsmid',
                group         =>'dst',
                label         =>'Destination-SMID',
                dataobjattr   =>getSMIDfromDesc()),


      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'Modification-Date',
                dataobjattr   =>SELpref.'screlationm1.sysmodtime'),

      new kernel::Field::Boolean(
                name          =>'dstvalid',
                group         =>'status',
                label         =>'Destination-Valid at insert time',
                dataobjattr   =>
                  "decode(".
                     "substr(dbms_lob.substr(dh_desc),".
                            "instr(dbms_lob.substr(dh_desc),'\n',1,1)+1,".
                            "4),".
                     "'true',1,0)"
                ),

      new kernel::Field::Text(
                name          =>'rawdepend',
                label         =>'raw Depend',
                dataobjattr   =>SELpref.'screlationm1.depend'),
#
#      new kernel::Field::Textarea(
#                name          =>'rawdstmodel',
#                label         =>'raw dstmodel',
#                dataobjattr   =>'device2m1dstdev.model'),
#
      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>SELpref.'screlationm1.dh_desc'),
   );
   
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(linenumber src dst sysmodtime));
   return($self);
}

# ACHTUNG: Die Verknüpfungen aus SM heraus sind etwas PERVERS. Innerhalb der
#          Darwin Web-Oberfläche werden wir mit SM Links arbeiten, d.h. wir
#          werden versuchen die Links von SM in der Darwin Oberfläche 
#          nachzubilden (also i.d.R. Links auf tssm::dev).
#          Um die Verbindung zum Rest der Welt rechnen zu können, brauchen
#          wir aber noch die Links auf AM (also tsacinv::system, tsacinv::appl)
#          die dann in dstamobj bzw. dstamid zu finden sein werden.


sub getSMIDfromDesc   # Link ID innerhalb von ServiceManager
{
   return("decode(depend_filename,'cm3r',depend,".
                                 "'cm3t',depend,".
                                 "'problem',depend,".
                                 "'rootcause',depend,".
                 "substr(dbms_lob.substr(dh_desc),1,".
                 "instr(dbms_lob.substr(dh_desc),chr(10),1,1)-1))");
}

sub getAMIDfromDesc   # Link ID nach AssetManager
{
   return("reverse(substr(reverse(depend),2,".
          "instr(substr(reverse(depend),2),'(')-1))");
}

sub getSrcDecode
{
   my $varname=shift;
   return("decode($varname,'cm3r','tssm::chm',".
                          "'rootcause','tssm::prm',".
                          "'problem','tssm::prm',".
                          "'incidents','tssm::inm'".
          ")");
}

sub getSMObjDecode
{
   my $varname=shift;
   return(
       "decode(depend_filename,'cm3r','tssm::chm',".
                              "'problem','tssm::inm',".
                              "'rootcause','tssm::prm',".
                              "'cm3t','tssm::chmtask',".
          "decode(substr($varname,0,1),'S','tsacinv::system',".
                                      "'T','tssm::chmtask',".
                                      "'A','tsacinv::appl',".
             "decode(substr($varname,0,4),".
                "'org=','tssm::dev')))");
}

sub isQualityCheckValid
{
   return(0);
}


sub getAMObjDecode
{
   my $depend=shift;
   my $smid=shift;

   return(
       "decode(depend_filename,'cm3r',NULL,".
                              "'cm3t',NULL,".
          "decode(instr($smid,'|struct=table|cit=amTsiCustAppl|'),0,".
               "decode(substr($depend,0,4),'SGER','tsacinv::system',".
                                           "'APPL','tsacinv::appl',".
                  "decode(substr($depend,0,1),".
                     "'A','tsacinv::asset',".
                     "'S','tsacinv::system')),".
          "'tsacinv::appl')".
       ")");
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(src dst amdst status));
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


sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."screlationm1 ".SELpref."screlationm1";
   return($from);
}

#sub initSqlWhere
#{
#   my $self=shift;
#   my $where="screlationm1.depend=device2m1dstdev.id(+)";
#   return($where);
#}


1;
