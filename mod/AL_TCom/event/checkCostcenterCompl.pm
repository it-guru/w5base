package AL_TCom::event::checkCostcenterCompl;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
use kernel::XLSReport;
use kernel::Field;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub checkCostcenterCompl
{
   my $self=shift;
   my %param=@_;
   my %flt;

   my $costcenter=getModuleObject($self->Config,"tsacinv::costcenter");

   $costcenter->SetFilter({usedbyactivesystems=>\'1',
                           saphier=>"9TS_ES.9DTIT 9TS_ES.9DTIT.*",
   #                        name=>"100003444O 100003468O 900472579O 80140070 900509483O E100008037",
                           islocked=>\'0'});
   $costcenter->SetCurrentView(qw(name saphier));
   my $cc=$costcenter->getHashIndexed("name");
   my @list=keys(%{$cc->{name}});

   my $icc=getModuleObject($self->Config,"itil::costcenter");
   $icc->SetFilter({conodenumber=>\@list});
   my @fl=qw(conodenumber cistatusid databoss databossid);
   foreach my $corec ($icc->getHashList(@fl)){
      if (exists($cc->{name}->{$corec->{conodenumber}})){
         foreach my $f (@fl){
            $cc->{name}->{$corec->{conodenumber}}->{$f}=$corec->{$f};
         }
      }
   }
   my %msg;
   foreach my $co (keys(%{$cc->{name}})){
      msg(DEBUG,"check $co");
      if (!exists($cc->{name}->{$co}->{cistatusid}) ||
          $cc->{name}->{$co}->{cistatusid}!=4){
         $msg{$co}={
          t=>"en: missing active costcenter $co\n".
             "de: das Kontierungsobjekt $co ist nicht erfasst",
         costcenter=>$co};
      }
      elsif($cc->{name}->{$co}->{databossid} eq ""){
         $msg{$co}={
          t=>"en: no valid databoss for costcenter $co\n".
             "de: kein gültiger Datenverantwortlicher im Kontierungsobjekt $co",
                    costcenter=>$co};
      }
      elsif($cc->{name}->{$co}->{databoss}=~m/\[.*\]$/){
         $msg{$co}={
          t=>"en: deleted databoss for costcenter $co\n".
             "de: gelöschter Datenverantwortlicher am Kontierungsobjekt $co",
          costcenter=>$co};
      }
   }
   my $sappsp=getModuleObject($self->Config,"tssapp01::psp");
   my $sapcost=getModuleObject($self->Config,"tssapp01::costcenter");

   foreach my $co (keys(%msg)){
      my $saprec;
      if (!defined($saprec)){
         $sapcost->ResetFilter();
         $sapcost->SetFilter({name=>"$co"});
         ($saprec)=$sapcost->getOnlyFirst(qw(ALL));
         if (defined($saprec) && $saprec->{responsible} ne ""){
            $msg{$co}->{contact}=lc($saprec->{responsible});
         }
      }
      if (!defined($saprec)){
         $sappsp->ResetFilter();
         $sappsp->SetFilter({name=>"?-$co"});
         ($saprec)=$sappsp->getOnlyFirst(qw(ALL));
         if (defined($saprec)){
            if ($saprec->{databoss} ne ""){
               $msg{$co}->{contact}=lc($saprec->{databoss});
            }
            elsif ($saprec->{sm} ne ""){
               $msg{$co}->{contact}=lc($saprec->{sm});
            }
         }
      }
      if (!defined($saprec)){
         $sapcost->ResetFilter();
         $sapcost->SetFilter({name=>"*0$co"});
         ($saprec)=$sapcost->getOnlyFirst(qw(ALL));
         if (defined($saprec) && $saprec->{responsible} ne ""){
            $msg{$co}->{contact}=lc($saprec->{responsible});
         }
      }
   }
   if (open(F,">/tmp/checkCostcenterCompl.missing.csv")){
      foreach my $co (sort(keys(%msg))){
         printf F ("%s;%s\r\n",$co,$msg{$co}->{contact});
      }
      close(F);
   }

 
   my %target;
   foreach my $co (keys(%msg)){
      my $t=$msg{$co}->{contact};
      $t="UNKNOWN" if ($t eq "");
      push(@{$target{$t}},$msg{$co});
   }

   #print STDERR Dumper(\%target);

   my $wa=getModuleObject($self->Config,"base::workflowaction");

   foreach my $t (keys(%target)){
      my %param=(
      #            adminbcc=>1,
                  emailbcc=>[qw(11634953080001)],
      #            emailbcc=>[qw(11634953080001)],
      #            emailcc=>[qw(11634955470001 
      #                         12762475160001)]
      );
      if ($t ne "UNKNOWN"){
#         $param{emailto}=$t;
      }
      my $m="determined contact $t\n\n".join("\n\n",
            map({$_->{t}} @{$target{$t}}));
      $m.="\n\nen:\n".
          "To manage costcenters in W5Base/Darwin, use the link\n".
          "https://darwin.telekom.de/darwin/auth/base/menu/msel/AL_TCom/kern/costcenter\n".
          "\n\nde:\n".
          "Zur Verwaltung der Kontierungsobjekte verwenden Sie bitte den ".
          "Link\n".
          "https://darwin.telekom.de/darwin/auth/base/menu/msel/AL_TCom/kern/costcenter\n".
          "Beziehen sich die Kontierungsobjekte auf die Bereiche TSS ".
          "oder DSS, so besprechen Sie die weitere Vorgehensweie bitte ".
          "mit Fr. Gräb Anja (Bamberg). ".
          "Bei Unklarheiten bei der Vorgehensweise zum erzeugen bzw. ".
          "bearbeiten von Kontierungsobjekten, kontaktieren Sie bitte ".
          "die Config-Manager im CC dieser Mail.";
      

      $wa->Notify("WARN",
                  "invalid or missing costcenter entries in W5Base/Darwin",$m,
                  %param);
   }

   return({exitcode=>0,msg=>"OK"});
}




1;
