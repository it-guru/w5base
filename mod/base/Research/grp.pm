package base::Research::grp;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use kernel::Research;
@ISA=qw(kernel::Research);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   $self->{dataobj}='base::grp';
   return($self);
}

sub getJSObjectClass
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;
   my $d=<<EOF;
(function(window, document, undefined) {
   var o='$self->{dataobj}';
   DataObject[o]=new Object();
   DataObject[o].Class=function(dataobjid){
      return(DataObjectBaseClass.call(this,o,dataobjid));
   };
   \$.extend(DataObject[o].Class.prototype,DataObjectBaseClass.prototype);

   DataObject[o].Class.prototype.loadShortRecord=function(){
         var dst=this;
         dst.rec={
            fullname:'????',
            name:'???'
         };  // define a default record
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         w5obj.SetFilter({grpid:this.dataobjid});
         W5App.setLoading(1,"loading "+this.dataobj+" "+this.dataobjid);
         w5obj.findRecord("id,name,fullname",function(data){
            if (data[0]){
               dst.rec=data[0];
            }
            W5App.setLoading(-1);
         });
   };

   DataObject[o].Class.prototype.shortname=function(){
      if (!this.rec) this.loadShortRecord();
      var shortname=this.rec.name;
      return(shortname);
   };
   DataObject[o].Class.prototype.fullname=function(){
      if (!this.rec) this.loadShortRecord();
      var fullname=this.rec.fullname;
      return(fullname);
   };
   DataObject[o].Class.prototype.getAvatarImage=function(){
      var i = new Image();
      i.src = '../../../public/base/load/grp.jpg'+
              '?HTTP_ACCEPT_LANGUAGE=$lang';
      return(i);
   };
})(this,document);
EOF
   return($d);
}

sub getObjectInfo
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;

   return({
      name=>$self->{dataobj},
      label=>$app->T($self->{dataobj},$self->{dataobj}),
      prio=>'500'
   });
}




1;
