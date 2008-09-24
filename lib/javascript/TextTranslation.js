
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
   e=e || window.event;
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
            txt=txt.replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
            ta.value=oldtext+"\n\n\n"+keystring+"\n"+txt;
            ta.focus();
         });
      return(false);
   }
   if (e.keyCode==120){
      if (parent.showPopWin){
         parent.currentObject=ta;
         parent.showPopWin("addAttach",400,180,setAddAttachString);
      }
      else if (document.showPopWin){
         document.currentObject=ta;
         document.showPopWin("addAttach",400,180,setAddAttachString);
      }
      else{
         alert("inline attachments are not allowed in this context");
      }
   }
   return(true);
}

