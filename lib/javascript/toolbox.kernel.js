function setwinpos()
{

   if (window.navigator.userAgent.indexOf("MSIE") > -1){
      // nothing
      var x=1;
   }
   else{
      win.moveTo(window.screenX+50,window.screenY+50);
   }
   win.focus();

}


function FakeBasicAuthLogoff(msg){
   alert(msg); 
//   var req = new XMLHttpRequest();
//   req.open("GET","",true);
//   req.setRequestHeader("Authorization", "");
//   req.send();
//   window.setTimeout(function(){
//      top.document.location.href="../../../public/base/menu/logout";
//   },3000);  // 1st try - 3 seconds seems to be ok
   return(false);
}


function getAbsolutY(e)
{
   var y=e.offsetTop;
   if (e.offsetParent){
      return(y+getAbsolutY(e.offsetParent));
   }
   return(y);
}

function jsAddVarToQueryString(q,Vari,Val)
{
  if (q!=""){
     q=q+"&"
  }
  q+=Vari;
  q+="=";
  q+=Val;
  return(q);

}

function getSiteCookie(c_name)
{
   var c_value = " "+document.cookie;
   var c_start = c_value.indexOf(" " + c_name + "=");
   if (c_start == -1){
      c_start = c_value.indexOf(c_name + "=");
   }
   if (c_start == -1){
      c_value = null;
   }
   else{
      c_start = c_value.indexOf("=", c_start) + 1;
      var c_end = c_value.indexOf(";", c_start);
      if (c_end == -1){
         c_end = c_value.length;
      }
      c_value = unescape(c_value.substring(c_start,c_end));
   }
   return c_value;
}

function setCookie(c_name,value,exdays,path)
{
   var exdate=new Date();
   exdate.setDate(exdate.getDate() + exdays);
   var c_value=escape(value) + 
               ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
   if (path!=null && path!=""){ // path seems not working in SSO context
      c_value+="; path="+path;
   }
   document.cookie=c_name + "=" + c_value;
}


