(function(window, document, undefined) {
   var applet='%SELFNAME%';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.loadItems=function(param){
     var dataobj=param[0];
     var dataobjid=param[1];
     var app=this.app;
     return(
        new Promise(function(ok,reject){
console.log("app=",app,"dataobj=",dataobj,"dataobjid=",dataobjid);
           app.Config().then(function(cfg){
              var w5obj=getModuleObject(cfg,dataobj);
                w5obj.SetFilter({ userid:dataobjid });
                w5obj.findRecord("userid,fullname,surname", function(data){
                   // detect all objects need to be preloaded
                   var cnt=data.length;
                   var preLoad=[W5Explore.loadDataObjClass("base::user"),
                                W5Explore.loadDataObjClass("base::grp")];
                   app.console.log("INFO","found "+data.length+
                                          " interface records");
                   console.log("fifi data=",data);
                   Promise.all(preLoad).then(function(preload){
                      var promlst=new Array();
                      var edges=new Array();
                      for(c=0;c<cnt;c++){
                         promlst.push(
                            app.addNode("base::user",data[c].userid,
                                                     data[c].surname));
                      //   for(s=0;s<data[c].systems.length;s++){
                      //      promlst.push(
                      //         app.addNode("itil::system",
                      //                     data[c].systems[s].systemid,
                      //                     data[c].systems[s].system)
                      //      );
                      //      edges.push({
                      //         fromid:app.toObjKey(dataobj,dataobjid),
                      //         toid:app.toObjKey('itil::system',
                      //                           data[c].systems[s].systemid)
                      //      });
                      //   }
                      } 
                      app.console.log("INFO","start resolving promise objects");
                      Promise.all(promlst).then(function(){
                         for(c=0;c<edges.length;c++){
                            app.addEdge(edges[c].fromid,edges[c].toid,{});
                         }
                         console.log("OK, all loaded");
                      }).catch(function(e){
                         console.log("not good - in ",e);
                      });
                   }).catch(function(e){
                      console.log("not good2 - in ",e);
                   });
                   ok(data[0]);
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
       );
   };




   ClassAppletLib[applet].class.prototype.searchItems=function(dialog,flt){
      var appletobj=this;
      this.app.Config().then(function(cfg){
         var w5obj=getModuleObject(cfg,'base::user');
         if (flt.indexOf("*")==-1 && flt.indexOf(" ")==-1){
            flt="*"+flt+"*";
         }
         w5obj.SetFilter({
            cistatusid:"4",
            fullname:flt
         });
         w5obj.findRecord("userid,fullname",function(data){
            var cnt=data.length;
            var res="";
            for(c=0;c<cnt;c++){
               res+="<div class='purebtn appstart' "+
                    "data-id='"+data[c].userid+"'"+
                    "data-dataobj='base::user'"+
                    ">"+
                    data[c].fullname+"</div>";
            }
            $(dialog).find("#SearchResult").height(   // fix result height
               $(dialog).find("#SearchResult").height()
            );
            $(dialog).find("#SearchResult").html(res);

            $(dialog).find(".appstart").click(function(e){
               console.log("click eon ",$(this).attr("data-id"));
               console.log("click eon ",$(this).attr("data-dataobj"));

               var id=$(this).attr("data-id");
               var dataobj=$(this).attr("data-dataobj");
               appletobj.run([dataobj,id]);
            });
         },function(e){
            $(dialog).find("#SearchResult").html("Fail");
         });
      }).catch(function(e){
         $(dialog).find("#SearchResult").html("Fail2");
      });
   }

   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      this.app.node.clear();
      this.app.edge.clear();
      if (arguments.length){
         var dataobj=arguments[0][0];
         var dataobjid=arguments[0][1];
         this.app.ShowNetworkMap({
            physics: {
               barnesHut:{
                  gravitationalConstant:-4100
               },
               enabled: true
            }
         });
         this.app.console.log("INFO","loading scenario ...");
         console.log(" run in "+dataobj+" and id="+dataobjid);
         this.loadItems(arguments[0]).then(function(d){
             appletobj.app.console.log("INFO","scenario is loaded");
             appletobj.app.setMPath({
                   label:ClassAppletLib['%SELFNAME%'].desc.label,
                   mtag:'%SELFNAME%'
                },
                {
                   label:d.fullname,
                   mtag:dataobj+"/"+d.userid
                }
             );
         }).catch(function(e){
             $(".spinner").hide();
         });
      }
      else{
         this.app.showDialog(function(){
            var dialog = document.createElement('div');
            $(dialog).css("height","100%");
            $(dialog).append("<table id=SearchTab width=97% height=90% "+
                              "border=0>"+  
                              "<tr height=1%><td >"+
           "<h1>"+ClassAppletLib['%SELFNAME%'].desc.label+"</h1>"+
                              "</td></tr>"+
                              "<tr height=1%><td width=10%>"+
                              "<form id=SearchFrm><div class='SearchLabel'>"+
                              "Suchen:</div></td><td>"+
                              "<div class='SearchLabel'>"+
                              "<input type=text name=SearchInp id=SearchInp>"+
                              "</div></form></td></tr>"+
                              "<tr><td colspan=2 valign=top>"+
                              "<div id=SearchContainer>"+
                              "<div id=SearchResult></div>"+
                              "</div>"+
                              "</td></tr>"+
                              "</table>");
            $(dialog).find("#SearchInp").focus();
            $(dialog).find("#SearchInp").on('keypress', function (e) {
               if(e.which === 13){
                  $(this).attr("disabled", "disabled");
                  appletobj.searchItems(dialog,$(this).val());
                  $(this).removeAttr("disabled");
                  $(dialog).find("#SearchInp").focus();
               }
            });
            return(dialog);
         },function(){
            appletobj.exit();
         });
      }
   };


})(this,document);
