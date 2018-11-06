var applet='%SELFNAME%';

define(["datadumper","jquery.flot","jquery.flot.pie"],function (Dumper){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.searchFilter='';
   ClassAppletLib[applet].class.prototype.searchResult='';

   ClassAppletLib[applet].class.prototype.showSummary=function(out,id,isum){
      var d={};
      //data generation for dataquality
      var dataquality={
         ok:0,
         fail:0,
         total:0
      };
      for(c=0;c<isum.dataquality.record.length;c++){
         dataquality.total+=1;
         if (isum.dataquality.record[c].dataissuestate=="OK"){
            dataquality.ok++;
         }
         else{
            dataquality.fail++;
         }
      }
      d.dataquality=[
         {
            label:"Issue free = "+dataquality.ok,
            data:dataquality.ok,
            color:"green"
         },
         {
            label:"DataIssue fail = "+dataquality.fail,
            data:dataquality.fail,
            color:"red"
         }
      ];

      var hardware={
         ok:0,
         fail:0,
         total:0
      };
      for(c=0;c<isum.hardware.record.length;c++){
         console.log(isum.hardware.record[c]);
         hardware.total+=1;
         if (isum.hardware.record[c].assetrefreshstate=="OK"){
            hardware.ok++;
         }
         else{
            hardware.fail++;
         }
      }
      d.hardware=[
         {
            label:"Hardware OK = "+hardware.ok,
            data:hardware.ok,
            color:"green"
         },
         {
            label:"HardwareRefresh fail = "+hardware.fail,
            data:hardware.fail,
            color:"red"
         }
      ];


      var system={
         ok:0,
         fail:0,
         total:0
      };
      for(c=0;c<isum.system.record.length;c++){
         console.log(isum.system.record[c]);
         system.total+=1;
         if (isum.system.record[c].osanalysestate=="OK"){
            system.ok++;
         }
         else{
            system.fail++;
         }
      }
      d.system=[
         {
            label:"OperationSystem OK = "+system.ok,
            data:system.ok,
            color:"green"
         },
         {
            label:"OperationSystem fail = "+system.fail,
            data:system.fail,
            color:"red"
         }
      ];


      var software={
         ok:0,
         fail:0,
         total:0
      };
      for(c=0;c<isum.software.record[0].i.length;c++){
         software.total+=1;
         if (isum.software.record[0].i[c].osanalysestate=="OK"){
            software.ok++;
         }
         else{
            software.fail++;
         }
      }
      d.software=[
         {
            label:"Software OK = "+software.ok,
            data:software.ok,
            color:"green"
         },
         {
            label:"Software fail = "+software.fail,
            data:software.fail,
            color:"red"
         }
      ];



      //visualisation
      $(out).html("");
      for (var chartname in d){
         $(out).append("<div id='"+chartname+"_' "+
                           "style='border-style:solid;border-color:gray;width:300px;height:130px;margin:2px;float:left;' />");
         $("#"+chartname+"_").append("<div align=center><p>"+chartname+"</p></div>");
         $("#"+chartname+"_").append("<div id='"+chartname+"' style=\"margin-bottom:2px;height:80px\" />");
         var placeholder=$("#"+chartname);
         $.plot(placeholder,d[chartname],{
            series:{
               pie:{
                  radius:0.8,
                  show:true
               }
            }
         });
      }
   };

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
   }

   ClassAppletLib[applet].class.prototype.searchItems=function(dialog,flt){
      var appletobj=this;
      this.app.Config().then(function(cfg){
         var w5obj=getModuleObject(cfg,'itil::appl');
         appletobj.searchFilter=flt;
         if (flt.indexOf("*")==-1 && flt.indexOf(" ")==-1){
            flt="*"+flt+"*";
         }
         w5obj.SetFilter({
            cistatusid:"4",
            name:flt
         });
         w5obj.findRecord("id,name",function(data){
            var cnt=data.length;
            var res="";
            for(c=0;c<cnt;c++){
               res+="<div class='purebtn appstart' "+
                    "data-id='"+data[c].id+"'"+
                    "data-dataobj='itil::appl'"+
                    ">"+
                    data[c].name+"</div>";
            }
            appletobj.setSearchResult(dialog,res);
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

      if (arguments.length){
         var dataobj=arguments[0][0];
         var dataobjid=arguments[0][1];
         this.app.LayoutSimple();
         this.app.console.log("INFO","loading scenario ...");

         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            },
            { label:"loading ...", mtag:dataobj+"/"+dataobjid }
         );
         this.MasterItem=undefined;
         this.app.workspace.innerHTML="";
         app.genenericLoadRecord(dataobj,"name,tsm,opm,id",{id:dataobjid},function(rec){
            console.log("ok rec=",rec);
            appletobj.MasterItem=rec[0]; 
            app.setMPath({
                  label:ClassAppletLib['%SELFNAME%'].desc.label,
                  mtag:'%SELFNAME%'
               },
               { label:appletobj.MasterItem.name, mtag:dataobj+"/"+appletobj.MasterItem.id}
            );
            var div=document.createElement('div');
            div.id = 'applOverview';
            this.workspace.appendChild(div);
            app.loadCss("public/AL_TCom/load/AL_TCom.Explore.applOverview.css");
            div.innerHTML="<div class=applOverviewHeader>Application: "+
                           appletobj.MasterItem.name+
                           "</div>"+
                          "<div id=analysedData data-id='"+appletobj.MasterItem.id+"'>"+
                          "<div class=analyseLoader>"+
                          'Analysing itemsummary...<br><img src="../../base/load/ajaxloader.gif">'+
                          "</div>"+
                          "</div>";
         },function(){
            $(".spinner").hide();
            if (appletobj.MasterItem){
               app.genenericLoadRecord("AL_TCom::appl","name,id,itemsummary",{id:dataobjid},function(rec){
                  var r=rec[0];
                  var out=$(this.workspace).find("[data-id=\""+r.id+"\"]").first();
                  $(out).css("height","100");
                  $(out).html(
                     "<div style='height:200px;overflow:auto'><xmp>"+Dumper(r)+"</xmp></div>"
                  );
                  appletobj.showSummary(out,r.id,r.itemsummary.xmlroot);
               },function(){
                  app.processOpStack(function(opResults){
                     $(".spinner").hide();
                  });
               });
            }
            else{
               app.processOpStack(function(opResults){
                  $(".spinner").hide();
               });
            }
         });
      }
      else{
         this.app.showDialog(function(){
            var dialog = document.createElement('div');
            $(dialog).css("height","100%");
            $(dialog).append("<div id=SearchTab><table width=100% "+
                              "cellspacing=0 cellpadding=0 border=0>"+  
                              "<tr height=1%><td>"+
            "<h1>"+ClassAppletLib['%SELFNAME%'].desc.label+"</h1>"+
                              "</td></tr>"+
                              "<tr height=1%><td>"+
                              "<form id=SearchFrm>"+
                              "<table width=100% "+
                              "cellspacing=0 cellpadding=0 border=0>"+
                              "<tr><td width=1%>"+
                              "<div class='SearchLabel'>"+
                              "Suchen:</div></td><td>"+
                              "<div class='SearchLabel'>"+
                              "<input type=text name=SearchInp id=SearchInp>"+
                              "</div></form></td></tr></table>"+
                              "</td></tr>"+
                              "<tr><td valign=top>"+
                              "<div id=SearchContainer>"+
                              "<div id=SearchResult></div>"+
                              "</div>"+
                              "</td></tr>"+
                              "</table></form></div>");

            $(dialog).find("#SearchInp").val(appletobj.searchFilter);
            $(dialog).find("#SearchInp").focus();
            appletobj.setSearchResult(dialog,appletobj.searchResult);
            $(dialog).find("#SearchInp").on('keypress', function (e) {
               if(e.which === 13){
                  $(this).attr("disabled", "disabled");
                  appletobj.searchItems(dialog,$(this).val());
                  $(this).removeAttr("disabled");
                  $(dialog).find("#SearchInp").focus();
                  return(false);
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
   }
   return(ClassAppletLib[applet].class);
});


