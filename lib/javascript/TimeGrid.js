function handleEditFrame()
{
  var g=getVal("baseScale")/getVal("baseGrid");
  SetMarkGrid(g);
   if (document.forms[0].elements['mode'].value!=""){
      // var editframe=document.getElementById("editframe");
      // editframe.style.display="block";
   }
}

function getVal(v)
{
   if (!document.forms[0].elements[v]) return(null);
   return(document.forms[0].elements[v].value);
}

function adjust(v,n)
{
   var r=v+"";
   while(r.length<n){
      r="0"+r;
   }
   return(r);
}

function FormatDate()
{
   if (getVal("baseLang")=="de"){
      return(adjust(this.getDate(),2)+"."+
             adjust(this.getMonth(),2)+"."+
             adjust(this.getCorrectYear(),1)+" "+
             adjust(this.getHours(),2)+":"+
             adjust(this.getMinutes(),2)+":"+
             adjust(this.getSeconds(),2));
   }
   else{
      return(adjust(this.getCorrectYear(),4)+"/"+
             adjust(this.getMonth(),2)+"/"+
             adjust(this.getDate(),2)+" "+
             adjust(this.getHours(),2)+":"+
             adjust(this.getMinutes(),2)+":"+
             adjust(this.getSeconds(),2));
   }
}

Date.prototype.FormatDate=FormatDate;
function getCorrectYear()
{
  var y=this.getYear();
  if (y<999) y=y+1900;
  return(y);
}
Date.prototype.getCorrectYear=getCorrectYear;

function addSeconds(n)
{
   this.setTime(this.getTime()+n*1000);
}
Date.prototype.addSeconds=addSeconds;

function activeEdit(selNode,selStart,selEnd)
{
   var b=new Date(getVal("baseYear"), getVal("baseMonth"),  getVal("baseDay"),
                  getVal("baseHour"), getVal("baseMinute"), getVal("baseSecond"));
   var s=new Date(b);
   var e=new Date(b);
   s.addSeconds(_gridedVal(0,getVal("baseScale"),getVal("baseScale")/100*selStart));
   e.addSeconds(_gridedVal(0,getVal("baseScale"),getVal("baseScale")/100*selEnd));

   document.forms[0].elements['name'].value=selNode.id;
   document.forms[0].elements['start'].value=s.FormatDate();
   document.forms[0].elements['end'].value=e.FormatDate();
   document.forms[0].elements['name'].value=b.getTime();
   document.forms[0].elements['start'].value=s.FormatDate();
   document.forms[0].elements['end'].value=e.FormatDate();
   document.forms[0].elements['mode'].value="add";
   handleEditFrame();
}

//window.onload=handleEditFrame;

//--------------------------------------------------------------------
// Mark library     
//
var _CurrentMousePos=new Object();
var _MarkBar;
var _MarkGrid=10;

function SetMarkGrid(n)
{
   _MarkGrid=n;
}
function StartMark(markElement,backcall)
{
   _cleanupMarkbar();
   var x=_gridedVal(markElement.offsetLeft,markElement.offsetWidth,
                    _CurrentMousePos.x);
   _MarkBar=document.createElement("div");
   _MarkBar.style.background="black";
   _MarkBar.style.width="1";
   _MarkBar.style.position="absolute";
   _MarkBar.style.top=markElement.offsetTop;
   _MarkBar.style.left=x;
   _MarkBar.style.height=markElement.offsetHeight-1;
   _MarkBar.style.opacity=0.2;
   _MarkBar.style.filter="alpha(opacity=20)";
   _MarkBar.startx=x;
   _MarkBar.backcall=backcall;
   markElement.appendChild(_MarkBar);
   return(false);
}
function _gridedVal(start,base,x)
{
   var g=base/_MarkGrid;
   var n=Math.round((x-start)/g)*g;
   return(n+start);
}
function _MouseMoveHandler()
{
   if (_MarkBar){
      var x=_gridedVal(_MarkBar.parentNode.offsetLeft,_MarkBar.parentNode.offsetWidth,_CurrentMousePos.x);
      if (_CurrentMousePos.x-_MarkBar.startx>0){
         _MarkBar.style.left=_MarkBar.startx;
         _MarkBar.style.width=x-_MarkBar.offsetLeft;
      }
      else{
         _MarkBar.style.left=x;
         _MarkBar.style.width=(x-_MarkBar.startx)*-1;
      }
   }
}
function _MouseUpHandler(e)
{
   if (_MarkBar){
      var max=_MarkBar.parentNode.offsetWidth;
      var selStart=(_MarkBar.offsetLeft-_MarkBar.parentNode.offsetLeft)*100/max;
      var selEnd=(_MarkBar.offsetLeft-_MarkBar.parentNode.offsetLeft+_MarkBar.offsetWidth)*100/max;
      if (_MarkBar.backcall){
         _MarkBar.backcall(_MarkBar.parentNode,selStart,selEnd);
      }
   }
   _cleanupMarkbar();
   return(false);
}
function _grabMouse(currentEvent)
{
   if (currentEvent == null) currentEvent = window.event; 
   var target = currentEvent.target != null ? currentEvent.target : currentEvent.srcElement;    
   _CurrentMousePos.x=currentEvent.clientX;
   _CurrentMousePos.y=currentEvent.clientY;
   if (_MarkBar){
      _MouseMoveHandler();
      return(false);
   }
   return(true);
}
function _cleanupMarkbar()
{
   if (_MarkBar){
      if (_MarkBar.parentNode){
         _MarkBar.parentNode.removeChild(_MarkBar);
      }
      _MarkBar=undefined;
   }
}
function OnMouseDown(currentEvent)
{ 
   if (currentEvent == null) currentEvent = window.event; 
   var target = currentEvent.target != null ? currentEvent.target : currentEvent.srcElement; 
   alert('Button='+currentEvent.button+' className='+target.className+
         ' nodeName='+target.nodeName);
   return(false);
}
document.onmouseup=_MouseUpHandler;
//document.onmousedown=OnMouseDown;
document.onmousedown=_grabMouse;
document.onmousemove=_grabMouse;
