package kernel::Input::XMLV01;

use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use Data::Dumper;

@ISA=qw(kernel::Universal);
   
sub new
{  
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);
   return($self);
}

sub getIconName
{
   my $self=shift;
   return("icon_xml");
}





sub SetInput
{
   my $self=shift;
   my $file=shift;
  
   my $firstline;
   eval("use XML::Parser;");
   return(undef) if ($@ ne "");
   while($firstline=<$file>){
      next if ($firstline=~m/^\s*$/);
      if ($firstline=~m/^<\?xml\s.*\?>\s*$/){
         my $p=new XML::Parser();
         my $recno=0;
         my $rec={};
         my $CurrentStart;
         my $CurrentTag;
         my $CurrentRecordType;
         $p->setHandlers(Start=>sub{
                            my ($p,$tag,%attr)=@_;
                            $CurrentTag=$tag;
                            if ($tag eq "record"){
                               $recno++;
                               $CurrentStart=$p->current_line()+1;
                               $CurrentRecordType=$attr{type};
                            }
                            my @c=$p->context();
                            if (join(".",@c) eq "root.record"){
                               $rec->{$CurrentTag}="";
                            }
                         },
                         End=>sub{
                            my ($p,$tag,%attr)=@_;
                            if ($tag eq "record"){
                               print msg(INFO,"[start record %d ".
                                              "starting at line %d ".
                                              "with %d vars for '%s']",
                                         $recno,$CurrentStart,
                                         scalar(keys(%{$rec})),
                                         $ENV{REMOTE_USER});
                               my @okeys=keys(%$rec);
                               my @nkeys=$self->getParent->getParent->
                                        CachedTranslateUploadFieldnames(@okeys);
                               my %trrec;
                               for(my $c=0;$c<=$#okeys;$c++){
                                  $trrec{$nkeys[$c]}=$rec->{$okeys[$c]};
                               }
                               &{$self->{Callback}}(\%trrec,$CurrentRecordType);
                               #sleep(1);
                               $rec={};
                            }
                         },
                         Char=>sub {
                            my ($p,$s)=@_;
                            my @c=$p->context();
                            if ($#c==2 && join(".",@c)=~m/^root\.record\./){
                               $rec->{$CurrentTag}=$s;
                            }
                         });
         $self->{Parser}=$p;
         $self->{File}=$file;
         return(1);
      }
   }
   return(undef) if ($firstline eq "");
}

sub Process
{
   my $self=shift;

   eval("\$self->{Parser}->parse(\$self->{File});");
}
   
sub SetCallback
{
   my $self=shift;
   my $callback=shift;

   $self->{Callback}=$callback;
}
   
1;
