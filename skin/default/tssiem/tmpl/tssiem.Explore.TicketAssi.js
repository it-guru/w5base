var applet='%SELFNAME%';
define(["datadumper"],function (){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


   ClassAppletLib[applet].class.prototype.tOpen=function(btn,e){
      var app=this.app;
      var appletobj=this;

      console.log("fifi:"+$(btn).data('exptickettitle'));
      console.log("curdata",app.curDataset);
      $(".spinner").show();
      app.showDialog(function(){
         var dialog = document.createElement('div');
         $(dialog).css("height","100%");
         $(dialog).append("<form id=SearchFrm style=\"height:100%\">"+
                          "<table id=SearchTab width=97% height=90% "+
                          "border=0>"+
                          "<tr height=1%><td nowrap colspan=2>"+
        "<h1>PRM Ticket - geht noch nicht!</h1>"+
                "</td></tr>"+

                "<tr height=1%><td valign=top width=10%>"+
                "<div class='FieldLabel'>"+
                "PRM-TicketID:</div></td>"+
                "<td valign=top>"+
                "<div class='FieldLabel'>"+
                "<input type=text id=prmid></div>"+
                "</td></tr>"+

                "<tr height=1%><td valign=top width=10%>"+
                "<div class='FieldLabel'>"+
                "Application:</div></td>"+
                "<td valign=top>"+
                "<div class='FieldLabel'>"+
                "<input type=text id=appl></div>"+
                "</td></tr>"+

                "<tr height=1%><td valign=top width=10%>"+
                "<div class='FieldLabel'>"+
                "Assignmentgroup:</div></td>"+
                "<td valign=top>"+
                "<div class='FieldLabel'>"+
                "<input type=text id=assi></div>"+
                "</td></tr>"+

                "<tr height=1%><td valign=top width=10%>"+
                "<div class='FieldLabel'>"+
                "SM9 PRM Prio:</div></td>"+
                "<td valign=top>"+
                "<div class='FieldLabel'>"+
                "<input type=text id=sm9prio></div>"+
                "</td></tr>"+

                "<tr><td valign=top width=10%>"+
                "</td>"+
                "<td valign=top>"+
                "<div class='FieldLabel'>"+
                "<textarea id=prmtext rows=5 style=\"width:80%\"></textarea>"+
                "</div>"+
                "</td></tr>"+

                "<tr height=1%><td colspan=2 align=center>"+
                "<input class=ticketcreate type=button "+
                "value=\"save\" "+
                "style=\"width:80%\">"+
                "</td></tr>"+
                "</table></form>");
        $(dialog).find(".ticketcreate").click(function(e){
           console.log(e);
        });
        return(dialog);
      },function(){
         console.log("Close of dialog");
      });
   };



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
                   ismsgtrackingactive:'1',
                   prmid:'[EMPTY]',
                });
                w5obj.findRecord("ictono,exptickettitle,msghashurl,perspective",
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
                         var button=document.createElement("button");
                         $(button).html("PRM-Ticket");
                         $(button).css("float","right");
                         $(button).data({
                            exptickettitle:data[c].exptickettitle
                         });
                         $(button).addClass("tOpen");
                         $(curtik).html("<b>Short-Description:</b> "+
                                        data[c].exptickettitle+"<br>"+
                                        "<b>Perspective:</b>"+
                                        data[c].perspective+"<br>"+
                                        "<b>Description:</b>");
                         $(curtik).append(button);
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
                   $(".tOpen").click(function(e){
                      return(appletobj.tOpen(this,e));
                   });
                   app.curDataset=data;
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
