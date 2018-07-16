<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<base href="%BASE%">
<link rel="stylesheet" href="../../../public/base/load/default.css">
<link rel="stylesheet" href="../../../public/base/load/work.css">
<link rel="stylesheet" href="../../../public/base/load/cssicon.css">
<link rel="stylesheet" href="../../../public/base/load/kernel.App.Web.css">
<link rel="stylesheet" href="../../../public/base/load/jquery.dataTables.css">
<link rel="stylesheet" href="../../../public/base/load/vis.min.css">


<!-- Main Layout  Handling -->
<style>
body{
 margin:0;padding:0;
}

#main{
 margin:0px;
 padding:0px;
 border-style:solid;
 border-color:gray;
 border-width:2px;
}

.cssswitches{
   padding:2px;
   padding-bottom:0;
}

.cssswitch{
   margin:2px;
   cursor:pointer;
   border: 1px solid white;
   border-bottom: 3px solid white;
}

.on{
   border-bottom: 3px solid blue;
}

.cssswitch:hover{
   border-left: 1px solid gray;
   border-right: 1px solid gray;
   border-top: 1px solid gray;
}

#mpath{
 border-width:0px;
 margin:0px;
 padding:0px;
 vertical-align:middle;
 height:22px;
}

#mpathfirst{
 width:20px;
 line-height:22px;
 xbackground-color:gray;
 text-align:center;
 float:left;
 margin:0px;
 padding:0px;
 transform: rotate(45deg);
 font-size:20px;
}

#workspace{
 xborder-style:solid;
 xborder-color:green;
 xborder-width:1px;
 margin:0px;
 padding:0px;
 overflow:auto;
 background-color:#ffffff;
 overflow:hidden;  /* sollte das Wrap Problem l�sen */
}

#netmap{
 xborder-style:solid;
 xborder-color:black;
 xborder-width:1px;
 margin:0px;
 padding:0px;
 float:left;
 overflow:auto;
}

#dbrec{
 xborder-style:solid;
 xborder-color:red;
 xborder-width:1px;
 border-left-style:solid;
 border-left-color:black;
 border-left-width:2px;

 margin:0px;
 padding:0px;
 width:220px;
 float:left;
 overflow:auto;
}

#cons{
 border-width:0px;
 margin:0px;
 padding:0px;
 height:0px;
 overflow:hidden;
 overflow-y:auto;
 font-family: monospace;
}
</style>


<!-- Modal Dialog  Handling -->
<style>
.modal-background {
    display: none; /* Hidden by default */
    position: fixed; /* Stay in place */
    z-index: 1001; /* Sit on top */
    left: 0;
    top: 0;
    width: 100%; /* Full width */
    height: 100%; /* Full height */
    overflow: auto; /* Enable scroll if needed */
    background-color: rgb(0,0,0); /* Fallback color */
    background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}

.modal-content {
    background-color: #fefefe;
    margin: 15% auto; /* 15% from the top and centered */
    padding: 20px;
    padding-top: 5px;
    border: 1px solid #888;
    width: 80%; 
    height: 40%;
}

.closebtn {
    color: #aaa;
    float: right;
    font-size: 28px;
    font-weight: bold;
}

.closebtn:hover,
.closebtn:focus {
    color: black;
    text-decoration: none;
    cursor: pointer;
}

.purebtn{
   color: rgba(0,0,0,.8);
   padding: .5em 1em;
   border: transparent;
   background-color: #e6e6e6;
   text-decoration: none;
   border-radius: 2px;
   display: inline-block;
   zoom: 1;
   white-space: nowrap;
   -webkit-user-drag: none;
   user-select: none;
   font-size:100%;
   cursor: pointer;
   margin: 2px;
}
.purebtn:hover{
   background-image: linear-gradient(transparent,rgba(0,0,0,.05) 40%,rgba(0,0,0,.1));
}

</style>


<!-- TILE Handling -->
<style>

