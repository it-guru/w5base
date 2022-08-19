var applet='%SELFNAME%';
define(["base/Explore/jsLib/base/kernel.Explore.network"],function (){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.searchFilter='';
   ClassAppletLib[applet].class.prototype.searchResult='';

   ClassAppletLib[applet].class.prototype.setSearchResult=function(dialog,res){
      var appletobj=this;
      $(dialog).find("#SearchResult").html(res);
      $(dialog).find(".appstart").click(function(e){
         console.log("click eon ",$(this).attr("data-id"));
         console.log("click eon ",$(this).attr("data-dataobj"));

         var id=$(this).attr("data-id");
         var dataobj=$(this).attr("data-dataobj");
         appletobj.run([dataobj,id]);
      });
      appletobj.searchResult=$(dialog).find("#SearchResult").html();
   };

   ClassAppletLib[applet].class.prototype.searchItems=function(dialog,flt){
      var appletobj=this;
      this.app.Config().then(function(cfg){
         var w5obj=getModuleObject(cfg,'itil::businessservice');
         appletobj.searchFilter=flt;
         if (flt.indexOf("*")==-1 && flt.indexOf(" ")==-1){
            flt="*"+flt+"*";
         }
         w5obj.SetFilter({
            cistatusid:"4",
            fullname:flt
         });
         w5obj.findRecord("id,fullname",function(data){
            var cnt=data.length;
            var res="";
            for(c=0;c<cnt;c++){
               res+="<div class='purebtn appstart' "+
                    "data-id='"+data[c].id+"'"+
                    "data-dataobj='itil::businessservice'"+
                    ">"+
                    data[c].fullname+"</div>";
            }
            appletobj.setSearchResult(dialog,res);
         },function(e){
            $(dialog).find("#SearchResult").html("Fail");
         });
      }).catch(function(e){
         $(dialog).find("#SearchResult").html("Fail2");
      });
   };

   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;

      app.InitObjectStore();

      if (arguments.length){
         var dataobj=arguments[0][0];
         var dataobjid=arguments[0][1];
         this.app.ShowNetworkMap({
            physics: {
               barnesHut:{
                  avoidOverlap: 0.99,
                  gravitationalConstant:-000
               },
               //enabled: true   // || "once"
               enabled: false   // || "once"
            },
            layout: {
               hierarchical: {
                 nodeSpacing: 200,
                 direction: 'UD',
                 //sortMethod: 'hubsize',
                 sortMethod: 'directed',
                 shakeTowards: 'roots',
                 levelSeparation:150,
                 treeSpacing: 800,
                 edgeMinimization:true
               }
            }
         });
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

        app.genenericLoadNode(dataobj,"id","fullname",{id:dataobjid},
                              function(d){
            var MasterItem=d[1];
            MasterItem['MasterItem']=true;
            console.log("MasterItem loaded:",MasterItem);
            app.setMPath({
                  label:ClassAppletLib['%SELFNAME%'].desc.label,
                  mtag:'%SELFNAME%'
               },
               { label:MasterItem.label, mtag:dataobj+"/"+MasterItem.dataobjid}
            );

            console.log("add master item ",MasterItem);
            MasterItem.nodeMethods['m500addTangCIs'].exec.call(
               MasterItem
            );

            app.processOpStack(function(opResults){
               console.log("scenario loaded",opResults);
               app.network.fit({
                  animation: true
               });
               $(".spinner").hide();
               //app.networkFitRequest=true;
            });
        });
      }
      else{
         this.app.showDialog(function(){
            var dialog = document.createElement('div');
            $(dialog).css("height","100%");
            $(dialog).append("<table id=SearchTab width=97% height=90% "+
                              "border=0>"+  
                              "<tr height=1%><td colspan=2>"+
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
            $(dialog).find("#SearchInp").val(appletobj.searchFilter);
            $(dialog).find("#SearchInp").focus();
            appletobj.setSearchResult(dialog,appletobj.searchResult);
            $(dialog).find("#SearchInp").on('keypress', function (e) {
               if(e.which === 13){
                  $(this).attr("disabled", "disabled");
                  appletobj.searchItems(dialog,$(this).val());
                  $(this).removeAttr("disabled");
                  $(dialog).find("#SearchInp").focus();
               }
            });
            function resizeModalHandler(e){
               var h=$(this).parent().height();
               var w=$(this).parent().width();
               var hSearchFrm=$(this).find('#SearchFrm').first().height();
               $(this).find('#SearchTab').width(w*0.95);
               $(this).find('#SearchContainer').height((0.9*h)-hSearchFrm-10);
               $(this).find('#SearchResult').height((0.9*h)-hSearchFrm-10);
               //console.log("got reszie in dialog "+
               //            "h="+h+" w="+w+" SearchFrm="+hSearchFrm);
               e.stopPropagation();
            }
            $(dialog).on('resize',resizeModalHandler);
            $(".spinner").hide();
            return(dialog);
         },function(){
            appletobj.exit();
         });
      }
   };
   return(ClassAppletLib[applet].class);
});
