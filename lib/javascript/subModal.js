/**
 * POPUP WINDOW CODE v1.1
 * Used for displaying DHTML only popups instead of using buggy modal windows.
 *
 * By Seth Banks (webmaster at subimage dot com)
 * http://www.subimage.com/
 *
 * Contributions by Eric Angel (tab index code) and Scott (hiding/showing selects for IE users)
 *
 * Up to date code can be found at http://www.subimage.com/dhtml/subModal
 *
 * This code is free for you to use anywhere, just keep this comment block.
 */

// Popup code
var gPopupMask = null;
var gPopupContainer = null;
var gPopFrame = null;
var gReturnFunc;
var gPopupIsShown = false;

var gHideSelects = false;


var gTabIndexes = new Array();
// Pre-defined list of tags we want to disable/enable tabbing into
var gTabbableTags = new Array("A","BUTTON","TEXTAREA","INPUT","IFRAME");   

// If using Mozilla or Firefox, use Tab-key trap.
if (!document.all) {
   document.onkeypress = keyDownHandler;
}



/**
 * Initializes popup code on load.   
 */
function initPopUp() {
   gPopupMask = document.getElementById("popupMask");
   gPopupContainer = document.getElementById("popupContainer");
   gPopFrame = document.getElementById("popupFrame");   
   gPopData = document.getElementById("popupData");   
   // check to see if this is IE version 6 or lower. hide select boxes if so
   // maybe they'll fix this in version 7?
   var brsVersion = parseInt(window.navigator.appVersion.charAt(0), 10);
   if (brsVersion <= 6 && window.navigator.userAgent.indexOf("MSIE") > -1) {
      gHideSelects = true;
   }
   //alert("initPopUp() gPopupMask="+gPopupMask+" gPopupContainer="+gPopupContainer);
}
addEvent(window, "load", initPopUp);
initPopUp();

 /**
   * @argument width - int in pixels
   * @argument height - int in pixels
   * @argument url - url to display
   * @argument returnFunc - function to call when returning true from the window.
   */

function resizePopWin(width,height){
   var titleBarHeight = parseInt(document.getElementById("TitleBar").offsetHeight, 10);
//alert("fifi height="+height+" width="+width);

   if (width!=null){   
      gPopupContainer.style.width = (width-1) + "px";
   }
   gPopupContainer.style.height = (height+titleBarHeight) + "px";
   // need to set the width of the iframe to the title bar width because of the dropshadow
   // some oddness was occuring and causing the frame to poke outside the border in IE6
   //gPopFrame.style.width = parseInt(document.getElementById("TitleBar").offsetWidth, 10) + "px"; // offensichtlich buggy
   gPopFrame.style.height = (height-6) + "px";
   gPopFrame.style.width = (width-6) + "px";
   gPopData.style.height = (height-6) + "px";
   gPopData.style.width = (width-6) + "px";
}

function showPopWin(url, width, height, returnFunc) {
   gPopupIsShown = true;
   disableTabIndexes();
   
   gPopupMask.style.display = "block";
   gPopupContainer.style.visibility = "visible";
   gPopupContainer.style.display = "block";
   // calculate where to place the window on screen
   if (height==null){   
      gPopupContainer.dynamicHeight=function(){return(getViewportHeight()-80)};
      height=gPopupContainer.dynamicHeight();
   }
   else{
      gPopupContainer.dynamicHeight=undefined;
   }
   if (width==null){   
      gPopupContainer.dynamicWidth=function(){return(getViewportWidth()-50)};
      width=gPopupContainer.dynamicWidth();
   }
   else{
      gPopupContainer.dynamicWidth=undefined;
   }
   centerPopWin(width, height);
   resizePopWin(width,height);
   
   
   // set the url
   if (url){
      if (typeof(url)==='function'){
         var d=url();
         gPopData.innerHTML=url();
         gPopData.style.visibility="visible";
         gPopData.style.display="block";
         gPopFrame.style.visibility="hidden";
         gPopFrame.style.display="none";
         var e=gPopData.elements;
         var inputs = gPopData.getElementsByTagName('*');
         if (inputs){
            for (var i=0;i<inputs.length;i++){
                if (inputs[i].tagName.toLowerCase()=='textarea' ||
                    inputs[i].tagName.toLowerCase()=='input'){
                   inputs[i].focus();
                   break;
                }
            }
         }
      }
      else{
         gPopData.style.visibility="hidden";
         gPopData.style.display="none";
         gPopFrame.style.visibility="visible";
         gPopFrame.style.display="block";
         gPopFrame.onload=function(){
            //console.log("is loaded");
            this.contentWindow.focus();
            //console.log("focus done");
         };
         gPopFrame.src = url;
         window.setTimeout("setPopTitle();", 600);
      }
   }
   
   gReturnFunc = returnFunc;
   // for IE
   if (gHideSelects == true) {
      hideSelectBoxes();
   }
   
}

