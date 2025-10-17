package W5Warehouse::applarchive;
use strict;
use vars qw(@ISA);
use kernel;
use W5Warehouse::lib::Listedit
@ISA=qw(W5Warehouse::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->setWorktable("APPLARCHIVE");
   $self->setDefaultView(qw(linenumber 
                            archivestamp
                            name
                            ));
   return($self);
}

sub AddAllFieldsFromWorktable
{
   my $self=shift;

   my @back=$self->SUPER::AddAllFieldsFromWorktable(@_);

#   if ($self->getField("itsemteamid")){ 
#      $self->getField("itsemteamid")->{uivisible}=0;
#      $self->getField("itsemteamid")->{noselect}=1;
#   }
   return(@back);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($self->IsMemberOf("admin")){
      return("ALL");
   }
   return();
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin)], "RMember")){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
               [orgRoles(),qw(RMember)],
               "both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();

      my @addflt=({name=>[-99]});
      #if ($ENV{REMOTE_USER} ne "anonymous"){
      #   push(@addflt);
      #}
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}


1;
