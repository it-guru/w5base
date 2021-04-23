var applet='%SELFNAME%';
function hightLight(v,txt){
   var re = new RegExp("("+v+")",'ig');
   txt=txt.replace(re,"<b><span class=hightLight>$1</span></b>");
   return(txt);
}

function extLink(h,url){
   var d="<div class=extlink>"+
         "<img height="+h+" "+
         "data-extlink=\""+url+"\""+
         "src=\"../../base/load/miniextlink.png\">"+
         "</div>";
   return(d);
}
define(["datadumper","TimeSpans"],function (datadumper,TimeSpans){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);



   ClassAppletLib[applet].class.prototype.loadDatabase=function(){
      var app=this.app;
      var appletobj=this;
      var searchbox=$("#search").first();
      return(
         new Promise(function(ok,reject){
            //$("#analysedData").html("<center>PAT Search Tool</center>");
            app.Config().then(function(cfg){
                 $(".spinner").show();
                 var frm=$("#analysedData").first();
                 appletobj.data=new Object();
                 $(frm).queue("load",[]);
                 $(frm).queue("load",function(next){
                 $(".spinner").show();
                    var w5obj=getModuleObject(cfg,'PAT::businessseg');
                    w5obj.SetFilter({
                    });
                    w5obj.findRecord(
                          "name,urlofcurrentrec,title,description,comments,"+
                          "subprocesses,id",
                          function(data){
                       appletobj.data['businessseg']=new Object();
                       $.each(data,function(index,item){
                          appletobj.data['businessseg'][item.id]=item;
                       }); 
                       next();
                    });
                 });
                 $(frm).queue("load",function(next){
                    $(".spinner").show();
                    var w5obj=getModuleObject(cfg,'PAT::ictname');
                    w5obj.SetFilter({
                    });
                    w5obj.findRecord(
                          "name,id,urlofcurrentrec,ictoid,"+
                          "comments",function(data){
                       appletobj.data['ictname']=new Object();
                       $.each(data,function(index,item){
                          item.subprocesses=new Object();
                          appletobj.data['ictname'][item.id]=item;
                       }); 
                       next();
                    });
                 });
                 $(frm).queue("load",function(next){
                    $(".spinner").show();
                    var w5obj=getModuleObject(cfg,'PAT::subprocess');
                    w5obj.SetFilter({
                    });
                    w5obj.findRecord(
                          "name,urlofcurrentrec,title,description,comments,"+
                          "businessseg,businesssegid,,"+
                          "onlinetime,"+
                          "usetime,"+
                          "coretime,"+
                          "ibicoretime,"+
                          "ibithcoretimemonfri,"+
                          "ibithcoretimesat,"+
                          "ibithcoretimesun,"+
                          "ibinonprodtime,"+
                          "ibithnonprodtimemonfri,"+
                          "ibithnonprodtimesat,"+
                          "ibithnonprodtimesun,"+
                          "ictnames,id",function(data){
                       appletobj.data['subprocess']=new Object();
                       $.each(data,function(index,item){
                          appletobj.data['subprocess'][item.id]=item;
                          if (item.ictnames.length){
                             for(var i=0;i<item.ictnames.length;i++){
                                var inid=item.ictnames[i].ictnameid;
                                appletobj.data['ictname'][inid
                                  ].subprocesses[item.id]=
                                   item;
                             }
                          }
                       }); 
                       next();
                    });
                 });
                 $(frm).queue("load",function(next){
                    console.log("fine=",appletobj.data);
                    $(".spinner").hide();
                    $(".databaseLoader").remove();
                    $("#dosearch").css("cursor","pointer");
                    $("#Reloader").css("cursor","pointer");
                    $("#dosearch").click(function(){
                       appletobj.doSearch(); 
                    });
                    if ($(searchbox).val().length>2){
                       appletobj.doSearch();
                    }
                    ok();
                 });
                 $(frm).dequeue("load");
     
                 //$(".spinner").hide();
                 //appletobj.data=data;
                 //$("#analysedData").html("<xmp>"+Dumper(data)+"</xmp>");
                 window.dispatchEvent(new Event('resize'));
                 ok("OK");
              }).catch(function(e){
                 console.log("get config failed",e);
                 app.console.log("can not get config");
                 reject(e); 
            });
         })
      )
   }

   ClassAppletLib[applet].class.prototype.addClickLinks=function(win){
      var appletobj=this;

      $(win).find("[data-dataobj]").addClass("clickableLink");
      $(win).find("[data-dataobj]").click(function(e){
         var id=$(this).attr("data-dataobjid");
         var dataobj=$(this).attr("data-dataobj");
         appletobj.showItem(dataobj,id); 
      });
      $(win).find("[data-extlink]").click(function(e){
         var url=$(this).attr("data-extlink");
         var w=window.open(url,"_blank",
                   'height=500,width=700,toolbar=no,status=no,'+
                   'resizable=yes,scrollbars=yes');
         e.stopPropagation();
         return(true);
      });
   }

   ClassAppletLib[applet].class.prototype.showBusinessSeg=function(item){
      var appletobj=this;
      var app=this.app;

      var d="";

      appletobj.app.setMPath({
            label:ClassAppletLib['%SELFNAME%'].desc.label,
            mtag:'%SELFNAME%'
         },
         {
            label:item.name,
            mtag:'PAT::businessseg'+"/"+item.id
         }
      );

      d+=item.comments;
      if (item.subprocesses.length){
         d+="<br><br>"+
            "%TRANSLATE(fieldgroup.subprocesses,PAT::businessseg)%:<br>"+
            "<hr>";
         for(var spc=0;spc<item.subprocesses.length;spc++){
            var spid=item.subprocesses[spc].id;
            d+="<div style=\"border:0;padding:10px;margin-bottom:15px\">";
            d+="<div ";
            d+="data-dataobj=\"PAT::subprocess\" ";
            d+="data-dataobjid=\""+spid+"\">";
            d+=item.subprocesses[spc].fullname;
            d+=extLink(9,appletobj.data.subprocess[spid].urlofcurrentrec); 
            d+="</div>";
            d+="<div>";
            var sitem=appletobj.data.subprocess[spid];
            var onlinetime=new TimeSpans(sitem.onlinetime,{defaultType:'o'});
            var usetime=new TimeSpans(sitem.usetime,{defaultType:'u'});
            var coretime=new TimeSpans(sitem.coretime,{defaultType:'c'});
            var optimes=new TimeSpans("",{
                typeColor:{
                   'o':'#F180BA',
                   'u':'#E20074',
                   'c':'#A90057' 
                },
                typeLabel:{
                   'o':'%T(online,PAT::Explore::ibicalc)%',
                   'u':'%T(use,PAT::Explore::ibicalc)%',
                   'c':'%T(core,PAT::Explore::ibicalc)%'
                },
                dayLabel:{
                   '0':'%TRANSLATE(mon-fri,kernel::Field::TimeSpans)%',
                   '1':'%TRANSLATE(sat,kernel::Field::TimeSpans)%',
                   '2':'%TRANSLATE(sun/HOL,kernel::Field::TimeSpans)%'
                }
            });
            optimes=optimes.overlay(onlinetime);
            optimes=optimes.overlay(usetime);
            optimes=optimes.overlay(coretime);
            d+=optimes.table();

            d+="</div>";
            d+="</div>";
         }
      }
      

      return({
         title:"%T(PAT::businessseg,PAT::businessseg)%",
         subtitle:item.name+": "+item.title,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
         }
      });


   }
   ClassAppletLib[applet].class.prototype.showSubProcess=function(item){
      var appletobj=this;
      var app=this.app;

      appletobj.app.setMPath({
            label:ClassAppletLib['%SELFNAME%'].desc.label,
            mtag:'%SELFNAME%'
         },
         {
            label:item.name,
            mtag:'PAT::subprocess'+"/"+item.id
         }
      );
      var d="<table class=\"recordsheet\">";
      d+="<tr><td>%T(Description,PAT::subprocess)%:</td>";
      d+="<td>"+item.description+"</td></tr>";
      d+="<tr class=block-end>";
      d+="<td>%T(Business-Segment,PAT::subprocess)%:</td>";
      d+="<td><div data-dataobj=\"PAT::businessseg\" ";
      d+="data-dataobjid=\""+item.businesssegid+"\">";
      d+=item.businessseg;
      d+=extLink(9,
         appletobj.data.businessseg[item.businesssegid].urlofcurrentrec); 
      d+="</div>";
      d+="</td></tr>";
      if (item.ictnames.length){
         d+="<tr>";
         d+="<td valign=top>ICTOs:</td>";
         d+="<td><table width=60%>";
         d+="<tr><th align=left>ICT-Name</th>"+
            "<th width=1%>Relevanz</th></tr>";
         for(var i=0;i<item.ictnames.length;i++){
            var ictid=item.ictnames[i].ictnameid;
            d+="<tr>";
            d+="<td nowrap>";
            d+="<div data-dataobj=\"PAT::ictname\" ";
            d+="data-dataobjid=\""+ictid+"\"> ";
            d+=item.ictnames[i].ictfullname;
            d+=extLink(10,appletobj.data.ictname[ictid].urlofcurrentrec); 
            d+="</div>";
            d+="</td>";
            d+="<td>";
            d+=item.ictnames[i].relevance;
            d+="</td>";
            d+="</tr>";
         }
         d+="</table>";
         d+="</td></tr>";
      }
      var onlinetime=new TimeSpans(item.onlinetime,{defaultType:'o'});
      var usetime=new TimeSpans(item.usetime,{defaultType:'u'});
      var coretime=new TimeSpans(item.coretime,{defaultType:'c'});
      var optimes=new TimeSpans("",{
          typeColor:{
             'o':'#F180BA',
             'u':'#E20074',
             'c':'#A90057' 
          },
          typeLabel:{
             'o':'%T(online,PAT::Explore::ibicalc)%',
             'u':'%T(use,PAT::Explore::ibicalc)%',
             'c':'%T(core,PAT::Explore::ibicalc)%'
          },
          dayLabel:{
             '0':'%TRANSLATE(mon-fri,kernel::Field::TimeSpans)%',
             '1':'%TRANSLATE(sat,kernel::Field::TimeSpans)%',
             '2':'%TRANSLATE(sun/HOL,kernel::Field::TimeSpans)%'
          }
      });
      optimes=optimes.overlay(onlinetime);
      optimes=optimes.overlay(usetime);
      optimes=optimes.overlay(coretime);

      var onlinetime=new TimeSpans(item.onlinetime,{defaultType:'o'});
      var usetime=new TimeSpans(item.usetime,{defaultType:'u'});
      var coretime=new TimeSpans(item.coretime,{defaultType:'c'});
      var optimes=new TimeSpans("",{
          typeColor:{
             'o':'#F180BA',
             'u':'#E20074',
             'c':'#A90057' 
          },
          typeLabel:{
             'o':'%T(online,PAT::Explore::ibicalc)%',
             'u':'%T(use,PAT::Explore::ibicalc)%',
             'c':'%T(core,PAT::Explore::ibicalc)%'
          },
          dayLabel:{
             '0':'%TRANSLATE(mon-fri,kernel::Field::TimeSpans)%',
             '1':'%TRANSLATE(sat,kernel::Field::TimeSpans)%',
             '2':'%TRANSLATE(sun/HOL,kernel::Field::TimeSpans)%'
          }
      });
      optimes=optimes.overlay(onlinetime);
      optimes=optimes.overlay(usetime);
      optimes=optimes.overlay(coretime);

      var ibinonprodtime=new TimeSpans(item.ibinonprodtime,{
          defaultType:'B'
      });
      var ibicoretime=new TimeSpans(item.ibicoretime,{
          defaultType:'C'
      });
      var ibitimes=new TimeSpans("",{
          typeColor:{
             'B':'#427BAB',
             'C':'#315C80' 
          },
          typeLabel:{
             'B':'%T(nonprod,PAT::Explore::ibicalc)%',
             'C':'%T(core,PAT::Explore::ibicalc)%'
          },
          dayLabel:{
             '0':'%TRANSLATE(mon-fri,kernel::Field::TimeSpans)%',
             '1':'%TRANSLATE(sat,kernel::Field::TimeSpans)%',
             '2':'%TRANSLATE(sun/HOL,kernel::Field::TimeSpans)%'
          }
      });
      ibitimes=ibitimes.overlay(ibinonprodtime);
      ibitimes=ibitimes.overlay(ibicoretime);

      d+="</table>";

      d+=""+
         "Operations-Times:<br>"+
         optimes.table()+"<br>"+
         //"onlinetime:"+item.onlinetime+"<br>"+
         //"usetime:"+item.usetime+"<br>"+
         //"coretime:"+item.coretime+"<br>"+
         "<br>"+
         "IBI-Times<br>"+
         ibitimes.table()+"<br>"+
         //"ibithnonprodtimesat:"+item.ibinonprodtime+"<br>"+
         //"ibicoretime:"+item.ibicoretime+"<br>"+
         "<hr>";


      return({
         title:"%T(PAT::subprocess,PAT::subprocess)%",
         subtitle:item.name+": "+item.title,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
         }
      });

   }
   ClassAppletLib[applet].class.prototype.showICTOName=function(item){
      var appletobj=this;

      console.log("showICTOName:",item);

      var label=item.ictoid+": "+item.name;

      var d="";

      if (d.comments){
         d+=item.comments;
         d+="<br>";
      }
      for(var spid in item.subprocesses){
         d+="<div>";
         d+="<div ";
         d+="data-dataobj=\"PAT::subprocess\" ";
         d+="data-dataobjid=\""+spid+"\"> ";
         d+=item.subprocesses[spid].name+": "+
            item.subprocesses[spid].title;
         d+="</div>";
         d+="</div>";
      }


      return({
         title:"%T(PAT::ictname,PAT::ictname)%",
         subtitle:label,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
         }
      });
   }


   ClassAppletLib[applet].class.prototype.showItem=function(dataobj,item){
      var appletobj=this;
      var app=this.app;

      if (typeof(item)!=='object'){
         console.log("item is not an Object; dataobj=",dataobj);
         if (dataobj==='PAT::businessseg'){
            console.log("item load as businessseg");
            item=appletobj.data.businessseg[item];
         }
         else if (dataobj=='PAT::subprocess'){
            console.log("item load as subprocess");
            item=appletobj.data.subprocess[item];
         }
         else if (dataobj=='PAT::ictname'){
            console.log("item load as ictname");
            item=appletobj.data.ictname[item];
         }
      }

      $("#analysedData").hide();
      $("#Detail").show();
      var ModalWin=$("#Detail").first();
      var showdata=new Object();
      console.log("ShowItem=",item,"as:",dataobj);
      if (dataobj=="PAT::businessseg"){
         showdata=this.showBusinessSeg(item,ModalWin);
      }
      else if (dataobj=="PAT::subprocess"){
         showdata=this.showSubProcess(item,ModalWin);
      }
      else if (dataobj=="PAT::ictname"){
         showdata=this.showICTOName(item,ModalWin);
      }
      var d="";
      d+="<div class=\"DetailWindow\">";
      d+="<div class=\"DetailTitle\">";
      d+="<div style=\"height:4.2em;display:inline-block;"+
         "float:left;overflow:hidden;white-space: nowrap;width:90%\" "+
         "<p>"+showdata.title+"</p>"+
         "<div "+
         "data-dataobj=\""+dataobj+"\" "+
         "data-dataobjid=\""+item.id+"\" "+
         "><h2>"+
         showdata.subtitle+
         extLink(16,item.urlofcurrentrec)+
         "</h2></div>"+
         "</div>";
      d+="<div style=\"height:4.2em;display:inline-block;"+
         "float:right;text-align:right;width:10%;cursor:pointer\" "+
         "id=\"close\"><b>X</b></div>";
      d+="<div style=\"float:none;\"></div>";
      d+="</div>";
      d+="<div id=DetailFrame class=\"DetailFrame\">"+
         showdata.d+"</div>";
      d+="</div>";
      $("#Detail").html(d);
      if (showdata.fine){
         showdata.fine($("#Detail"));
      }
      $("#close").click(function(e){
         console.log("click on close");
         $("#analysedData").show();
         $("#Detail").hide();
         console.log("fifi setMPath on close click");
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            }
         );
      });
      window.dispatchEvent(new Event('resize'));
   }
   ClassAppletLib[applet].class.prototype.doSearch=function(){
      var appletobj=this;
      var app=this.app;
      var searchbox=$("#search").first();
      var v=searchbox.val();
      var mode=$("#dosearch").css("cursor");
      if (mode=="pointer"){
         if (searchbox.val().length>2){
            $("#analysedData").html("");
            $("#Detail").hide();
            $("#analysedData").show();
            var processSearch="";
            for (var businesssegid in appletobj.data.businessseg){
               var item=appletobj.data.businessseg[businesssegid];
               var showSeg=0;
               var subitem=new Array();
               if (item.name.toLowerCase().indexOf(v.toLowerCase())!=-1 ||
                   item.title.toLowerCase().indexOf(v.toLowerCase())!=-1){
                  showSeg=1;
               }
               $.each(item.subprocesses,function(subindex,item){
                  var n=item.fullname
                  var showSub=0;
                  var showNames=0;
                  var names=new Array();
                  if (n.toLowerCase().indexOf(v.toLowerCase())!=-1 ){
                     showSeg=1;
                     showSub=1;
                  }
                  $.each(appletobj.data.subprocess[item.id].ictnames,
                         function(ictindex,ictrec){
                     names.push(ictrec.ictfullname);
                     if (ictrec.ictfullname.toLowerCase().indexOf(
                         v.toLowerCase())!=-1){
                        showSeg=1;
                        showSub=1;
                        showNames=1;
                     }
                  })
                  if (showSub){
                     var d="<div class=subprocessitem "+
                           "data-dataobj=\"PAT::subprocess\" "+
                           "data-dataobjid=\""+item.id+"\" "+
                           ">"+
                           "<div class=subprocessLabel "+
                           ">"+hightLight(v,n)+"</div>"
                     if (showNames){
                        d+="<div class=subprocessICTnames>"+
                           hightLight(v,names.join(", "))+"</div>";
                     }
                     d+="</div>";
                     subitem.push(d);
                  }
               });
               if (showSeg){
                  var blk="<div class=businesssegItem>";
                  blk+="<div class=businesssegLabel "+
                       "data-dataobj=\"PAT::businessseg\" "+
                       "data-dataobjid=\""+item.id+"\" "+">"+
                       hightLight(v,"<b>"+item.name+"</b>"+" - "+item.title)+
                       extLink(12,item.urlofcurrentrec)+ 
                       "</div>";
                  $.each(subitem,function(subindex,item){
                     blk+=item;
                  });
                  blk+="</div>";
                  processSearch+=blk;
               }
            };
            var ictoSearch="";
            for (var ictnameid in appletobj.data.ictname){
               var item=appletobj.data.ictname[ictnameid];
               if (item.name.toLowerCase().indexOf(v.toLowerCase())!=-1 ||
                   item.ictoid.toLowerCase().indexOf(v.toLowerCase())!=-1){
                  var blk="<div class=ictnameItem>";
                  blk+="<div class=ictnameLabel "+
                       "data-dataobj=\"PAT::ictname\" "+
                       "data-dataobjid=\""+item.id+"\" "+
                       ">"+
                       hightLight(v,"<b>"+item.ictoid+"</b>"+": "+
                       item.name)+"</div>";
                  blk+="</div>";
                  ictoSearch+=blk;
               }
            }
            if (v.toLowerCase().indexOf("icto-")!=-1){
               $("#analysedData").append(ictoSearch);
               $("#analysedData").append(processSearch);
            }
            else{
               $("#analysedData").append(processSearch);
               $("#analysedData").append(ictoSearch);
            }

            appletobj.addClickLinks($("#analysedData").first());
          //  $(".businesssegLabel").css("cursor","pointer");
          //  $(".subprocessitem").css("cursor","pointer");
          //  $(".businesssegLabel").click(function(e){
          //     var id=$(this).attr("data-dataobjid");
          //     var dataobj=$(this).attr("data-dataobj");
          //     var item=appletobj.data.businessseg[id];
          //     appletobj.showItem(dataobj,item); 
          //  });  
          //  $(".subprocessitem").click(function(e){
          //     var id=$(this).attr("data-dataobjid");
          //     var dataobj=$(this).attr("data-dataobj");
          //     var item=appletobj.data.subprocess[id];
          //     appletobj.showItem(dataobj,item); 
          //  });  
            console.log("app",appletobj.data);
         }
         else{
            $("#analysedData").html("");
         }
      }
   }
   ClassAppletLib[applet].class.prototype.loadEntries=function(){
     var appletobj=this;
     var app=this.app;
     var div=document.createElement('div');
     div.id = 'PRMTicketAssi';
     var searchbox=$("#search").first();
     app.workspace.innerHTML="";
     app.workspace.appendChild(div);
     div.innerHTML="<div class=PATAssiHeader "+
                    "style=\"width:100%;display:inline-block\">"+
                    "<div style=\"width:95%;float:left;text-align:center;"+
                    "border:0px solid blue\">"+
                    "<div style=\"display:inline-block;margin-bottom:10px;"+
                    "vertical-align:middle;\">"+
                    "<label for='search'>%T(PAT-Search,PAT::Explore::ibicalc)%"+
                    ":</label> &nbsp;"+
                    "<input type=text id=search >"+
                    "</div>"+
                    "<img id=dosearch "+
                    "style=\"cursor:not-allowed;vertical-align:bottom\" "+
                    "src=\"../../../public/PAT/load/pat-search.png\">"+
                    "</div>"+
                    "<div style=\"float:right;text-align:right;\">"+
                    "<img id=Reloader style=\"cursor:not-allowed\" "+
                    "src=\"../../../public/base/load/reload.gif\">"+
                    "</div>"+
                    "</div>"+
                   "<div id=Detail style=\"display:none;postion:relative\">"+
                   "</div>"+
                   "<div id=analysedData "+
                   "style=\"display: block;postion:relative\">"+
                   "<div style=\"text-align:center\">"+
                   "<a href=\"https://share.zspi.telekom.de/"+
                   "sites/LPRM_TelIT_RCA/PAT/app/pat.aspx\" target=_blank> "+
                   "<img "+
                   "style=\"cursor:pointer;width:30%;height:30%;"+
                   "margin-top:20px\" "+
                   "src=\"../../../public/PAT/load/pat-logo.png\"></a>"+
                   "<center>"+
                   "<div id=infotext style=\"width:80%;text-align:left\">"+
                   "</div>"+
                   "</center>"+
                   "<div class=databaseLoader "+
                   "style=\"position:absolute;text-align:center;left:50%;"+
                   "margin-left:auto;margin-right:auto;left:0;right:0;"+
                   "bottom:20px\">"+
                   'Loading database...<br>'+
                   "</div>"+
                   "</div>"+
                   "</div>";
     $("#search").focus();
     $("#search").on("input",function(){
        if ($(this).val().length>2){
           clearTimeout(appletobj.curImputTimer);
           appletobj.curImputTimer=setTimeout(function(){
              appletobj.doSearch();
           },500);
        }
     });
     setTimeout(function(){
        $.ajax({
           type:'GET',
           url:"../../../public/PAT/load/tmpl/PAT.infotext?RAW=1",
           headers:{
             'Accept': "text/plain; charset=utf-8",         
             'Content-Type': "text/html; charset=utf-8"   
           },
           dataType:'html',
           success:function(d){
              $("#infotext").html(d);
           },
           error:function(){
              console.log("something went wrong");
           }
        });
     },1000);

     $("#search").on('keypress',function(e) {
       if (e.which == 13) {
          appletobj.doSearch();
       }
     });
     $(".spinner").show();
     this.loadDatabase().then(function(d){
         appletobj.app.console.log("INFO","scenario is loaded");
        // $(".spinner").hide();
     }).catch(function(e){
         $(".spinner").hide();
     });
   };



   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;
      this.app.LayoutSimple();
      //$(".spinner").hide();

      app.loadCss("public/PAT/load/PAT.Explore.Finder.css");

      function resizeModalHandler(e){
         var workspace=$("#workspace");
         var h=$(workspace).height();
         $(workspace).find('#analysedData').height((h-80));
         $(workspace).find('#Detail').height((h-80));
         $(workspace).find('#DetailFrame').height((h-180));
         if (e){
            e.stopPropagation();
         }
      }
      $(window).on('resize',resizeModalHandler);
      console.log("run: arguments:",arguments);
      if (arguments.length){
         var dataobj=arguments[0][0];
         var dataobjid=arguments[0][1];
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            },
            { label:"loading ...", mtag:dataobj+"/"+dataobjid }
         );
         var frm=$("#workspace");

         appletobj.loadEntries();
      }
      else{
         console.log("fifi setMPath without arguments");
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            }
         );
         if (!appletobj.data){
            appletobj.loadEntries();
         }
      }
   }
});
