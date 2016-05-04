(function($){
  $.fn.extend({
      ellipsis:function(params){
         var conf = {};
         $.extend(conf, params);
         return $(this).each(function(){
             function tl(o,t){
                var cont = $('<div>'+t+'</div>').css("display", "table")
                   .css("z-index", "-1").css("position", "absolute")
                   .css("font-family", o.css("font-family"))
                   .css("font-size", o.css("font-size"))
                   .css("font-weight", o.css("font-weight")).appendTo('body');
                var cwidth=cont.width();
                cont.remove();
                return(cwidth);
             }
             function dotdotdot(o,bottomcnt){
                var max=o.parent().width();
                var txt=o.text();
                //console.log("1max=",max,"for ",txt,"parent=",o.parent(),"o=",o);
                var tchk=txt;
                for(var c=bottomcnt+3;c<txt.length;c++){
                   if (tl(o,tchk)>max){
                      tchk=txt.substring(txt.length-c,0)+"..."+
                           txt.substring(txt.length-bottomcnt-1,txt.length);
                   }
                }
                o.text(tchk);
                //console.log("2max=",max,"for ",txt,"parent=",o.parent(),"o=",o);
                o.width(max);
             }
             dotdotdot($(this),10);
         });
      }
  });
})(jQuery);
