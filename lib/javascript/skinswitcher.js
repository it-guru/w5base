function setSkin(name){
   //console.log("set new W5SKIN to:"+name);
   //console.log("setSkin this=",this);
   setTimeout(function(){
      var aNewBodyElement = this.document.createElement("body");
      var aText = document.createElement("div");
      aText.innerHTML="Prepairing ...";
      this.document.body=aNewBodyElement
      this.document.body.appendChild(aText);
   },10);

   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST","setSkin",true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4 && (xmlhttp.status==200 || xmlhttp.status==304)){
       var res = JSON.parse(xmlhttp.responseText);
       if ((res) && res.exitcode==0){
          eval('top.location.reload(true);');
       }
    }
   };
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   xmlhttp.setRequestHeader('Accept','application/json');
   var r=xmlhttp.send('name='+name);









//   if (!name.length){
//      setCookie("W5SKIN","",-1,path);
//   }
//   else{
//      setCookie("W5SKIN",name,999999,path);
//   }
   //if (Cache && Cache.delete){
   //   console.log("try to delete the cache");
   //   Cache.delete();
   //}
   //if (window.location && window.location.reload){
//   eval('top.location.reload(true);');
   //}
   //top.document.location.href=top.document.location.href;
}
