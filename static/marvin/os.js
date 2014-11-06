
function setScreenBaseLayout(){
   console.log("screen resize");

  // setTimeout(function(){
      var screen=$.mobile.getScreenHeight();

      var header=$(".ui-header").hasClass("ui-header-fixed") ? 
                 $(".ui-header").outerHeight()-1 : 
                    $(".ui-header").outerHeight();

      var footer=$(".ui-footer").hasClass("ui-footer-fixed") ? 
                 $(".ui-footer").outerHeight()-1 : 
                    $(".ui-footer").outerHeight();

      var contentCurrent=$(".ui-content").outerHeight()-
                 $(".ui-content").height();

      content=screen-header-footer-contentCurrent;
      $(".ui-content").height(content);
  // },1);
}

//$(document).on("pagecontainertransition",setScreenBaseLayout);
//$(window).on("resize",setScreenBaseLayout);
//$(window).on("load",setScreenBaseLayout);
//$(window).on("ready",setScreenBaseLayout);
//$(window).on("orientationchange",setScreenBaseLayout)

