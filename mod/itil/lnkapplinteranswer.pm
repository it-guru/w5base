package itil::lnkapplinteranswer;
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
use base::interanswer;
@ISA=qw(base::interanswer);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'parentname',
                htmlwidth     =>'100px',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Application name',
                translation   =>'itil::appl',
                vjointo       =>'itil::appl',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Import( $self,
                vjointo       =>'itil::appl',
                dontrename    =>1,
                readonly      =>1,
                group         =>'relation',
                uploadable    =>0,
                fields        =>[qw(businessteam businessteamid 
                                    mandator mandatorid
                                    )]),
      insertafter=>'parentname'
   );


   $self->getField("parentobj")->{searchable}=0;
   $self->{secparentobj}='itil::appl';
   $self->{analyticview}=['name','interviewst'];
   $self->setDefaultView(qw(parentname mandator relevant name 
                            answer mdate editor));
   return($self);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my %g=$self->getGroupsOf($ENV{REMOTE_USER},
                               [qw(RCFManager RCFManager2 RAuditor RQManager)],
                               'down');
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my @secflt=({mandatorid=>\@mandators});
      if (keys(%g)){
         push(@secflt,{mandatorid=>[keys(%g)]});
      }
      push(@flt,\@secflt);
   }
   return($self->SetFilter(@flt));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL"); 
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $secobj=$self->{secparentobj};

   return("appl left outer join $worktable ".
          "on $worktable.parentobj='$secobj' and ".
          "$worktable.parentid=appl.id ".
          "left outer join interview ".
          "on $worktable.interviewid=interview.id ");
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="(appl.cistatus<=5 and appl.cistatus>=3)";
   return($where);
}


sub collectAnalyticsDataObjects
{
   my $self=shift;
   my $q=shift;

   my $parentobj=getModuleObject($self->Config,$self->{secparentobj});
   my $pidname=$parentobj->IdField->Name();

   $self->ResetFilter();
   $self->SecureSetFilter($q);
   $self->SetCurrentView(qw(parentid));
   my $i=$self->getHashIndexed("parentid");

   my $interview=getModuleObject($self->Config,"base::interview");
   $interview->SetFilter({parentobj=>\$self->{secparentobj}});
   $interview->SetCurrentView(qw(interviewcatid));
   my $ic=$interview->getHashIndexed("interviewcatid");

   if ($self->LastMsg()>0){
      return();
   }
   my @dataobj=({name=>'ianswers',
                 dataobj=>$self,
                 view   =>[qw(parentid cdate mdate interviewcatid
                              qtag answer relevant)]},
                {name=>'interview',
                 dataobj=>$interview,
                 view=>[qw(name id interviewcatid)]},
                {name=>'interviewcat',
                 dataobj=>getModuleObject($self->Config,"base::interviewcat"),
                 filter=>{id=>[keys(%{$ic->{interviewcatid}})]},
                 view=>[qw(name id fullname)]},
                {name=>'iparent',
                 dataobj=>$parentobj,
                 filter=>{$pidname=>[keys(%{$i->{parentid}})]},
                 view=>[$pidname,@{$self->{analyticview}}]
                }
                );
   return(dataobj=>\@dataobj,
          js=>[qw(jquery.js jquery.layout.js sprintf.js 
                  analytics.js)],
          css=>[qw(base/css/default.css 
                   base/css/work.css 
                   base/css/jquery.layout.css)],
          menu=>['m1'=>{label=>'einfache Analyse der Antwortenanzahl',
                        js=>"AnalyticsQCount({base:'',key:'name'});"},
                 'm2'=>{label=>'Erreichungsgrad analyse',
                        js=>"AnalyticsGoal({base:'',key:'name',".
                            "desc:'Erreichungsgrad in %'});"}]
         );

}






1;