.parent {
  display: -webkit-flex;
  display: flex;
  -webkit-align-items: center;
  align-items: center;
  -webkit-justify-content:center;
  justify-content:center;
  -webkit-flex-wrap:wrap;
  flex-wrap:wrap;
  
  xbackground: #FFD54F;
  margin: 0 auto;
  width: 96%;
  margin-top:20px;
}

.parent .item,
.parent .dummyItem{
  width: 260px;
  height: 140px;
}

.parent .dummyItem {
  height:0;
  border-style: none;
}

.mtile{
  width:100%;
  height:100%;
}

.mtiletxt{
  position:relative;
  height:70%;
  margin:10px;
  background-color:#e0e0e0;
  color:#424242;
  border-style:solid;
  border-color:#e0e0e0;
  border-width:1px;
  padding:10px;
  cursor:pointer;
}

.mtiletxt span{
  font-size:18px;
  font-weight:400;
}

.mtiletxt small{
  font-size:85%;
  font-weight:400;
  position:absolute;
  right:15px;
  bottom:10px;
  color:#bdbdbd;
}

.mtiletxt:hover{
  background-color: #ffffff;
  transition: background-color 0.4s;
}

</style>


<!-- Dialog  Masks -->
<style>
div.SearchInp{
  padding:5px;
  background-color: #f0f0f0;
  line-height:25px;
}
input#SearchInp{
  width:90%
}
div.SearchLabel{
  padding:5px;
  line-height:25px;
  background-color: #f0f0f0;
}
div#SearchContainer{
  height:100%;
  border-top:1px solid black
}
div#SearchResult{
  height:inherit;
  overflow-x:hidden;
  overflow-y:scroll;
}

</style>






<style>
.nodeMethodCall{
  cursor:pointer;
}
.nodeMethods{
  list-style: none;
   margin:0px;
}
.nodeMethods li {
}
.nodeMethods li span div{
   margin-right:4px;
}
</style>

<style>
#HtmlExploreDetail{
   margin:2px;
   font-family: "Segoe UI",Tahoma,"Helvetica Neue",Helvetica,Arial,sans-serif;
   border-style:solid;
   border-width:1px;
   border-color:black;
   margin-top:0px;
   border-top-width:0px;
   padding-top-width:0px;
   overflow-x:hidden;
   overflow-y:scroll;
}
.ExploreOutput .Record {
   margin:2px;
   margin-top:0px;
}
.ExploreOutput .Record .FieldLabel{
   background-color:#efefef;
   font-weight:700;
}
.ExploreOutput .Record .FieldValue{
   background-color:#cfcfcf;
}

</style>



<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<title>W5Explore - preBETA!</title>
</head><body><div id='main'></div>
<script language="JavaScript" src="../../../public/base/load/promise.js?5">
</script>
<script language="JavaScript" src="../../../auth/base/load/J5Base.js">
</script>
<script language="JavaScript" src="../../../public/base/load/spin.js">
</script>
<script language="JavaScript" src="../../../public/base/load/datadumper.js">
</script>
<script language="JavaScript" src="../../../public/base/load/vis.min.js">
</script>
<script language="JavaScript" src="../../../public/base/load/jquery.ellipsis.js">
</script>

<script langauge="JavaScript">






Object.defineProperty(Object.prototype, "extend", { 
    value: function(obj) {
        if (obj){
           for (var i in obj) {
              if (obj.hasOwnProperty(i)) {
                 this[i] = obj[i];
              }
           }
        }
        return(this);
    },
    enumerable : false
});










// #######################################################################

var ClassDataObjLib=new Object();
var ClassAppletLib=new Object();

// Top Class for all DataObjs
(function(window, document, undefined) {

   ClassDataObj=function(app){
      this.app=app;
   };
   ClassDataObj.prototype.update=function(o){
      o.id=this.id;
      this.parentNodeDataSet.update(o);
   };

   ClassApplet=function(app){
      this.app=app;
      console.log("top constructor ClassApplet");
   };
   ClassApplet.prototype.run=function(){
      alert("no run() defined in this Applet");
   };
   ClassApplet.prototype.exit=function(){
      this.app.setMPath();
      // maybe cleanup old objects
   };

})(this,document);


