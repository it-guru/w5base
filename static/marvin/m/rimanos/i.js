
// derevation for itil::appl
var Appl=new Class(W5ModuleObject,{
   Constructor:function(pApp,frontname){
      this.SUPER('Constructor',pApp,frontname,"itil::appl");
      this.listView=['name'];
      this.detailView=['name','description','cdate','mdate','owner'];
   },
   setFilter:function(f){
      f['cistatusid']=4;
      return(this.SUPER('setFilter',f));
   }
});

var Toplist=new Class(W5ModuleObject,{
   Constructor:function(pApp,frontname){
      this.SUPER('Constructor',pApp,frontname,"itil::mgmtitemgroup");
      this.listView=['name','applications'];
      this.detailView=['name','applications','cdate','mdate'];
   },
   setFilter:function(f){
      f['cistatusid']=4;
      f['name']="top*";
      return(this.SUPER('setFilter',f));
   },
   softFilterRecord:function(rec){
      if (rec['applications'].length==0){
         return(undefined);
      }
      return(rec);
   },
   openDetailResult:function(rec){
      var queryStack={mgmtitemgroup:rec.name,cistatusid:4};
      console.log("set queryStack for App.ToplistAppl.queryStack",queryStack);
      App.ToplistAppl.queryStack=queryStack;
      App.ToplistAppl.doSearch(queryStack);
   }
});

var ToplistAppl=new Class(W5ModuleObject,{
   Constructor:function(pApp,frontname){
      this.SUPER('Constructor',pApp,frontname,"itil::appl");
      this.listView=['name'];
      this.detailView=['name','cdate','mdate'];
   },
   queryStackHandler:function(hash,queryStack){
       console.log("handling Stack hash='"+hash+"'",queryStack);
       if (hash=="search"){
          App.Toplist.doSearch({});
          // Back Button muﬂ noch definiert werden!
          return(true);
       }
       if (hash=="search-result"){
          App.ToplistAppl.doSearch(queryStack);
          // Back Button muﬂ noch definiert werden!
          return(true);
       }
       if (hash=="detail"){
          App.ToplistAppl.doSearch({id:queryStack.ID});
          return(true);
       }
       return(false);
   }
});


var Application=function(){
   this.Appl=new Appl(this,"appl");
   this.Toplist=new Toplist(this,"toplist");
   this.ToplistAppl=new ToplistAppl(this,"toplistappl");
}
