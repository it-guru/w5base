function setwinpos()
{

   if (window.navigator.userAgent.indexOf("MSIE") > -1){
      // nothing
   }
   else{
      win.moveTo(window.screenX+50,window.screenY+50);
   }
   win.focus();

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

function getQueryString(index) {
  var paramExpressions;
  var param
  var val
  paramExpressions = window.location.search.substr(1).split("&");
  if (index < paramExpressions.length) {
    param = paramExpressions[index]; 
    if (param.length > 0) {
      return eval(unescape(param));
    }
  }
  return ""
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



function openwin(url,id,param)
{
   win=window.open(url,id,param);
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

function custopenwin(url,mode,width)
{
   var scroll="no";
   if (mode=='auto'){
      win=window.open(url,'_blank',
                   'height=1,width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
      if (!window.screenY){
         window.screenY=0;
      }
     // win.resizeTo(width,screen.availHeight-window.screenY-60);
   }
   else if (mode=='large'){
      win=window.open(url,'_blank',
                   'height=800,width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
   }
   else{
      win=window.open(url,'_blank',
                   'height=640,width='+width+',toolbar=no,status=no,'+
                   'resizable=yes,scrollbars='+scroll);
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
   var imgID = (myImage.id) ? "id='" + myImage.id + "' " : ""
   var imgClass = (myImage.className) ? "class='"+myImage.className+"' " : ""
   var imgTitle = (myImage.title) ? "title='"+myImage.title+"' " : "title='"+ 
                   myImage.alt + "' "
   var imgStyle = "display:inline-block;" + myImage.style.cssText 
   var strNewHTML = "<span " + imgID + imgClass + imgTitle
   strNewHTML += " style=\"" + "width:"+myImage.width+"px; height:"+
                 myImage.height + "px;" + imgStyle + ";"
   var url=myImage.src;
   url=url.replace(/^https:/,"http:");
   strNewHTML += "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
   //strNewHTML += "(src=\'" + myImage.src+"\', sizingMethod='scale');\"></span>" 
   strNewHTML += "(src=\'"+url+"\', sizingMethod='scale');\"></span>" 
   myImage.outerHTML = strNewHTML
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
   var timeString = hour +
                    ':' +
                    minute +
                    ':' +
                    second +
                    " " +
                    ap;
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
                           function(e){
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
                           });
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


/**
*
* UTF-8 data encode / decode
* http://www.webtoolkit.info/
*
**/

var Utf8 = {

    // public method for url encoding
    encode : function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // public method for url decoding
    decode : function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

}


/**
*
* URL encode / decode
* http://www.webtoolkit.info/
*
**/

var Url = {

    // public method for url encoding
    encode : function (string) {
        return escape(this._utf8_encode(string));
    },

    // public method for url decoding
    decode : function (string) {
        return this._utf8_decode(unescape(string));
    },

    // private method for UTF-8 encoding
    _utf8_encode : function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // private method for UTF-8 decoding
    _utf8_decode : function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

}

/**
*
* Base64 encode / decode
* http://www.webtoolkit.info/
*
**/

var Base64 = {

    // private property
    _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

    // public method for encoding
    encode : function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        input = Base64._utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output +
            this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
            this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
    },

    // public method for decoding
    decode : function (input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = this._keyStr.indexOf(input.charAt(i++));
            enc2 = this._keyStr.indexOf(input.charAt(i++));
            enc3 = this._keyStr.indexOf(input.charAt(i++));
            enc4 = this._keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

        }

        output = Base64._utf8_decode(output);

        return output;

    },

    // private method for UTF-8 encoding
    _utf8_encode : function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // private method for UTF-8 decoding
    _utf8_decode : function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

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


/**

 * sprintf() for JavaScript v.0.4

 *

 * Copyright (c) 2007 Alexandru Marasteanu <http://alexei.417.ro/>

 * Thanks to David Baird (unit test and patch).

 *

 * This program is free software; you can redistribute it and/or modify it under

 * the terms of the GNU General Public License as published by the Free Software

 * Foundation; either version 2 of the License, or (at your option) any later

 * version.

 *

 * This program is distributed in the hope that it will be useful, but WITHOUT

 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS

 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more

 * details.

 *

 * You should have received a copy of the GNU General Public License along with

 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple

 * Place, Suite 330, Boston, MA 02111-1307 USA

 */



function str_repeat(i, m) { for (var o = []; m > 0; o[--m] = i); return(o.join('')); }



function sprintf () {

  var i = 0, a, f = arguments[i++], o = [], m, p, c, x;

  while (f) {

    if (m = /^[^\x25]+/.exec(f)) o.push(m[0]);

    else if (m = /^\x25{2}/.exec(f)) o.push('%');

    else if (m = /^\x25(?:(\d+)\$)?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(f)) {

      if (((a = arguments[m[1] || i++]) == null) || (a == undefined)) throw("Too few arguments.");

      if (/[^s]/.test(m[7]) && (typeof(a) != 'number'))

        throw("Expecting number but found " + typeof(a));

      switch (m[7]) {

        case 'b': a = a.toString(2); break;

        case 'c': a = String.fromCharCode(a); break;

        case 'd': a = parseInt(a); break;

        case 'e': a = m[6] ? a.toExponential(m[6]) : a.toExponential(); break;

        case 'f': a = m[6] ? parseFloat(a).toFixed(m[6]) : parseFloat(a); break;

        case 'o': a = a.toString(8); break;

        case 's': a = ((a = String(a)) && m[6] ? a.substring(0, m[6]) : a); break;

        case 'u': a = Math.abs(a); break;

        case 'x': a = a.toString(16); break;

        case 'X': a = a.toString(16).toUpperCase(); break;

      }

      a = (/[def]/.test(m[7]) && m[2] && a > 0 ? '+' + a : a);

      c = m[3] ? m[3] == '0' ? '0' : m[3].charAt(1) : ' ';

      x = m[5] - String(a).length;

      p = m[5] ? str_repeat(c, x) : '';

      o.push(m[4] ? a + p : p + a);

    }

    else throw ("Huh ?!");

    f = f.substring(m[0].length);

  }

  return o.join('');

}


