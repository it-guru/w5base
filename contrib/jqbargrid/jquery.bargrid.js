(function($) {
$.fn.bargrid = function (setOptions) {
   var defaultOptions = {
      name:         "",      // FUTURE REFERENCE - not used right now
      vari1:        true,    // test
      rowHeigh:     35,
      colWidth:     50,
      colCount:     10,
   };
   
   $.extend(setOptions,defaultOptions);
   

   // ------------------------------------------------------------------
   function clear(){
      $(this).html("");
   };
   // ------------------------------------------------------------------
   function draw(){
      $.each($(this),function(){
         var opts=this.opts;

         var rowLabelTable="";
         rowLabelTable+="<table border=1>";
         $.each(this.opts.row,function(){
            rowLabelTable+="<tr height=\""+opts.rowHeigh+"\"><td>"+
                           this.label+"</td></tr>";
         });
         rowLabelTable+="</table>";

         var colLabelTable="";
         colLabelTable+="<table border=1><tr height=\""+opts.rowHeigh+"\">";
         $.each(this.opts.col,function(){
            colLabelTable+="<td align=center width=\""+opts.colWidth+"\">"+
                           this.label+"</td>";
         });
         colLabelTable+="</table>";

         var masterTab="<table border=1>";
         masterTab+="<tr><td></td><td>"+colLabelTable+"</td></tr>";
         masterTab+="<tr><td>"+rowLabelTable+"</td><td>data</td></tr>";
         masterTab+="</table>";
         this.target.html(masterTab);
      });
   }
   // ------------------------------------------------------------------

   return({
      target:$(this),
      opts: setOptions,
      draw  :draw,
   });
}})(jQuery);

