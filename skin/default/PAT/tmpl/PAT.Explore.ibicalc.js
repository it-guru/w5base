var applet='%SELFNAME%';
define(["datadumper"],function (){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);



   ClassAppletLib[applet].class.prototype.loadTicketList=function(){
     var app=this.app;
     var appletobj=this;
     return(
        new Promise(function(ok,reject){
           app.Config().then(function(cfg){
                $("#analysedData").html("<center>PAT Search Tool</center>");
                $(".spinner").hide();
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
   ClassAppletLib[applet].class.prototype.loadEntries=function(){
     var app=this.app;
     var div=document.createElement('div');
     div.id = 'PRMTicketAssi';
     app.workspace.innerHTML="";
     app.workspace.appendChild(div);
     div.innerHTML="<div class=PATAssiHeader>"+
                    "<div style=\"text-align:right\">"+
                    "<img id=Reloader style=\"cursor:not-allowed\" "+
                    "src=\"../../../public/base/load/reload.gif\">"+
                    "</div>"+
                    "</div>"+
                   "<div id=analysedData>"+
                   "<div style=\"text-align:center\">"+
                   "<div class=analyseLoader>"+
                   'Analysing Entries...<br>'+
                   "</div>"+
                   "</div>"+
                   "</div>";
     $(".spinner").show();
     this.loadTicketList().then(function(d){
         appletobj.app.console.log("INFO","scenario is loaded");
         $(".spinner").hide();
     }).catch(function(e){
         $(".spinner").hide();
     });
   };



   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;
      this.app.LayoutSimple();
      $(".spinner").hide();

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
