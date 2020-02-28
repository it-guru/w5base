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
              var w5obj=getModuleObject(cfg,'tssiem::secent');
                w5obj.SetFilter({
                   islatest:"1",
                   isdup:"0",
                   pci_vuln:'yes',
                   severity:'4 5',
                   prmid:'[EMPTY]',
                });
                w5obj.findRecord("ictono,exptickettitle,msghashurl",
                                 function(data){
                   // detect all objects need to be preloaded
                   console.log(data);
                   $("#analysedData").html("");
                   var cnt=data.length;
                   var ttitle;
                   var curdiv;
                   var curtik;
                   var curtxt;
                   for(c=0;c<cnt;c++){
                      if (data[c].exptickettitle!=ttitle){
                         curtik=document.createElement('div');
                         curtxt=document.createElement('xmp');
                         curdiv=document.createElement('div');
                         $(curdiv).addClass("ticket");
                         var curheader=document.createElement('div');
                         $(curheader).html(data[c].exptickettitle);
                         $(curheader).addClass("ticketheader");
                         $(curheader).click(function(){
                            $(this).parent()
                                   .parent()
                                   .find(".ticketval").slideUp();
                            $(this).parent()
                                   .find(".ticketval").slideToggle();
                         });
                         $(curdiv).append(curheader);
                         $(curdiv).append(curtik);
                         $(curtik).addClass("ticketval");
                         $(curtik).html("<b>Short-Description:</b> "+
                                        data[c].exptickettitle+"<br>"+
                                        "<b>Description:</b>");
                         $(curtxt).append("The following Qualys "+
                                          "Scan-Entries are needed to "+
                                          "be fixed:\n");
                         $(curtik).append(curtxt);
                         $("#analysedData").append(curdiv);
                         ttitle=data[c].exptickettitle;
                      }
                      $(curtxt).append(data[c].msghashurl+"\n");
                   }
                   $("#Reloader").css("cursor","pointer");
                   $("#Reloader").click(function(){
                       appletobj.loadEntries();
                   });

                   //$("#analysedData").html("<xmp>"+Dumper(data)+"</xmp>");
                   window.dispatchEvent(new Event('resize'));
                   ok("OK");
                },function(exception){
                   app.console.log("got error from call");
                   reject(exception);
                });
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
     div.innerHTML="<div class=PRMTicketAssiHeader>"+
                    "<div style=\"text-align:right\">"+
                    "<img id=Reloader style=\"cursor:not-allowed\" "+
                    "src=\"../../../public/base/load/reload.gif\">"+
                    "</div>"+
                    "</div>"+
                   "<div id=analysedData>"+
                   "<div style=\"text-align:center\">"+
                   "<div class=analyseLoader>"+
                   'Analysing Entries...<br>'+
                   '<img src="../../base/load/ajaxloader.gif">'+
                   "</div>"+
                   "</div>"+
                   "</div>";
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

      app.loadCss("public/tssiem/load/tssiem.Explore.TicketAssi.css");

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
