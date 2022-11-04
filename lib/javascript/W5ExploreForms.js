(function (factory) {
   if (typeof define === 'function' && define.amd) {
       // AMD. Register as an anonymous module.
       define(['jquery'], factory);
   } else if (typeof exports === 'object' && typeof require === 'function') {
       // Browserify
       factory(require('jquery'));
   } else {
       // Browser globals
       factory(jQuery);
   }
}(function ($) {

    function W5Field_autocomplete(){
    }

    function W5Field(el, options) {
       var that = this;
       that.element = el;
       that.el = $(el);
       that.options = $.extend(true, {}, W5Field.defaults, options);
       
       if (that.options.type=='autocomplete'){
          this.W5Field_autocomplete();
       }
       if (that.options.type=='text'){
          this.W5Field_text();
       }
       if (that.options.type=='select'){
          this.W5Field_select();
       }
    };

    W5Field.prototype = {
        initialize: function () {
           console.log("W5Field.prototype initialize");
        },
        W5Field_select:function(){
           var el=this.el;

           var path=this.options.vjointo;
           path=path.replaceAll("::","/"); 

           var vjoinbase;
           if (this.options.vjoinbase){
              vjoinbase=this.options.vjoinbase;
           }

           var query={};
           query['FormatAs']='nativeJSON';

           if (vjoinbase){
              $.each(vjoinbase,function(k,v){
                 query['search_'+k]=v;
              });
           }

           var rkeyfld="fullname";
           var rvalfld="id";
           if (this.options.vjoindisp){
              rvalfld=this.options.vjoindisp;
           } 
           if (this.options.vjoinon){
              rkeyfld=this.options.vjoinon;
           }

           $.ajax({
                 type: "POST",
                 url:'../../../auth/'+path+'/Result',
                 data: query,
                 dataType: "json",
                 success: function(data){
                    $(el).empty()
                    $.each(data,function(index,rec){
                       $(el).append($("<option></option>")
                            .attr("value",rec[rkeyfld]).text(rec[rvalfld])); 
                    });
                 },
                 failure: function(errMsg) {
                     alert(errMsg);
                 }
           });
        },
        W5Field_text:function(){
           if (this.options.maxlength){
              $(this.el).attr("maxlength",this.options.maxlength);
           }
           if (this.options.alphanum){
              $(this.el).keydown(function (e){
                 var k = e.keyCode || e.which;
                 var ok = k >= 65 && k <= 90 || // A-Z
                    k >= 96 && k <= 105 || // a-z
                    k >= 35 && k <= 40 || // arrows
                    k == 9 || //tab
                    k == 46 || //del
                    k == 8 || // backspaces
                    (!e.shiftKey && k >= 48 && k <= 57); 
                 if(!ok || (e.ctrlKey && e.altKey)){
                    e.preventDefault();
                 }
              });
           }
        },
        W5Field_autocomplete:function(){
           var path=this.options.vjointo;
           path=path.replaceAll("::","/"); 

           var targetfield=this.options.vjoindisp;
           if (targetfield==''){
              targetfield='fullname';
           }

           var vjoinbase;
           if (this.options.vjoinbase){
              vjoinbase=this.options.vjoinbase;
           }
           var vjoinon;
           if (this.options.vjoinon){
              vjoinon=this.options.vjoinon;
           }
           var remotefield="id";
           var localfield;
           if (vjoinon.length>1){
              localfield=vjoinon[0];
              remotefield=vjoinon[1];
           }
           if (vjoinon.length==1){
              remotefield=vjoinon[0];
           }
           $(this.el).autocomplete({
              serviceUrl:'../../../auth/'+path+'/Result',
              type:'POST',
              paramName:'search_'+targetfield,
              minChars: 2,
              maxHeight:100,
              dataType:'json',
              showNoSuggestionNotice:true,
              onSelect:function (suggestion) {
                 if (localfield){
                    $("#"+localfield).val(suggestion.data.id);
                 }
              },
              onSearchStart:function (query){
                 query['search_'+targetfield]=
                               '"*'+query['search_'+targetfield]+'*"';
                 if (vjoinbase){
                    $.each(vjoinbase,function(k,v){
                       query['search_'+k]=v;
                    });
                 }
                 query.FormatAs="nativeJSON";
                 query.CurrentView="("+targetfield+","+remotefield+")";
                 query.Limit="50";
                 return(query);
              },
              autoSelectFirst:true,
              ajaxSettings:{
                 headers:{
                    Accept: 'application/json'
                 }
              },
              transformResult:function(response, originalQuery) {
                 var r={
                    suggestions:new Array()
                 };
                 for(var c=0;c<response.length;c++){
                    r.suggestions.push({value:response[c][targetfield],data:{
                       id:response[c][remotefield]
                    }});
                 }
                 return(r);
              },
           });
        }
    };
    

    $.fn.addAlertTip=function(txt){
        return this.each(function () {
           $(this).addClass("alert");
           $(this).parent().addClass("alerttip")
           $(this).parent().append("<span class=\"alerttiptext\">"+
                                   txt+"</span>");
        });
    };

    $.fn.remAlertTip=function(txt){
        return this.each(function () {
           $(this).parent().find(".alerttiptext").remove();
           $(this).removeClass("alert");
           $(this).parent().removeClass("alerttip");
        });
    };




    $.fn.devbridgeW5Field = function (options, args) {
        var dataKey = 'w5field';
        // If function invoked without argument return
        // instance of the first matched element:
        if (!arguments.length) {
            return this.first().data(dataKey);
        }

        return this.each(function () {
            var inputElement = $(this),
                instance = inputElement.data(dataKey);

            if (typeof options === 'string') {
                if (instance && typeof instance[options] === 'function') {
                    instance[options](args);
                }
            } else {
                // If instance already exists, destroy it:
                if (instance && instance.dispose) {
                    instance.dispose();
                }
                instance = new W5Field(this, options);
                inputElement.data(dataKey, instance);
            }
        });
   };

   $.W5Field=W5Field;
   W5Field.defaults={
      xxx:'xxx'
   };

   $.fn.W5Field=$.fn.devbridgeW5Field;
}));

var W5ExploreForms = (function(){
	var maxIterations = 1000;
   var s={
      f1:function(){
         console.log("fifi f1");
      }
   };
   return(s);

})();
if (define){
   define([],function(){return(W5ExploreForms);});
}
