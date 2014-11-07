$(document).ready(function (){
//   window.setTimeout(loadMgmtItemGroups,1);
//
  console.log("ready done");

$.mobile.loading( "show", {
  text: "foo",
  textVisible: true,
  theme: "a",
  html: "xxx"
});


});

$( document ).on( "mobileinit", function() {
  $.mobile.loader.prototype.options.text = "loading ...";
  $.mobile.loader.prototype.options.textVisible = true;
  $.mobile.loader.prototype.options.theme = "a";
  $.mobile.loader.prototype.options.html = "";
  console.log("mobileinit done");
});


function loadMgmtItemGroups()
{
   var o=getModuleObject(W5Base,"itil::mgmtitemgroup");
   o.SetFilter({cistatusid:"4",name:"top*"});  
   o.findRecord("name,id",addApplNames);
}


