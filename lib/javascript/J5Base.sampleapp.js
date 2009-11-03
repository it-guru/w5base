function doSearch()
{
   var W5Base=createConfig({
                            useUTF8:false,
                            mode:'auth'
                           });
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

      var res=o.findRecord("name,tsm");
      for(c=0;c<res.length;c++){
         //result+=res[c].name+" TSM="+Utf8.decode(res[c].tsm)+"<br>";
         result+=res[c].name+" TSM="+res[c].tsm+"<br>";
      }
   }
   if (o.name()=="base::user"){
      o.SetFilter({
                       fullname:$("#searchtext").val(),
                       cistatusid:"<=4"
                     });

      var res=o.findRecord("fullname");
      for(c=0;c<res.length;c++){
         result+=Utf8.decode(res[c].fullname)+"<br>";
      }
   }
   $("#Result").html(result).width("100%").height("100px")
               .css({overflow:"auto"});
}

function appStart()
{
   $(this).attr("title","J5Base - Sample Application"); // set window title
   $(".searchButton").click(doSearch);


}

$(document).ready(appStart);

