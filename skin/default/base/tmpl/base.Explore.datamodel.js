(function(window, document, undefined) {
   var applet='%SELFNAME%';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


//   ClassAppletLib[applet].class.prototype.searchItems=function(dialog,flt){
//      var appletobj=this;
//      this.app.Config().then(function(cfg){
//         var w5obj=getModuleObject(cfg,'base::user');
//         if (flt.indexOf("*")==-1 && flt.indexOf(" ")==-1){
//            flt="*"+flt+"*";
//         }
//         w5obj.SetFilter({
//            cistatusid:"4",
//            fullname:flt
//         });
//         w5obj.findRecord("userid,fullname",function(data){
//            var cnt=data.length;
//            var res="";
//            for(c=0;c<cnt;c++){
//               res+="<div class='purebtn appstart' "+
//                    "data-id='"+data[c].userid+"'"+
//                    "data-dataobj='base::user'"+
//                    ">"+
//                    data[c].fullname+"</div>";
//            }
//            $(dialog).find("#SearchResult").height(   // fix result height
//               $(dialog).find("#SearchResult").height()
//            );
//            $(dialog).find("#SearchResult").html(res);
//
//            $(dialog).find(".appstart").click(function(e){
//               console.log("click eon ",$(this).attr("data-id"));
//               console.log("click eon ",$(this).attr("data-dataobj"));
//
//               var id=$(this).attr("data-id");
//               var dataobj=$(this).attr("data-dataobj");
//               appletobj.run([dataobj,id]);
//            });
//         },function(e){
//            $(dialog).find("#SearchResult").html("Fail");
//         });
//      }).catch(function(e){
//         $(dialog).find("#SearchResult").html("Fail2");
//      });
//   }

   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;
      this.app.node.clear();
      this.app.edge.clear();
      if (arguments.length){
         var datamodel=arguments[0][0];
         var depth=arguments[0][1];
         this.app.ShowNetworkMap({
            physics: {
               barnesHut:{
                  gravitationalConstant:-70000
               },
               enabled: true
            }
         });
         this.app.console.log("INFO","loading scenario ...");
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            },
            {
               label:"loading ...",
               mtag:datamodel+"/"+depth
            }
         );

         var dataobj="base::menu";
         console.log("load ",datamodel," with depth=",depth);
         var app=this.app;
         app.Config().then(function(cfg){
            var w5obj=getModuleObject(cfg,'base::menu');
            w5obj.SetFilter({
               datamodel:datamodel
            });
            w5obj.findRecord("datamodel,target",function(data){
               console.log("found:",data);
               var dataobj=new Object();
               for(c=0;c<data.length;c++){
                  dataobj[data[c].target]++
               }
               var fulltarget=Object.keys(dataobj).join(" ");
               var dataobj="base::reflexion_dataobj";
           
               app.genenericLoadNode(dataobj,"id","fullname",{id:fulltarget},
                                    function(d){
                  app.network.fit({
                     animation: true
                  });
                  app.setMPath({
                        label:ClassAppletLib['%SELFNAME%'].desc.label,
                        mtag:'%SELFNAME%'
                     },
                     { label:datamodel, mtag:datamodel+"/"+depth}
                  );
                  console.log("add master list ",d);
                  for(c=1;c<d.length;c++){
                     d[c].nodeMethods['m100extDataModeldepth'].exec.call(
                        d[c]
                     );
                  }
                  app.processOpStack(function(opResults){
                     console.log("scenario loaded",opResults);
                     $(".spinner").hide();
                     app.network.fit({
                        animation: true
                     });
                  });
              });
           
            });
         });



      }
      else{
         var app=this.app;
         app.Config().then(function(cfg){
            var w5obj=getModuleObject(cfg,'base::menu');
            w5obj.SetFilter({
               datamodel:"!\"\""
            });
            w5obj.findRecord("datamodel,target",function(data){
                var dm=new Object();
                for(c=0;c<data.length;c++){
                   dm[data[c].datamodel]++
                }
                var selbox="<select id=datamodel>";
                var dmname=Object.keys(dm);
                for(var c=0;c<dmname.length;c++){
                   var k=dmname[c];
                   selbox+="<option value=\""+k+"\">"+k+"</option>";
                }
                selbox+="</select>";
                console.log("fifi found",dm);
                app.showDialog(function(){
                   var dialog = document.createElement('div');
                   $(dialog).css("height","100%");
                   $(dialog).append("<form id=SearchFrm style=\"height:100%\">"+
                                    "<table id=SearchTab width=97% height=90% "+
                                    "border=0>"+  
                                    "<tr height=1%><td nowrap colspan=2>"+
                  "<h1>"+ClassAppletLib['%SELFNAME%'].desc.label+"</h1>"+
                          "</td></tr>"+
                          "<tr><td valign=top width=10%>"+
                          "<div class='SearchLabel'>"+
                          "Datenmodel:</div></td><td valign=top>"+
                          "<div class='SearchLabel'>"+selbox+
                          "</div></form></td></tr>"+
                          "<tr height=1%><td colspan=2 align=center>"+
                          "<input class=appstart type=button "+
                          "value=\"visualisieren\" "+
                          "style=\"width:80%\">"+
                          "</td></tr>"+
                          "</table></form>");
                  $(dialog).find(".appstart").click(function(e){
                     console.log(e);
                     var selbox=$(dialog).find("#SearchFrm #datamodel").first();
                     console.log("find selbox=",selbox);
                     var sel=selbox.val();
                     console.log("val=",sel);
                     if (sel!=""){
                        $(".spinner").show();
                        appletobj.run([sel,2]);
                     }
                  });

                   return(dialog);
                },function(){
                   appletobj.exit();
                });
            });
         });
      }
   };


})(this,document);