function getQueryParams(url){
   var parts = (url||'').split(/[?#]+/);
   var qparts;
   var qpart;
   var i=0;
   var qparams={
      SCRIPT_URI:parts[0],
      QUERY_STRING:parts[1],
      ANKER:parts[2],
      query:{}
   };

   if (parts.length<=1){
      return(qparams);
   }
   else{
      qparts = parts[1].split('&');
      for(i in qparts){
         qpart = qparts[i].split('=');
         var vari=decodeURIComponent(qpart[0]);
         var vali=decodeURIComponent(qpart[1]||'');
         if (!qparams.query[vari]){
         qparams.query[vari]=[vali];
         }
         else{
            qparams.query[vari].push(vali);
         }
      }
   }
   return(qparams);
}

function makeLocationHREF(o){
   var url="";

   url+=o.SCRIPT_URI;
   if (o.QUERY_STRING){
      url+="?";
      url+=o.QUERY_STRING;
   }
   else if (o.query){
      var query_string="";
      for(v in o.query){
         for(var i=0;i<o.query[v].length;i++){
            if (query_string!=""){
               query_string+="&";
            }
            var vari=encodeURIComponent(v);
            var vali=encodeURIComponent(o.query[v][i]);
            query_string+=vari+"="+vali;
         }
      }
      if (query_string!=""){
         url+="?";
         url+=query_string;
      }
   }
   if (o.ANKER){
      url+="#";
      url+=o.ANKER;
   }
   return(url);
}


function hasClass(el, className) {
  if (el.classList){
    return el.classList.contains(className);
  }
  else{
    return !!el.className.match(new RegExp('(\\s|^)' + className + '(\\s|$)'));
  }
}

function addClass(el, className) {
  if (el.classList){
    el.classList.add(className)
  }
  else if (!hasClass(el, className)) el.className+= " "+className;
}

function removeClass(el, className) {
  if (el.classList){
    el.classList.remove(className)
  } else if (hasClass(el, className)) {
    var reg = new RegExp('(\\s|^)' + className + '(\\s|$)')
    el.className=el.className.replace(reg, ' ')
  }
}



function findXpos(obj){
   var lPos = 0;
   if (obj.offsetParent){
      while (obj.offsetParent){
         lPos += obj.offsetLeft;
         obj = obj.offsetParent;
      }
   }
   else if (obj.x)
      lPos += obj.x;
   return lPos;
}
function findYpos(obj){
   var oPos = 0;
   if (obj.offsetParent){
      while (obj.offsetParent){
         oPos += obj.offsetTop;
         obj = obj.offsetParent;
      }
   }
   else if (obj.y)
      oPos += obj.y;
   return oPos;
}

function copyToClipboard(eid) {
 var element;
 if (Object.prototype.toString.call(eid)==="[object String]"){
    element=document.getElementById(eid);
 }
 else{
    element=eid;
 }
 function listener(e) {
   var clipText=" "+element.innerText;
   var noHtml=false;
   // tables are not trasfered as Html in clipboard -> kernel rule in w5base
   if (element.innerHTML.toLowerCase().indexOf("</table>")!=-1 ||
       element.innerHTML.toLowerCase().indexOf("</td>")!=-1    ||
       element.innerHTML.toLowerCase().indexOf("<img ")!=-1){
      noHtml=true;
   }
   clipText=clipText.trim();
   clipText=clipText.replace(/^\s*/mg, "");
   clipText=clipText.replace(/\s*$/mg, "");
   //console.log("clipText0=",clipText,clipText.split(/\r\n|\r|\n/).length);
   //console.log("clipText1=",clipText.split(/\r\n|\r|\n/));
   if (clipText.split(/\r\n|\r|\n/).length>1){
      clipText+="\n";
   }
   //console.log("clipText2='"+clipText+"'");
   if (e.clipboardData){ // this is not defined in IE
      e.clipboardData.setData("text/plain", clipText);
      var clipStr=element.innerHTML.toLowerCase();
      if (!noHtml){
         var html=element.innerHTML+"<br>\r\n<br>\r\n";
         e.clipboardData.setData("text/html", html);
      }
   }
   else{
      console.log("Sorry - "+
                  "clipboard is not supported - pleas use a real browser");
   }
   e.preventDefault();
 }
 var clipText=" "+element.innerText;
 clipText=clipText.trim();
 if (window.clipboardData){
    window.clipboardData.setData("Text",clipText);
 }
 else{
    document.addEventListener("copy", listener);
    document.execCommand("copy");
    document.removeEventListener("copy", listener);
 }
}




function openwin(url,id,param)
{
   var useid=id;
   if (id=="fullscreen"){
      useid="_blank";
   }
   win=window.open(url,useid,param);
   if (id=="fullscreen"){
      if (win.outerWidth<screen.availWidth || 
          win.outerHeight < screen.availHeight){
         win.moveTo(0,0);
         win.resizeTo(screen.availWidth, screen.availHeight);
      }
   }
   if (!win){
      alert("ERROR: popup blocker didn't allow window.open");
   }
   win.focus();
//   setwinpos();
   return;
}

function xopenwin(url,id,param)
{
   win=window.open(url,id,param);
   if (!win){
      alert("ERROR: popup blocker didn't allow window.open");
   }
//   setwinpos();
   return(win);
}

function custopenwin(url,mode,width,height,name)
{
   var scroll="no";
   if (name==""){
      name="_blank";
   }
   if (mode=='auto'){
      win=window.open(url,name,
                   'height=1,width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
      var sy=700;
 
      if (window.screenY){
         sy=window.screenY;
      }
      var height=screen.availHeight-sy-30;
      width=width+20;
      win.resizeTo(width,height);
   }
   else if (mode=='persi'){
      var s=getSiteCookie("W5WINSIZE");
      if (s){
         var sp=s.indexOf(";");
         if (sp!=-1){
            width=parseInt(s.substring(0,sp));
            height=parseInt(s.substring(sp+1));
            if (width<100){
               width=100;
            }
            if (height<100){
               height=100;
            }
         }
      }
      win=window.open(url,name,
                   'height='+height+',width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else if (mode=='f800'){
      win=window.open(url,name,
                   'height=680,width=780,toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else if (mode=='f1024'){
      win=window.open(url,name,
                   'height=750,width=990,toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else if (mode=='large'){
      win=window.open(url,name,
                   'height=800,width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else if (mode=='vmax800'){
      var height=screen.availHeight-50;
      var winTitleHeight=25;
      var curX=window.screenLeft+winTitleHeight;
      var curY=window.screenTop+winTitleHeight;
      win=window.open(url,name,
                   'height='+height+',width=780,'+
                   'left='+curX+',top='+curY+','+
                   'toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else if (mode=='vmax600'){
      var height=screen.availHeight-50;
      var winTitleHeight=25;
      var curX=window.screenLeft+winTitleHeight;
      var curY=window.screenTop+winTitleHeight;
      win=window.open(url,name,
                   'height='+height+',width=630,'+
                   'left='+curX+',top='+curY+','+
                   'toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
      win.moveTo(curX,curY);
   }
   else{  // normal mode
      win=window.open(url,name,
                   'height='+height+',width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   if (name!="_blank"){
      win.focus();
   }
   //setwinpos();
   return;
}



/**
 * X-browser event handler attachment and detachment
 * TH: Switched first true to false per http://www.onlinetools.org/articles/unobtrusivejavascript/chapter4.html
 *
 * @argument obj - the object to attach event to
 * @argument evType - name of the event - DONT ADD "on", pass only "mouseover", etc
 * @argument fn - function to call
 */
function addEvent(obj, evType, fn){
 if (obj.addEventListener){
    obj.addEventListener(evType, fn, false);
    return true;
 } else if (obj.attachEvent){
    var r = obj.attachEvent("on"+evType, fn);
    return r;
 } else {
    return false;
 }
}
function removeEvent(obj, evType, fn, useCapture){
  if (obj.removeEventListener){
    obj.removeEventListener(evType, fn, useCapture);
    return true;
  } else if (obj.detachEvent){
    var r = obj.detachEvent("on"+evType, fn);
    return r;
  } else {
    alert("Handler could not be removed");
  }
}

/**
 * COMMON DHTML FUNCTIONS
 * These are handy functions I use all the time.
 *
 * By Seth Banks (webmaster at subimage dot com)
 * http://www.subimage.com/
 *
 * Up to date code can be found at http://www.subimage.com/dhtml/
 *
 * This code is free for you to use anywhere, just keep this comment block.
 */

/**
 * Code below taken from - http://www.evolt.org/article/document_body_doctype_switching_and_more/17/30655/
 *
 * Modified 4/22/04 to work with Opera/Moz (by webmaster at subimage dot com)
 *
 * Gets the full width/height because it's different for most browsers.
 */
function getViewportHeight() {
   if (window.innerHeight!=window.undefined) return window.innerHeight;
   if (document.compatMode=='CSS1Compat') return document.documentElement.clientHeight;
   if (document.body) return document.body.clientHeight; 
   return window.undefined; 
}
function getViewportWidth() {
   if (window.innerWidth!=window.undefined) return window.innerWidth; 
   if (document.compatMode=='CSS1Compat') return document.documentElement.clientWidth; 
   if (document.body) return document.body.clientWidth; 
   return window.undefined; 
}


/**
 *
 * Fix the transparent Handling in Internet-Explorer
 * img src="xxx" onload="fixPNGtransparent(this)
 *
**/

function fixPNGtransparent(myImage)
{
   var imgID = (myImage.id) ? "id='" + myImage.id + "' " : "";
   var imgClass = (myImage.className) ? "class='"+myImage.className+"' " : "";
   var imgTitle = (myImage.title) ? "title='"+myImage.title+"' " : "title='"+ 
                   myImage.alt + "' ";
   var imgStyle = "display:inline-block;" + myImage.style.cssText ;
   var strNewHTML = "<span " + imgID + imgClass + imgTitle;
   strNewHTML += " style=\"" + "width:"+myImage.width+"px; height:"+
                 myImage.height + "px;" + imgStyle + ";";
   var url=myImage.src;
   url=url.replace(/^https:/,"http:");
   strNewHTML += "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader";
   //strNewHTML += "(src=\'" + myImage.src+"\', sizingMethod='scale');\"></span>" 
   strNewHTML += "(src=\'"+url+"\', sizingMethod='scale');\"></span>" ;
   myImage.outerHTML = strNewHTML;
}

/////////////////////////////////////////////////////////////////////////
var tooltip_Current=undefined;

function tooltip_Show(tt)
{
   (tooltip_Current) & tooltip_Hide(tooltip_Current);
   tt.style.visibility="visible";
   tt.style.display="block";
   tooltip_Current=new Object();
   tooltip_Current.tooltip=tt;
   tooltip_Current.tooltip.onmouseover=new Function("s",
                        "window.clearTimeout(tooltip_Current.timer);");
   tooltip_Current.tooltip.onmouseout=new Function("h_",
                                     "tooltip_SetLatentHide(1000);");
}

function tooltip_Hide()
{
   if (tooltip_Current){
      tooltip_Current.tooltip.style.visibility="hidden";
      tooltip_Current.tooltip.style.display="none";
      window.clearTimeout(tooltip_Current.timer);
      tooltip_Current=undefined;
   }
}

function tooltip_SetLatentHide(n)
{
   if (tooltip_Current){
      window.clearTimeout(tooltip_Current.timer);
      tooltip_Current.timer=window.setTimeout('tooltip_Hide();',n);
   }
}

function hideSpec(tooltip)
{
   var e=document.getElementById(tooltip);
   e & tooltip_Hide(e);
}

function displaySpec(parent,tooltip)
{
   var e=document.getElementById(tooltip);
   if (e){
      tooltip_Hide();
      if (!tooltip_Current){
         tooltip_Show(e);
         parent.onmouseout=new Function("h_"+tooltip,
                                     "tooltip_SetLatentHide(1000);");
      }
   }

  // alert("fifi");
}

function getClockTime()
{
   var now    = new Date();
   var hour   = now.getHours();
   var minute = now.getMinutes();
   var second = now.getSeconds();
   var ap = "AM";
   if (hour   > 11) { ap = "PM";             }
   if (hour   > 12) { hour = hour - 12;      }
   if (hour   == 0) { hour = 12;             }
   if (hour   < 10) { hour   = "0" + hour;   }
   if (minute < 10) { minute = "0" + minute; }
   if (second < 10) { second = "0" + second; }
   var timeString = hour + ':' + minute + ':' + second + " " + ap;
   return timeString;
} // function getClockTime()


function include(script_filename) {
    document.write('<' + 'script');
    document.write(' language="javascript"');
    document.write(' type="text/javascript"');
    document.write(' src="' + script_filename + '">');
    document.write('</' + 'script' + '>');
}

//function InitJsConsole()
//{ 
//   var cons;
//   var p=window.parent;
//   if (window.opener){
//      include('../../../static/firebug/firebug.js');
//      console.open();
//      return;
//   }
//   var level=0;
//   while(p){
//      if (p.console){
//         cons=p.console;
//         break;
//      }
//      if (!p.parent || level>5){
//         break;
//      }
//      level++;
//      p=p.parent;
//      //alert("level="+level+" obj="+p+" name="+p.document.title);
//   }
//   var names = ["log", "debug", "info", "warn", "error", "assert", "open",
//                "close",
//                "dir", "dirxml","group", "groupEnd", "time", "timeEnd", 
//                "count", "trace", "profile", "profileEnd"];
//   window.console = {};
//   if (cons){
//      for (var i = 0; i < names.length; ++i){
//        window.console[names[i]] = cons[names[i]];
//      }
//   }
//   else{
//     for (var i = 0; i < names.length; ++i){
//        window.console[names[i]] = function(){};
//      }
//   }
//}
//InitJsConsole();
//console.log("CONSOLE: %s in %s",new Date(),window.name);
//console.log("CONSOLE: %s in %s",new Date(),window.name);

function divSwitcher(sel,defval,dofineSwitch)
{
   var syncctrl=false;
   var tags=new Array("input","select","textarea");
   if (defval && defval!=""){
      for(c=0;c<sel.options.length;c++){
         if (sel.options[c].value==defval){
            sel.options[c].selected=true;
         }
      }
   }
   for(c=0;c<sel.options.length;c++){
      var ov=sel.options[c].value; 
      var d=document.getElementById(sel.id+ov);
      if (d){
         var disa=true;
         if (sel.options[c].selected){
            d.style.display="block";
            d.style.visibility="visible";
            disa=false;
            if (ov=="0"){
               syncctrl=true;
            }

            // Attribute 'data-visiblebuttons' controls,
            // which Buttons are shown in the selected divset.
            // A comma-separated list of button names is expected.
            // Shows all possible buttons, if attribute is omitted or
            // the value 'All' is found in the list.
            var possibleBtn=$('.workflowbutton');
            var attr=d.getAttribute("data-visiblebuttons");
            if(attr!=null && attr.search(/All/)==-1) {
               for(n=0;n<possibleBtn.length;n++) {
                  possibleBtn[n].style.display="none";
                  possibleBtn[n].style.visibility="hidden";
               }
               var visibleBtn=attr.split(',');
               for(n=0;n<visibleBtn.length;n++) {
                  var name=$.trim(visibleBtn[n]);
                  if (document.getElementsByName(name).length>0) {
                     document.getElementsByName(name)[0].
                              style.display="inline";
                     document.getElementsByName(name)[0].
                              style.visibility="visible";
                  }
               }
            }
            else {
               for(n=0;n<possibleBtn.length;n++) {
                  possibleBtn[n].style.display="inline";
                  possibleBtn[n].style.visibility="visible";
               }
            }
            // 'data-visiblebuttons' end

         }
         else{
            d.style.display="none";
            d.style.visibility="hidden";
         }
         for(tn=0;tn<tags.length;tn++){
            var subs=d.getElementsByTagName(tags[tn]);
            for(cc=0;cc<subs.length;cc++){
               subs[cc].disabled=disa;
            }
         }
      }
   }
   if (dofineSwitch){
      dofineSwitch(sel);
   }
   else{
     alert("no fine Switch");
   }
   addEvent(sel,"change",function(){divSwitcher(sel,"",dofineSwitch);});
}

function addFunctionKeyHandler(form,f)
{
   var inputs=new Array();
   var el=new Array("input","select");
   for(var jj=0;jj<el.length;jj++){
      var i=form.getElementsByTagName(el[jj]);
      for(var j=0;j<i.length;j++){
         inputs.push(i[j]);
      }
   }
   for(var j=0;j<inputs.length;j++){
      addEvent(inputs[j],"keydown",function(e){
         e=e || window.event;
         return(f(e));
      });
   }
}


function EnterSubmitEvtHandler(e,form,vname)
{
   e=e || window.event;
   if (e.keyCode == 13) {
      if (typeof(vname)=="function"){
         return(vname());
      }
      if (vname){
         form.elements[vname].click();
      }
      else{
         form.submit();
      }
      return false;
   }
}



function setEnterSubmit(form,vname)
{
   addEvent(window, "load", 
            function(){
               var inputs=new Array();
               var el=new Array("input","select");
               for(var jj=0;jj<el.length;jj++){
                  var i=form.getElementsByTagName(el[jj]);
                  for(var j=0;j<i.length;j++){
                     inputs.push(i[j]);
                  }
               }
               for(var j=0;j<inputs.length;j++){
                  addEvent(inputs[j],"keydown",
                    function(e){return(EnterSubmitEvtHandler(e,form,vname));});
               }
            });
}

function isArray()
{
   if (typeof arguments[0] == 'object'){
      var criterion = arguments[0].constructor.toString().match(/array/i); 
      return (criterion != null);  
   }
   return (false);
}


function doClickOn(element){
  if (element!=null){
     try {
        element.click();
     }
     catch(e) {
        var evt=document.createEvent("MouseEvents");
        evt.initMouseEvent("click",true,true,
                           window,0,0,0,0,0,false,false,false,false,0,null);
        element.dispatchEvent(evt);
     }
  }
}


function setFocus(vname)
{
   addEvent(window, "load", function(){
                               var f,e;
                               for(f=0;f<document.forms.length;f++){
                                  var fo=document.forms[f];
                                  for(e=0;e<fo.elements.length;e++){
                                     var el=fo.elements[e];
                                     if (el.name==vname || vname==""){
                                        window.setTimeout("document.forms["+
                                                          f+"].elements["+e+
                                                          "].focus();",50);
                                        // focus via setTimeout is needed
                                        // because mozilla sometimes makes
                                        // shit, if you do this direct
                                        return(false);
                                     }
                                  }
                               }
                            });

}


function swfvideo(url)
{
   var w=xopenwin("Empty","_blank","height=610,width=780,toolbar=no,"
                 +"status=no,resizable=no,scrollbars=no");
   w.document.write("<html>");
   w.document.write("<head>");
   w.document.write("<script type=\"text/javascript\" "+
                    "src=\"../../../static/video/shockwave/swfobject.js\">"+
                    "</script>");
   w.document.write("<title>");
   w.document.write("W5Video:");
   w.document.write("</title>");
   w.document.write("</head>");
   w.document.write("<style>");
   w.document.write("body,html,form{padding:0;margin:0}");
   w.document.write("</style>");
   w.document.write("<body onload=\"setupSeekBar();\">");
   w.document.write("<table width=100% height=100% "+
                    "cellspacing=0 cellpadding=0><tr>");
   w.document.write("<td align=center valign=center>");
   w.document.write("<object "+
                   "classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\" "+
                   "width=\"785\" height=\"580\" "+
                   "codebase=\"../../../static/video/shockwave/swflash.cab\">");
   w.document.write("<param name=\"scale\" value=\"showall\">");
   w.document.write("<param name=\"movie\" value=\""+url+"\">");
   w.document.write("<param name=\"play\" value=\"true\">");
   w.document.write("<param name=\"loop\" value=\"false\">");
   w.document.write("<param name=\"quality\" value=\"height\">");
   w.document.write("<embed src=\""+url+"\" width=\"785\" height=\"582\" play=\"true\" loop=\"false\" scale=\"showall\" quality=\"height\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\"></embed>");
   w.document.write("</object>");
   w.document.write("</td>");
   w.document.write("</tr></table>");
   w.document.write("</body>");
   w.document.write("</html>");
   w.document.close();
}

function getXMLHttpRequest()
{
   var xmlhttp=false;
   if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
        try {
                xmlhttp = new XMLHttpRequest();
        } catch (e) {
                xmlhttp=false;
        }
   }
   if (!xmlhttp && window.createRequest) {
        try {
                xmlhttp = window.createRequest();
        } catch (e) {
                xmlhttp=false;
        }
   }
   if (!xmlhttp){
      try {
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
      } catch (e) {
       try {
       xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
       } catch (E) {
        xmlhttp = false;
       }
      }
   }
   return(xmlhttp);
}


var $jsonp = (function(){
  var that = {};

  that.send = function(src, options) {
    var callback_name = options.callbackName || 'callback',
      on_success = options.onSuccess || function(){},
      on_timeout = options.onTimeout || function(){},
      timeout = options.timeout || 10; // sec

    var timeout_trigger = window.setTimeout(function(){
      window[callback_name] = function(){};
      on_timeout();
    }, timeout * 1000);

    window[callback_name] = function(data){
      window.clearTimeout(timeout_trigger);
      on_success(data);
    }

    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.src = src;

    document.getElementsByTagName('head')[0].appendChild(script);
  }

  return that;
})();


function normalizeRequestPath(p)
{
   var href=document.location.href; //path must be calced dynamicly
   var path=href.substring(0,href.indexOf("/public/"));
   if (path==""){
       path=href.substring(0,href.indexOf("/auth/"));
   }
   //alert("document.location.href="+path);
   path = path+p;
   return(path);   
}



function insertAtCursor(myField, myValue) 
{
   //IE support
   if (document.selection) {
      myField.focus();
      sel = document.selection.createRange();
      sel.text = myValue;
   }
   //MOZILLA/NETSCAPE support
   else if (myField.selectionStart || myField.selectionStart == 0) {
      var startPos = myField.selectionStart;
      var endPos = myField.selectionEnd;
      myField.value = myField.value.substring(0, startPos)
         + myValue
         + myField.value.substring(endPos, myField.value.length);
   } else {
     myField.value += myValue;
   }
}


