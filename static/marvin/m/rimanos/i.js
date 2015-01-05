var ApplDetailView=['name','ictono'];

function itemsummary2html(rec,o){


   var isum=rec.itemsummary.xmlroot;
   var d={};
   //data generation for dataquality
   var dataquality={
      ok:0,
      fail:0,
      total:0
   };
   for(c=0;c<isum.dataquality.record.length;c++){
      dataquality.total+=1;
      if (isum.dataquality.record[c].dataissuestate=="OK"){
         dataquality.ok++;
      }
      else{
         dataquality.fail++;
      }
   }
   d.dataquality=[
      {
         label:"Issue free = "+dataquality.ok,
         data:dataquality.ok,
         color:"green"
      },
      {
         label:"DataIssue fail = "+dataquality.fail,
         data:dataquality.fail,
         color:"red"
      }
   ];

   var hardware={
      ok:0,
      fail:0,
      total:0
   };
   for(c=0;c<isum.hardware.record.length;c++){
      console.log(isum.hardware.record[c]);
      hardware.total+=1;
      if (isum.hardware.record[c].assetrefreshstate=="OK"){
         hardware.ok++;
      }
      else{
         hardware.fail++;
      }
   }
   d.hardware=[
      {
         label:"Hardware OK = "+hardware.ok,
         data:hardware.ok,
         color:"green"
      },
      {
         label:"HardwareRefresh fail = "+hardware.fail,
         data:hardware.fail,
         color:"red"
      }
   ];


   var system={
      ok:0,
      fail:0,
      total:0
   };
   for(c=0;c<isum.system.record.length;c++){
      console.log(isum.system.record[c]);
      system.total+=1;
      if (isum.system.record[c].osanalysestate=="OK"){
         system.ok++;
      }
      else{
         system.fail++;
      }
   }
   d.system=[
      {
         label:"OperationSystem OK = "+system.ok,
         data:system.ok,
         color:"green"
      },
      {
         label:"OperationSystem fail = "+system.fail,
         data:system.fail,
         color:"red"
      }
   ];


   var software={
      ok:0,
      fail:0,
      total:0
   };
   for(c=0;c<isum.software.record[0].i.length;c++){
      software.total+=1;
      if (isum.software.record[0].i[c].osanalysestate=="OK"){
         software.ok++;
      }
      else{
         software.fail++;
      }
   }
   d.software=[
      {
         label:"Software OK = "+software.ok,
         data:software.ok,
         color:"green"
      },
      {
         label:"Software fail = "+software.fail,
         data:software.fail,
         color:"red"
      }
   ];


   o.html("");
   for (var chartname in d){
      var dataset=d[chartname];
      o.append("<div id='"+chartname+"_' "+
         "style='border-style:solid;border-color:gray;width:300px;height:130px;margin:2px;float:left' /></div>");
      $('#'+chartname+'_').append("<div id='"+chartname+"' style=\"margin-bottom:2px;height:80px\" />");
      var placeholder=$("#"+chartname);
      $.plot(placeholder,dataset,{
         series:{
            pie:{
               radius:0.8,
               show:true
            }
         }
      });
   }
}

function formatDetail(rec){
   console.log("formatDetail on ",this);
   var d=this.SUPER('formatDetail',rec);
   d+="<hr><div id='summaryresult'></div>";
   var o=this.DataObj();
   var useView=['itemsummary','name','id'];
   $.mobile.loading('show');
   o.findRecord(useView,function(l){
      if (l.length==0){
         $('#summaryresult').html("record not found");
      }
      else{
         itemsummary2html(l[0],$('#summaryresult'));

      } 
      $.mobile.loading('hide');
   });
   return(d);
}

// derevation for itil::appl
var Appl=new Class(W5ModuleObject,{
   Constructor:function(pApp,frontname){
      this.SUPER('Constructor',pApp,frontname,"AL_TCom::appl");
      this.listView=['name'];
      this.detailView=ApplDetailView;
   },
   setFilter:function(f){
      f['cistatusid']=4;
      return(this.SUPER('setFilter',f));
   },
   formatDetail:formatDetail
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
      this.SUPER('Constructor',pApp,frontname,"AL_TCom::appl");
      this.listView=['name'];
      this.detailView=ApplDetailView;
   },
   queryStackHandler:function(hash,queryStack,ui){
       console.log("handling Stack hash='"+hash+"'",queryStack);
       if (hash=="search"){
          App.Toplist.doSearch({});
          return(true);
       }
       if (hash=="search-result"){
          this.doSearch(queryStack);
          return(true);
       }
       if (hash=="detail"){
          this.doSearch({id:queryStack.ID});
          return(true);
       }
       return(false);
   },
   formatDetail:formatDetail
});


var Application=function(){
   this.Appl=new Appl(this,"appl");
   this.Toplist=new Toplist(this,"toplist");
   this.ToplistAppl=new ToplistAppl(this,"toplistappl");
}
