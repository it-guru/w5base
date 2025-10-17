var applet='%SELFNAME%';

define(["datadumper","jquery.dataTables"],function (Dumper){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.searchFilter='';
   ClassAppletLib[applet].class.prototype.searchResult='';

   ClassAppletLib[applet].class.prototype.showSummary=function(app,o,id,sys){
      var d={};
      var systems=new Array();
      $.each(sys,function(i,v){
         systems.push(v.systemid);
      });

      app.genenericLoadRecord("AL_TCom::system",
                                       "name,id,cpucount,systemid,"+
                                       "hwcpucount,hwcorecount,"+
                                       "actsystemsonassetcount,"+
                                       "acrelassingmentgroup",
                                       {id:systems.join(" ")},
                                       function(rec){
            var tab=document.createElement("table");
            tab.id="DataTable";
            var tabhead=document.createElement("thead");
           
            var h=document.createElement("tr");
            $.each(["Systemname","SystemID",
                    "logical CPU",
                    "phys. CPU",
                    "phys. Core",
                    "analyse result",
                    "Assignment"],function(i,v){
               var cell = document.createElement("th");
               $(cell).append(v);
               h.appendChild(cell);
            });
            tab.appendChild(tabhead);
            tabhead.appendChild(h);
           
            var tabbody=document.createElement("tbody");
            for(c=0;c<rec.length;c++){
               var h=document.createElement("tr");
               var r="<font color=green>plausible</font>";
               if (rec[c].hwcpucount=="" ||
                   rec[c].hwcorecount=="" ||
                   rec[c].cpucount==""){
                 r="<font color=red>BAD(0)</font>";
               }
               else if (rec[c].actsystemsonassetcount=="1" &&
                        (parseInt(rec[c].cpucount)!=
                         parseInt(rec[c].hwcorecount)) &&
                        (parseInt(rec[c].cpucount)!=
                         parseInt(rec[c].hwcorecount)*2)){

                 r="<font color=red>BAD(1)</font>";
               }
               else if ((parseInt(rec[c].hwcpucount)>
                         parseInt(rec[c].hwcorecount))){
                 r="<font color=red>BAD(2)</font>";
               }
               $.each([rec[c].name,
                       rec[c].systemid,
                       rec[c].cpucount,
                       rec[c].hwcpucount,
                       rec[c].hwcorecount,r,
                       rec[c].acrelassingmentgroup
                       ],function(i,v){
                  var cell = document.createElement("th");
                  $(cell).append(v);
                  h.appendChild(cell);
               });
               tabbody.appendChild(h);
            }
            tab.appendChild(tabbody);
           
            $(o).append("<hr>"); $(o).append(tab); $(o).append("<hr>");
            $(tab).DataTable({
                fixedHeader: true,
                info:true,
                paging:true,
                lengthChange:false,
                select:true
            });
            function resizeDataTable(){
                h=$(window).height();
                mp=$("#mpath").height();
                h1=$("#applOverviewHeader").height();
                h=h-(60)-mp-h1;
                var n=parseInt(h/31)-3;
                if (n<3){
                   n=3;
                }
                if (n>50){
                   n=50;
                }
                $('#DataTable').DataTable().page.len(n).draw();
            }
            $(window).resize(function () {
               resizeDataTable();
            });
            resizeDataTable();
         },function(){
            app.processOpStack(function(opResults){
               $(".spinner").hide();
            });
         });

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
         app.genenericLoadRecord(dataobj,
                                 "name,tsm,opm,id",
                                 {id:dataobjid},
                                 function(rec){
            console.log("ok rec=",rec);
            appletobj.MasterItem=rec[0]; 
            app.setMPath({
                  label:ClassAppletLib['%SELFNAME%'].desc.label,
                  mtag:'%SELFNAME%'
               },
               { 
                  label:appletobj.MasterItem.name, 
                  mtag:dataobj+"/"+appletobj.MasterItem.id
               }
            );
            var div=document.createElement('div');
            div.id = 'applOverview';
            this.workspace.appendChild(div);
            app.loadCss("public/AL_TCom/load/AL_TCom.Explore.applOverview.css");
            div.innerHTML="<div class=applOverviewHeader>"+
                           appletobj.MasterItem.name+
                           "</div>"+
                          "<div id=analysedData data-id='"+
                          appletobj.MasterItem.id+"'>"+
                          "<div class=analyseLoader>"+
                          'Analysing CPU counts ...<br>'+
                          '<img src="../../base/load/ajaxloader.gif">'+
                          "</div>"+
                          "</div>";
         },function(){
            $(".spinner").hide();
            if (appletobj.MasterItem){
               app.genenericLoadRecord("AL_TCom::appl",
                                       "name,id,icto,systems",
                                       {id:dataobjid},
                                       function(rec){
                  var r=rec[0];
                  var out=$(this.workspace)
                            .find("[data-id=\""+r.id+"\"]")
                            .first();
                  out.html("");
                  out.append("CPU Counting check<br>");
                  appletobj.showSummary(app,out,r.id,r.systems);
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
                              "SearchApp:</div></td><td>"+
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


