package tsacinv::invalid_smitem;
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
use itil::lib::Listedit;
use tsacinv::costcenter;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
   $self->{MainSearchFieldLines}=3;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'iid',
                label         =>'ID',
                ignorecase    =>1,
                dataobjattr   =>'e.id'),

      new kernel::Field::Text(
                name          =>'iname',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'e.name'),

      new kernel::Field::Text(
                name          =>'icostcenter',
                label         =>'Costcenter',
                ignorecase    =>1,
                dataobjattr   =>'e.costcenter'),

      new kernel::Field::Text(
                name          =>'icustomerlink',
                label         =>'CustomerLink',
                ignorecase    =>1,
                dataobjattr   =>'e.customerlink'),

      new kernel::Field::Text(
                name          =>'isaphier',
                label         =>'SAP-Hier',
                ignorecase    =>1,
                dataobjattr   =>'e.saphier'),

      new kernel::Field::Text(
                name          =>'imsskey',
                label         =>'MSS-Key',
                ignorecase    =>1,
                dataobjattr   =>'e.msskey'),

      new kernel::Field::Textarea(
                name          =>'itodo',
                label         =>'ToDo',
                dataobjattr   =>"
                   decode(e.costcenter,NULL,'-missing valid costcenter',
                   decode(e.customerlink,NULL,'-missing valid customerlink',
                   decode(e.msskey,NULL,'-missing default SC Location',
                   '')))
                "),
   );
   $self->setDefaultView(qw(linenumber iid iname icostcenter 
                            icustomerlink imsskey itodo));
   return($self);
}


sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isaphier"))){
     Query->Param("search_isaphier"=>
                  "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
}


sub getSqlFrom
{
   my $self=shift;

   my $o=getModuleObject($self->Config,"tssm::company");
   $o->SetCurrentView(qw(id msskey));

   my $validComp=$o->getHashIndexed("msskey");

   my @msskeyok=keys(%{$validComp->{msskey}});

   my $rest="";

   while($#msskeyok!=-1){
      my @l=splice(@msskeyok,0,999);
      $rest.=" and " if ($rest ne "");
      $rest.="amtsisclocations.sclocationid not in (".
            join(",",map({"'".$_."'" } @l)).")";
   }

   $rest="and (($rest) or amtsisclocations.sclocationid is null)";

   my $saphier=tsacinv::costcenter::getSAPhierSQL();


   my $from=<<EOF;
(
select amportfolio.assettag          id,
       amportfolio.name              name,
       amcostcenter.trimmedtitle     costcenter,
       amtsiaccsecunit.identifier    customerlink,
       $saphier                      saphier,
       amtsisclocations.sclocationid msskey
       
from amtsiswinstance 
     join amportfolio 
        on amportfolio.lportfolioitemid=amtsiswinstance.lportfolioid 
           and amportfolio.bdelete='0'
     left outer join amcostcenter 
        on amportfolio.lcostid=amcostcenter.lcostid 
           and amcostcenter.bdelete='0'
     left outer join amtsiaccsecunit
        on amcostcenter.lcustomerlinkid=amtsiaccsecunit.lunitid
     left outer join amtsisclocations
        on amtsiaccsecunit.ldefaultsclocationid=amtsisclocations.ltsisclocationsid
     
where amportfolio.externalsystem='W5Base'
   and amtsiswinstance.status='in operation'
   $rest
--   and ROWNUM<100   
   
union
   
select amtsicustappl.code            id,
       amtsicustappl.name            name,
       amcostcenter.trimmedtitle     costcenter,
       amtsiaccsecunit.identifier    customerlink,
       $saphier                      saphier,
       amtsisclocations.sclocationid msskey

from amtsicustappl
     left outer join amcostcenter
        on amtsicustappl.lcostcenterid=amcostcenter.lcostid 
           and amcostcenter.bdelete='0'
     left outer join amtsiaccsecunit
        on amcostcenter.lcustomerlinkid=amtsiaccsecunit.lunitid
     left outer join amtsisclocations
        on amtsiaccsecunit.ldefaultsclocationid=amtsisclocations.ltsisclocationsid
    
where amtsicustappl.externalsystem='W5Base'
   and amtsicustappl.status='IN OPERATION'
   and amtsicustappl.bdelete='0'
   $rest
--   and ROWNUM<100
) e
EOF
   #printf STDERR ("fifi l=%d\n",length($from));
   return($from);
}  


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}





1;
