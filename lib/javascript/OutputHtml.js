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



