function saveScrollCoordinates() 
{
  var MainFrame=document.getElementById("HtmlDetail");
  document.forms[0].ScrollY.value = document.body.scrollTop;
}


function DetailTopEdit(group,recid)
{
   var grp=document.getElementById('CurrentFieldGroupToEdit');
   var id=document.getElementById('CurrentIdToEdit');
   if (grp){
      id.value=recid;
      grp.value=group;
      document.forms[0].action="#I."+recid+"."+group;
      document.forms[0].ScrollY.value="";
      document.forms[0].submit();
   }
}

function DetailCopy(recid)
{
   var id=document.getElementById('CurrentIdToEdit');
   id.value=recid;
   document.forms[0].target="_parent";
   document.forms[0].action="Copy";
   document.forms[0].submit();
}

function DetailEdit(group,recid)
{
   var grp=document.getElementById('CurrentFieldGroupToEdit');
   var id=document.getElementById('CurrentIdToEdit');
   if (grp){
      if (document.querySelectorAll){
         document.querySelectorAll('*').forEach(function(node) {
            node.style.cursor = 'progress';
         });
      }
      id.value=recid;
      grp.value=group;
      saveScrollCoordinates();
      var curaction=document.location.href;
      curaction=curaction.replace(/^.*\//,"");
      curaction=curaction.replace(/[?#].*$/,"");
      document.forms[0].action=curaction;
      document.forms[0].submit();
   }
}

function DetailEditBreak()
{
   var grp=document.getElementById('CurrentFieldGroupToEdit');
   var id=document.getElementById('CurrentIdToEdit');
   if (grp){
      if (document.querySelectorAll){
         document.querySelectorAll('*').forEach(function(node) {
            node.style.cursor = 'progress';
         });
      }
      id.value="";
      grp.value="";
      saveScrollCoordinates();
      var curaction=document.location.href;
      curaction=curaction.replace(/^.*\//,"");
      curaction=curaction.replace(/[?#].*$/,"");
      document.forms[0].action=curaction;
      document.forms[0].submit();
   }
}

function DetailTopEditBreak()
{
   var grp=document.getElementById('CurrentFieldGroupToEdit');
   var id=document.getElementById('CurrentIdToEdit');
   if (grp){
      if (document.querySelectorAll){
         document.querySelectorAll('*').forEach(function(node) {
            node.style.cursor = 'progress';
         });
      }
      id.value="";
      grp.value="";
      saveScrollCoordinates();
      var curaction=document.location.href;
      curaction=curaction.replace(/^.*\//,"");
      curaction=curaction.replace(/[?#].*$/,"");
      document.forms[0].action=curaction;
      document.forms[0].submit();
   }
}


function HistoryCommentedDetailEditSave(comment){
   var HistoryCommentsInputField = document.createElement("input");
   HistoryCommentsInputField.type = "hidden";
   HistoryCommentsInputField.name = "HistoryComments";
   HistoryCommentsInputField.value=comment;
   document.forms[0].appendChild(HistoryCommentsInputField);

   shiftKey=0;  // ensure not history dialog is opened
   DetailEditSave();
}

function DetailEditSave()
{
   var op=document.getElementById('OP');
   if (op){
      if (shiftKey){
         shiftKey=0;
         if (parent.showPopWin){
            var thisdoc=document;
            var HistoryCommentedSaveButtonText="continue";
            if (document.HistoryCommentedSaveButtonText){
               HistoryCommentedSaveButtonText=
                  document.HistoryCommentedSaveButtonText;
            }
            parent.showPopWin(function(){
               var d="";
               d+="<form name=HistoryComment>";
               d+="<center>";
               d+="<textarea style='margin-top:10px;resize:none;"+
                  "margin-bottom:10px;width:90%;height:150px' "+
                  "name='HistoryComments' id=HistoryCommentsText></textarea>";
               d+="<input type='button' value='"+HistoryCommentedSaveButtonText+
                  "' "+
                  "style='width:80%' "+
                  "onclick=\"HistoryCommentedSave("+
                  "document.getElementById('HistoryCommentsText'));\">";
               d+="</center>";
               d+="</form>";
               parent.setPopTitle("HistoryComments");
               return(d);
            },400,220,function(){
               // do nothing;
            });
         }
      }
      else{ 
         if (document.querySelectorAll){
            document.querySelectorAll('*').forEach(function(node) {
               node.style.cursor = 'progress';
            });
         }
         op.value="save";
         saveScrollCoordinates();
         //document.forms[0].action="Detail";
         document.forms[0].submit();
      }
   }
   else{
      alert("ERROR: can't get OP field");
   }
}



function DetailTestFunc()
{
   window.document.body.scrollTop=100;
}

