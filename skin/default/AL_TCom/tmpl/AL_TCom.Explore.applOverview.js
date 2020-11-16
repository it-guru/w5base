var applet='%SELFNAME%';

define(["datadumper","jquery.flot","jquery.flot.pie"],function (Dumper){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.searchFilter='';
   ClassAppletLib[applet].class.prototype.searchResult='';

   ClassAppletLib[applet].class.prototype.showSummary=function(o,id,isum){
      var d={};

      var baseTags=new Array('dataquality','system','software',
                             'hpsaswp','osroadmap','interview');
      for(tpos=0;tpos<baseTags.length;tpos++){
         var tag=baseTags[tpos];
         d[tag]=new Object();
         d[tag].cnt={
            ok:0,
            fail:0,
            total:0,
            commented:0,
            warn:0
         };
         if (tag=='dataquality'){
            d[tag].label="Datenqualit&auml;t";
            for(c=0;c<isum[tag].record.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[c].dataissuestate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[c].dataissuestate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[c].dataissuestate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (tag=='osroadmap'){
            d[tag].label="OS-Roadmap";
            for(c=0;c<isum.osroadmap.record.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[c].osroadmapstate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[c].osroadmapstate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[c].osroadmapstate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (tag=='system'){
            d[tag].label="Betriebssystemversion";
            for(c=0;c<isum[tag].record.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[c].osanalysestate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[c].osanalysestate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[c].osanalysestate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (tag=='software'){
            d[tag].label="Software-Installationen";
            for(c=0;c<isum[tag].record[0].i.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[0].i[c].softwareinstrelstate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[0].i[c].softwareinstrelstate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[0].i[c].
                        softwareinstrelstate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (tag=='hpsaswp'){
            d[tag].label="HPSA-Prozess";
            for(c=0;c<isum[tag].record[0].i.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[0].i[c].softwarerelstate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[0].i[c].softwarerelstate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[0].i[c].
                        softwarerelstate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (tag=='interview'){
            d[tag].label="Interview(HCO)";
            for(c=0;c<isum[tag].record.length;c++){
               d[tag].cnt.total+=1;
               if (isum[tag].record[c].questionstate=="OK"){
                  d[tag].cnt.ok++;
               }
               else if (isum[tag].record[c].questionstate=="WARN"){
                  d[tag].cnt.warn++;
               }
               else if (isum[tag].record[c].
                        questionstate.match(/but OK$/)){
                  d[tag].cnt.commented++;
               }
               else{
                  d[tag].cnt.fail++;
               }
            }
         }
         if (d[tag].cnt.total>0){
            d[tag].plot=[
               {
                  label:"OK:"+d[tag].cnt.ok,
                  data:d[tag].cnt.ok,
                  color:"green"
               },
               {
                  label:"Commented:"+d[tag].cnt.commented,
                  data:d[tag].cnt.commented,
                  color:"blue"
               },
               {
                  label:"Warn:"+d[tag].cnt.warn,
                  data:d[tag].cnt.warn,
                  color:"yellow"
               },
               {
                  label:"Fail:"+d[tag].cnt.fail,
                  data:d[tag].cnt.fail,
                  color:"red"
               }
            ];
         }
      }

      var col=0;
      var plotarea=document.createElement('div');
      $(plotarea).addClass("plotarea");
      for (var chartname in d){
         if (d[chartname].plot){
            var dataset=d[chartname].plot;
            col=col+1;
            var plotframe=document.createElement('div');
            $(plotframe).addClass("plotframe");

            $(plotframe).append("<p align=center>"+
                                              d[chartname].label+
                                              "</p>");
            var plotdiv=document.createElement('div');
            $(plotframe).append(plotdiv);
            $(plotdiv).addClass("plotdiv");
            $(plotdiv).width(300);
            $(plotdiv).height(100);
            $.plot(plotdiv,dataset,{
                    series:{
                       pie:{
                          radius:0.8,
                          show:true
                       }
                    }
            });
            $(plotarea).append(plotframe);
         }
      }
      for (var chartname in d){
         var plotframe=document.createElement('div');
         $(plotframe).addClass("plotframeDummy");
         $(plotarea).append(plotframe);
      }
      o.append("<hr>");
      o.append(plotarea);
      o.append("<hr>");
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
                          'Analysing itemsummary...<br>'+
                          '<img src="../../base/load/ajaxloader.gif">'+
                          "</div>"+
                          "</div>";
         },function(){
            $(".spinner").hide();
            if (appletobj.MasterItem){
               app.genenericLoadRecord("AL_TCom::appl",
                                       "name,id,icto,itemsummary",
                                       {id:dataobjid},
                                       function(rec){
                  var r=rec[0];
                  var out=$(this.workspace)
                            .find("[data-id=\""+r.id+"\"]")
                            .first();
                  out.html("");
                  if (r.icto){
                     out.append(r.icto+"<br>");
                  }
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


