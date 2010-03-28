var slideCount = 0;
var styleNumber = 0;
var styleRatio  = 0;
var slideArray = [];
var currentSlide = 1;
var lang="default";


function positionSlide(slide) {
    if (slide<0){
       slide=0;
    }
    else if (slide>=slideCount){
       slide=slideCount;
    }
    hideSlide(slideArray[currentSlide]);
    currentSlide = slide;
    showSlide(slideArray[currentSlide]);
    setXofYLabel();
    enableButtons();
}

function setXofYLabel() {
    var lnk="<a href=\""+document.location.href+"\" target=_blank>";
    $("#page").html(lnk+currentSlide+"</a>");
    $("#pagecount").text(slideCount+"("+styleNumber+")");
}

/**
 * Positions the slide deck to the next slide
 */
function nextSlide() {
   positionSlide(currentSlide + 1);
}

/**
 * Positions the slide deck to the previous slide
 */
function prevSlide() {
   positionSlide(currentSlide - 1);
}

function enableButtons() {
    if (currentSlide === 1) {
        $("#first").addClass("firstdisabled")
                   .removeClass("firstenabled")
                   .attr("disabled","disabled");
        $("#prev").addClass("previousdisabled")
                  .removeClass("previousenabled")
                  .attr("disabled","disabled");
        $("#next").removeClass("nextdisabled")
                  .addClass("nextenabled")
                  .removeAttr("disabled");
        $("#last").removeClass("lastdisabled")
                  .addClass("lastenabled")
                  .removeAttr("disabled");
    } else if (currentSlide === slideCount) {
        $("#first").removeClass("firstdisabled")
                   .addClass("firstenabled")
                   .removeAttr("disabled");
        $("#prev").removeClass("previousdisabled")
                  .addClass("previousenabled")
                  .removeAttr("disabled");
        $("#next").addClass("nextdisabled")
                  .removeClass("nextenabled")
                  .attr("disabled","disabled");
        $("#last").addClass("lastdisabled")
                  .removeClass("lastenabled")
                  .attr("disabled","disabled");
    } else {
        $("#first").removeClass("firstdisabled")
                   .addClass("firstenabled")
                   .removeAttr("disabled");
        $("#prev").removeClass("previousdisabled")
                  .addClass("previousenabled")
                  .removeAttr("disabled");
        $("#next").removeClass("nextdisabled")
                  .addClass("nextenabled")
                  .removeAttr("disabled");
        $("#last").removeClass("lastdisabled")
                  .addClass("lastenabled")
                  .removeAttr("disabled");
    }
}

/**
 * Checks every key event for a key ID that we want to respond to
 */
var KeyCheck = function(e) {
    var KeyID = (window.event) ? event.keyCode : e.keyCode;
    switch(KeyID) {
        case 37:    //the left arrow key
            prevSlide();
            e.returnValue = false;
            return false;
        case 39:    // the right arrow key
     //   case 32:    //the space key
            nextSlide();
            e.returnValue = false;
            return false;
        case 35:    // the end key
            positionSlide(slideCount);
            e.returnValue = false;
            return false;
        case 36:    // the home key
            positionSlide(1);
            e.returnValue = false;
            return false;
    }
};


var addListener = function(element, type, expression, bubbling)
{
    bubbling = bubbling || false;
 
    if(window.addEventListener) { // Standard
        element.addEventListener(type, expression, bubbling);
        return true;
    } else if(window.attachEvent) { // IE
        element.attachEvent('on' + type, expression);
        return true;
    } else {
        return false;
    }
};

function selectStyleSheet()
{
   var resizeCss=$("link#resize").attr("href");
   if (resizeCss!=undefined){
      var docHeight=$(document).height();
      var docWidth=$(document).width();
      var newStyleNumber;
      if (docHeight<150 || docWidth<200){
         newStyleNumber=0;
      }
      else if (docHeight<300 || docWidth<300){
         newStyleNumber=1;
      }
      else if (docHeight<400 || docWidth<600){
         newStyleNumber=2;
      }
      else if (docHeight<500 || docWidth<700){
         newStyleNumber=3;
      }
      else if (docHeight<600 || docWidth<800){
         newStyleNumber=4;
      }
      else if (docHeight<700 || docWidth<900){
         newStyleNumber=5;
      }
      else if (docHeight<900 || docWidth<1100){
         newStyleNumber=6;
      }
      else if (docHeight<1100 || docWidth<2048){
         newStyleNumber=7;
      }
      else if (docHeight<1400 || docWidth<2500){
         newStyleNumber=8;
      }
      else{
         newStyleNumber=9;
      }
      var newCss=resizeCss.replace(/size\.[0-9]\./g,
                                   "size."+newStyleNumber+".");
      if (newStyleNumber!=styleNumber){
         styleNumber=newStyleNumber;
         $("link#resize").attr("href",newCss);
         window.setTimeout(resizePresenter,10);
      }
   }
}

