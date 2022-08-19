define(["visjs"],function(vis){
  W5ExploreClass.prototype.InitObjectStore=function(){
     if (!this.edge){
        this.edge = new vis.DataSet();
     }
     this.edge.clear();
     if (!this.node){
        this.node = new vis.DataSet();
     } 
     this.node.clear();
  };


  W5ExploreClass.prototype.ShowNetworkMap=function(MapParamTempl){
      var app=this;
      this.LayoutNetworkMap();

      var preNetworkPrint=function(){
        app.network.setOptions({
           width:'1754px',
           height:'1150px'
        });
        app.network.moveTo({

        });
      };
      var postNetworkPrint=function(){
        app.network.setOptions({
           width:'100%',
           height:'100%'
        });
     
      };

      $( window ).bind( "beforeprint",preNetworkPrint);
      $( window ).bind( "afterprint",postNetworkPrint);
      $(".spinner").show();
      var data = {
        nodes: this.node,
        edges: this.edge
      };
      var options = {
        edges: {
          font: {
            size: 12
          },
          smooth: true
        },
        physics:{
           barnesHut: {
             avoidOverlap: 1
           }
        },
        interaction: { 
          multiselect: true,
          navigationButtons: false,
          keyboard: true
        },
        nodes: {
          color:{
             background:'#ffff00'
          },
          level:1
        },
      };
      var usephysicsonce=false;
      if (MapParamTempl.physics && MapParamTempl.physics.enabled=="once"){
         usephysicsonce=true;
         MapParamTempl.physics.enabled=true; 
      }
      




      $.extend(options,MapParamTempl);
      this.network = new vis.Network(this.netmap, data, options);
      this.network.on("stabilized", function () {
         if (app.networkFitRequest){
            if (!app.networkFitRequestCanceledByUser){
               app.network.fit({
                  animation: true
               });
            }
            $(".spinner").hide();
            app.networkFitRequest=false;
            app.networkFitRequestCanceledByUser=false;
            app.console.log("INFO","autolayout done");
         }
         if (usephysicsonce){
            this.setOptions( { physics: false } );
         }
      });
      this.network.on("zoom", function (params) {
         app.networkFitRequestCanceledByUser=true;
      });
      this.network.on("click", function (params) {
          params.event = "[original event]";
          if (params.nodes[0]){
             var n;
             var out=document.createElement('div');
             var methods=Object();
             var selectedNodes=params.nodes;
             app.createItemSelectors(out,selectedNodes);
             for(n=0;n<selectedNodes.length;n++){
                var nodeobj=app.node.get(selectedNodes[n]);
                var dataid=app.toObjKey(nodeobj.dataobj,nodeobj.dataobjid);
                for (var m in nodeobj.nodeMethods){
                   var isPosible=true;
                   if (nodeobj.nodeMethods[m].isPosible){
                      isPosible=nodeobj.nodeMethods[m].isPosible(
                         nodeobj,app.activeApplet,selectedNodes
                      );
                   }
                   if (isPosible){
                      if (methods[m]){
                         methods[m].cnt++;
                      }
                      else{
                         methods[m]={
                            cnt:1,
                            label:nodeobj.nodeMethods[m].label,
                            cssicon:nodeobj.nodeMethods[m].cssicon
                         };
                      }
                   }
                }
             }
             var path="";
             if (selectedNodes.length==1){
                var nodeobj=app.node.get(selectedNodes[0]);
                var dataobj=nodeobj.dataobj;
                var dataobjid=nodeobj.dataobjid;
                app.console.log("INFO","load HtmlExplore for "+dataobj+
                                " id="+dataobjid);
                var dataobjpath=dataobj.replace('::','/');
                path="../../"+dataobjpath+"/Result?";
                path=path+"FormatAs=HtmlExplore&";
                path=path+"search_"+nodeobj.fieldnameid+"="+dataobjid;
                var DetailFrame=$("<div id=HtmlExploreDetail "+
                                  "style='display:none'></div>");
                $(out).append(DetailFrame);
                var HtmlExploreSpinner=$("<div id=HtmlExploreSpinner><img src=\"../../base/load/ajaxloader.gif\"></div>");
                $(out).append(HtmlExploreSpinner);
             }
             $(out).append($("<hr>"));

             var mdiv=document.createElement('ul');
             $(mdiv).addClass("nodeMethods");
             var posibleMethodsList=new Array();
             for (var m in methods){
                 posibleMethodsList.push(m);
             }
             posibleMethodsList=posibleMethodsList.sort();
             for(var mpos=0;mpos<posibleMethodsList.length;mpos++){
                var m=posibleMethodsList[mpos];
                if (methods[m].cnt==selectedNodes.length){
                   $(mdiv).append("<li "+
                                  "style='padding-bottom:5px;"+
                                  "padding-left:20px'>"+
                                  "<span class=nodeMethodCall data-id='"+m+"'>"+
                                  "<div style='position:relative'>"+
                                  "<div style='position:absolute;left:-20px' "+
                                  "class='cssicon "+methods[m].cssicon+"'>"+
                                  "</div>"+
                                  "</div>"+
                                  methods[m].label+"</span></li>");
                }
             }
             $(mdiv).find(".nodeMethodCall").click(function(e){
                $(".spinner").show();
                var methodName=$(this).attr("data-id");
                for(n=0;n<selectedNodes.length;n++){
                   var nodeobj=app.node.get(selectedNodes[n]);
                   nodeobj.nodeMethods[methodName].exec.call(nodeobj);
                }
                app.processOpStack(function(resultOfOpStack){
                   $(".spinner").hide();
                   if (nodeobj.nodeMethods[methodName].postExec){
                      nodeobj.nodeMethods[methodName].postExec.call(nodeobj,resultOfOpStack);
                   }
                   else{
                      console.log("INFO","processOpStack:"+
                                  "finisch after call of "+
                                   methodName+" result=",resultOfOpStack);
                   }
                });
             });
             $(dbrec).html(""); 
             $(dbrec).append($(out)); 
             $(dbrec).append(mdiv); 
             if (selectedNodes.length==1){
                $.ajax({
                   type:'GET',
                   url:path,
                   beforeSend:function(){
                   },
                   success:function(data){
                     $('#HtmlExploreSpinner').remove();
                     var maxw=$(app.dbrec).width();
                     $('#HtmlExploreDetail').height("auto").html(data);
                     //$('#HtmlExploreDetail').find(".FieldValue").ellipsis();
                     var h=$('#HtmlExploreDetail').height();
                     var maxh=$(app.dbrec).height();
                     if (h>maxh/2){
                        h=maxh/2;
                     }
                     $('#HtmlExploreDetail').height(0);
                     $('#HtmlExploreDetail').show();
                     $('#HtmlExploreDetail').animate({height: h}, 400);
                     //$("#HtmlExploreDetail").hide().html(data).fadeIn('slow');
                     app.console.log("INFO","got HtmlExplore");
                   }
                });
             }
          }
          else{
             app.showDefaultDBRec();
          }
      });
   };

   W5ExploreClass.prototype.LayoutNetworkMap=function(){
      if (!this.main ||  $(this.main).attr("data-layout")!="NetworkMap"){
         this.LayoutBase();
         this.netmap = document.createElement('div');
         this.netmap.id = 'netmap';
         this.workspace.appendChild(this.netmap);
         this.netmap.innerHTML = 'netmap';
        
         this.ctrl = document.createElement('div');
         this.ctrl.id = 'ctrl';
         this.workspace.appendChild(this.ctrl);

         this.ctrlbar = document.createElement('div');
         this.ctrlbar.id = 'ctrlbar';
         this.ctrl.appendChild(this.ctrlbar);

         this.dbrec = document.createElement('div');
         this.dbrec.id = 'dbrec';
         this.ctrl.appendChild(this.dbrec);

         this.showDefaultDBRec();
        
         this.console.div = document.createElement('div');
         this.console.div.id = 'cons';
         this.console.div.innerHTML = '';
         this.main.appendChild(this.console.div);
         $(this.ctrlbar).html(""); 
         $(this.ctrlbar).append($(this.globalFunctions())); 
         this.ResizeLayout();
         $.fn.disableSelection = function() {
             return this
                      .attr('unselectable', 'on')
                      .css('user-select', 'none')
                      .on('selectstart', false);
         };
         $(this.main).attr("data-layout","NetworkMap");
      }
   };


   W5ExploreClass.prototype.addNode=function(dataobj,id,initialLabel,nodeTempl){
      this.pushOpStack(
          new Promise(function(res,rej){
              W5Explore.loadDataObjClass(dataobj).then(
                 function(DataObjClassPrototype){
                    var o=new DataObjClassPrototype(id,initialLabel,nodeTempl);
                    //var curobj=W5Explore.node._data[o.id];
                    var curobj=W5Explore.node.get(o.id);
                    if (!curobj){
                       if (!o.app.nextAngle || o.app.nextAngle>300){
                          o.app.nextAngle=1;
                       }
                       o.app.nextAngle=o.app.nextAngle+30;
                       var radius = 300;
         
                       o.x=radius*Math.sin(Math.PI*2*o.app.nextAngle/360);
                       o.y=radius*Math.cos(Math.PI*2*o.app.nextAngle/360);
                       //console.log("x="+o.x,"y="+o.y);
                       o.allowedToMoveX=true;
                       o.allowedToMoveY=true;
 
                       W5Explore.node.add(o);
                       o.parentNodeDataSet=W5Explore.node;
                       o.app=W5Explore;
                       o.refreshLabel();
                    }
                    else{
                       res(curobj);
                    }
                    res(o);
                 }
              );
          })
      )
   };

   W5ExploreClass.prototype.genenericLoadNode=function(dataobj,idfield,labelfield,filter,
                                   okcallback){
      var app=this;
      this.pushOpStack(
        new Promise(function(ok,reject){
           app.Config().then(function(cfg){
              var w5obj=getModuleObject(cfg,dataobj);
                w5obj.SetFilter(filter);
                w5obj.findRecord(idfield+","+labelfield, function(data){
                   // detect all objects need to be preloaded
                   var cnt=data.length;
                   for(c=0;c<cnt;c++){
                      app.addNode(dataobj,data[c][idfield],
                                          data[c][labelfield]);
                   }
                   ok("genenericLoadNode");
                });
             }).catch(function(e){
                console.log("get config failed",e);
                app.console.log("can not get config");
                reject(e);
             });
          })
       );
       this.processOpStack(okcallback);
   };



   W5ExploreClass.prototype.addEdge=function(fromid,toid,edgeTempl){
      this.pushOpStack(
          new Promise(function(res,rej){
             var edgeid=fromid+"::"+toid;
             var cur=W5Explore.edge.get(edgeid);
             if (edgeTempl && edgeTempl.noAcross){
                if (!cur){
                   var ledgeid=toid+"::"+fromid;
                   cur=W5Explore.edge.get(ledgeid);
                }
                delete edgeTempl['noAcross'];
             }

             if (!cur){
                var e={id:edgeid,from:fromid,to:toid};
                $.extend(e,edgeTempl);
                W5Explore.edge.add(e);
                res(e);
             }
             res(cur);
         })
      );
   };

   W5ExploreClass.prototype.createItemSelectors=function(out,selectedNodes){
      var app=this;
      for(n=0;n<selectedNodes.length;n++){
         var nodeobj=app.node.get(selectedNodes[n]);
         var dataid=app.toObjKey(nodeobj.dataobj,nodeobj.dataobjid);
         var lnk="";
         if (nodeobj.urlofcurrentrec){
            lnk="<div data-id='"+nodeobj.urlofcurrentrec+"' style='float:right;cursor:pointer' "+
                "class='cssicon arrow_right openItem'></div>";
         }




         $(out).append($("<div id='sel_"+dataid+"' "+
                         "class='SelectedItem'>"+lnk+
                         "<span data-id='"+dataid+"' style='cursor:pointer' class='centerItem'>"+nodeobj.label+"</span></div><div style='clear:both'></div>"));
      }
      $(out).find(".openItem").click(function(e){
         var url=$(this).attr("data-id");
         custopenwin(url,"f800");
      });
      $(out).find(".centerItem").click(function(e){
         var id=$(this).attr("data-id");
         var nodeobj=app.node.get(id);
         var oldScale=app.network.getScale();
         if (oldScale<=0.9){
            var scaleOption = { scale : 0.9 };
            app.network.moveTo(scaleOption);
         }
         app.network.focus(id,{
            animation: {
                   duration: 200,
                   easingFunction: 'linear'
            }
         });
         $("#foundItems").hide();
         $("#findItem").val("");
         console.log("click on nodeobj",nodeobj);
      });
   };
   W5ExploreClass.prototype.findItem=function(v){
       var app=this;
       var showit=0;
       var matchedNodes=new Array();

       if (v.length>1){
          app.node.forEach(function(e){
             if (e.label.toLowerCase().indexOf(v.toLowerCase())>=0){
                matchedNodes.push(e.id);
             }
          });
          if (matchedNodes.length>0 && matchedNodes.length<20){
             showit=1;
          }
       }
       if (showit){
          $("#foundItems").show();
          $("#foundItems").html("");
          var out=$("#foundItems")[0];
         
          app.createItemSelectors(out,matchedNodes);
       }
       else{
          $("#foundItems").hide();
       }
   };



   W5ExploreClass.prototype.globalFunctions=function(){
       var app=this;
       var gdiv=document.createElement('div');

       var switches=$("<div class='cssswitches'></div>");
       var swrow=$("<div class='cssswitchrow'></div>");
       $(switches).append(swrow);

       $(swrow).append( "<div class='cssswitchcell'>"+
                        "<div class='cssicon cssswitch "+
                        "application_delete' "+
                        "id='ControlSwitchNavigation' "+
                        "title='Switch Navigation Controls'></div></div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "&nbsp;</div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "<div class='cssicon cssswitch "+
                          "application_lightning on' "+
                          "id='ControlSwitchPhysics' "+
                          "title='Switch Autolayout'></div></div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "<div class='cssicon cssswitch application_key' "+
                          "id='ControlSwitchDebugConsole' "+
                          "title='Switch debug console'></div></div>");


       $(swrow).append("<div class='cssswitchcell'>"+
                        "<div class='cssicon cssswitch "+
                          "application_view_columns cssswitchdisabled' "+
                          "id='SwitchNothing' "+
                          "title='Show data as table'></div></div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "&nbsp;</div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "&nbsp;</div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "&nbsp;</div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "&nbsp;</div>");

       $(swrow).append("<div class='cssswitchcell'>"+
                        "<div class='cssicon cssswitch printer "+
                          "cssswitchdisabled' "+
                          "id='ControlSwitchPrint' "+
                          "title='Print Network'></div></div>");

       $(switches).find(".cssswitch").not(".cssswitchdisabled").click(function(){
          console.log("click on ",this);
          var id=$(this).attr("id");
          if (id=="ControlSwitchPrint"){
             var work=document.getElementById("workspace");
             if (work){
                console.log("set focus to work");
                work.focus();
             }
             window.print();
          }
          if (id=="ControlSwitchDebugConsole"){
             if (app.console.div){
                if ($(this).hasClass("on")){
                   $(app.console.div).height(0);
                }
                else{
                   $(app.console.div).height(60);
                }
                app.ResizeLayout();
             }
             $(this).toggleClass('on');
          }
          if (id=="ControlSwitchPhysics"){
             if ($(this).hasClass("on")){
                app.network.setOptions({
                   physics: { 
                     enabled: false,
                   }
                });
             }
             else{
                app.network.setOptions({
                   physics: { 
                     enabled: true,
                   }
                });
             }
             $(this).toggleClass('on');
          }
          if (id=="ControlSwitchNavigation"){
             if ($(this).hasClass("on")){
                app.network.setOptions({
                   interaction: {
                     navigationButtons: false,
                   }
                });
             }
             else{
                app.network.setOptions({
                   interaction: {
                     navigationButtons: true,
                   }
                });
             }
             $(this).toggleClass('on');
          }
       });



       var finder=$("<table border=0 width=100%>"+
                    "<tr><td valign=middle>"+
                    "<input id=findItem style='width:100%' type=text></td>"+
                    "<td width=1%>"+
                    "<div style='margin:3px;cursor:pointer' "+
                    "title='find item in current szenario' "+
                    "id=findItemButton class='cssicon find'></div>"+
                    "</td></tr></table>");
       $(finder).find("#findItemButton").click(function(e){
          alert("i do my best to find "+$("#findItem").val());
       });

       $(finder).find("#findItem").on("keyup",function(){
          var v=$("#findItem").val();
          if (v!=""){
             app.findItem(v);
          }
       });
       //$(finder).find("#findItem").change(function(){
       //   var v=$(this).val();
       //   app.findItem(v);
       //});

       $(gdiv).append(switches);
       $(gdiv).append(finder);
       $(gdiv).append("<div style='position:relative;width:98%;margin:2px'><div id=foundItems style='z-index:1000;height:200px;top:0px;overflow:auto;position:absolute;background-color:#fefefe;border-color:black;border-style:solid;border-width:1px;width:inherit;display:none'></div></div>");
       $(gdiv).append($("<hr<br>"));
       return(gdiv) 
   }
   W5ExploreClass.prototype.showDefaultDBRec=function(){
      //var out="<p>Add Object:<br><select><option>A</option><option>B</option></select><input type=text><br>xxxxhier könnte z.B. eine Suchmaske für das hinzufügen "+
      //        "von beliebigen Items stehen</p>";
      $(this.dbrec).html(""); 
      //$(dbrec).append($(out)); 
   };

   W5ExploreClass.prototype.resetItemSelection=function(){
      this.network.unselectAll();
      this.showDefaultDBRec();
   };


});


