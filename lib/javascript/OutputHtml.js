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

function inlineEdit(e,tdelement){
   if (!e) var e = window.event;                // Get the window event
   e.cancelBubble = true;                       // IE Stop propagation
   if (e.stopPropagation) e.stopPropagation();  // Other Broswers
   var td=e.target;
   if (td.tagName.toLowerCase() == 'td'){
      if (td.hasAttribute("data-restoreval")){
         console.log("we are already in edit mode=");
      }
      else{
         var oldval=td.innerHTML;
         td.innerHTML="<form><textarea name=inlineData "+
                     "style=\"min-width:200px;width:100%;height:80px\">"+
                     td.innerText+"</textarea>"+
                     "<table width=100% border=0 cellspacing=0 cellpadding=0>"+
                     "<tr><td>"+
                     "<div id=LastMsg class=LastMsg></div></td>"+
                     "<td width=40 valign=top nowrap>"+
                     "<input type=image style=\"float:right\" "+
                     "src=\"../../base/load/ok.gif\" title=\"save\" "+
                     "onclick=\"inlineEditSave(this);return(false);\" "+
                     "value=ok>"+
                     "<input type=image style=\"float:left\" "+
                     "src=\"../../base/load/abort.gif\" title=\"abort\" "+
                     "onclick=\"inlineEditCancel(this);return(false);\" "+
                     "value=break>"+
                     "</td></tr></table>";
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

function DirectView(format)
{
   parent.DoRemoteSearch("Result","DirectView",format,undefined,0);
   setViewFrame(1);
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

function DirectDownload(format,target)
{
   format=">"+format;
   parent.DoRemoteSearch("Result","DirectView",format,undefined,0);
}