//////////////////////////////////////////////////////////////////////////
// Main Application Class

var W5ExploreClass=function(){
   this.console=new Object();
   this.runingApplet=new Object();
   this._opStack=new Array();

   this.spinnerOpts={
        lines: 13 // The number of lines to draw
      , length: 28 // The length of each line
      , width: 8 // The line thickness
      , radius: 22 // The radius of the inner circle
      , scale: 1 // Scales overall size of the spinner
      , corners: 1 // Corner roundness (0..1)
      , color: '#000' // #rgb or #rrggbb or array of colors
      , opacity: 0.25 // Opacity of the lines
      , rotate: 0 // The rotation offset
      , direction: 1 // 1: clockwise, -1: counterclockwise
      , speed: 1 // Rounds per second
      , trail: 60 // Afterglow percentage
      , fps: 20 // Frames per second when using setTimeout() 
      , zIndex: 2e9 // The z-index (defaults to 2000000000)
      , className: 'spinner' // The CSS class to assign to the spinner
      , top: '50%' // Top position relative to parent
      , left: '50%' // Left position relative to parent
      , shadow: false // Whether to render a shadow
      , hwaccel: false // Whether to use hardware acceleration
      , position: 'relative' // Element positioning
      , id:'spinner'
   };

   this.InitObjectStore=function(){
      this.node = new vis.DataSet();
      this.edge = new vis.DataSet();
   };
   this.toObjKey=function(dataobj,id){
      return(dataobj+'::'+id);
   };
   this.ResizeLayout=function(level2){
      if (!level2){
         var app=this;
         this.main && $(this.main).height(1);
         this.workspace && $(this.workspace).height(1);
         this.netmap && $(this.netmap).height(1);
         this.netmap && $(this.netmap).width(1);
         this.dbrec && $(this.dbrec).height(1);
        // setTimeout(function(){app.ResizeLayout(1);}, 1);
      }
      if (!level2){
         $(this.main).outerHeight(
             $(window).innerHeight());
         if (this.console.div){
            $(this.workspace).outerHeight(
              $(this.main).innerHeight()-
              $(this.console.div).outerHeight()-
              $(this.mpathline).outerHeight());
         }
         else{
            $(this.workspace).outerHeight(
              $(this.main).innerHeight()-
              $(this.mpathline).outerHeight()-5);
         }
         if (this.netmap){
            $(this.netmap).outerHeight(
                $(this.workspace).innerHeight());
         }
         if (this.dbrec){
            $(this.dbrec).outerHeight(
                $(this.workspace).innerHeight());
         }
         if (this.netmap){
            $(this.netmap).outerWidth(
                $(this.workspace).innerWidth()-
                $(this.dbrec).outerWidth()-5);
         }
      }
   };

   this.LayoutBase=function(){
      this.main = document.getElementById('main');
      this.main.innerHTML = '';

      //if (!this.mpathline){   // ensure existing mpathline to be not destroyed
         this.mpathline = document.createElement('div');
         this.mpathline.id = 'mpath';
         $(this.mpathline).addClass("TitleBar");

         var mfirst = document.createElement('div');
         mfirst.id='mpathfirst';
         if (window.name=='msel'){      //in this case, 
            mfirst.innerHTML="\u2756";  // i in fullwindow with title mode
            $(mfirst).css("cursor","pointer");
            $(mfirst).click(function(){
               window.location="../menu/msel";
            });
         }
         else{
            mfirst.innerHTML="\u2756";
         }
         this.mpathline.appendChild(mfirst);

         this.mpath = document.createElement('ul');
         $(this.mpath).addClass("TitleBar-arrows");
         this.mpathline.appendChild(this.mpath);
      //}
      this.main.appendChild(this.mpathline);

      this.workspace = document.createElement('div');
      this.workspace.id = 'workspace';
      this.main.appendChild(this.workspace);
      this.spinner = new Spinner(W5Explore.spinnerOpts).spin(this.main);
   };

   this.LayoutMenuLayer=function(){
      this.LayoutBase();
      this.ResizeLayout();
   };
   this.LayoutNetworkMap=function(){
      this.LayoutBase();
      this.netmap = document.createElement('div');
      this.netmap.id = 'netmap';
      this.workspace.appendChild(this.netmap);
      this.netmap.innerHTML = 'netmap';

      this.dbrec = document.createElement('div');
      this.dbrec.id = 'dbrec';
      this.workspace.appendChild(this.dbrec);
      this.showDefaultDBRec();

      this.console.div = document.createElement('div');
      this.console.div.id = 'cons';
      this.console.div.innerHTML = '';
      this.main.appendChild(this.console.div);
      this.ResizeLayout();
      $.fn.disableSelection = function() {
          return this
                   .attr('unselectable', 'on')
                   .css('user-select', 'none')
                   .on('selectstart', false);
      };
   };

   this.setMPath=function(){
      var app=this;
      var url=document.location.href;
      url=url.replace(/\/Explore\/Main.*$/,"/Explore/Main");

      this.mpath.innerHTML = '';
      var m = document.createElement('li');
      m.innerHTML="<a href='"+url+"' class=TitleBarLink>Explore</a>";
      $(m).find("a").click(function(e){
         app.MainMenu(); 
         e.preventDefault();
      });
      $(this.mpath).append(m);
      var paramstack=new Array();
      var appletname;
      console.log("this.setMPath setMPath()",arguments);
      if (arguments){
         for(mi=0;mi<arguments.length;mi++){

            url+="/";
            url+=arguments[mi].mtag;
            var m = document.createElement('li');
            m.innerHTML="<a href='"+url+"' class=TitleBarLink>"+
                        arguments[mi].label+"</a>";
            if (mi==0){
               appletname=arguments[mi].mtag;
               $(m).find("a").click(function(e){
                  app.LayoutMenuLayer();
                  app.showAppletList();
                  app.runApplet(appletname);
                  e.preventDefault();
               });
            }
            else{
               paramstack=arguments[mi].mtag.split('/');


               $(m).find("a").click(function(e){
console.log("start applet with param stack=",appletname,paramstack);
                  app.runApplet(appletname,paramstack);
                  e.preventDefault();
               });
            }
            $(this.mpath).append(m);
         }
      }
      window.history.pushState("objectstring", "Applet",url);
   };

   this.Init=function(){
      this.InitObjectStore();
      this.LayoutMenuLayer();
   };

   this.loadDataObjClass=function(dataobj){
      var dataobjpath=dataobj.replace('::','/');
      if (ClassDataObjLib[dataobj]){
         return(Promise.resolve(ClassDataObjLib[dataobj]));
      }
      else{
          ClassDataObjLib[dataobj]=new Promise(function(res,rej){
                   $.getScript("../../"+dataobjpath+"/jsExplore", 
                   function( data, textStatus, jqxhr ) {
                      console.log(dataobj+" is initial loaded",ClassDataObjLib);
                      res(ClassDataObjLib[dataobj]);
                   }).fail(function(e,parseerror){
                      console.log("e=",e,"parseerror=",parseerror);
                      rej("ERROR: can not resolv dataobj "+dataobj);
                   });
             })
         return(ClassDataObjLib[dataobj]);
      }
   };

   this.loadApplets=function(){
      return(
          new Promise(function(res,rej){
                $.getScript("jsApplets", 
                function( data, textStatus, jqxhr ) {
                   console.log("Applets is loaded");
                   res(1);
                }).fail(function(e,parseerror){
                   if (e.readyState==0){
                      alert("fail to load script");
                   }
                   else{
                      alert("script parse error "+parseerror);
                   }
                   console.log("fail",e);
                   rej(e);
                });
          })
       );
   };

   this.loadAppletClass=function(applet){
      if (ClassAppletLib[applet].class){
         console.log("load applet "+applet+" from cache");
         return(Promise.resolve(ClassAppletLib[applet].class));
      }
      $(".spinner").show();
      return(
         new Promise(function(res,rej){
               $.getScript("jsApplets/"+applet, 
               function( data, textStatus, jqxhr ) {
                  console.log("Applets code is loaded");
        //          $(".spinner").hide();
                  res(ClassAppletLib[applet].class);
               }).fail(function(e,parseerror){
                  console.log("fail",e);
                  rej(e);
               });
         })
      );
   };

   this.runApplet=function(applet,paramstack){
      var app=this;
      app.activeApplet=applet;
      if (app.runingApplet[applet]){
         if (paramstack){
            app.runingApplet[applet].run(paramstack);
         }
         else{
            app.runingApplet[applet].run();
         }
         // $(".spinner").hide(); # hide needs to be done from applet
      }
      else{
         W5Explore.loadAppletClass(applet).then(function(AppletClassPrototype){
            app.runingApplet[applet]=new AppletClassPrototype(app);
            if (paramstack){
               app.runingApplet[applet].run(paramstack);
            }
            else{
               app.runingApplet[applet].run();
            }
           // $(".spinner").hide(); # hide needs to be done from applet
         }).catch(function(e){
            $(".spinner").hide();
            alert("Applet "+applet+" execution error.");
         });
      }
      app.setMPath({ label:ClassAppletLib[applet].desc.label, mtag:applet });

   };

   this.pushOpStack=function(promiseObject){
      this._opStack.push(promiseObject);
   };

   this.processOpStack=function(finish,preloadResult){
      var app=this;
      var result=new Array();
      if (preloadResult){
         result=result.concat(preloadResult);
      }

      this._opStack.reduce(function(promiseChain, currentTask,i){
          app._opStack.splice(i,1);
          return(promiseChain.then(function(chainResults){
              if (!currentTask.then){
                 currentTask=new Promise(currentTask);
              }
              return(currentTask.then(function(currentResult){
                  var l=chainResults;
                  l.push(currentResult);
                  return(l);
              }))
          }));
      }, Promise.resolve([])).then(function(data){
         result=result.concat(data);
         app.networkFitRequest=true;
         if (app._opStack.length){
            app.processOpStack(finish,result);
         }
         else{
            finish(result)
         }
       });
   };


   this.addNode=function(dataobj,id,initialLabel,nodeTempl){
      this.pushOpStack(
          new Promise(function(res,rej){
              W5Explore.loadDataObjClass(dataobj).then(
                 function(DataObjClassPrototype){
                    var o=new DataObjClassPrototype(id,initialLabel,nodeTempl);
                    //var curobj=W5Explore.node._data[o.id];
                    var curobj=W5Explore.node.get(o.id);
                    if (!curobj){
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

   this.genenericLoadNode=function(dataobj,idfield,labelfield,filter,
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



   this.addEdge=function(fromid,toid,edgeTempl){
      this.pushOpStack(
          new Promise(function(res,rej){
             var edgeid=fromid+"::"+toid;
             var cur=W5Explore.edge.get(edgeid);
             if (edgeTempl && edgeTempl.noAcross){
                if (!cur){
                   var edgeid=toid+"::"+fromid;
                   cur=W5Explore.edge.get(edgeid);
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

   function displayTime() {
       var str = "";

       var currentTime = new Date()
       var hours = currentTime.getHours()
       var minutes = currentTime.getMinutes()
       var seconds = currentTime.getSeconds()

       if (minutes < 10) {
           minutes = "0" + minutes
       }
       if (seconds < 10) {
           seconds = "0" + seconds
       }
       str += hours + ":" + minutes + ":" + seconds + " ";
       return str;
   }


   this.console.log=function(level,text){
      var currentdate = new Date(); 
      var datetime =  displayTime();
      if (this.div){
         var curConsVal=this.div.innerHTML.split("\n");
         var maxcons=10;
         if (curConsVal.length>=maxcons){
            curConsVal=curConsVal.splice(maxcons*-1);
            this.div.innerHTML=curConsVal.join("\n");
         }
         var color="<font>";
         if (level=="ERROR"){
            color="<red>";
         }
         var line=datetime+" "+color+level+": "+text+"</font><br>\n";
         line=line.replace(' ','&nbsp;');
         line=line.replace('<red>','<font color=red>');
         this.div.innerHTML+=line;
         $(this.div).scrollTop($(this.div).prop("scrollHeight"));
      }
      else{
         console.log("W5Explore",level,text);
      }
   };


   this.Config=function(){
      return(
         new Promise(function(ok,error){
            if (!this._Config){
               this._Config=createConfig({
                  useUTF8:false,
                  mode:'auth',
                  transfer:'JSON',baseUrl:'../../../'
               });
            }
            ok(this._Config);
         })
      )
   };

   this.createItemSelectors=function(out,selectedNodes){
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
   this.findItem=function(v){
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


   this.globalFunctions=function(){
       var app=this;
       var gdiv=document.createElement('div');

       var switches=$("<div class='cssswitches'></div>");

       $(switches).append("<div class='cssicon cssswitch application_key' "+
                          "id='ControlSwitchDebugConsole' "+
                          "title='Switch debug console'></div>");

       $(switches).find(".cssswitch").click(function(){
          console.log("click on ",this);
          var id=$(this).attr("id");
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
          }
          $(this).toggleClass('on');
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
   this.showDefaultDBRec=function(){
      //var out="<p>Add Object:<br><select><option>A</option><option>B</option></select><input type=text><br>xxxxhier k�nnte z.B. eine Suchmaske f�r das hinzuf�gen "+
      //        "von beliebigen Items stehen</p>";
      $(dbrec).html(""); 
      $(dbrec).append($(this.globalFunctions())); 
      //$(dbrec).append($(out)); 
   };

   this.resetItemSelection=function(){
      this.network.unselectAll();
      this.showDefaultDBRec();
   };

   this.ShowNetworkMap=function(MapParamTempl){
      var app=this;
      app.networkFitRequest=true;
      this.LayoutNetworkMap();
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
          multiselect: true
        },
        nodes: {
          color:{
             background:'#ffff00'
          },
          level:1
        }
      };
      var usephysicsonce=false;
      if (MapParamTempl.physics && MapParamTempl.physics.enabled=="once"){
         usephysicsonce=true;
         MapParamTempl.physics.enabled=true; 
      }
      $.extend(options,MapParamTempl);
      this.network = new vis.Network(this.netmap, data, options);
      this.network.on("stabilized", function () {
         if ($(".spinner").is(":visible")){
            $(".spinner").hide();
         }
         if (app.networkFitRequest){
            app.network.fit({
               animation: true
            });
            app.networkFitRequest=false;
            app.console.log("INFO","autolayout done");
         }
         if (usephysicsonce){
            this.setOptions( { physics: false } );
         }
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
                
                $(out).append($("<div id=HtmlExploreDetail style='display:none'></div>"));
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
                var methodName=$(this).attr("data-id");
                for(n=0;n<selectedNodes.length;n++){
                   var nodeobj=app.node.get(selectedNodes[n]);
                   nodeobj.nodeMethods[methodName].exec.call(nodeobj);
                }
                app.processOpStack(function(resultOfOpStack){
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
             $(dbrec).append($(app.globalFunctions())); 
             $(dbrec).append($(out)); 
             $(dbrec).append(mdiv); 
             if (selectedNodes.length==1){
                $.ajax({
                   type:'GET',
                   url:path,
                   beforeSend:function(){
                   },
                   success:function(data){
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

   this.SampleMap=function(){
      this.LayoutNetworkMap();
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
        nodes: {
          font: {
            face: "arial",
            bold: {
              color: '#0077aa'
            }
          }
        },
        layout: {
           hierarchical: {
             sortMethod: 'directed'
           }
         },
        physics: {
          enabled: false
        }
      };
      this.network = new vis.Network(this.netmap, data, options);
//  network.once("beforeDrawing", function() {
//      network.focus(2, {
//        scale: 12
//      });
//    });
    


      this.network.on("click", function (params) {
          //params.event = "[original event]";
          if (params.nodes[0]){
             dbrec.innerHTML = '<h2>Click event: on '+params.nodes[0]+
                               '</h2><xmp>' + JSON.stringify(params, null, 4)+
                               "</xmp>";
          }
          else{
             dbrec.innerHTML='';
          }
      });
   };

   this.showDialog=function(genContent,exitCode){
      var modal=document.createElement('div');
      $(modal).id='myModal';
      $(modal).addClass('modal-background');
      var modalframe=document.createElement('div');
      $(modalframe).addClass('modal-content');
      $(modalframe).append("<span class='closebtn'>&times;</span>");
      $(modalframe).append(genContent());
      $(modal).append(modalframe);
      $(this.workspace).append(modal);
      $(".closebtn").click(function(){
         $(modal).remove();
         exitCode();
      }); 
      $(modal).show();
      $(modalframe).find("input:text:visible:first").focus();
   }



   this.showW5ExploreLogo=function(){
      var app=this;
      $("#workspace").html("<br><br><center><h1>W5Explore</h1></center>");
   }

   this.showAppletList=function(){
      var app=this;
      $("#workspace").html("");
      var p=document.createElement('div');
      $(p).addClass("parent");
      $(this.workspace).append(p);
      var appletKey=Object.keys(ClassAppletLib);
      var appletCnt=appletKey.length;
      for(var c=0;c<appletCnt;c++){
         var k=appletKey[c];
         var e=document.createElement('div');
         $(e).addClass("item");
         var tile=document.createElement('div');
         $(tile).attr("data-id",k);
         $(tile).addClass("mtile");
         $(tile).click(function(e){
             var applet=$(this).attr("data-id");
             app.runApplet(applet);
         });
         var m=document.createElement('div');
         $(m).addClass("mtiletxt");
         var htmltext="<span>"+ClassAppletLib[k].desc.label+"</span>";
         htmltext+="<p>"+ClassAppletLib[k].desc.description+"</p>";
         htmltext+="<small>"+ClassAppletLib[k].desc.sublabel+"</small>";
         $(m).html(htmltext);
         tile.appendChild(m);
         e.appendChild(tile);
         p.appendChild(e);
      }
      for(var c=0;c<appletCnt;c++){
         var e=document.createElement('div');
         $(e).addClass("dummyItem");
         p.appendChild(e);
      }
   }



   this.MainMenu=function(runpath){
      var app=this;
      this.LayoutMenuLayer();
      this.loadApplets().then(function(){
         if (runpath==undefined || runpath.length==0){
            app.showAppletList();
            console.log("reset setMPath()");
            app.setMPath();
            $(".spinner").hide();
         }
         else{
            app.showW5ExploreLogo();
            $(".spinner").show();
            var applet=runpath.shift();
            app.loadAppletClass(applet).then(function(AppletClassPrototype){
               if (runpath.length==0){
                  app.runApplet(applet);
               }
               else{
                  app.runApplet(applet,runpath);
               }
            }).catch(function(e){
               $(".spinner").hide();
               alert("Applet "+applet+" execution error.");
            });
         }
      }).catch(function(e){
         $(".spinner").hide();
         console.log("e=",e);
         $("#workspace").html("not OK");
      });
   }
};





var W5Explore=new W5ExploreClass();
W5Explore.Init();

$(window).resize(function() {
   W5Explore.ResizeLayout();
});


var runurl=document.location.href;
runurl=runurl.replace(/^.*\/Explore\/Main[\/]{0,1}/,"");
runurl=runurl.replace(/\?.*$/,""); // remove query parameters
var runpath=runurl.split("/").filter(function(e){if (e==""){return(false)}else{return(true)}});
//console.log("runurl=",runurl,"runpath=",runpath,"n=",runpath.length);

W5Explore.MainMenu(runpath);


</script>
</body>



</html>