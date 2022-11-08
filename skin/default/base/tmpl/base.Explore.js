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
    overflow: hidden; 
    background-color: rgb(0,0,0); /* Fallback color */
    background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}

.modal-content {
    background-color: #fefefe;
    margin: 5% auto; /* 15% from the top and centered */
    padding: 20px;
    padding-top: 5px;
    border: 1px solid #888;
    overflow:hidden;
    width: 80%; 
    height: 70%;
    min-width:600px;
    xmin-height:400px;
    position:relative; // to allow absolute enties
}

.modal-content #title{
   font-size:18px;
   font-weight:700;
   padding-right:80px;
   overflow:hidden;
   padding-top:15px;
   padding-bottom:15px;
}
.modal-content #content{
   overflow-y:auto;
   overflow-x:hidden;
}
.modal-content #control{
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

.mtiletxt div.visi{
  position:absolute;
  left:15px;
  bottom:10px;
  width:20px;
  height:20px;
  cursor:pointer;
  background:url(../../../public/base/load/visibility_empty.gif)  no-repeat;
  background-size: 20px 20px;
}

.mtiletxt div.vision{
  position:absolute;
  left:15px;
  bottom:10px;
  width:20px;
  height:20px;
  background:url(../../../public/base/load/visibility_on.gif)  no-repeat;
  background-size: 20px 20px;
}