//
var gi = 0;
function centerPopWin(width, height) {
   if (gPopupIsShown == true) {
      if (typeof width==='object' && width!==null ){ //resize event
         if (gPopupContainer.dynamicWidth){
            width=gPopupContainer.dynamicWidth();
         }
         if (gPopupContainer.dynamicHeight){
            height=gPopupContainer.dynamicHeight();
         }
         if (width>0 && height>0){
            resizePopWin(width,height);
         }
      }
      if (width == null || isNaN(width)) {
         width = gPopupContainer.offsetWidth;
      }
      if (height == null || isNaN(height)) {
         height = gPopupContainer.offsetHeight;
      }
      
      var fullHeight = getViewportHeight();
      var fullWidth = getViewportWidth();
      
      var theBody = document.documentElement;
      
      var scTop = parseInt(theBody.scrollTop,10);
      var scLeft = parseInt(theBody.scrollLeft,10);
      
      gPopupMask.style.height = (fullHeight-2) + "px";
      gPopupMask.style.width = (fullWidth-2) + "px";
      gPopupMask.style.top = scTop + "px";
      gPopupMask.style.left = scLeft + "px";
      
      window.status=gPopupMask.style.top+" "+gPopupMask.style.left+" "+gi++;
      
      var titleBarHeight=
           parseInt(document.getElementById("TitleBar").offsetHeight, 10);
      
      gPopupContainer.style.top=
           (scTop+((fullHeight-(height+titleBarHeight))/2))+"px";

      gPopupContainer.style.left=
           (scLeft+((fullWidth-width)/2))+"px";
      //alert(fullWidth + " " + width + " " + gPopupContainer.style.left);
   }
}
addEvent(window, "resize", centerPopWin);
//addEvent(window, "scroll", centerPopWin);
window.onscroll = centerPopWin;

/**
 * @argument callReturnFunc - bool - determines if we call the return function specified
 * @argument returnVal - anything - return value 
 */
function hidePopWin(callReturnFunc) {
   hidePopWin(callReturnFunc,0)
}
function hidePopWin(callReturnFunc,isbreak,sendReturnVal) {
   gPopupIsShown = false;
   restoreTabIndexes();
   if (gPopupMask == null) {
      return;
   }
   gPopupMask.style.display = "none";
   gPopupContainer.style.visibility = "hidden";
   gPopupContainer.style.display = "none";
   if (callReturnFunc == true && gReturnFunc != null) {
      if (sendReturnVal){
         gReturnFunc(sendReturnVal,isbreak);
      }
      else{
         gReturnFunc(window.frames["popupFrame"].returnVal,isbreak);
      }
   }
   var href=document.location.href; //path must be calced dynamicly
   var path=href.substring(0,href.indexOf("/public/"));
   if (path==""){
       path=href.substring(0,href.indexOf("/auth/"));
   }
   //alert("document.location.href="+path);
   gPopFrame.src = path+'/public/base/msg/Empty';
   // display all select boxes
   if (gHideSelects == true) {
      displaySelectBoxes();
   }
}

/**
 * Sets the popup title based on the title of the html document it contains.
 * Uses a timeout to keep checking until the title is valid.
 */
function setPopTitle(windowTitle) {
   if (!windowTitle){
      if (window.frames["popupFrame"].document.title == null) {
         window.setTimeout("setPopTitle();", 50);
      } else {
         document.getElementById("popupTitle").innerHTML = window.frames["popupFrame"].document.title;
      }
      window.setTimeout("setPopTitle();", 1500);
   }
   else{
      document.getElementById("popupTitle").innerHTML = windowTitle;
   }
}

// Tab key trap. iff popup is shown and key was [TAB], suppress it.
// @argument e - event - keyboard event that caused this function to be called.
function keyDownHandler(e) {
    if (gPopupIsShown && e.keyCode == 9)  return false;
}

// For IE.  Go through predefined tags and disable tabbing into them.
function disableTabIndexes() {
   if (document.all) {
      var i = 0;
      for (var j = 0; j < gTabbableTags.length; j++) {
         var tagElements = document.getElementsByTagName(gTabbableTags[j]);
         for (var k = 0 ; k < tagElements.length; k++) {
            gTabIndexes[i] = tagElements[k].tabIndex;
            tagElements[k].tabIndex="-1";
            i++;
         }
      }
   }
}

// For IE. Restore tab-indexes.
function restoreTabIndexes() {
   if (document.all) {
      var i = 0;
      for (var j = 0; j < gTabbableTags.length; j++) {
         var tagElements = document.getElementsByTagName(gTabbableTags[j]);
         for (var k = 0 ; k < tagElements.length; k++) {
            tagElements[k].tabIndex = gTabIndexes[i];
            tagElements[k].tabEnabled = true;
            i++;
         }
      }
   }
}


/**
* Hides all drop down form select boxes on the screen so they do not appear above the mask layer.
* IE has a problem with wanted select form tags to always be the topmost z-index or layer
*
* Thanks for the code Scott!
*/
function hideSelectBoxes() {
   for(var i = 0; i < document.forms.length; i++) {
      for(var e = 0; e < document.forms[i].length; e++){
         if(document.forms[i].elements[e].tagName == "SELECT") {
            document.forms[i].elements[e].style.visibility="hidden";
         }
      }
   }
}

/**
* Makes all drop down form select boxes on the screen visible so they do not reappear after the dialog is closed.
* IE has a problem with wanted select form tags to always be the topmost z-index or layer
*/
function displaySelectBoxes() {
   for(var i = 0; i < document.forms.length; i++) {
      for(var e = 0; e < document.forms[i].length; e++){
         if(document.forms[i].elements[e].tagName == "SELECT") {
         document.forms[i].elements[e].style.visibility="visible";
         }
      }
   }
}

