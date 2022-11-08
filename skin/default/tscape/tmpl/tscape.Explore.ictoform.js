var applet='%SELFNAME%';

define(["jquery","datadumper",
        "../../public/base/load/W5ExploreForms"],
 function ($,Dumper,W5ExploreForms){
   var W5Form=new W5ExploreForms();   // instance AppletClass object

   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   $.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);
   ClassAppletLib[applet].class.prototype.AppletClass=W5Form;
   ClassAppletLib[applet].class.prototype.SELFNAME=function(){return(applet);};
   ClassAppletLib[applet].class.prototype.TemplBase=function(){
      return('tscape/load/tmpl/tscape.Explore.ictoform');
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
               this.AppletClass.addForm(this,"subform2");
            }
         }
         else if (formname=='subform2'){
            if (this.ValidateFormStep(formname)){
               this.AppletClass.addForm(this,"subformCheck");
            }
         }
      }
      if (e.target.id=="FormOperationBack"){
         var formname=$("#formspace>div").last().attr("id");
         if (formname!="subform1"){
            this.AppletClass.removeForm(this,formname);
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
                  that.AppletClass.addForm(that,"subformEnd",function(){
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


   ClassAppletLib[applet].class.prototype.run=function(paramstack){
      var appletobj=this;
      var app=this.app;

      W5Form.run(appletobj,paramstack);   // default runhandler for AppletClass
      appletobj.AppletClass.addForm(appletobj,"subform1");
   };
   return(ClassAppletLib[applet].class);
});