function resizePresenter()
{
   $("#Presenter").height(0);
   var navHeight=$("#Navigator").height();
   var docHeight=$(document).height();
   var PresenterHeight=docHeight-navHeight;
   $("#Presenter").height(PresenterHeight);
   selectStyleSheet();
   setXofYLabel();
}



function addReloadMethod()
{
   var oldloc=document.location.href;
   //document.location.href="";
   var curid=slideArray[currentSlide].attr("id");
   if (curid!=undefined){
      var h="#"+curid;
      document.location.hash=h;
     // oldloc.replace(/#[0-9a-z]+$/ig,"");
     // oldloc+=h;
   }
   document.location.href=oldloc;
   document.location.reload();
}



function addIndexMethod()
{
   var d="";
   var oldc;
   for(i=1;i<slideArray.length;i++){
      var t=slideArray[i].attr("title");
      var c=slideArray[i].attr("category");
      if (c!=oldc){
         d+="<b>"+c+"</b><br>";
      }
      oldc=c;
      d+="<span style=\"cursor:pointer;color:darkblue\" "+
         "onclick=\"positionSlide("+i+");\">Slide "+i+"</span>: "+t+"<br>";
   }
   if (slideArray.length>10){
      d="<div style='height:150px;overflow:auto'>"+d+"</div>";
   }
   $("#index-message").html(d);
   $("#index-message").dialog({
      autoOpen: false, 
      modal: true,
      buttons: {
         Ok: function() {
            $(this).dialog('close');
         }
      }
   });
   $("#index-message").dialog('open');
}



function addHelpMethod()
{
   $("#help-message").load("bin/ui.presenter.Help."+lang+".html",
                           function (){
      $("#help-message").dialog({
         autoOpen: false, 
         modal: true,
         buttons: {
            Ok: function() {
               $(this).dialog('close');
            }
         }
      });
      $("#help-message").dialog('open');
   });
}



function initNavigator()
{
   resizePresenter();
   $("#prev").click(prevSlide);
   $("#next").click(nextSlide);
   $("#first").click(function (){
      positionSlide(1);
   });
   $("#last").click(function (){
      positionSlide(slideCount);
   });
   $("#help").click(addHelpMethod);
   $("#index").click(addIndexMethod);
   $("#reload").click(addReloadMethod);

   positionSlide(currentSlide);  
}



function createPresenter()
{
   // create the main window - presenter
   var Presenter = document.createElement('div');
   Presenter.setAttribute("id","Presenter");
   Presenter.setAttribute("class","ControlBase Presenter");
   document.body.appendChild(Presenter);

   // create the navigation bar
   var Navigator = document.createElement('div');
   Navigator.setAttribute("id","Navigator");
   Navigator.setAttribute("class","ControlBase Navigator");
   document.body.appendChild(Navigator);
   $("#Navigator").load("bin/ui.presenter.Navigator."+lang+".html",initNavigator);
   $(window).resize(function(){
      resizePresenter();
   });
}



function hideSlide(div)
{
   // noop
}



function showSlide(div)
{
   var divHead="<div class=slide style='display:block;visibility:visible'>";
   var divBottom="</div>";
   $("#Presenter").html(divHead+div.html()+divBottom);
   if (document.baseTitle==undefined){
      if (document.title==undefined){
         document.baseTitle="";
      }
      else{
         document.baseTitle=document.title;
      }
   }
   if (div.attr("title")!="" && div.attr("title")!="undefined"){
      document.title=document.baseTitle+":"+div.attr("title");
   }
   else{
      document.title=document.baseTitle;
   }
}



$(document).ready(function () {
   var browserLang;
   if (navigator.appName == 'Netscape')
      browserLang=navigator.language;
   else
      browserLang=navigator.browserLanguage;
   if ($.query.get("lang")!=undefined){
      browserLang=$.query.get("lang");
   }

   if (browserLang=="de" ||
       browserLang=="en"){
      lang=browserLang;
   }

   //alert(document.location.hash);
   $(".slide").each(function () {
       slideCount++;
       slideArray[slideCount] = $(this);
       if ($(this).attr("id")=="" || $(this).attr("id")=="undefined"){
          $(this).attr("id","S"+slideCount);
       }
       var slideId="#"+$(this).attr("id");
       if (slideId==document.location.hash ||
           document.location.hash==$(this).attr("id")){
          currentSlide=slideCount;
       }
   });
  
   // initialize the presenations div
   createPresenter();
 
   // add key handler 
   addListener(document, 'keyup', KeyCheck);
});

