var applet='%SELFNAME%';

define(["datadumper","W5ExploreForms","AjaxAutocomplete"],function (Dumper,W5ExploreForms,AjaxAutocomplete){
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);



   ClassAppletLib[applet].class.prototype.removeForm=function(formname){
      var appletobj=this;
      var workspace=this.app.workspace;
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



   ClassAppletLib[applet].class.prototype.setLastDivReadOnly=function(){
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


   ClassAppletLib[applet].class.prototype.addForm=function(formname,callback){
      var appletobj=this;
      var workspace=this.app.workspace;
      this.removeForm(formname);
      $.get("../../tscape/load/tmpl/tscape.Explore.ictoform."+formname+"?RAW=1",
           function(data, textStatus, jqXHR) {
              appletobj.setLastDivReadOnly();
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

   /////////////////////////////////////////////////////////////////
   // Form Event methods

   ClassAppletLib[applet].class.prototype.ValidateFormStep=function(formname){
      if (formname=='subform1'){
         var formok=true;
         if ($("#enddate").val()==""){
            $("#enddate").addAlertTip(
                "%TRANSLATE(NoEmpty,tscape::template::messages)%");
            $("#enddate").blur(function() {
               $("#enddate").remAlertTip();
            })
            $("#enddate").focus();
            formok=false;
         }

         if ($("#applname").val()==""){
            $("#applname").addAlertTip(
                "%TRANSLATE(NoEmpty,tscape::template::messages)%");
            $("#applname").blur(function() {
               $("#applname").remAlertTip();
            })
            $("#applname").focus();
            formok=false;
         }


         if (!formok) return(false);
      }

      return(1);
   }


   ClassAppletLib[applet].class.prototype.FormOperation=function(e){
      if (e.target.id=="FormOperationNext"){
         var formname=$("#formspace>div").last().attr("id");
         if (formname=='subform1'){
            if (this.ValidateFormStep(formname)){
               this.addForm("subform2");
            }
         }
         else if (formname=='subform2'){
            if (this.ValidateFormStep(formname)){
               this.addForm("subformCheck");
            }
         }
      }
      if (e.target.id=="FormOperationBack"){
         var formname=$("#formspace>div").last().attr("id");
         if (formname!="subform1"){
            this.removeForm(formname);
         }
      }
      if (e.target.id=="FormOperationSave"){
         var msg="";
         var fields=new Array("applname","applmgr","applmgrid","w5appl");
         $.each(fields,function(i,fld){
            msg+="<b>"+fld+" :</b>\n";
            var v=$("#"+fld).val();
            msg+=v+" <br><br>";
         });


         var that=this;
         $.ajax({
               type: "POST",
               url:'../../../auth/base/workflow/externalMailHandler',
               headers : { Accept : 'application/json' },
               data: {
                  ACTION:'send',
                  to:'hartmut.vogler@telekom.de',
                  subject:'Form: ICT-Request',
                  msg:msg,
                  senderbcc:'1'
               },
               dataType: "json",
               success: function(data){
                  console.log("data=",data);
                  that.addForm("subformEnd",function(){
                     $("#endmsg").html("1st data");
                     var res="";
                     res+=data.lastmsg[0];
                     res+="<br>";
                     if (data.urlofcurrentrec){
                        res+="<br>"+
                    "%TRANSLATE(your reference,tscape::template::messages)%: "+
                             "<a href=\""+data.urlofcurrentrec+"\" "+
                             "target=_blank>"+
                             data.urlofcurrentrec+"</a><br>";
                     }
                     $("#endmsg").html(res);
                 });
               },
               error: function() { 
                 alert('fail:');
               }
         });
      }
   };


   ClassAppletLib[applet].class.prototype.initForm=function(frm,formname){
      var appletobj=this;
      if (formname=="subform1"){
         // -------------------------------------------------
         // prefill ApplicationManager field with current user
         // contact (readonly)
         $.ajax({
               type: "POST",
               url:'../../../auth/base/user/Result',
               headers : { Accept : 'application/json' },
               data: {
                  search_fullname:'[SELF]',
                  CurrentView:'(fullname,userid)'
               },
               dataType: "json",
               success: function(data){
                  $("#applmgr").val(data[0].fullname);
                  $("#applmgrid").val(data[0].userid);
               }
         });
         // -------------------------------------------------

         $("#shortname").W5Field({
            type:'text',
            maxlength:16,
            whitepace:false,
            charspace:['alphanum']
         });

         $("#applmgr").W5Field({
            type:'autocomplete',
            vjointo:'base::user',
            vjoindisp:'fullname',
            vjoinon:['applmgrid','userid'],
            vjoinbase:{
               cistatusid:'4',
               usertyp:'!service'
            }
         });

         $("#resporgit").W5Field({
            type:'select',
            vjointo:'tscape::organisation',
            vjoindisp:'name',
            vjoinon:'name'    // id field
           // vjoinbase:{
           //    name:'*T*'
           // }
         });

         $("#projectmgr").W5Field({
            type:'autocomplete',
            vjointo:'base::user',
            vjoindisp:'fullname',
            vjoinon:['projectmgrid','userid'],
            vjoinbase:{
               cistatusid:'4',
               usertyp:'user extern'
            }
         });
      }
      if (formname=="subform2"){
         $("#shortname").W5Field({
            type:'text',
            maxlength:20,
            whitepace:false,
            charspace:['ascii']
         });
      }
      if (formname=="subformCheck"){
         setTimeout(function() {
            $("#lastmsg").html(
             "OK - all valid - now you can save the formular");
            $("#FormOperationSave").show();
         }, 1000);
      }
   };



   ClassAppletLib[applet].class.prototype.activateForm=function(frm,formname){
      var appletobj=this;

      $("#FormOperationBreak").hide();
      $("#FormOperationSave").hide();
      if (formname=="subform1" || formname=="subformEnd"){
         $("#FormOperationBack").hide();
      }
      else{
         $("#FormOperationBack").show();
      }
      if (formname=="subformCheck" || formname=="subformEnd"){
         $("#FormOperationNext").hide();
      }
      else{
         $("#FormOperationNext").show();
      }
   };
   /////////////////////////////////////////////////////////////////




   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      var app=this.app;

      this.app.LayoutSimple();
      this.app.console.log("INFO","loading scenario ...");
      appletobj.app.setMPath(
          {
             label:ClassAppletLib['%SELFNAME%'].desc.label,
             mtag:'%SELFNAME%'
          }
      );
      app.loadCss("public/base/load/Output.HtmlDetail.css");
      app.loadCss("public/base/load/jquery.AjaxAutocomplete.css");
      this.app.workspace.innerHTML="<div id=formspace "+
         "style=\"width:100%;height:10px;border-style:solid:border-width:1px;"+
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
      // init the 1st subform
      appletobj.addForm("subform1");
   };
   return(ClassAppletLib[applet].class);
});


