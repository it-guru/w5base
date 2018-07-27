(function(window, document, undefined) {
   var applet='%SELFNAME%';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);


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
      var app=this.app;
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
         this.app.network.moveTo({scale:0.5,animation:false});
         this.app.console.log("INFO","loading scenario ...");
         console.log(" run in "+dataobj+" and id="+dataobjid);
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            },
            {
               label:"loading ...",
               mtag:dataobj+"/"+dataobjid
            }
         );


        app.genenericLoadNode(dataobj,"userid","fullname",{userid:dataobjid},
                              function(d){
            var MasterItem=d[1];
            app.node.update({id:MasterItem.id,level:30});
            MasterItem['MasterItem']=true;
            console.log("MasterItem loaded:",MasterItem);
            app.setMPath({
                  label:ClassAppletLib['%SELFNAME%'].desc.label,
                  mtag:'%SELFNAME%'
               },
               { label:MasterItem.label, mtag:dataobj+"/"+MasterItem.dataobjid}
            );
            console.log("add master item ",MasterItem);
            MasterItem.nodeMethods['m100addUserOrgParentTree'].exec.call(
               MasterItem
            );
            app.processOpStack(function(opResults){
               MasterItem.nodeMethods['m100addUserOrgParentTree'].postExec.call(
                  MasterItem,opResults
               );
               app.networkFitRequest=true;
               console.log("scenario loaded",opResults);
            });
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
