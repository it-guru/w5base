var applet='%SELFNAME%';
define(["datadumper"],function (){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


   ClassAppletLib[applet].class.prototype.StorePRM=function(frm,rec,next){
      var app=this.app;
      var appletobj=this;

   };
   ClassAppletLib[applet].class.prototype.StoreOrLinkTicket=function(btn,e,frm,okCleanup){
      var app=this.app;
      var appletobj=this;

      var prmid=$(frm).find("#prmid").first().val();
      $(frm).queue("prm",[]);

      var title=$(frm).find("#ttitle").first().val();

      var AffectedCI=$(frm).find("#desiredsm9applci").first().val();

      var CBI=$(frm).find("#desiredsm9prmcbi").first().val();

      var AssignmentGroup=$(frm).find("#desiredsm9applag").first().val();
      var Description=$(frm).find("#prmtext").first().val();




      if (prmid==""){  // create a new prm
         $(frm).queue("prm",function(next){
            console.log("PRM Create");
            $("#oplog").append("Try creating of ProblemTicket:<br>"); 

            var prmreq={
               'Customer':"DEUTSCHE TELEKOM",
               'AffectedCI':AffectedCI,
               'CBI':CBI,
               'Category1':'SECURITY',
               'Category2':'DATA SECURITY',
               'AssignmentGroup':AssignmentGroup,
               'EventRisk':'NORMAL',
               'Description':Description,
               'ManagerGroup':'TIT.TSI.HU.SCANTEAM',
               'Title':title,
               'TriggeredBy':'SECURITY INFO',

            };
            console.log("prmreq=",prmreq);
            prmreq.AssignmentGroup="TIT.TSI.DE.W5BASE";
            prmreq.AffectedCI="W5BASE/DARWIN (APPL052025)";
            $.ajax({
               type:'POST',
               url:"../../tssm/prm/openProblem",
               data:JSON.stringify(prmreq),
               dataType:'json',
               //contentType:"application/json; charset=utf-8",
               contentType:"application/json",
               success:function(d){
                  console.log("result d=",d);
                  if (d.exitcode!=0){
                     for(var c=0;c<d.exitmsg.length;c++){
                        $("#oplog").append("<font color=red>ERROR: "+
                                           d.exitmsg[c]+
                                           "</font><br>");
                        $("#oplog").scrollTop($("#oplog").prop("scrollHeight"));
                     }
                     setTimeout(function(){
                        next();
                     },2000);
                  }
                  else{
                     $("#oplog").append("ProblemTicket '"+d.id+
                                        "' succesfuly created<br>"); 
                     $(frm).find("#prmid").first().val(d.id);
                     next();
                  }
               },
               error:function(){
                  $("#oplog").append("<font color=red>Fail</font><br>");
                  $("#oplog").scrollTop($("#oplog").prop("scrollHeight"));
                  setTimeout(function(){
                     next();
                  },2000);
               }
            });
         });
      }
      $(frm).queue("prm",function(baseNext){
         for(var c=0;c<app.data.length;c++){
            if (app.data[c].exptickettitle==title){
               console.log("add "+c+" to queue");
               (function(){
                   var rec=app.data[c];
                   console.log("rec=",rec);
                   $(frm).queue("prm",function(next){
                       var prmid=$(frm).find("#prmid").first().val();
                       if (prmid!=""){
                          var log=$('#oplog');
                          log.append(" Saving "+rec.srcid+" ... "); 
                          $.ajax({
                             type:'POST',
                             url:"../../tssiem/secent/Modify",
                             data:JSON.stringify({
                                OP:'save',
                                srcid:rec.srcid,
                                Formated_prmid:prmid
                             }),
                             dataType:'json',
                             contentType:"application/json; charset=utf-8",
                             success:function(d){
                                console.log("result d=",d);
                                if (d.LastMsg){
                                   log.append("<font color=red>"+
                                             d.LastMsg.join(" ")+"</font><br>");
                                }
                                else{
                                  log.append("<font color=green>OK</font><br>");
                                }
                                log.scrollTop(log.prop("scrollHeight"));
                                setTimeout(function(){
                                   next();
                                },1000);
                             },
                             error:function(){
                                log.append("<font color=red>Fail</font><br>");
                                log.scrollTop(log.prop("scrollHeight"));
                                next();
                             }
                          });
                       }
                       else{
                          next();
                       }
                   });
               })();
            }
         }
         $(frm).queue("prm",function(next){
            console.log("all done - world is ok");
            setTimeout(function(){
               $("#oplog").remove();
               app.closeDialog();
               okCleanup();
            },4000);
            next();
         });
         baseNext();
      });

       

      console.log("frm=",frm);
      var d="<div style=\"position:absolute;background-color:white;height:40px;overflow:hidden;overflow-y:auto;top:50px;left:50%;margin-left:-40%;width:80%;height:60%;border-style:solid;border-color:black;border-width:2px\" id=oplog>Start processing ...<br><br></div>";
      $(frm).append(d);
      $(frm).dequeue("prm");

   };
   ClassAppletLib[applet].class.prototype.getDialogForm=function(){
      var d="<table class=ModalForm width=100% border=0>"+

            "<tr height=1%><td valign=top width=10%>"+
            "<div class='FieldLabel'>"+
            "PRM-TicketID:</div></td>"+
            "<td valign=top>"+
            "<div class='FieldLabel'>"+
            "<input type=text id=prmid></div>"+
            "</td></tr>"+

            "<tr height=1%><td valign=top width=10%>"+
            "<div class='FieldLabel'>"+
            "Title:</div></td>"+
            "<td valign=top>"+
            "<div class='FieldLabel'>"+
            "<input type=text style=\"width:100%\" readonly "+
            "id=ttitle></div>"+
            "</td></tr>"+

            "<tr height=1%><td valign=top width=10%>"+
            "<div class='FieldLabel'>"+
            "Application:</div></td>"+
            "<td valign=top>"+
            "<div class='FieldLabel'>"+
            "<input type=text style=\"width:70%\" readonly "+
            "id=desiredsm9applci></div>"+
            "</td></tr>"+

            "<tr height=1%><td valign=top width=10%>"+
            "<div class='FieldLabel'>"+
            "Assignmentgroup:</div></td>"+
            "<td valign=top>"+
            "<div class='FieldLabel'>"+
            "<input type=text  style=\"width:100%\" readonly "+
            "id=desiredsm9applag></div>"+
            "</td></tr>"+

            "<tr height=1%><td valign=top width=10%>"+
            "<div class='FieldLabel'>"+
            "SM9 PRM CBI:</div></td>"+
            "<td valign=top>"+
            "<div class='FieldLabel'>"+
            "<input type=text id=desiredsm9prmcbi readonly ></div>"+
            "</td></tr>"+

            "<tr>"+
            "<td valign=top colspan=2>"+
            "<div class='FieldLabel' align=center>"+
            "<textarea id=prmtext readonly rows=10 style=\"width:100%\">"+
            "</textarea>"+
            "</div>"+
            "</td></tr>"+

            "</table>";
      return(d);
   };
   ClassAppletLib[applet].class.prototype.tOpen=function(btn,e,text,okCleanup){
      var app=this.app;
      var appletobj=this;
      var rec=app.data[$(btn).attr('data-id')];

      $(".spinner").show();


      app.Config().then(function(cfg){
          var w5obj=getModuleObject(cfg,'tssiem::secent');
                w5obj.SetFilter({
                   srcid:rec.srcid
                });
                w5obj.findRecord("ALL",function(data){
                   var frec=data[0];
                   app.showDialog(function(){
                      var dialog = document.createElement('div');
                      //$(dialog).css("position","relative");
                      //$(dialog).css("height","auto");
                      var title=$("<div id=title>PRM Ticket</div>")
                      var content=$("<div id=content></div>")
                      var control=document.createElement('div');
                      $(control).prop("id","control"); 
                      $(control).css("text-align","center"); 
                      $(dialog).append(title);
                      $(dialog).append(content);
                  
                      var button=document.createElement("button");
                      $(button).text("save");
                      $(button).click(function(e){
                         var frm=$(this).parent().parent().parent();
                         return(appletobj.StoreOrLinkTicket(this,e,frm,okCleanup));
                      });
                      $(control).append(button);
                      $(dialog).append(control);
                      $(content).append(appletobj.getDialogForm());
                      $(content).find("#prmtext").first().val(text); 

                      $(content).find("#ttitle")
                         .first().val(frec.exptickettitle); 
                     
                      $(content).find("#desiredsm9applag")
                         .first().val(frec.desiredsm9applag); 
                     
                      $(content).find("#desiredsm9applci")
                         .first().val(frec.desiredsm9applci); 

                      $(content).find("#desiredsm9prmcbi")
                         .first().val(frec.desiredsm9prmcbi); 

                      $(dialog).find(".ticketcreate").click(function(e){
                         console.log(e);
                      });
                      return(dialog);
                   },function(){
                      console.log("Close of dialog");
                   });
                });
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
                w5obj.findRecord("ictono,exptickettitle,msghashurl,"+
                                 "srcid,perspective",
                                 function(data){
                   // detect all objects need to be preloaded
                   console.log(data);
                   $("#analysedData").html("");
                   $(".spinner").hide();
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
                         $(button).attr('data-id',c);
                         $(button).addClass("tOpen");
                         $(curtik).html("<b>Short-Description:</b> "+
                                        data[c].exptickettitle+"<br>"+
                                        "<b>Perspective:</b>"+
                                        data[c].perspective+"<br>"+
                                        "<b>Description:</b>");
                         $(curtik).append(button);
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
                      var p=$(this).parent();
                      var pp=$(this).parent().parent();
                      var okCleanup=function(){
                         pp.hide('slow', function(){ pp.remove(); });
                      };
                      var xmp=$(p).find("xmp").first();
                      var xmptext="";
                      if (xmp){
                         xmptext=xmp.text();
                      }
                      return(appletobj.tOpen(this,e,xmptext,okCleanup));
                   });
                   app.data=data;
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
