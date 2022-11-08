require(['jquery',
         '../public/base/load/jquery.AjaxAutocomplete'],function(jQuery){
    $=jQuery;
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

});

   var W5ExploreForm = function(){
      this.maxIterations = 1000;

      this.removeForm=function(appletobj,formname){
         var workspace=appletobj.app.workspace;
         $("#formspace #"+formname).remove();
         $("#formspace>div:last").find('.readonly').remove();
         $("#formspace>div:last").removeAttr('inert');
         $("#formspace>div").last().find('button, a, input, '+
                              'select, textarea').removeAttr('readonly');
         $("#formspace>div").last().find('button, a, input, select, textarea,'+
                                    ' [tabindex]:not([tabindex="-1"])').first()
                                    .focus(); 
         $("#formspace>div").last().each(function(){
            appletobj.activateForm(this,$(this).attr("id"));
         });
      };



      this.setLastDivReadOnly=function(){
         $(".detailframe").append("<div class=readonly "+
             "style=\"position:absolute; top:0px; left:0px; "+
             "background-color: rgba(192, 192, 192, 0.1); "+
             "width: 100%; height: 100%; z-index: 2;\">"+
             "</div>");
         $("#formspace>div").last().attr('inert','1');
         //$("#formspace>div").last().find('button, a, input, '+
         //                             'select, textarea')
         //                   .attr('readonly', true);
      }


      this.addForm=function(appletobj,formname,callback){
         var that=this;
         var workspace=appletobj.app.workspace;
         that.removeForm(appletobj,formname);
         $.get("../../"+appletobj.TemplBase()+"."+formname+"?RAW=1",
              function(data, textStatus, jqXHR) {
                 that.setLastDivReadOnly();
                 $("#formspace").append("<div "+
                      "style=\"position:relative\" id=\""+formname+"\">"+
                      data+"</div>");
                 $(".detailframe").css({position:'relative'});
                 $("#"+formname).find('button, a, input, select, textarea,'+
                                      ' [tabindex]:not([tabindex="-1"])').first()
                                      .focus(); 
                 $("#"+formname).find('div[data-type=template]').each(function(){
                    var templ=$(this).attr("data-template");
                    var target=this;
                    $.ajax({
                       url:"../../tscape/load/tmpl/"+templ,
                       data:{RAW:'1'},
                       headers:{Accept:'text/html; charset=UTF-8;'},
                       success:function(d){
                          $(target).html(d);
                       }
                    });
                 });
                 appletobj.initForm($("#"+formname),formname);
                 appletobj.activateForm($("#"+formname),formname);
                 if (callback){
                    callback();
                 }
              }
         );
      };


      this.run=function(appletobj,paramstack){
         var app=appletobj.app;

         app.LayoutSimple();
         app.console.log("INFO","loading scenario ...");
         appletobj.app.setMPath(
             {
                label:ClassAppletLib[appletobj.SELFNAME()].desc.label,
                mtag:appletobj.SELFNAME()
             }
         );
         app.loadCss("public/base/load/Output.HtmlDetail.css");
         app.loadCss("public/base/load/jquery.AjaxAutocomplete.css");
      
         app.workspace.innerHTML="<div id=formspace "+
            "style=\"width:100%;height:10px;"+
            "border-style:solid:border-width:1px;"+
            "border-color:darkgray;overflow:auto\"></div>"+
            "<div id=formcontroler style=\"height:2px;border-top-style:solid;"+
            "border-top-width:2px;border-top-color:black\">"+
            "<table width=100% border=0 cellspacing=5 cellpadding=5>"+
            "<tr>"+
            "<td wdth=25%>"+
            "<input style=\"width:80px\" type=button class=FormOperation "+
            "value='abort' id='FormOperationBreak'>"+
            "</td>"+
            "<td wdth=25% align=center>"+
            "<input style=\"width:80px\" type=button class=FormOperation "+
            "value='back' id='FormOperationBack'>"+
            "</td>"+
            "<td width=25% align=center>"+
            "<input style=\"width:80px\" type=button class=FormOperation "+
            "value='next' id='FormOperationNext'>"+
            "</td>"+
            "<td width=25% align=right>"+
            "<input style=\"width:80px\" type=button class=FormOperation "+
            "value='save' id='FormOperationSave'>"+
            "</td>"+
            "</tr>"+
            "</table>"+
            "</div>";
         $(".FormOperation").css({cursor:'pointer'});
         $(".FormOperation").click(function(e){
            return(appletobj.FormOperation(e));
         });
         $(".spinner").hide();
      
         function resizeModalHandler(e){
            var workspace=$("#workspace");
            var h=$(workspace).height();
            $(workspace).find('#formcontroler').height(40);
            $(workspace).find('#formspace').height((h-40));
            if (e){
               e.stopPropagation();
            }
         }
         $(window).on('resize',resizeModalHandler);
         resizeModalHandler();
      };
   };
   define(function(){return(W5ExploreForm);});

