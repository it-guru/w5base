function doSearch()
{
   var W5Base=createConfig({
                            useUTF8:false,
                            mode:'auth'
                           },'../../../../');
   var ModuleObjectName=$(this).attr("moduleobject");
   if (ModuleObjectName==""){
      return;
   }
   var o=getModuleObject(W5Base,ModuleObjectName);
   var result="";
   if (o.name()=="itil::appl"){
      o.SetFilter({
                       name:$("#searchtext").val(),
                       cistatusid:"<=4"
                     });

      var res=o.findRecord("name,tsm,systems");
      for(c=0;c<res.length;c++){
         result+=res[c].name+" TSM="+res[c].tsm+"<br>";
         console.log(res[c]);
      }
   }
   if (o.name()=="base::user"){
      o.SetFilter({
                       fullname:$("#searchtext").val(),
                       cistatusid:"<=4"
                     });

      var res=o.findRecord("fullname");
      for(c=0;c<res.length;c++){
         result+=res[c].fullname+"<br>";
      }
   }
   $("#Result").html(result)
               .css({overflow:"auto"});
}

function showUserinfo()
{
   var W5Base=createConfig({
                            useUTF8:false,
                            mode:'auth'
                           });
   var i=W5Base.ContextInfo();
   if (i && i.groupids && i.groupids.RMember && i.groupids.RMember.item){
      var d="";
      var gid=i.groupids.RMember.item;
      for(c=0;c<gid.length;c++){
         if (d!=""){
            d+=",";
         }
         d+=gid[c];
      }
      d+="<br>Hello: "+i.fullname;
      $("#Result").html(d).width("100%").height("100px")
                  .css({overflow:"auto"});
   }
   
   console.log(i);
}

function appStart()
{
   $(this).attr("title","J5Base - Sample Application"); // set window title
   $(".searchButton").click(doSearch);
   $("#userinfoButton").click(showUserinfo);
 //  $("#doToggle").click(switchResult);


}

$(document).ready(appStart);

