function forceLocationPath(curapp){
   if (!top.location.pathname.match(/\/index.html$/)){ // if top is not index
      top.location.pathname=
         top.location.pathname.replace(/\/[^\/]*$/,"/index.html");
   }
   if (top.location.search!="?"+curapp){ // make it reloadable
      top.location.search="?"+curapp;
   }
}

function getCurrentJ5BaseURL(){
   var j5baseurl=document.w5basesite+"/"+document.w5baseconfig+"/auth"+
                 "/base/load/J5Base.js";
   return(j5baseurl);
}

