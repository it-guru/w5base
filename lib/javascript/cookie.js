function wrCookie(name,value,path,hours) {
   var date = new Date();
   if (!hours){
      date.setTime(date.getTime()+(3650*24*60*60*1000));
   }
   else{
      date.setTime(date.getTime()+(3600*hours*1000));
   }
   var expires = "; expires="+date.toGMTString();
   document.cookie = name+"="+value+expires+"; path="+
                     normalizeRequestPath(path);
}

function normalizeRequestPath(p)
{
   var href=document.location.href; //path must be calced dynamicly
   var path=href.substring(0,href.indexOf("/public/"));
   if (path==""){
       path=href.substring(0,href.indexOf("/auth/"));
   }
   path=path.replace(/^.*:\/\/.*?\//,"/");
   //alert("document.location.href="+path);
   path = path+p;
   return(path);
}


function rdCookie(name) {
   var nameEQ = name + "=";
   var ca = document.cookie.split(';');
   for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while(c.charAt(0)==' ') 
         c=c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) 
         return c.substring(nameEQ.length,c.length);
   }
   return null;
}

function rmCookie(name) {
   wrCookie(name,"",-1);
}
