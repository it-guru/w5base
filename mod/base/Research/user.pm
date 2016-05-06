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

   my $addGroups=quoteHtml($self->getParent->T("add all related groups"));
   my $addOrgs=quoteHtml($self->getParent->T("add organisation groups"));
   my $orgRoles=join(" ",orgRoles());

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
            surname:'???',
            givenname:''
         };  // define a default record
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         w5obj.SetFilter({userid:this.dataobjid});
         W5App.setLoading(1,"loading "+this.dataobj+" "+this.dataobjid);
         w5obj.findRecord("id,surname,givenname,fullname",function(data){
            if (data[0]){
               dst.rec=data[0];
            }
            W5App.setLoading(-1);
         });
   };

   DataObject[o].Class.prototype.shortname=function(){
      if (!this.rec){
         this.loadShortRecord();
      }
      var shortname=this.rec.surname;
      if (this.rec.givenname!=""){
         if (this.rec.surname.length>20){
            shortname+=", "+substr(this.rec.givenname,1)+".";
         }
         else{
            shortname+=", "+this.rec.givenname;
         }
      }
      return(shortname);
   };

   DataObject[o].Class.prototype.fullname=function(){
      if (!this.rec){
         this.loadShortRecord();
      }
      var fullname=this.rec.fullname;
      return(fullname);
   };

   DataObject[o].Class.prototype.getPosibleActions=function(){
      var l=DataObjectBaseClass.prototype.getPosibleActions.call(this);
      l.push({name:'addGroups',label:'$addGroups'});
      l.push({name:'addOrgs',label:'$addOrgs'});
      return(l);
   };
   DataObject[o].Class.prototype.onAction=function(name){
      if (name=='addGroups'){
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         var skey=W5App.toObjKey(this.dataobj,this.dataobjid);
         w5obj.SetFilter({userid:this.dataobjid});
         W5App.setLoading(1,"groupadd "+this.dataobj);
         w5obj.findRecord("groups",function(data){
            if (data[0]){
               for(var c=0;c<data[0].groups.length;c++){
                  var dkey=W5App.toObjKey('base::grp',data[0].groups[c].grpid);
                  W5App.addObject('base::grp',data[0].groups[c].grpid);
                  W5App.addConnectorKK(skey,dkey,0);
               }
            }
            W5App.setLoading(-1);
         });
         return(1);
      }
      if (name=='addOrgs'){
         var w5obj=getModuleObject(W5App.Config(),"base::lnkgrpuser");
         var skey=W5App.toObjKey(this.dataobj,this.dataobjid);
         w5obj.SetFilter({userid:this.dataobjid,nativroles:'$orgRoles'});
         W5App.setLoading(1,"groupadd "+this.dataobj);
         w5obj.findRecord("grpid",function(data){
            if (data[0]){
               for(var c=0;c<data.length;c++){
                  var dkey=W5App.toObjKey('base::grp',data[c].grpid);
                  W5App.addObject('base::grp',data[c].grpid);
                  W5App.addConnectorKK(skey,dkey,0);
               }
            }
            W5App.setLoading(-1);
         });
         return(1);
      }
      return(DataObjectBaseClass.prototype.onAction.call(this,name));
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
         W5App.setLoading(1,"searching "+this.dataobj);
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
            W5App.setLoading(-1);
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
