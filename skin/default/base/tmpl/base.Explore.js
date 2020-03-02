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
<link rel="stylesheet" href="../../../public/base/load/vis-network.min.css">


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
   padding:0;
   display:table;
   width:100%;
   border-bottom:1px solid silver;
}

.cssswitchrow{
   display:table-row;
}
.cssswitchcell{
   display:table-cell;
   width:10%;
}
.cssswitch{
   margin:2px;
   cursor:pointer;
   border: 1px solid white;
   border-bottom: 4px solid white;
}

.cssswitchdisabled{
   cursor:not-allowed;
   opacity: 0.4;
   filter: alpha(opacity=40); /* msie */
}

.on{
   border-bottom: 4px solid #35ad53;
}

.cssswitch:hover{
   border-left: 1px solid gray;
   border-right: 1px solid gray;
   border-top: 1px solid gray;
}

.cssswitchdisabled:hover{
   border: 1px solid white;
   border-bottom: 4px solid white;
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
 overflow:hidden;  /* sollte das Wrap Problem lösen */
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
 margin:0px;
 width:inherit;
 padding:0px;
 float:left;
 overflow:auto;
}

#ctrl{
 border-left-style:solid;
 border-left-color:black;
 border-left-width:2px;

 margin:0px;
 padding:0px;
 width:280px;
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

@media print {
   body{
      border:none;
      overflow:visible;
      width:1754px;
      height:1150px;
   }
   #main{
      border:none;
      overflow:visible;
      width:1754px;
      height:1150px;
   }
   #workspace{
      border:none;
      overflow:visible;
      width:1754px;
      height:1150px;
   }
   #netmap{
      border:none;
      overflow:visible;
      width:1754px;
      height:1150px;
   }
   #ctrl{
      display:none;
   }
   #cons{
      display:none;
   }
   #dbrec{
      display:none;
   }
   #mpath{
      display:none;
   }
}

</style>

<!-- Startup box -->
<style>

#W5ExploreLogo{
   display:none;
   position:absolute;
   height:40%;
   max-height:250px;
   width:40%;
   max-width:408px;
   background:#f9f9f9;
   border:10px outset #cecece;
   z-index:2;
   padding:12px;
   font-size:13px;
   left: 50%;
   top: 50%;
   transform: translate(-50%,-50%);
   box-shadow: inset 0px 0px 0px 1px black;
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
    height: 50%;
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
  -webkit-touch-callout: none; 
    -webkit-user-select: none; 
     -khtml-user-select: none;
       -moz-user-select: none; 
        -ms-user-select: none; 
            user-select: none; 
}

.mtiletxt span{
  font-size:18px;
  font-weight:400;
  -webkit-touch-callout: none; 
    -webkit-user-select: none; 
     -khtml-user-select: none;
       -moz-user-select: none; 
        -ms-user-select: none; 
            user-select: none; 
}

.mtiletxt small{
  font-size:85%;
  font-weight:400;
  position:absolute;
  right:15px;
  bottom:10px;
  color:#bdbdbd;
  -webkit-touch-callout: none; 
    -webkit-user-select: none; 
     -khtml-user-select: none;
       -moz-user-select: none; 
        -ms-user-select: none; 
            user-select: none; 
}

.mtiletxt:hover{
  background-color: #ffffff;
  transition: background-color 0.4s;
}

.mtileChose {
  color: #fff;
  background-color: gray;
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
  width:95%
}
div.SearchLabel,div.FieldLabel,div.FieldData{
  padding:5px;
  line-height:25px;
  background-color: #f0f0f0;
}
div#SearchContainer{
  margin-top:2px;
  padding-top:2px;
  border-top:1px solid black
}
div#SearchResult{
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
#HtmlExploreSpinner{
   text-align:center;
   margin:2px;
}
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

