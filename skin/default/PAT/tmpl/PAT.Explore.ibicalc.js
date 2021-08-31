var applet='%SELFNAME%';
function hightLight(v,txt){
   v=v.replace("(","\\(");
   v=v.replace(")","\\)");
   var re = new RegExp("("+v+")",'ig');
   txt=txt.replace(re,"<b><span class=hightLight>$1</span></b>");
   return(txt);
}

function extLink(h,url,id){
   if (id!==undefined){
      url=url.replace("::","/");
      url="../../"+url+"/ById/"+id;
   }
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
                 $(frm).queue("load",[]);
                 if (!appletobj.data){
                    appletobj.data=new Object();
                    $(frm).queue("load2",function(next){
                       $(".spinner").show();
                       var w5obj=getModuleObject(cfg,'TS::lnkcanvasappl');
                       w5obj.SetFilter({
                       });
                       w5obj.findRecord(
                             "canvascanvasid,canvas,canvasid,applid,"+
                             "appl,ictono,"+
                             "voushort",function(data){
                          appletobj.data['relation']=new Object();
                          appletobj.data.relation['raw']=new Array();
                          appletobj.data.relation['byappl']=new Object();
                          appletobj.data.relation['byicto']=new Object();
                          $.each(data,function(index,item){
                             var reldata=appletobj.data.relation; 
                             reldata.raw.push(item);
                             reldata.byappl[item.applid]=item;
                             if (item.ictono!=""){
                                if (!reldata.byicto[item.ictono]){
                                   reldata.byicto[item.ictono]=new Array();
                                }
                                reldata.byicto[item.ictono].push(item);
                             }
                          }); 
                          console.log("raw relations",appletobj.data.relation);
                          next();
                       });
                    });
                    $(frm).queue("load",function(next){
                       $(".spinner").show();
                       var w5obj=getModuleObject(cfg,'PAT::ictname');
                       w5obj.SetFilter({
                       });
                       w5obj.findRecord(
                             "name,id,urlofcurrentrec,fullname,ictoid,"+
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
                             "businessseg,businesssegid,"+
                             "business,businesssubprocess,"+
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
                    $(frm).queue("load2",function(next){
                    $(".spinner").show();
                       var w5obj=getModuleObject(cfg,'PAT::businessseg');
                       w5obj.SetFilter({
                       });
                       w5obj.findRecord(
                             "name,urlofcurrentrec,title,description,comments,"+
                             "subprocesses,bsegopt,sopt,id",
                             function(data){
                          appletobj.data['businessseg']=new Object();
                          $.each(data,function(index,item){
                             appletobj.data['businessseg'][item.id]=item;
                          }); 
                          next();
                       });
                    });
                 }
                 $(frm).queue("load",function(next){
                    console.log("fine database:",appletobj.data);
                    $(".spinner").hide();
                    $(".databaseLoader").remove();
                    $("#dosearch").css("cursor","pointer");
                    $("#Reloader").css("cursor","pointer");
                    $("#dosearch").click(function(){
                       appletobj.doSearch(); 
                    });
                    $("#Reloader").click(function(){
                       delete appletobj.data;
                       appletobj.app.setMPath({
                             label:ClassAppletLib['%SELFNAME%'].desc.label,
                             mtag:'%SELFNAME%'
                          }
                       );
                       appletobj.loadMainPage();
                    });
                    if ($(searchbox).val().length>2){
                       appletobj.doSearch();
                    }
                    ok();
                 });
                 $(frm).dequeue("load2");
                 $(frm).dequeue("load");
     
                 //$(".spinner").hide();
                 //appletobj.data=data;
                 //$("#analysedData").html("<xmp>"+Dumper(data)+"</xmp>");
                 window.dispatchEvent(new Event('resize'));
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
      $(win).find("[data-dataobj]").css("cursor","pointer");
      $(win).find("[data-dataobj]").click(function(e){
         var id=$(this).attr("data-dataobjid");
         var dataobj=$(this).attr("data-dataobj");
         var method=$(this).attr("data-method");
         appletobj.showItem(dataobj,id,method); 
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

   ClassAppletLib[applet].class.prototype.addvjoindataload=function(win){
      var appletobj=this;
      var app=this.app;

      $(win).find("[data-vjointo]").each(function(i,e){
         var target=e;
         $(target).html("<b>...</b");
         var dataobj=$(e).attr("data-vjointo");
         var view=$(e).attr("data-vjoindisp");
         var fld=$(e).attr("data-vjoinfld");
         var val=$(e).attr("data-vjoinval");
         app.Config().then(function(cfg){
            $(target).html(dataobj+"::"+val+"...");
            var w5obj=getModuleObject(cfg,dataobj);
            var flt=new Object();
            flt[fld]=val;
            w5obj.SetFilter(flt);
            w5obj.findRecord(view,function(data){
               $(target).text(data[0][view]);
            });
         });
      });
   }

   ClassAppletLib[applet].class.prototype.showBusinessSeg=function(item){
      var appletobj=this;
      var app=this.app;

      var d="<table class=\"recordsheet\">";

      appletobj.app.setMPath({
            label:ClassAppletLib['%SELFNAME%'].desc.label,
            mtag:'%SELFNAME%'
         },
         {
            label:item.name,
            mtag:'PAT::businessseg'+"/"+item.id
         }
      );

      if (item.name){
         d+="<tr class=headline>"+
            "<td class=label><b>%T(Shortname,PAT::businessseg)%:</b></td>";
         d+="<td width=70%>"+item.name+"</td></tr>";
      }
      if (item.bsegopt){
         d+="<tr><td class=label>"+
            "<b>%T(Business-Segment OPT,PAT::businessseg)%:</b></td>";
         d+="<td>"+item.bsegopt+"</td></tr>";
      }
      if (item.sopt){
         d+="<tr><td class=label><b>%T(S-OPT,PAT::businessseg)%:</b></td>";
         d+="<td>"+item.sopt+"</td></tr>";
      }
      if (item.comments){
         d+="<tr><td class=label><b>%T(Comments,PAT::businessseg)%:</b></td>";
         d+="<td>"+item.comments+"</td></tr>";
      }
      d+="<tr><td colspan=2 class=block-end style=\"padding:0\">"+
         "&nbsp;</td></tr>";
      if (item.subprocesses.length){
         d+="<tr><td colspan=2 class=label style=\"padding-bottom:0\">"+
            "%TRANSLATE(fieldgroup.subprocesses,PAT::businessseg)%:"+
            "</td></tr>";
         for(var spc=0;spc<item.subprocesses.length;spc++){
            var spid=item.subprocesses[spc].id;
            d+="<tr><td colspan=2>";
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
            d+="</td></tr>";
         }
      }
      d+="</table>";
      

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
      d+="<tr><td class=label>%T(Description,PAT::subprocess)%:</td>";
      d+="<td>"+item.description+"</td></tr>";
      d+="<tr>";
      d+="<td class=label>%T(Business-Segment,PAT::subprocess)%:</td>";
      d+="<td><div data-dataobj=\"PAT::businessseg\" ";
      d+="data-dataobjid=\""+item.businesssegid+"\">";
      d+=item.businessseg;
      d+=extLink(9,
         appletobj.data.businessseg[item.businesssegid].urlofcurrentrec); 
      d+="</div>";
      d+="</td></tr>";
      d+="<tr class=block-end><td class=label>Business:</td>";
      d+="<td>"+item.business+"</td></tr>";
      if (item.ictnames.length){
         d+="<tr>";
         d+="<td valign=top class=label>ICTO-Aliases:</td>";
         d+="<td><table width=60% class=subrecords>";
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


      d+="<tr><td class=label colspan=2  style=\"padding-bottom:0\">"+
         "%T(Operations-Times,PAT::Explore::ibicalc)%:</td>"+
         "</tr>";
      d+="<tr><td colspan=2>"+ 
         optimes.table()+
         "</td></tr>";
      d+="<tr><td class=label colspan=2 style=\"padding-bottom:0\">"+
         "%T(IBI-Times,PAT::Explore::ibicalc)%:</td>"+
         "</tr>";
      d+="<tr><td colspan=2>"+ 
         ibitimes.table()+
         "</td></tr>";
      d+="<tr><td class=label colspan=2 style=\"padding-bottom:0\">"+
         "%T(IBI-Thresholds,PAT::Explore::ibicalc)%:</td>"+
         "</tr>";
      d+="<tr><td colspan=2><table width=100%>"; 

      d+="<tr>"; 
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold Core-Time mon-fri,PAT::subprocess)%</td>"; 
      if (item.ibithcoretimemonfri){
         d+="<td>"+item.ibithcoretimemonfri+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold NonProd-Time mon-fri,PAT::subprocess)%</td>"; 
      if (item.ibithnonprodtimemonfri){
         d+="<td>"+item.ibithnonprodtimemonfri+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }

      d+="<td width=10%>&nbsp;</td>";
      d+="</tr>"; 

      d+="<tr>"; 
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold Core-Time sat,PAT::subprocess)%</td>"; 
      if (item.ibithcoretimesat){
         d+="<td>"+item.ibithcoretimesat+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold NonProd-Time sat,PAT::subprocess)%</td>"; 
      if (item.ibithnonprodtimesat){
         d+="<td>"+item.ibithnonprodtimesat+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }
      d+="</tr>"; 
      
      d+="<tr>"; 
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold Core-Time sun/HOL,PAT::subprocess)%</td>"; 
      if (item.ibithcoretimesun){
         d+="<td>"+item.ibithcoretimesun+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }
      d+="<td width=10%>&nbsp;</td>";
      d+="<td>%T(IBI Threashold NonProd-Time sun/HOL,PAT::subprocess)%</td>"; 
      if (item.ibithnonprodtimesun){
         d+="<td>"+item.ibithnonprodtimesun+" min</td>"; 
      }
      else{
         d+="<td>-</td>"; 
      }
      d+="<td width=10%>&nbsp;</td>";
      d+="</tr>"; 
      
      
      
      d+="</table></td></tr>";
      d+="</table>";


      return({
         title:"%T(PAT::subprocess,PAT::subprocess)%",
         subtitle:item.name+": "+item.title,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
         }
      });

   }
   ClassAppletLib[applet].class.prototype.IBIcalc=function(
         item,startDay,start_time,endDay,end_time){
      var appletobj=this;
      var spid=item.id;
      var out={
         SumCoreMins:0,
         SumNonprodMins:0,
         corePercVal:0,
         nonprodPercVal:0,
         ibipoints:new Array(),
         spans:[]
      };
      var evDayNum=0;
      var day=new Date(startDay);
      var startMins=parseInt(start_time.split(":")[0])*60+
                    parseInt(start_time.split(":")[1]);
      var endMins = parseInt(end_time.split(":")[0])*60+
                    parseInt(end_time.split(":")[1]);
      out.endMins=endMins;
      out.startMins=startMins;
      var sprec=appletobj.data['subprocess'][spid];
      var ibinonprodtime=new TimeSpans(sprec.ibinonprodtime,{
          defaultType:'B'
      });
      var ibicoretime=new TimeSpans(sprec.ibicoretime,{
          defaultType:'C'
      });
      var ibitimes=new TimeSpans("");
      ibitimes=ibitimes.overlay(ibinonprodtime);
      ibitimes=ibitimes.overlay(ibicoretime);
      out.thcoreSum=0;
      out.thnonprodSum=0;


      do{
         if (!out.ibipoints[evDayNum]){
            out.ibipoints[evDayNum]=0;
         }
         var thnonprod=parseInt(sprec.ibithnonprodtimemonfri);
         var thcore=parseInt(sprec.ibithcoretimemonfri);
         var isSat = (day.getDay() == 6);
         var isSun = (day.getDay() == 0);
         var dayno=0;
         if (isSat){
            thnonprod=parseInt(sprec.ibithnonprodtimesat);
            thcore=parseInt(sprec.ibithcoretimesat);
            dayno=1;
         }
         else if (isSun){
            thnonprod=parseInt(sprec.ibithnonprodtimesun);
            thcore=parseInt(sprec.ibithcoretimesun);
            dayno=2;
         }
         if (item.relevance!=1){
            thnonprod*=3;
            thcore*=3;
         }
         if (thcore>0){
            out.thcoreSum=out.thcoreSum+thcore;
         }
         if (thnonprod>0){
            out.thnonprodSum=out.thnonprodSum+thnonprod;
         }
         //--------------------------------------------------
         if (item.relevance==1 &&   // laut SharePoint 2 - 4 raus genommen
             thcore>0){
            var dayStartMins=startMins;
            var dayEndMins=endMins;
            if (evDayNum!=0){
               dayStartMins=0;
            }
            if (day<endDay){
               dayEndMins=1440;
            }
            var spans=ibitimes.RangeScan(dayStartMins,dayEndMins,dayno);
            if (spans.length){
               var SumCoreMins=0;
               var SumNonprodMins=0;
               for(var spanno=0;spanno<spans.length;spanno++){
                  if (spans[spanno].type=='C'){
                     var t=spans[spanno].endMin-spans[spanno].startMin;
                     SumCoreMins+=t;
                  }
                  if (spans[spanno].type=='B'){
                     var t=spans[spanno].endMin-spans[spanno].startMin;
                     SumNonprodMins+=t;
                  }
               }
               var nonprodPercVal=0;
               var corePercVal=0;
               if (SumNonprodMins>0 && thnonprod>0){
                  nonprodPercVal=Math.round(SumNonprodMins/thnonprod*1000);
               }
               if (SumCoreMins>0 && thcore>0){
                  corePercVal=Math.round(SumCoreMins/thcore*1000);
               }
               var dayIBI=((nonprodPercVal+corePercVal)>=1000) ? 1 : 0;
               out.ibipoints[evDayNum]+=dayIBI;
               out.SumNonprodMins+=SumNonprodMins;
               out.SumCoreMins+=SumCoreMins;
               out.nonprodPercVal+=nonprodPercVal;
               out.corePercVal+=corePercVal;
            }
            out.spans.push(spans);
         }
         //--------------------------------------------------
         day.setDate(day.getDate()+1);
         evDayNum++;
      }while(day <= endDay);
      return(out);
   }
   ClassAppletLib[applet].class.prototype.doVote=function(
         win,item,start_date,start_time,end_date,end_time,fullcheck){
      var appletobj=this;
      var dateStartDay = new Date(start_date);
      var dateEndDay = new Date(end_date);
      console.log("dovote",item,
                           start_date,start_time,
                           end_date,end_time,
                           fullcheck);



     // if (start_time.split(":")[0])>23 ||
      var error=new Array();
      if ((!start_time.match(/^[0-9]{1,2}:[0-9]{1,2}/)) ||
          parseInt(start_time.split(":")[0])>23 ||
          parseInt(start_time.split(":")[1])>59){
         error.push("%T(errStartTime,PAT::Explore::ibicalc)%");
      }
      if ((!end_time.match(/^[0-9]{1,2}:[0-9]{1,2}/)) ||
           parseInt(end_time.split(":")[0])>23 ||
           parseInt(end_time.split(":")[1])>59){
         error.push("%T(errEndTime,PAT::Explore::ibicalc)%");
      }

      if (error.length){
         var estr="";
         error.map(function(str){
             estr+="<font color=red><b>ERROR:</b> "+str+"</font><br>";
          });
         
         $(win).find("#vote").html(estr);
         return;
      }
      var relsub=new Object();
      for (var subprocessid in appletobj.data.subprocess){
          var sp=appletobj.data.subprocess[subprocessid];
          for (var i=0;i<sp.ictnames.length;i++){
              if (sp.ictnames[i].ictnameid==item.id ||
                  (fullcheck==true && item.ictoid==sp.ictnames[i].ictoid)){
                 if (!(sp.id in relsub)){
                    relsub[sp.id]={
                       name:sp.name,
                       id:sp.id,
                       business:sp.business,
                       businesssubprocess:sp.businesssubprocess,
                       businessseg:sp.businessseg,
                       businesssegid:sp.businesssegid,
                       title:sp.title,
                       relevance:sp.ictnames[i].relevance
                    };
                 }
                 if (relsub[sp.id].relevance>sp.ictnames[i].relevance){
                    relsub[sp.id].relevance=sp.ictnames[i].relevance;
                 }
              }
          }
      }


      var ibisumbusinessseg=new Object();
      for (var spid in relsub){
         var ibi=this.IBIcalc(relsub[spid],dateStartDay,start_time,
                                           dateEndDay,end_time);
         console.log("IBIcalc=",ibi);
         relsub[spid]=Object.assign(relsub[spid],ibi);
         for(var DayNum=0;DayNum<relsub[spid].ibipoints.length;DayNum++){
            if (relsub[spid].ibipoints[DayNum]){
               var businesslist=relsub[spid].business;
               if (!businesslist){
                  businesslist="NONE";
               }
               //businesslist=businesslist.split(/[,;+ ]+/);
               businesslist=new Array(businesslist);
               for(var i=0;i<businesslist.length;i++){
                  if (businesslist[i]!=""){
                     ibisumbusinessseg[businesslist[i]+"@"+
                                       relsub[spid].businesssubprocess+"@"+
                                       relsub[spid].businesssegid+"@"+
                                       DayNum]=1;
                  }
               }
            }
         }
      }
      console.log("ibisumbusinessseg=",ibisumbusinessseg);

      var subp=Object.keys(relsub).map(function(spid){
        return relsub[spid];
      }).sort(function(a,b){
         if (a.ibipoints<b.ibipoints){
            return(1);
         }
         else if (a.ibipoints>b.ibipoints){
            return(-1);
         }
         else{
            if (a.relevance>b.relevance){
               return(1);
            }
            else if (a.relevance<b.relevance){
               return(-1);
            }
            else{
               if (a.businessseg>b.businessseg){
                  return(1);
               }
               else if (a.businessseg<b.businessseg){
                  return(-1);
               }
               else{
                  if (a.name>b.name){
                     return(1);
                  }
                  else if (a.name<b.name){
                     return(-1);
                  }
               }
            }
         }
         return(0);
      });
      var d="";
      var ibisum=0;
      var ibibusinesssegsum=0;
      var lastbusinesssegid;
      
      for(var businesssegid in ibisumbusinessseg){
         ibibusinesssegsum+=ibisumbusinessseg[businesssegid];
      }

      for(var i=0;i<subp.length;i++){
         var spid=subp[i].id;
         ibisum+=subp[i].ibipoints;
         d+="<div>";
         d+="<div>";
         if (lastbusinesssegid!=subp[i].businesssegid){
            d+="&nbsp;<br>";
         }
         lastbusinesssegid=subp[i].businesssegid;
         d+="<b>"+subp[i].businessseg+"</b>"+": "+
            "<span data-dataobj=\"PAT::subprocess\" "+
            "data-dataobjid=\""+spid+"\">"+
            subp[i].name+": "+subp[i].title;
         d+=extLink(9,appletobj.data.subprocess[subp[i].id].urlofcurrentrec); 
         d+="</span>";
         d+="</div>";
         d+="<div style=\"margin-left:5px;margin-bottom:10px\">";
         d+="<font size=-1><i>"+
            subp[i].business+" "+subp[i].businesssubprocess+"</i></font><br>";
         d+=subp[i].ibipoints+" Pkt.";
         d+=" Begründung: ";
         if (subp[i].relevance==1){
            d+=" Kernapplikation ";
         }
         d+=" %T(relevance,PAT::Explore::ibicalc)% "+subp[i].relevance;
         d+="<br>";
         d+="%T(core,PAT::Explore::ibicalc)%: "+subp[i].thcoreSum+"min";
         d+=", ";
         d+="Schwelle Nebenzeit: "+subp[i].thnonprodSum+"min";
         if (subp[i].SumCoreMins>0 || subp[i].SumNonprodMins>0){
            d+="<br>";
            d+="%T(Duration,PAT::Explore::ibicalc)%: ";
            if (subp[i].SumCoreMins>0){
               var pct=Math.round(subp[i].corePercVal/10.0)+"%";
               d+="%T(core,PAT::Explore::ibicalc)% "+
                  subp[i].SumCoreMins+"min ("+pct+")";
            }
            if (subp[i].SumNonprodMins>0 && subp[i].SumCoreMins>0){
               d+=", ";
            }
            if (subp[i].SumNonprodMins>0){
               var pct=Math.round(subp[i].nonprodPercVal/10.0)+"%";
               d+="%T(nonprod,PAT::Explore::ibicalc)% "+
                  subp[i].SumNonprodMins+"min ("+pct+")";
            }
         }
         d+="</div>";
         d+="</div>";
      }
      console.log("relsub=",subp);
      var a="";
      if (fullcheck){
         a+="<h2>"+item.ictoid+"</h2>";
      }
      else{
         a+="<h2>"+item.ictoid+": "+item.name+"</h2>";
      }
      if (start_date!=end_date){
         a+="<p>%T(Event,PAT::Explore::ibicalc)%: "+
               "%T(from,PAT::Explore::ibicalc)% "+start_date+" "+start_time+
               " %T(to,PAT::Explore::ibicalc)% "+end_date+" "+end_time+"</p>";
      }
      else{
         a+="<p>%T(Event,PAT::Explore::ibicalc)%: "+start_date+" "+
               "%T(from,PAT::Explore::ibicalc)% "+start_time+
               " -"+end_time+"</p>";
      }
      a+="<h3>IBI %T(points sum,PAT::Explore::ibicalc)%:"+
         ibibusinesssegsum+"</h3>";
      a+="<hr>";
      a+="<p>Detail-Analyse:</p>";
      a+=d;
      $(win).find("#vote").html(a);
      appletobj.addClickLinks(win);
   }
   ClassAppletLib[applet].class.prototype.showIBIVote=function(item,m){
      var appletobj=this;

      console.log("showIBIvote:",item,m);

      var label=item.ictoid+": "+item.name;

      var now=new Date();
      var today=now.getFullYear()+"-"+((now.getMonth() < 9) ? "0" : "")+
                (now.getMonth()+1)+"-"+((now.getDate() < 10) ? "0" : "") + 
                now.getDate();
      var nowStr=((now.getHours() < 10) ? "0" : "") + 
                 now.getHours() + ":" + ((now.getMinutes() < 10) ? "0" : "") + 
                 now.getMinutes();
      now=new Date(now - 3600000);
      var nowM60=((now.getHours() < 10) ? "0" : "") + 
                 now.getHours() + ":" + ((now.getMinutes() < 10) ? "0" : "") + 
                 now.getMinutes();

      var d="";

      var d="<table class=\"recordsheet\">";

      d+="<tr><td></td><td width=20% nowrap>"+
         "%T(Begin,PAT::Explore::ibicalc)%"+
         ":</td>";
      d+="<td width=20% nowrap><input id=start_date style=\"width:100%\" "+
         "type=date value=\""+today+"\"></td>";

      d+="<td width=10% nowrap>"+
         "%T(Begin time,PAT::Explore::ibicalc)% (HH:MM):</td>";
      d+="<td width=20% nowrap><input id=start_time style=\"width:60%\" "+
         "maxlength=5 type=text value=\""+nowM60+"\"></td><td></td></tr>";

      d+="<tr><td></td><td width=20% nowrap>"+
         "%T(End,PAT::Explore::ibicalc)%"+
         ":</td>";
      d+="<td width=20% nowrap><input id=end_date style=\"width:100%\" "+
         "type=date value=\""+today+"\"></td>";

      d+="<td width=10% nowrap>"+
         "%T(End time,PAT::Explore::ibicalc)% (HH:MM):</td>";
      d+="<td width=20% nowrap><input id=end_time style=\"width:60%\" "+
         "maxlength=5 type=text value=\""+nowStr+"\"></td><td></td></tr>";

      if (item.ictoid && item.ictoid!=""){
         d+="<tr><td></td><td colspan=3>"+
            "%T(full ICTO vote,PAT::Explore::ibicalc)%"+
            ": &nbsp;";
         d+="<input id=fullcheck "+
            "type=checkbox></td><td></td></tr>";
      }

      d+="</table><br><br>";
      d+="<center><input id=dovote type=button style=\"width:80%\" "+
         "value=\"%T(vote,PAT::Explore::ibicalc)%\"></center>";
      d+="<hr>";
      d+="<div id=vote></div>";

      return({
         title:"%T(Incident IBI analysis,PAT::Explore::ibicalc)%: ",
         subtitle:label,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
            $(win).find("#dovote").click(function(e){
               var start_date=$(win).find("#start_date").first().val();
               var start_time=$(win).find("#start_time").first().val();
               var end_date=$(win).find("#end_date").first().val();
               var end_time=$(win).find("#end_time").first().val();
               var fcheck=$(win).find("#fullcheck").first().prop('checked');
               appletobj.doVote(win,item,
                                start_date,start_time,
                                end_date,end_time,fcheck);
            });
         }
      });
   }

   ClassAppletLib[applet].class.prototype.showICTOName=function(item){
      var appletobj=this;

      appletobj.app.setMPath({
            label:ClassAppletLib['%SELFNAME%'].desc.label,
            mtag:'%SELFNAME%'
         },
         {
            label:item.fullname,
            mtag:'PAT::ictname'+"/"+item.id
         }
      );

      var label=item.fullname;
      var d="";
      var d="<table class=\"recordsheet\">";

      var allnames=new Array();
      $.each(appletobj.data.ictname,function(ictindex,ictrec){
         if (ictrec.ictoid==item.ictoid){
            allnames.push(ictrec)
         }
      });
      if (allnames.length>1){
         d+="<tr class=headline><td><b>Alias-Names:</b></td>";
         d+="<td>";
         d+=allnames.map(function(rec){
               var l="<div data-dataobj=\"PAT::ictname\" ";
               l+=" data-dataobjid=\""+rec.id+"\">";
               l+=rec.name;
               l+=extLink(9,rec.urlofcurrentrec); 
               l+="</div>";
               return(l);
            }).join("\n");
         d+="</td></tr>";
      }
      if (item.ictoid){
         d+="<tr><td><b>%T(ICTO-ID,PAT::ictname)%:</b></td>";
         d+="<td>"+item.ictoid+"</td></tr>";
      }
      if (item.ictoid  && appletobj.data.relation.byicto[item.ictoid]){
         d+="<tr><td><b>Canvas:</b></td>";
         d+="<td>";
         var canvas=new Object();
         $.each(appletobj.data.relation.byicto[item.ictoid],function(i,relrec){
             if (relrec.canvascanvasid!=""){
                canvas[relrec.canvascanvasid]=relrec;
             }
         });
         for(var canvascanvasid in canvas){
            var relrec=canvas[canvascanvasid];
            d+="<div class=clickableLink>";
            d+=canvascanvasid+" - "+relrec.canvas;
            if (relrec.canvasid!=""){
               d+=extLink(9,"TS::canvas",relrec.canvasid);
            }
            d+="</div>";
         };
         d+="</td></tr>";
      }
      if (1){
         d+="<tr><td><b>IBI Ansprechpartner:</b></td>";
         d+="<td>"+
            "<span data-vjointo=\"PAT::ictname\" "+
                 "data-vjoindisp=\"ibiresponse\" "+
                 "data-vjoinfld=\"id\" "+
                 "data-vjoinval=\""+item.id+"\" "+
            "></span>";
         d+="</td></tr>";
      }

      if (item.comments){
         d+="<tr><td><b>%T(Comments,PAT::ictname)%:</b></td>";
         d+="<td>"+item.comments+"</td></tr>";
      }

      d+="<tr class=block-end>";
      d+="<td colspan=2>";
      d+="<ul class=actions>";
     // d+="<li>";
      d+="<li data-dataobj=\"PAT::ictname\" ";
      d+="     data-dataobjid=\""+item.id+"\" ";
      d+="     data-method=\"ibiictovote\">";
      d+="%T(Vote Incident,PAT::Explore::ibicalc)%";
      d+="</li>";
      d+="</li>";
      d+="</ul>";
      d+="</td></tr>";

      d+="<tr class=block-end>"+
         "<td><b>%T(Sub-Process references,PAT::ictname)%:</b></td>";
      d+="<td>";
      for(var spid in item.subprocesses){
         d+="<div>";
         d+="<div ";
         d+="data-dataobj=\"PAT::subprocess\" ";
         d+="data-dataobjid=\""+spid+"\"> ";
         d+=item.subprocesses[spid].name+": "+
            item.subprocesses[spid].title;
         d+=extLink(9,appletobj.data.subprocess[spid].urlofcurrentrec); 
         d+="</div>";
         d+="</div>";
      }
      d+="</td></tr>";

      if (appletobj.data.relation.byicto[item.ictoid]){
         d+="<tr class=block-end>"+
            "<td><b>%T(Applications,itil::system)%:</b></td>";
         d+="<td>";
         var appl=new Object();

         $.each(appletobj.data.relation.byicto[item.ictoid],function(i,relrec){
            appl[relrec.applid]=relrec;
         });
         $.each(Object.values(appl),function(i,relrec){
            d+="<div>";
            d+="<div class=clickableLink> ";
            d+=relrec.appl;
            d+=extLink(9,"TS::appl",relrec.applid);
            d+="</div>";
            d+="</div>";
         });
         d+="</td></tr>";
      }

      d+="</table>";


      return({
         title:"%T(PAT::ictname,PAT::ictname)%",
         subtitle:label,
         d:d,
         fine:function(win){
            appletobj.addClickLinks(win);
            appletobj.addvjoindataload(win);
         }
      });
   }


   ClassAppletLib[applet].class.prototype.showItem=function(dataobj,item,m){
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
      if (typeof(item)=='object'){
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
            if (m=="ibiictovote" || m=="ibinamevote"){
               showdata=this.showIBIVote(item,m,ModalWin);
            }
            else{
               showdata=this.showICTOName(item,ModalWin);
            }
         }
         var d="";
         d+="<div class=\"DetailWindow\">";
         d+="<div class=\"DetailTitle\">";
         d+="<div style=\"height:4.2em;display:inline-block;"+
            "float:left;overflow:hidden;white-space: nowrap;width:90%\" "+
            "<span style=\"font-size:+1\">"+showdata.title+"</span>"+
            "<div "+
            "data-dataobj=\""+dataobj+"\" "+
            "data-dataobjid=\""+item.id+"\" "+
            "><h2>"+
            showdata.subtitle+
            extLink(16,item.urlofcurrentrec)+
            "</h2></div>"+
            "</div>";
         d+="<div style=\"height:4.2em;display:inline-block;"+
            "float:right;text-align:right;width:10%;\">";
         if (appletobj.modalStack.length){
            d+="<div style=\"display:inline-block;cursor:pointer;width:15px\" "+
               "id=\"back\"><b><</b></div>";
         }
         d+="<div style=\"display:inline-block;cursor:pointer;width:15px\" "+
            "id=\"close\"><b>X</b></div>";
         d+="</div>";
         d+="<div style=\"float:none;\"></div>";
         d+="</div>";
         d+="<div id=DetailFrame class=\"DetailFrame\">"+
            showdata.d+"</div>";
         d+="</div>";
         appletobj.modalStack.push({
            dataobj:dataobj,
            dataobjid:item.id,
            method:m
         });
         $("#Detail").html(d);
         if (showdata.fine){
            showdata.fine($("#Detail"));
         }
         $("#back").click(function(e){
            var backo=appletobj.modalStack.pop(); // das aktuelle Modal
            backo=appletobj.modalStack.pop();     // das letzte Modal (vor akt.)
            var id=backo.dataobjid;
            var dataobj=backo.dataobj;
            var method=backo.method;
            appletobj.showItem(dataobj,id,method); 
         });
         $("#close").click(function(e){
            console.log("click on close");
            $("#analysedData").show();
            $("#Detail").hide();
            appletobj.app.setMPath({
                  label:ClassAppletLib['%SELFNAME%'].desc.label,
                  mtag:'%SELFNAME%'
               }
            );
            appletobj.modalStack=new Array();
         });
      }
      else{
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            },{
               label:"invalid deep link",
               mtag:''
            }
         );
      }
      window.dispatchEvent(new Event('resize'));
   }
   ClassAppletLib[applet].class.prototype.doSearch=function(){
      var appletobj=this;
      var app=this.app;
      var searchbox=$("#search").first();
      var v=searchbox.val();
      v=v.trim();
      var mode=$("#dosearch").css("cursor");
      if (mode=="pointer"){
         if (v.length>2){
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
               var showByApplication=0;
               var showByICTOid=0;
               var applications=new Array();
               if (appletobj.data.relation.byicto[item.ictoid]){
                  $.each(appletobj.data.relation.byicto[item.ictoid],
                         function(subindex,item){
                     if (item.appl.toLowerCase().indexOf(v.toLowerCase())!=-1){
                        showByApplication++;
                     }
                     applications.push(item.appl);
                  });
               }

               if (item.name.toLowerCase().indexOf(v.toLowerCase())!=-1 ||
                   item.ictoid.toLowerCase().indexOf(v.toLowerCase())!=-1){
                  showByICTOid++;
               }

               if (showByICTOid || showByApplication){
                  var blk="<div class=ictnameItem>";
                  blk+="<div class=ictnameLabel "+
                       "data-dataobj=\"PAT::ictname\" "+
                       "data-dataobjid=\""+item.id+"\" "+
                       ">"+
                       hightLight(v,"<b>"+item.fullname+"</b>")+
                       extLink(12,item.urlofcurrentrec)+ 
                       "</div>";
                  if (applications.length){
                     blk+="<div class=ictnameapplications>"+
                          hightLight(v,applications.join(", "))+"</div>";
                     blk+="</div>";
                  }
                  blk+="</div>";
                  ictoSearch+=blk;
               }
            }
            if (ictoSearch==""){
               for (var ictono in appletobj.data.relation.byicto){
                  var item=appletobj.data.relation.byicto[ictono];
                  var showByApplication=0;
                  var showByICTOid=0;
                  var applications=new Array();
                  if (appletobj.data.relation.byicto[ictono]){
                     $.each(appletobj.data.relation.byicto[ictono],
                            function(subindex,item){
                        if (item.appl.toLowerCase().indexOf(v.toLowerCase())!=-1){
                           showByApplication++;
                        }
                        applications.push(item.appl);
                     });
                  }
              
                  if (ictono.toLowerCase().indexOf(v.toLowerCase())!=-1 ||
                      ictono.toLowerCase().indexOf(v.toLowerCase())!=-1){
                     showByICTOid++;
                  }
              
                  if (showByICTOid || showByApplication){
                     var blk="<div class=ictnameItem>";
                     blk+="<div class=ictnameLabel "+
                          ">"+
                          hightLight(v,"<b>"+ictono+"</b>")+
                          "</div>";
                     if (applications.length){
                        blk+="<div class=ictnameapplications>"+
                             hightLight(v,applications.join(", "))+"</div>";
                        blk+="</div>";
                     }
                     blk+="</div>";
                     ictoSearch+=blk;
                  }
               }
            }
            //if (v.toLowerCase().indexOf("icto-")!=-1){
            // ictos sind immer das wichtigste
               $("#analysedData").append(ictoSearch);
               $("#analysedData").append(processSearch);
            //}
            //else{
            //   $("#analysedData").append(processSearch);
            //   $("#analysedData").append(ictoSearch);
            //}

            appletobj.addClickLinks($("#analysedData").first());
            console.log("app",appletobj.data);
         }
         else{
            $("#analysedData").html("");
         }
      }
   }
   ClassAppletLib[applet].class.prototype.loadMainPage=function(dataobj,id,m){
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
         if (dataobj!==undefined){
            appletobj.showItem(dataobj,id,m); 
         }
     }).catch(function(e){
         $(".spinner").hide();
     });

   };



   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;
      this.app.LayoutSimple();
      //$(".spinner").hide();
      appletobj.modalStack=new Array();

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
         var m=arguments[0][2];
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            }
            ,{ label:"loading direct link ...", mtag:dataobj+"/"+dataobjid }
         );
         var frm=$("#workspace");
         
         if (!appletobj.data){
            appletobj.loadMainPage(dataobj,dataobjid,m); // load data and showItem
         }
         else{
            appletobj.showItem(dataobj,dataobjid,m); 
         }
      }
      else{
         appletobj.app.setMPath({
               label:ClassAppletLib['%SELFNAME%'].desc.label,
               mtag:'%SELFNAME%'
            }
         );
         appletobj.loadMainPage();
      }
   }
});
