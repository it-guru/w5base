var applet='%SELFNAME%';
function hightLight(v,txt){
   var re = new RegExp("("+v+")",'ig');
   txt=txt.replace(re,"<b><span class=hightLight>$1</span></b>");
   return(txt);
}
define(["datadumper"],function (){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);



   ClassAppletLib[applet].class.prototype.loadDatabase=function(){
     var app=this.app;
     var appletobj=this;
     return(
        new Promise(function(ok,reject){
           //$("#analysedData").html("<center>PAT Search Tool</center>");
           app.Config().then(function(cfg){
                $(".spinner").show();
                var frm=$("#analysedData").first();
                app.data=new Object();
                $(frm).queue("load",[]);
                $(frm).queue("load",function(next){
                $(".spinner").show();
                   var w5obj=getModuleObject(cfg,'PAT::businessseg');
                   w5obj.SetFilter({
                   });
                   w5obj.findRecord("name,urlofcurrentrec,title,"+
                                    "subprocesses",function(data){
                      app.data['businessseg']=data;
                      next();
                   });
                });
                $(frm).queue("load",function(next){
                   $(".spinner").show();
                   var w5obj=getModuleObject(cfg,'PAT::subprocess');
                   w5obj.SetFilter({
                   });
                   w5obj.findRecord("name,urlofcurrentrec,title,"+
                                    "ictnames",function(data){
                      app.data['subprocess']=data;
                      next();
                   });

                });
                $(frm).queue("load",function(next){
                   console.log("fine=",app.data);
                   $(".spinner").hide();
                   $(".databaseLoader").remove();
                   $("#dosearch").css("cursor","pointer");
                   $("#Reloader").css("cursor","pointer");
                   $("#dosearch").click(function(){
                      appletobj.doSearch(); 
                   });
                   ok();
                });
                $(frm).dequeue("load");

                //$(".spinner").hide();
                //app.data=data;
                //$("#analysedData").html("<xmp>"+Dumper(data)+"</xmp>");
                window.dispatchEvent(new Event('resize'));
                ok("OK");
             }).catch(function(e){
                console.log("get config failed",e);
                app.console.log("can not get config");
                reject(e); 
             });
          })
       )
   }
   ClassAppletLib[applet].class.prototype.doSearch=function(){
     var appletobj=this;
     var app=this.app;
      var searchbox=$("#search").first();
      var v=searchbox.val();
      var mode=$("#dosearch").css("cursor");
      if (mode=="pointer"){
         if (searchbox.val().length>2){
            $("#analysedData").html("");
            $.each(app.data.businessseg,function(index,item){
               var showSeg=0;
               var subitem=new Array();
               if (item.name.toLowerCase().indexOf(v.toLowerCase())!=-1 ||
                   item.title.toLowerCase().indexOf(v.toLowerCase())!=-1){
                  showSeg=1;
               }
               $.each(item.subprocesses,function(subindex,item){
                  var n=item.fullname
                  if (n.toLowerCase().indexOf(v.toLowerCase())!=-1 ){
                     showSeg=1;
                     subitem.push("<div class=subprocessLabel "+
                                  "data-dataobj=\"PAT::subprocess\" "+
                                  ">"+
                                  hightLight(v,n)+"</div>");
                  }
               });
               if (showSeg){
                  var blk="<div class=businesssegItem>";
                  blk+="<div class=businesssegLabel "+
                       "data-dataobj=\"PAT::businessseg\" "+
                       ">"+
                       hightLight(v,"<b>"+item.name+"</b>"+" - "+
                       item.title)+"</div>";
                  $.each(subitem,function(subindex,item){
                     blk+=item;
                  });
                  blk+="</div>";
                  $("#analysedData").append(blk);
               }
               
            });
            console.log("app",app.data);
         }
         else{
            $("#analysedData").html("ERROR: zu kurz");
         }
      }
   }
   ClassAppletLib[applet].class.prototype.loadEntries=function(){
     var appletobj=this;
     var app=this.app;
     var div=document.createElement('div');
     div.id = 'PRMTicketAssi';
     app.workspace.innerHTML="";
     app.workspace.appendChild(div);
     div.innerHTML="<div class=PATAssiHeader "+
                    "style=\"width:100%;display:inline-block\">"+
                    "<div style=\"width:95%;float:left;text-align:center;"+
                    "border:0px solid blue\">"+
                    "<div style=\"display:inline-block;margin-bottom:10px;"+
                    "vertical-align:middle;\">"+
                    "<label for='search'>%T(PAT-Search,PAT::Explore::ibicalc)%"+
                    ":</label> &nbsp;"+
                    "<input type=text id=search >"+
                    "</div>"+
                    "<img id=dosearch "+
                    "style=\"cursor:not-allowed;vertical-align:bottom\" "+
                    "src=\"../../../public/PAT/load/pat-search.png\">"+
                    "</div>"+
                    "<div style=\"float:right;text-align:right;\">"+
                    "<img id=Reloader style=\"cursor:not-allowed\" "+
                    "src=\"../../../public/base/load/reload.gif\">"+
                    "</div>"+
                    "</div>"+
                   "<div id=analysedData "+
                   "style=\"display: block;postion:relative\">"+
                   "<div style=\"text-align:center\">"+
                   "<img "+
                   "style=\"cursor:not-allowed;width:30%;height:30%;"+
                   "margin-top:20px\" "+
                   "src=\"../../../public/PAT/load/pat-logo.png\">"+
                   "<div class=databaseLoader "+
                   "style=\"position:absolute;text-align:center;left:50%;"+
                   "margin-left:auto;margin-right:auto;left:0;right:0;"+
                   "bottom:20px\">"+
                   'Loading database...<br>'+
                   "</div>"+
                   "</div>"+
                   "</div>";
     $("#search").focus();
     $("#search").on("input",function(){
        if ($(this).val().length>2){
           clearTimeout(appletobj.curImputTimer);
           appletobj.curImputTimer=setTimeout(function(){
              appletobj.doSearch();
           },500); 
        }
     });
     $("#search").on('keypress',function(e) {
       if (e.which == 13) {
          appletobj.doSearch();
       }
     });
     $(".spinner").show();
     this.loadDatabase().then(function(d){
         appletobj.app.console.log("INFO","scenario is loaded");
        // $(".spinner").hide();
     }).catch(function(e){
         $(".spinner").hide();
     });
   };



   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;
      this.app.LayoutSimple();
      //$(".spinner").hide();

      app.loadCss("public/PAT/load/PAT.Explore.Finder.css");

      function resizeModalHandler(e){
         var workspace=$("#workspace");
         var h=$(workspace).height();
         $(workspace).find('#analysedData').height((h-80));
         if (e){
            e.stopPropagation();
         }
      }
      $(window).on('resize',resizeModalHandler);

      appletobj.app.setMPath({
            label:ClassAppletLib['%SELFNAME%'].desc.label,
            mtag:'%SELFNAME%'
         }
      );
      appletobj.loadEntries();
   }
});
