package base::Research::user;
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
   $self->{dataobj}='base::user';
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

   DataObject[o].Class.prototype.displayname=function(){
      if (!this.rec){
         var dst=this;
         dst.rec={surname:'???',givenname:''};  // define a default record
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         w5obj.SetFilter({userid:this.dataobjid});
         w5obj.findRecord("id,surname,givenname",function(data){
            if (data[0]){
               dst.rec=data[0];
            }
         });
      }
      var displayname=this.rec.surname;
      if (this.rec.givenname!=""){
         if (this.rec.surname.length>20){
            displayname+=", "+substr(this.rec.givenname,1)+".";
         }
         else{
            displayname+=", "+this.rec.givenname;
         }
      }
      return(displayname);
   };
   DataObject[o].Class.prototype.getPosibleActions=function(){
      return([{name:'addGroups',label:'add all related groups'},
              {name:'addOrgs',label:'add organisation groups'}]);
      return([]);
   };
   DataObject[o].Class.prototype.onAction=function(name){
      console.log('action=',name);
      if (name=='addGroups'){
         console.log("curobj",this);
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         var skey=W5App.toObjKey(this.dataobj,this.dataobjid);
         w5obj.SetFilter({userid:this.dataobjid});
         w5obj.findRecord("groups",function(data){
            if (data[0]){
               for(var c=0;c<data[0].groups.length;c++){
                  var dkey=W5App.toObjKey('base::grp',data[0].groups[c].grpid);
                  W5App.addObject('base::grp',data[0].groups[c].grpid);
                  W5App.addConnectorKK(skey,dkey,0);
               }
            }
            console.log("add Groups=",data);
         });
      }
      return([]);
   };

   DataObject[o].Class.prototype.getAvatarImage=function(){
      var i = new Image();
      i.src = '../../../public/base/load/user.jpg'+
              '?HTTP_ACCEPT_LANGUAGE=$lang';
      return(i);
   };
   DataObject[o].handleSearch=function(searchstring){
         var w5obj=getModuleObject(W5App.Config(),'$self->{dataobj}');
         var curDataObj='$self->{dataobj}';
         w5obj.SetFilter({fullname:searchstring,cistatusid:4});
         w5obj.findRecord("fullname,userid",function(data){
            if (data){
               for(c=0;c<data.length;c++){
                  W5App.SearchAddResultRecord({
                     label:data[c].fullname,
                     dataobj:curDataObj,
                     dataobjid:data[c].userid
                  });
               }
            }
            W5App.SearchFinishResult();
         });
   }

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
      name=>'base::user',
      label=>$app->T($self->{dataobj},$self->{dataobj}),
      prio=>'500'
   });
}



1;
