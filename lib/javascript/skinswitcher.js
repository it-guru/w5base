function setSkin(name){
   if (!name.length){
      setCookie("W5SKIN","",-1,"/");
   }
   else{
      setCookie("W5SKIN",name,999999,"/");
   }
   //if (Cache && Cache.delete){
   //   console.log("try to delete the cache");
   //   Cache.delete();
   //}
   //if (window.location && window.location.reload){
   eval('top.location.reload(true);');
   //}
   //top.document.location.href=top.document.location.href;
}
