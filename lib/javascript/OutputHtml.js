function DoSubListEditAdd()
{
   var op=document.getElementById('OP');
   if (op){
      op.value="save";
      document.forms[0].submit();
   }
}

function DoSubListEditCancel()
{
   var op=document.getElementById('OP');
   var id=document.getElementById('CurrentIdToEdit');
   if (op){
      op.value="cancel";
      id.value="";
      document.forms[0].submit();
   }
}

function inlineEditSave(e){
   console.log("inlineEditSave",e);
   console.log("inlineEditSave",e.form.parentElement);
   var form=e.form;
   var td=e.form.parentElement;
   var tr=td.parentElement;
   var storedata=form.elements['inlineData'].value;
   var idname=tr.getAttribute("data-idname");
   var fieldname=td.getAttribute("data-name");
   var id=tr.getAttribute("data-id");
   var dataobj=tr.getAttribute("data-obj");
   var dataobjurl=dataobj="../../"+dataobj.replace("::","/")+"/Modify";
   console.log("save data=",storedata);

   if (idname=="" || id==""){
      alert("missing data");
   }
   else{
      var xmlhttp=getXMLHttpRequest();
      xmlhttp.open("POST",dataobjurl,true);
      xmlhttp.setRequestHeader('Content-type', 
                      'application/x-www-form-urlencoded;charset=utf-8');
      xmlhttp.onreadystatechange=function() {
            if (xmlhttp.readyState<4){
//               var t="<font color=silver>Loading ...</font>";
//               if (r.innerHTML!=t){
//                  r.innerHTML=t;
//               }
            }
            if (xmlhttp.readyState==4 &&
                (xmlhttp.status==200||xmlhttp.status==304)){
               opResult = JSON.parse(xmlhttp.responseText);
               console.log("response=",opResult);
               if (opResult[0]){
                  if (fieldname in opResult[0]){
                     var storedval=opResult[0][fieldname];
                     td.innerText=storedval;
                     td.removeAttribute("data-restoreval");
                  }
                  else{
                    opResult={LastMsg:[
                       'ERROR: attribute write error or not existing attribute'
                    ]};
                  }
               }
               if (opResult['LastMsg']){
                  var e=td.querySelector("#LastMsg");
                  if (e){
                     var LastMsg=opResult['LastMsg'];
                     e.innerHTML=LastMsg.map(function(k){
                         if (k.match(/^ERROR:/)){
                            k="<font style=\"color:red\">"+k+"</font>";
                         }
                         return(k);
                     }).join("<br>");
                  }
               }
            }
         };

      var data = new Object();
      data["Formated_"+fieldname]=storedata;
      data["OP"]="save";
      data["CurrentIdToEdit"]=id;
      data["CurrentView"]="("+fieldname+")";
      data[idname]=id;
      data['FormatAs']="nativeJSON";
      var datastr= Object.keys(data).map(function (key){
         return encodeURIComponent(key) + '=' + Url.encode(data[key]);
      }).join('&');
      var r=xmlhttp.send(datastr);
   }
}

function inlineEditCancel(e){
   var td=e.form.parentElement;
   var oldVal=td.getAttribute("data-restoreval");
   td.innerHTML=oldVal;
   td.removeAttribute("data-restoreval");
}

