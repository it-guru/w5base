
function setScreenBaseLayout(){

      var screen=$.mobile.getScreenHeight();

      $(".ui-content").height(1);
      $(".ui-content").width(640);
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
}

//$(document).on("pagecontainertransition",setScreenBaseLayout);
//$(window).on("resize",setScreenBaseLayout);
//$(window).on("load",setScreenBaseLayout);
//$(window).on("pageshow",setScreenBaseLayout);
//$(window).on("ready",setScreenBaseLayout);
//$(window).on("orientationchange",setScreenBaseLayout)


function call(f)
{
   window.setTimeout(f,10);
}

function Application(){
   this.run=function(){
       console.log("running Appl");
       console.log($.t("Back"));

   }
   return(this);
};
