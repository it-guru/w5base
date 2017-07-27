function setSkin(name){
   if (!name.length){
      setCookie("W5SKIN","",-1,"/");
   }
   else{
      setCookie("W5SKIN",name,999999,"/");
   }
   top.document.location.href=top.document.location.href;
}