function inlineEdit(e,tdelement,behavior,extra){
   if (!e) var e = window.event;                // Get the window event
   e.cancelBubble = true;                       // IE Stop propagation
   if (e.stopPropagation) e.stopPropagation();  // Other Broswers
   var td=e.target;
   console.log("clickon ",td);
   if (td.tagName.toLowerCase() == 'td'){
      var attr=td.attributes;
      for(var i = attr.length - 1; i >= 0; i--) {
         console.log("a=",attr[i].name,attr[i].value);
      }

      if (attr["data-restoreval"]){
         console.log("we are already in edit mode=");
      }
      else{
   console.log("fifi 02");
         var oldval=td.innerHTML;
         var edtfld="";
         if (behavior=='singleline'){
            var v=td.innerText;
            v=v.replace("\"","&quote;");
            v=v.replace("\n"," ");
            v=v.replace("\r"," ");
            v=v.replace("<br>"," ");
            v=v.replace(">","&gt;");
            v=v.replace("<","&lt;");
            edtfld="<input type=text name=inlineData "+
                   "style=\"min-width:200px;width:100%\" "+
                   "value=\""+v+"\">";
         }
         else if (behavior=='hugemulti'){
            var v=td.innerText;
            v=v.replace("\"","&quote;");
            v=v.replace(">","&gt;");
            v=v.replace("<","&lt;");
            edtfld="<textarea name=inlineData "+
                   "style=\"min-width:300px;width:100%;height:180px\">"+
                   v+"</textarea>";
         }
         else if (behavior=='select'){
            var v=td.innerText;
            v=v.replace("\"","&quote;");
            v=v.replace(">","&gt;");
            v=v.replace("<","&lt;");
            edtfld="<select name=inlineData "+
                   "style=\"min-width:200px;width:100%\">";
            var opt=new Array();
            if (extra){
               var opt=extra.split("|").map(function(e){
                  e=e.trim();
                  return(e);
               });
            }
            
            for(c=0;c<opt.length;c++){
               var qopt=opt[c];
               qopt=qopt.replace('"',"&quote;");
               edtfld+="<option";
               if (opt[c]==v){
                  edtfld+=" selected";
               }
               edtfld+=" value=\""+qopt+"\">";
               edtfld+=opt[c];
               edtfld+="</option>";
            }
            edtfld+="</select>";
         }
         else{
            var v=td.innerText;
            v=v.replace("\"","&quote;");
            v=v.replace(">","&gt;");
            v=v.replace("<","&lt;");
            edtfld="<textarea name=inlineData "+
                   "style=\"min-width:200px;width:100%;height:80px\">"+
                   v+"</textarea>";
         }
         td.innerHTML="<form>"+edtfld+
                     "<div style=\"display:table;width:100%\">"+
                     "<div style=\"display:table-row\">"+
                     "<div style=\"display:table-cell\">"+
                     "<div id=LastMsg class=LastMsg></div></div>"+
                     "<div style=\"display:table-cell;width:40\">"+
                     "<input type=image style=\"float:right\" "+
                     "src=\"../../base/load/ok.gif\" title=\"save\" "+
                     "onclick=\"inlineEditSave(this);return(false);\" "+
                     "value=ok>"+
                     "<input type=image style=\"float:left\" "+
                     "src=\"../../base/load/abort.gif\" title=\"abort\" "+
                     "onclick=\"inlineEditCancel(this);return(false);\" "+
                     "value=break>"+
                     "</div></div></div>";
                     "</form>";
         td.setAttribute("data-restoreval",oldval);
      }
   }
}

function DoSubListEditSave()
{
   var op=document.getElementById('OP');
   if (op){
      op.value="save";
      document.forms[0].submit();
   }
}

function DoSubListEditDelete()
{
   var op=document.getElementById('OP');
   if (op){
      op.value="delete";
      document.forms[0].submit();
   }
}

function EditView(newview,action)
{
   parent.DoRemoteSearch(action,"Result","HtmlViewEditor",newview,0);
}
function FormatSelect(newview,action)
{
   parent.DoRemoteSearch(action,"Result","HtmlFormatSelector",newview,0);
}

function ChangeView(newview,action)
{
   parent.DoRemoteSearch(action,"Result","HtmlV01",newview,0);
}

function ShowUrl(format)
{
   parent.DoRemoteSearch("Result","DirectView","ShowUrl;"+format,undefined,0);
   setViewFrame(1);
}

function InitWorkflow(WorflowName)
{
   var fa=document.getElementById('WorkflowName');
   if (fa){
      fa.value=WorflowName;
      document.forms[0].action="InitWorkflow";
   //   document.forms[0].target="DirectView";
      document.forms[0].target="_blank";
      document.forms[0].submit();
   }
   else{
      alert("ERROR: can't init ProcessWorkflow - "+
            "WorkflowName hidden field not found");
   }
   //setViewFrame(1);
   return;
}

// funktioniert nicht, wegen Namenskollision mit dem Framenamen
//function DirectView(pHtmlElement,format)
//{
//   console.log("fifi DirectView:",pHtmlElement,format);
//   parent.DoRemoteSearch("Result","DirectView",format,undefined,0);
//   setViewFrame(1);
//}

function doDirectView(pHtmlElement,format)
{
   var oldcursor;
   if (pHtmlElement && pHtmlElement.style){
       oldcursor=pHtmlElement.style.cursor;
   }
   if (oldcursor){
      pHtmlElement.style.cursor ="wait";
      setTimeout(function(){
         pHtmlElement.style.cursor=oldcursor;
      },60000);
   }
   parent.DoRemoteSearch("Result","DirectView",format,undefined,0);
   setViewFrame(1);
}

function DirectDownload(pHtmlElement,format,target)
{
   var oldcursor;
   if (pHtmlElement && pHtmlElement.style){
       oldcursor=pHtmlElement.style.cursor;
   }
   if (oldcursor){
      pHtmlElement.style.cursor ="wait";
      setTimeout(function(){
         pHtmlElement.style.cursor=oldcursor;
      },60000);
   }
   format=">"+format;
   parent.DoRemoteSearch("Result","DirectView",format,undefined,0);
}

function ClipIconFunc(e){
  e = e || window.event; e.preventDefault();
  e.stopPropagation();
  var p=this.parentElement;

  var text=p.innerText;

  copyToClipboard(p);

  return(false);
}

function add_clipIconFunc(){
  var l=document.getElementsByClassName('clipicon');
  var i;
  for (i=0;i<l.length;i++){
     l[i].onclick=ClipIconFunc;
  }
}




