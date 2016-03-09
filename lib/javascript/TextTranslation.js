
function doTranslate(fromlang,tolang,fromtext,setFunc)
{
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST",
                normalizeRequestPath('/public/base/TextTranslation/Main'),true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var result=xmlobject.getElementsByTagName("result")[0];
       var childNode=result.childNodes[0];
       var resulttext=childNode.nodeValue;
       setFunc(fromlang,tolang,resulttext);
    }
    if (xmlhttp.readyState==4 && (xmlhttp.status==503 )){
       alert("ERROR: translation service not configured or not active");
    }
   }
   fromtext=Url.encode(fromtext);
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('srclang='+fromlang+'&dstlang='+tolang+
                "&mode=xml&src="+fromtext);
   return;
}

function setAddAttachString()
{
   parent.currentObject=null;
}

function textareaKeyHandler(ta,e)
{
   e=e || window.event;  // translation handling
   if ((e.ctrlKey && e.altKey && e.keyCode==84) || e.keyCode==121){
      var dstlang=ALTLANG;
      var keystring="["+dstlang+":]";
      var oldtext=ta.value;
      if (oldtext.indexOf(keystring)>0){
         oldtext=oldtext.substring(0,
               oldtext.indexOf(keystring)-3);
      }
      doTranslate(CURLANG,dstlang,oldtext,function(xsrclang,xdstlang,txt){
            var txt=Utf8.decode(txt);
            txt=txt.replace(/&amp;/g,'&')
                   .replace(/&quot;/g,'"')
                   .replace(/&#39;/g,"'")
                   .replace(/&lt;/g,'<')
                   .replace(/&gt;/g,'>');
            ta.value=oldtext+"\n\n\n"+keystring+"\n"+txt;
            ta.focus();
         });
      return(false);
   }
   if (e.keyCode==120){   // allow inline attachment
      if (parent.showPopWin){
         parent.currentObject=ta;
         parent.showPopWin("addAttach",400,220,setAddAttachString);
      }
      else if (window.showPopWin){
         window.currentObject=ta;
         window.showPopWin("addAttach",400,220,setAddAttachString);
      }
      else{
         alert("inline attachments are not allowed in this context");
      }
   }
   
   if (e.keyCode==84 && e.altKey){   // insert current timestamp ALT+t
      var d = new Date()
      if (CURLANG=="de"){
         var ds=sprintf("[%02d.%02d.%04d %02d:%02d]\n",d.getDate(),
                                                     d.getMonth()+1,
                                                     d.getFullYear(),
                                                     d.getHours(),
                                                     d.getMinutes());
         if (ta){
            insertAtCursor(ta,ds);
         }
      }
      else{
         var ds=sprintf("[%04d-%02d-%02d %02d:%02d]\n",d.getFullYear(),
                                                     d.getMonth()+1,
                                                     d.getDate(),
                                                     d.getHours(),
                                                     d.getMinutes());
         if (ta){
            insertAtCursor(ta,ds);
         }
      }
   }
   return(true);
}

