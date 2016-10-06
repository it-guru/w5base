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
      var curaction=document.location.href;
      curaction=curaction.replace(/^.*\//,"");
      curaction=curaction.replace(/[?#].*$/,"");
      document.forms[0].action=curaction+"#I."+id.value+"."+grp.value;
      document.forms[0].ScrollY.value="";
      id.value="";
      grp.value="";
      document.forms[0].submit();
   }
}

function DetailEditSave()
{
   var op=document.getElementById('OP');
   if (op){
      op.value="save";
      saveScrollCoordinates();
      //document.forms[0].action="Detail";
      document.forms[0].submit();
   }
   else{
      alert("ERROR: can't get OP field");
   }
}



function DetailTestFunc()
{
   window.document.body.scrollTop=100;
}