.SubListExplore td {
   background-color:silver;
}
.SubListExploreClick{
   width:15px;
   height:15px;
   transform: scale(0.6);
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
<script language="JavaScript" src="../../../public/base/load/Sortable.js">
</script>
<script language="JavaScript" src="../../../public/base/load/spin.js">
</script>
<script language="JavaScript" src="../../../public/base/load/jquery.ellipsis.js">
</script>
<script language="JavaScript" src="../../../public/base/load/require.js"></script>

<script langauge="JavaScript">

requirejs.onError = function (err) {
    console.log("genrell Erro:",err.requireType);
    if (err.requireType === 'timeout') {
        console.log('modules: ' + err.requireModules);
    }
    throw err;
};

requirejs.config({
   baseUrl:"../../",
   paths: {
        app: '../app',
        J5Base: '../auth/base/load/J5Base',
        'jquery': '../auth/base/load/jquery',
        'jquery.flot': '../auth/base/load/jquery.flot',
        'jquery.flot.pie': '../auth/base/load/jquery.flot.pie',
        'jquery.dataTables': '../auth/base/load/jquery.dataTables',
        ellipsis: '../public/base/load/jquery.ellipsis',
        datadumper: '../public/base/load/datadumper',
        visjs: '../public/base/load/vis.min'
   },
   shim: {
        'jquery.flot': {
               exports: '$.plot'
        },
        'jquery.flot.pie': {
               deps: ['jquery.flot']
        }
   },
});







//Object.defineProperty(Object.prototype, "extend", { 
//    value: function(obj) {
//        if (obj){
//           for (var i in obj) {
//              if (obj.hasOwnProperty(i)) {
//                 this[i] = obj[i];
//              }
//           }
//        }
//        return(this);
//    },
//    enumerable : false
//});










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

   //this.InitObjectStore=function(){
   //  // this.node = new vis.DataSet();
   //  // this.edge = new vis.DataSet();
   //   this.node = new Object();
   //   this.edge = new Object();
   //};
   this.toObjKey=function(dataobj,id){
      return(dataobj+'::'+id);
   };
   this.loadCss=function (url) {
      var loadurl="../../../"+url;
      var found=0;
      $('link').each(function () {
         if ($(this).attr("href")==loadurl){
            found=1;
         }
      });
      if (!found){
         var link = document.createElement("link");
         link.type = "text/css";
         link.rel = "stylesheet";
         link.href = loadurl;
         document.getElementsByTagName("head")[0].appendChild(link);
         console.log("loadCss loaded ",loadurl);
      }
      else{
         console.log("loadCss already loaded ",loadurl);
      }
   }
   this.ResizeLayout=function(level2){
      if (!level2){
         var app=this;
         this.main && $(this.main).height(1);
         this.workspace && $(this.workspace).height(1);
         this.netmap && $(this.netmap).height(1);
         this.netmap && $(this.netmap).width(1);
         this.dbrec && $(this.dbrec).height(1);
         this.ctrl && $(this.ctrl).height(1);
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
         if (this.ctrl){
            $(this.ctrl).outerHeight(
                $(this.workspace).innerHeight());
         }
         if (this.dbrec){
            $(this.dbrec).outerHeight(
                $(this.ctrl).innerHeight()-
                $(this.ctrlbar).outerHeight()-5);
         }
         if (this.netmap){
            $(this.netmap).outerWidth(
                $(this.workspace).innerWidth()-
                $(this.ctrl).outerWidth()-5);
         }
         $('.modal-content  div').first().trigger('resize');
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
      if (!this.main ||  $(this.main).attr("data-layout")!="MenuLayer"){
         this.LayoutBase();
         this.ResizeLayout();
         $(this.main).attr("data-layout","MenuLayer");
      }
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
      this.LayoutMenuLayer();
   };

   this.LayoutSimple=function(){
      if (!this.main ||  $(this.main).attr("data-layout")!="Simple"){
         this.LayoutBase();
         this.ResizeLayout();
         $.fn.disableSelection = function() {
             return this
                      .attr('unselectable', 'on')
                      .css('user-select', 'none')
                      .on('selectstart', false);
         };
         $(this.main).attr("data-layout","Simple");
      }
   };


   this.genenericLoadRecord=function(dataobj,view,filter,reccallback,okcallback){
      var app=this;
      this.pushOpStack(
        new Promise(function(ok,reject){
           app.Config().then(function(cfg){
              var w5obj=getModuleObject(cfg,dataobj);
                w5obj.SetFilter(filter);
                w5obj.findRecord(view, function(data){
                   reccallback(data);
                   ok("genenericLoadRecord");
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


   this.loadDataObjClass=function(dataobj){
      var dataobjpath=dataobj.replace('::','/');
      if (ClassDataObjLib[dataobj]){
         return(Promise.resolve(ClassDataObjLib[dataobj]));
      }
      else{
          ClassDataObjLib[dataobj]=new Promise(function(res,rej){
                require([dataobjpath+"/jsExplore"],
                   function() {
                      console.log(dataobj+" is initial loaded",ClassDataObjLib);
                      res(ClassDataObjLib[dataobj]);
                   },function(e){
                      console.log("e=",e);
                      rej("ERROR: can not resolv dataobj "+dataobj);
                });
             })
         return(ClassDataObjLib[dataobj]);
      }
   };

   this.loadApplets=function(){
      return(
          new Promise(function(res,rej){
             require(["base/Explore/jsApplets"], 
                function() {
                   console.log("Applets is loaded");
                   res(1);
                },function(error){
                   alert("script parse error "+error);
                   console.log("fail",error);
                   rej(e);
                }
             );
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
            require(["jsApplets/"+applet], 
               function(o) {
                  console.log("Applets code is loaded",o);
                  res(ClassAppletLib[applet].class);
               },function(e){
                  console.log("fail",e);
                  rej(e);
               }
            );
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
            setTimeout(function(){$("#W5ExploreLogo").fadeOut(1500);},2000);
           // $(".spinner").hide(); # hide needs to be done from applet
         }).catch(function(e){
            $(".spinner").hide();
            throw e;
            //alert("Applet "+applet+" execution error.");
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
         if (app._opStack.length){
            app.processOpStack(finish,result);
         }
         else{
            finish(result)
         }
       });
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

   this.showDialog=function(genContent,exitCode){
      var modal=document.createElement('div');
      $(modal).id='myModal';
      $(modal).addClass('modal-dialog');
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
      $(".spinner").hide();
      $(modal).show();
      $(modal).on('resize',function(e){
         e.stopPropagation();
      });
      $('.modal-content  div').first().trigger('resize');
      $(modalframe).find("input:text:visible:first").focus();
   }



   this.showW5ExploreLogo=function(applet){
      var app=this;
      var box=document.createElement('div');
      box.id="W5ExploreLogo";
      $(box).append($("<center><h1>W5Explore</h1></center>"));
      if (applet!=""){
         $(box).append($("<center><h2>Starting applet "+applet+"</h2></center>"));
      }
      else{
         $(box).append($("<center><h2>Data Explorer Main</h2></center>"));
      }
      $(box).append($("<div style='margin-top:140px'>... you are "+
                      "booting the hidden feature code "+
                      "W5Explore. Not warenty and no support! "+
                      "Use at your own risk.</div>"));
      $("body").append(box);
      $("body").find("#W5ExploreLogo").fadeIn();


      //$("#workspace").html("<br><br><center><h1>W5Explore</h1></center>");
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

      app.MainSortable = new Sortable(p, {
         delay: 0, 
         store: null,  // @see Store
         animation: 850,  // ms, animation speed moving items
         handle: ".parent",  // Drag handle selector within list items
         draggable: ".item", 
         chosenClass: "mtileChose",
         filter: ".dummyItem",
         dataIdAttr: 'data-id',
         touchStartThreshold: 3,
         forceFallback: true,      // needed for ieEdge mode
         store: {
            get: function (sortable) {
               var order = localStorage.getItem(sortable.options.group.name);
               var a=order ? order.split('|') : [];
               //console.log("get:",a);
               return(a);
            },
            set: function (s) {
               var order = s.toArray();
               var a=order.join('|');
               //console.log("set:",a);
              localStorage.setItem(s.options.group.name,a);
            }
       }
      });

   }



   this.MainMenu=function(runpath){
      var app=this;
      this.LayoutMenuLayer();
      if (runpath!=undefined){
         app.showW5ExploreLogo("");
      }
      this.loadApplets().then(function(){
         if (runpath==undefined || runpath.length==0){
            app.showAppletList();
            //console.log("reset setMPath()");
            app.setMPath();
            $(".spinner").hide();
            setTimeout(function(){$("#W5ExploreLogo").fadeOut(1500);},2000);
         }
         else{
            var applet=runpath.shift();
            app.showW5ExploreLogo(applet);
            $(".spinner").show();
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
