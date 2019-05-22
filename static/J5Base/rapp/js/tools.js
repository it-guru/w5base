function forceLocationPath(curapp){
   if (!top.location.pathname.match(/\/index.html$/)){ // if top is not index
      top.location.pathname=
         top.location.pathname.replace(/\/[^\/]*$/,"/index.html");
   }
   if (top.location.search!="?"+curapp){ // make it reloadable
      top.location.search="?"+curapp;
   }
}

function getCurrentW5BaseURL(){
   var w5baseurl=document.w5basesite+"/"+document.w5baseconfig;
   return(w5baseurl);

}

function getCurrentJ5BaseURL(){
   var j5baseurl=getCurrentW5BaseURL()+"/public"+"/base/load/J5Base.js";
   return(j5baseurl);
}