.mtiletxt div.visioff{
  position:absolute;
  left:15px;
  bottom:10px;
  width:20px;
  height:20px;
  background:url(../../../public/base/load/visibility_off.gif)  no-repeat;
  background-size: 20px 20px;
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
input{
   box-sizing : border-box;
}
textarea{
   box-sizing : border-box;
   resize: vertical;
}
div.SearchLabel,div.FieldLabel,div.FieldData{
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

.ModalForm td{
  background-color: #f0f0f0;
  padding:5px;
  line-height:25px;
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


function wrapText(long_string, max_char) {

  var sumchar_of_words=function(word_array){
    var out=0;
    if (word_array.length!=0){
      for (var i=0; i<word_array.length; i++){
        var word = word_array[i];
        out=out+word.length;
      }
    };
    return out;
  }

  var split_out=[[]];
  var split_string = long_string.split(' ');
  for (var i=0; i<split_string.length; i++){
    var word = split_string[i];
    
    if ((sumchar_of_words(split_out[split_out.length-1])+word.length)>max_char){
      split_out=split_out.concat([[]]);
    }
    
    split_out[split_out.length-1]=split_out[split_out.length-1].concat(word);
  }
  
  for (var i=0;i<split_out.length;i++){
    split_out[i]=split_out[i].join(" ");
  }
  
  return split_out.join('\n');
}


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
        TimeSpans: '../public/base/load/TimeSpans',
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
      //console.log("top constructor ClassApplet");
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
var W5AppletHideController=function(_app){
   this.hiddenApplets=new Array();
   this._fullView=0;
   this.app=_app;

   this.loadHiddenApplets=function(){
      var o=this.app.GetApplicationKeyItem("ExplorerTileHide");
      var a=o ? o.split('|') : [];
      this.hiddenApplets=a;
   };
   this.saveHiddenApplets=function(){
      var a=this.hiddenApplets.join('|');
      this.app.SetApplicationKeyItem("ExplorerTileHide",a);
   }

   this.fullView=function(newMode){
      if (newMode===undefined){
         return(this._fullView);
      }
      this._fullView=newMode;
      return(this._fullView);
   };
   

   this.isAppletVisible=function(k){
      if (this._fullView){
         return(true);
      }
      if (!this.isAppletHidden(k)){
         return(true);
      }
      return(false);
   };
   this.isAppletHidden=function(k){
      if (jQuery.inArray(k,this.hiddenApplets)!=-1){
         return(true);
      }
      return(false);
   };


   this.hideApplet=function(k){
      if (jQuery.inArray(k,this.hiddenApplets)==-1){
         this.hiddenApplets.push(k);
         this.saveHiddenApplets();
      }
   };
   this.showApplet=function(k){
      if (jQuery.inArray(k,this.hiddenApplets)!=-1){
         this.hiddenApplets=$.grep(this.hiddenApplets,function(n,i){
            return(n==k);
         },true);
         this.saveHiddenApplets();
      }
   };
};

var W5ExploreClass=function(){
   this.console=new Object();
   this.runingApplet=new Object();
   this._opStack=new Array();
   this.hideControl=new W5AppletHideController(this);

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
         //console.log("loadCss loaded ",loadurl);
      }
      else{
         //console.log("loadCss already loaded ",loadurl);
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
             $(window).innerHeight()-1);  // -1 prevent scrollbars
         if (this.console.div){
            $(this.workspace).outerHeight(
              $(this.main).innerHeight()-
              $(this.console.div).outerHeight()-
              $(this.mpathline).outerHeight());
         }
         else{
            $(this.workspace).outerHeight(
              $(this.main).innerHeight()-
              $(this.mpathline).outerHeight()-3);
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
         var showMain=1;
         if (document.location.href.match(/\/Start\//)){
            showMain=0;
         }
         var mfirst = document.createElement('div');
         mfirst.id='mpathfirst';
         if (showMain){
            mfirst.title='ShowAll';
            $(mfirst).css("cursor","pointer");
         }
         var app=this;
         if (showMain){
            $(mfirst).click(function(){
               var mpathentries=$("#mpath_ul_listentries li").length;
               if (mpathentries!=1) return(0);  // show all only on top level
               if (app.hideControl.fullView()){
                  app.hideControl.fullView(0);
               }
               else{
                  app.hideControl.fullView(1);
               }
               app.LayoutMenuLayer();
               app.showAppletList();
            });
         }
         mfirst.innerHTML="\u2756";  // i in fullwindow with title mode
         this.mpathline.appendChild(mfirst);

         this.mpath = document.createElement('ul');
         $(this.mpath).attr("id","mpath_ul_listentries");
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
      var wintitle=new Array();
      var showMain=1;
      if (url.match(/\/Start\//)){
         showMain=0;
      }
      url=url.replace(/\/Explore\/Main.*$/,"/Explore/Main");
      url=url.replace(/\/Explore\/Start.*$/,"/Explore/Start");

      this.mpath.innerHTML = '';
      var m = document.createElement('li');
      if (showMain){
         m.innerHTML="<a href='"+url+"' class=TitleBarLink>W5Explore</a>";
         wintitle.push("W5Explore");
      }
      else{
         m.innerHTML="W5Explore";
         wintitle.push("W5Explore");
      }
      $(m).find("a").click(function(e){
         app.MainMenu(); 
         e.preventDefault();
      });
      $(this.mpath).append(m);
      var paramstack=new Array();
      var appletname;
      //console.trace("setMPath");
      //console.log("this.setMPath setMPath()",arguments);
      if (arguments){
         for(mi=0;mi<arguments.length;mi++){

            url+="/";
            url+=arguments[mi].mtag;
            var m = document.createElement('li');
            m.innerHTML="<a href='"+url+"' class=TitleBarLink>"+
                        arguments[mi].label+"</a>";
            wintitle.push(arguments[mi].label);
            if (mi==0){
               appletname=arguments[mi].mtag;
               if (showMain){
                  $(m).find("a").click(function(e){
                     app.LayoutMenuLayer();
                     app.showAppletList();
                     app.runApplet(appletname);
                     e.preventDefault();
                  });
               }
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
      window.document.title=wintitle.join(" -> ");
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
                   //console.log("Applets is loaded");
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
         // console.log("load applet "+applet+" from cache");
         return(Promise.resolve(ClassAppletLib[applet].class));
      }
      $(".spinner").show();
      return(
         new Promise(function(res,rej){
            require(["jsApplets/"+applet], 
               function(o) {
                  //console.log("Applets code is loaded",o);
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
            return;
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
      $(modal).prop('id','myModal');
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
         var hc=$("#myModal div#content").outerHeight();
         var hm=$("#myModal .modal-content").height();
         var ht=$("#myModal div#title").outerHeight();
         var hs=$("#myModal div#control").outerHeight();
         if (hm && hc){
            var controlh=hm;
            if (ht){
               controlh-=ht;
            }
            if (hs){
               controlh-=hs;
            }
            $("#myModal div#content").height(controlh);
         }
         e.stopPropagation();
      });
      $('.modal-content  div').first().trigger('resize');
      $(modalframe).find("input:text:visible:first").focus();
   }

   this.closeDialog=function(){
      $('#myModal').remove();
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

   this.GetApplicationKeyItem=function(k,callb){// Interface to read pers Varis
      var oString=localStorage.getItem(k);
      var val;
      var loadSync=0;
      var load=0;

      if (oString){
         var o;
         try{
            o=JSON.parse(oString);
         }
         catch(e){
            console.log("parse error",e);
         }
         if (o){
            val=o.value;
            var now=new Date().getTime();
            if (o.timestamp+6000<now){   //refresh after 60sec
               console.log("get Needed for ",k);
               load=1;
               loadSync=1;   // test if sync load makes problems
            }
         }
         else{  // local object is invalid
            load=1;
            loadSync=1;
         }
      }
      else{
         load=1;
         loadSync=1;
      }
      if (load){
         var request={   // der IE bekommt das nicht richtig als POST "gebacken"
            type:'GET',
            url:"../../base/note/Result",
            data:{
               search_name:k,
               search_parentobj:'base::Explore',
               search_parentid:k,
               FormatAs:'nativeJSON',
               T:(new Date().getTime())
            },
            dataType:'json',
            success:function(d){
               var v;
               if (d && d[0]){
                  //console.log("got from server d=",d[0]);
                  v=d[0].comments;
                  var o={value:v,timestamp: new Date().getTime()};
                  localStorage.setItem(k,JSON.stringify(o));
               }
               if (callb){
                  callb(v);
               }
            },
            error:function(e){
               console.log("load Errorerror=",e);
               if (callb){
                  callb();
               }
            }
         };
         if (loadSync){
            request.async=false;
         }
         $.ajax(request);
      }
      else{
         if (callb){
            callb(val);
         }
      }
      return(val);
   };

   this.SetApplicationKeyItem=function(k,v){ // Interface to write pers Variales
      var val=localStorage.getItem(k);
      try{
         val=JSON.parse(val);
      }
      catch(e){
         console.log("parse error",e);
      }
      if (!(val) || val.value!=v){   // send it to server
         //console.log("sending k=v",k,v,"to server curvalue=",val.value);
         var request={
            type:'POST',
            url:"../../base/note/Modify",
            data:JSON.stringify({
               OP:'save',
               Formated_name:k,
               Formated_comments:v,
               Formated_parentobj:'base::Explore',
               Formated_parentid:k
            }),
            dataType:'json',
            contentType:"application/json; charset=utf-8",
            success:function(d){
               console.log("SetApplicationKeyItem server result d=",d);
            },
            error:function(e){
               console.log("error=",e);
            }
         };
         $.ajax(request);
      }
      var o={value:v,timestamp: new Date().getTime()};
      localStorage.setItem(k,JSON.stringify(o));
   };


   this.showAppletList=function(){
      var app=this;  // prepair some readings to ensure K-Varis are current
      var lastuxday=app.GetApplicationKeyItem("ExplorerStart",function(v){
          if (v=="" || v===undefined){
             console.log("HEY - NEW and FIRST Start",v);
          }
          var uxday=(((new Date().getTime())/1000)/(24*60*60)).toFixed(0);
          app.SetApplicationKeyItem("ExplorerStart",uxday);

          app.GetApplicationKeyItem("ExplorerTileHide",function(v){
             app.GetApplicationKeyItem("ExplorerTileOrder",function(v){
                app._showAppletList();
             });
          });
      });
   }


   this._showAppletList=function(){
      var app=this;

      $("#workspace").html("");
      var p=document.createElement('div');
      $(p).addClass("parent");
      $(this.workspace).append(p);
      var appletKey=Object.keys(ClassAppletLib);
      var appletCnt=appletKey.length;
      for(var c=0;c<appletCnt;c++){
         var k=appletKey[c];
         if (app.hideControl.isAppletVisible(k) && 
             (!ClassAppletLib[k].desc.hidden)){
            var e=document.createElement('div');
            $(e).addClass("item");
            var tile=document.createElement('div');
            $(e).attr("data-id",k);
            $(tile).addClass("mtile");
            $(tile).click(function(e){
                var applet=$(this).parent().attr("data-id");
                app.runApplet(applet);
            });
            var m=document.createElement('div');
            $(m).addClass("mtiletxt");
            var htmltext="<span>"+ClassAppletLib[k].desc.label+"</span>";
            htmltext+="<p>"+ClassAppletLib[k].desc.description+"</p>";
            htmltext+="<small>"+ClassAppletLib[k].desc.sublabel+"</small>";
            htmltext+="<div class=visi title=\"switch visibility\"></div>";
            $(m).html(htmltext);
            if (app.hideControl.fullView()){
               if (app.hideControl.isAppletHidden(k)){
                  $(m).find(".visi").addClass("vision");
               }
               else{
                  $(m).find(".visi").addClass("visioff");
               }
            }
            tile.appendChild(m);
            e.appendChild(tile);
            p.appendChild(e);
         }
      }


      $(p).find(".visi").click(function(e){
         var k=$(this).parent().parent().parent().attr("data-id");
         if (app.hideControl.isAppletHidden(k)){
            app.hideControl.showApplet(k);
         }
         else{
            app.hideControl.hideApplet(k);
         }
         if (!app.hideControl.fullView()){
            $(this).parent().parent().parent().remove();
         }
         else{
            $(this).removeClass("vision");
            $(this).removeClass("visioff");
            if (app.hideControl.isAppletHidden(k)){
               $(this).addClass("vision");
            }
            else{
               $(this).addClass("visioff");
            }
         }
         e.preventDefault();
         e.stopPropagation();
         return(true);
      });

      $(p).find(".visi").hover(function(e){
         if (!app.hideControl.fullView()){
            if (app.hideControl.isAppletHidden(k)){
               $(this).addClass("vision");
            }
            else{
               $(this).addClass("visioff");
            }
         }
      },
      function(e){
         if (!app.hideControl.fullView()){
            if (app.hideControl.isAppletHidden(k)){
               $(this).removeClass("vision");
            }
            else{
               $(this).removeClass("visioff");
            }
         }
      });



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
               var order = app.GetApplicationKeyItem("ExplorerTileOrder");
               var a=order ? order.split('|') : [];
               //console.log("get:",a);
               return(a);
            },
            set: function (s) {
               var order = s.toArray();
               var a=order.join('|');
               app.SetApplicationKeyItem("ExplorerTileOrder",a);
            }
       }
      });

   }


   this.MainMenu=function(runpath){
      var app=this;

      this.LayoutMenuLayer();
      this.hideControl.loadHiddenApplets();
      if (runpath!=undefined){
         if (!document.location.href.match(/\/Start\//)){
            app.showW5ExploreLogo("");
         }
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
            console.log("URL:",document.location.href);
            //console.log("runpath:",runpath);
            if (!document.location.href.match(/\/Start\//)){
               app.showW5ExploreLogo(applet);
               $(".spinner").show();
            }
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
runurl=runurl.replace(/^.*\/Explore\/Start[\/]{0,1}/,"");
runurl=runurl.replace(/\?.*$/,""); // remove query parameters
var runpath=runurl.split("/").filter(function(e){if (e==""){return(false)}else{return(true)}});
//console.log("runurl=",runurl,"runpath=",runpath,"n=",runpath.length);

W5Explore.MainMenu(runpath);


</script>
</body>



</html>
