var ApplDetailView=['name','ictono'];

function itemsummary2html(rec,o){

   var isum=rec.itemsummary.xmlroot;
   var d={};

   var baseTags=new Array('dataquality','hardware','system','software',
                          'hpsaswp','osroadmap','interview');
   for(tpos=0;tpos<baseTags.length;tpos++){
      var tag=baseTags[tpos];
      d[tag]=new Object();
      d[tag].cnt={
         ok:0,
         fail:0,
         total:0,
         commented:0,
         warn:0
      };
      if (tag=='dataquality'){
         d[tag].label="Datenqualit&auml;t";
         for(c=0;c<isum[tag].record.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[c].dataissuestate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[c].dataissuestate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[c].dataissuestate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='hardware'){
         d[tag].label="Hardware-Refresh";
         for(c=0;c<isum.hardware.record.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[c].assetrefreshstate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[c].assetrefreshstate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[c].assetrefreshstate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='osroadmap'){
         d[tag].label="OS-Roadmap";
         for(c=0;c<isum.osroadmap.record.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[c].osroadmapstate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[c].osroadmapstate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[c].osroadmapstate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='system'){
         d[tag].label="Betriebssystemversion";
         for(c=0;c<isum[tag].record.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[c].osanalysestate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[c].osanalysestate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[c].osanalysestate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='software'){
         d[tag].label="Software-Installationen";
         for(c=0;c<isum[tag].record[0].i.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[0].i[c].softwareinstrelstate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[0].i[c].softwareinstrelstate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[0].i[c].
                     softwareinstrelstate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='hpsaswp'){
         d[tag].label="HPSA-Prozess";
         for(c=0;c<isum[tag].record[0].i.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[0].i[c].softwarerelstate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[0].i[c].softwarerelstate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[0].i[c].
                     softwarerelstate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      if (tag=='interview'){
         d[tag].label="Interview(HCO)";
         for(c=0;c<isum[tag].record.length;c++){
            d[tag].cnt.total+=1;
            if (isum[tag].record[c].questionstate=="OK"){
               d[tag].cnt.ok++;
            }
            else if (isum[tag].record[c].questionstate=="WARN"){
               d[tag].cnt.warn++;
            }
            else if (isum[tag].record[c].
                     questionstate.match(/but OK$/)){
               d[tag].cnt.commented++;
            }
            else{
               d[tag].cnt.fail++;
            }
         }
      }
      d[tag].plot=[
         {
            label:"OK:"+d[tag].cnt.ok,
            data:d[tag].cnt.ok,
            color:"green"
         },
         {
            label:"Commented:"+d[tag].cnt.commented,
            data:d[tag].cnt.commented,
            color:"blue"
         },
         {
            label:"Warn:"+d[tag].cnt.warn,
            data:d[tag].cnt.warn,
            color:"yellow"
         },
         {
            label:"Fail:"+d[tag].cnt.fail,
            data:d[tag].cnt.fail,
            color:"red"
         }
      ];
   }

   var col=0;
   o.html("");
   for (var chartname in d){
      var dataset=d[chartname].plot;
      col=col+1;
      o.append("<div id='"+chartname+"_border' "+
         "style='border-style:solid;border-color:gray;"+
         "width:300px;height:150px;margin:2px;float:left' />");

      $('#'+chartname+'_border').append("<p align=center>"+
                                        d[chartname].label+
                                        "</p>");
      $('#'+chartname+'_border').append("<div id='"+chartname+"_plot' "+
         "style=\"margin-bottom:2px;height:80px;width:280px\" />");
      var placeholder=$("#"+chartname+"_plot");
      $.plot(placeholder,dataset,{
              series:{
                 pie:{
                    radius:0.8,
                    show:true
                 }
              }
      });
      if (col==2){
         o.append("<div style='clear:both' />");
         col=0;
      }
   }
}

function formatDetail(rec,jqo){
   this.SUPER('formatDetail',rec,jqo);
   var o=this.DataObj();
   jqo.append("<hr><div id=summaryresult />");
   call(function(){
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
   },1000);
   return;
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
