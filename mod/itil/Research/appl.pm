package itil::Research::appl;
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
   $self->{dataobj}='itil::appl';
   return($self);
}

sub getJSObjectClass
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;

    my $addIf=quoteHtml($self->getParent->T("add interfaces"));
    my $addSys=quoteHtml($self->getParent->T("add systems"));


   my $d=<<EOF;
(function(window, document, undefined) {
   var o='$self->{dataobj}';
   DataObject[o]=new Object();
   DataObject[o].Class=function(dataobjid){
      return(DataObjectBaseClass.call(this,o,dataobjid));
   };
   \$.extend(DataObject[o].Class.prototype,DataObjectBaseClass.prototype);
   DataObject[o].handleSearch=function(searchstring){
         var w5obj=getModuleObject(W5App.Config(),'$self->{dataobj}');
         var curDataObj='$self->{dataobj}';
         w5obj.SetFilter({name:searchstring,cistatusid:4});
         W5App.setLoading(1,"searching "+this.dataobj);
         w5obj.findRecord("name,id",function(data){
            if (data){
               for(c=0;c<data.length;c++){
                  W5App.SearchAddResultRecord({
                     label:data[c].name,
                     dataobj:curDataObj,
                     dataobjid:data[c].id
                  });
               }
            }
            W5App.SearchFinishResult();
            W5App.setLoading(-1);
         });
   }
   DataObject[o].getPosibleExtractors=function(){
      return([{name:'dataobjid',label:'W5BaseID'},
              {name:'dataobj'  ,label:'W5BaseObj'}]);
   };
   DataObject[o].Class.prototype.loadShortRecord=function(){
         var dst=this;
         dst.rec={
            name:'????'
         };  // define a default record
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         w5obj.SetFilter({id:this.dataobjid});
         W5App.setLoading(1,"loading "+this.dataobj+" "+this.dataobjid);
         w5obj.findRecord("id,name",function(data){
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
      var shortname=this.rec.name;
      return(shortname);
   };

   DataObject[o].Class.prototype.getAvatarImage=function(){
      var i = new Image();
      i.src = '../../../public/itil/load/appl.jpg'+
              '?HTTP_ACCEPT_LANGUAGE=$lang';
      return(i);
   };

   DataObject[o].Class.prototype.getPosibleActions=function(){
      var l=DataObjectBaseClass.prototype.getPosibleActions.call(this);
      var l=new Array();
      l.push({name:'addIf',label:'$addIf'});
      l.push({name:'addSystems',label:'$addSys'});
      return(l);
   };

   DataObject[o].Class.prototype.onAction=function(name){
      if (name=='addIf'){
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         var skey=W5App.toObjKey(this.dataobj,this.dataobjid);
         w5obj.SetFilter({id:this.dataobjid});
         W5App.setLoading(1,"addIf "+this.dataobj);
         w5obj.findRecord("interfaces",function(data){
            if (data[0]){
               console.log(data);
               for(var c=0;c<data[0].interfaces.length;c++){
                  var dkey=W5App.toObjKey('itil::appl',
                                          data[0].interfaces[c].toapplid);
                  W5App.addObject('itil::appl',
                                  data[0].interfaces[c].toapplid);
                  W5App.addConnectorKK(skey,dkey,0);
               }
            }
            W5App.setLoading(-1);
         });
         return(1);
      }
      if (name=='addSystems'){
         var w5obj=getModuleObject(W5App.Config(),this.dataobj);
         var skey=W5App.toObjKey(this.dataobj,this.dataobjid);
         w5obj.SetFilter({id:this.dataobjid});
         W5App.setLoading(1,"addIf "+this.dataobj);
         w5obj.findRecord("systems",function(data){
            if (data[0]){
               for(var c=0;c<data[0].systems.length;c++){
                  var dkey=W5App.toObjKey('itil::system',
                                          data[0].systems[c].systemid);
                  W5App.addObject('itil::system',
                                  data[0].systems[c].systemid);
                  W5App.addConnectorKK(skey,dkey,0);
               }
            }
            W5App.setLoading(-1);
         });
         return(1);
      }
      return(DataObjectBaseClass.prototype.onAction.call(this,name));
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
