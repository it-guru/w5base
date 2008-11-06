var contextable = new Array(); // array for all objects that should have own context menus
var mouseEvent; // current event
var x = 100; // x-position of the mouse cursor
var y = 100; // y-position of the mouse cursor
var currentContextMenu; // hold a reference to the current context menu object
var whichMenu; // holds String for identification of context menu
var currentElement; // holds reference to the element the mouse cursor is over

function ContextMenuInit() {
   check();

   // register events for IE and Gecko-based browsers...
   if (document.all){ // IE
      if(document.getElementById) {
         document.oncontextmenu = clickContextDummy;
//         document.oncontextmenu = function(){return false;};
         document.onmousedown=clickIE;
      } else {
         document.onmousedown=clickIE;
      }
   } else if ((document.layers || document.getElementById) && 
              !document.all){ // all Gecko browsers
      if(document.layers) {
         document.captureEvents(Event.MOUSEDOWN);
         document.onmousedown=clickNS;
      } else {
         document.oncontextmenu = clickContext;
      }
   }

   // register events for Opera...
   if(window.opera) {
      document.onmousedown = clickOpera;
   }

   document.onmousemove = setEvent;
   document.onmouseup = function(){ window.setTimeout('hideContext()',4000);};
}

function check() {
   var opera = false;
   if(window.opera) opera = true;
   // alert("Attribute cont='" + document.getElementsByTagName("td")[0].getAttribute("cont") + "'");
}

function setEvent(e) {
   if(!e) e = window.event;
   mouseEvent = e;
   var targetEle = (document.all) ? e.srcElement : e.target;
   if(targetEle) currentElement = targetEle;
   x = (document.all) ? e.clientX : e.pageX;
   y = (document.all) ? e.clientY : e.pageY;
}

function clickContext() {
   if(currentElement != null && 
           currentElement.getAttribute("cont") != null && 
           currentElement.getAttribute("cont") != "") {
      window.setTimeout('showContext()', 1);
      return false;
   } else {
      return true;
   }
}

function clickContextDummy() {
   if (window.disableContextMenu){
      return(false);
   }
   if(currentElement != null && 
           currentElement.getAttribute("cont") != null && 
           currentElement.getAttribute("cont") != "") {
      return false;
   } else {
      return true;
   }
}

function clickIE() {
   if (window.disableContextMenu){
      return(false);
   }
   if(event.button == 2){
     if (currentElement != null && 
         currentElement.getAttribute("cont") != null && 
         currentElement.getAttribute("cont") != "") {
        window.disableContextMenu=1;
        window.setTimeout('showContext()', 1);
        return false;
     }
   } else {
      return true;
   }
   return(true);
}

function clickNS(e) {
   if ((e.which==2 || e.which==3) && 
            currentElement != null && 
            currentElement.getAttribute("cont") != null && 
            currentElement.getAttribute("cont") != ""){
      window.setTimeout('showContext()', 1);
      return false;
   } else {
      return true;
   }
}

function clickOpera(e) {
   if(!e) e = window.event;
   if ((e.which==2 || e.which==3) && 
            currentElement != null && 
            currentElement.getAttribute("cont") != null && 
            currentElement.getAttribute("cont") != ""){
      e.preventDefault();
      window.setTimeout('showContext()', 1);
      return false;
   } else {
      return true;
   }
}

function showContext() {
   if(currentElement) {
      whichMenu = currentElement.getAttribute("cont");
      if(whichMenu == null || whichMenu == "") return;
      var e = mouseEvent;
      var ele = document.getElementById('context_menu');
      var srcMenu = document.getElementById(whichMenu);
      if (!srcMenu) return;
      ele.innerHTML=srcMenu.innerHTML; // the srcMenu must be transfered to
      if(ele) {                        // to a global menu, to allo random
         currentContextMenu = ele;     // position of srcMenu
         ele.style.display = 'block';
         ele.style.visibility = 'visible';
         ele.style.left = '' + x + 'px';
         if (document.all){  // IE style 
            ele.style.top = '' + (y+document.body.scrollTop) + 'px';
         }
         else{
            ele.style.top = '' + y + 'px';
         }
      }
      window.setTimeout('hideContext()', 4000);
   }
}

function hideContext() {
   var ele = currentContextMenu;
   if(ele) {
      ele.style.display = 'none';
      ele.style.visibility = 'hidden';
      currentContextMenu=null;
      window.disableContextMenu=0;
   }
}
addEvent(window,"load",ContextMenuInit);

