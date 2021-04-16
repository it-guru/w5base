var applet='%SELFNAME%';
function hightLight(v,txt){
   var re = new RegExp("("+v+")",'ig');
   txt=txt.replace(re,"<b><span class=hightLight>$1</span></b>");
   return(txt);
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
                          "name,urlofcurrentrec,title,"+
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
                    var w5obj=getModuleObject(cfg,'PAT::subprocess');
                    w5obj.SetFilter({
                    });
                    w5obj.findRecord(
                          "name,urlofcurrentrec,title,"+
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

   ClassAppletLib[applet].class.prototype.showBusinessSeg=function(item){
      var appletobj=this;
      var app=this.app;

      var d="";

      d+="<br>"+
         "<hr>"+
         "Subprocesses:<br>"+
         "<hr>";

      return({
         title:"%T(PAT::businessseg,PAT::businessseg)%",
         subtitle:item.name+": "+item.title,
         d:d,
         fine:function(win){
         }
      });


   }
   ClassAppletLib[applet].class.prototype.showSubProcess=function(item){
      var appletobj=this;
      var app=this.app;

      var d="";
      var onlinetime=new TimeSpans(item.onlinetime,{defaultType:'o'});
      var usetime=new TimeSpans(item.usetime,{defaultType:'u'});
      var coretime=new TimeSpans(item.coretime,{defaultType:'c'});
      var optimes=new TimeSpans("",{
          typeColor:{
             'o':'#F180BA',
             'u':'#E20074',
             'c':'#A90057' 
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
          dayLabel:{
             '0':'%TRANSLATE(mon-fri,kernel::Field::TimeSpans)%',
             '1':'%TRANSLATE(sat,kernel::Field::TimeSpans)%',
             '2':'%TRANSLATE(sun/HOL,kernel::Field::TimeSpans)%'
          }
      });
      ibitimes=ibitimes.overlay(ibinonprodtime);
      ibitimes=ibitimes.overlay(ibicoretime);

      d+="<br>"+
         "<hr>"+
         "Operations-Times:<br>"+
         optimes.table()+"<br>"+
         "onlinetime:"+item.onlinetime+"<br>"+
         "usetime:"+item.usetime+"<br>"+
         "coretime:"+item.coretime+"<br>"+
         "<br>"+
         "<hr>"+
         "IBI-Times<br>"+
         ibitimes.table()+"<br>"+
         "ibithnonprodtimesat:"+item.ibinonprodtime+"<br>"+
         "ibicoretime:"+item.ibicoretime+"<br>"+
         "<hr>";

      return({
         title:"%T(PAT::subprocess,PAT::subprocess)%",
         subtitle:item.name+": "+item.title,
         d:d,
         fine:function(win){
         }
      });

   }
   ClassAppletLib[applet].class.prototype.showICTOName=function(item){
      return({
         title:"%T(PAT::ictname,PAT::ictname)%",
         subtitle:"showICTOName",
         d:"showICTOName",
         fine:function(win){
         }
      });
   }


   ClassAppletLib[applet].class.prototype.showItem=function(dataobj,item){
      var appletobj=this;
      var app=this.app;
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
      else if (dataobj=="PAT::ictoname"){
         showdata=this.showICTOName(item,ModalWin);
      }
      var d="";
      d+="<div class=\"DetailWindow\">";
      d+="<div class=\"DetailTitle\">";
      d+="<div style=\"height:2.2em;display:inline-block;"+
         "float:left;overflow:hidden;width:90%\">"+
         showdata.title+"<br>"+
         "<b>"+showdata.subtitle+"</b></div>";
      d+="<div style=\"height:2.2em;display:inline-block;"+
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
                       "data-dataobjid=\""+item.id+"\" "+
                       ">"+
                       hightLight(v,"<b>"+item.name+"</b>"+" - "+
                       item.title)+"</div>";
                  $.each(subitem,function(subindex,item){
                     blk+=item;
                  });
                  blk+="</div>";
                  $("#analysedData").append(blk);
               }
               
            };
            $(".businesssegLabel").css("cursor","pointer");
            $(".subprocessitem").css("cursor","pointer");
            $(".businesssegLabel").click(function(e){
               var id=$(this).attr("data-dataobjid");
               var dataobj=$(this).attr("data-dataobj");
               var item=appletobj.data.businessseg[id];
               appletobj.showItem(dataobj,item); 
            });  
            $(".subprocessitem").click(function(e){
               var id=$(this).attr("data-dataobjid");
               var dataobj=$(this).attr("data-dataobj");
               var item=appletobj.data.subprocess[id];
               appletobj.showItem(dataobj,item); 
            });  
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
                   "<img "+
                   "style=\"cursor:not-allowed;width:30%;height:30%;"+
                   "margin-top:20px\" "+
                   "src=\"../../../public/PAT/load/pat-logo.png\">"+
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
         $(workspace).find('#DetailFrame').height((h-140));
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
