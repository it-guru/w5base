
function transformElement(e,param)
{
   if (param['type']==undefined){
      param['type']='text';
   }
   var i;
   if (param['type']=='text' ||
       param['type']=='button'){
      i=document.createElement("input");
      var i=document.createElement("input");
      i.setAttribute('type',param['type']);
      i.setAttribute('value',e.value); 
      i.setAttribute('name',e.name); 
      if (param['className']==undefined){
         i.setAttribute('class',e.className); 
      }
      else{
         i.setAttribute('class',param['className']);
         i.className=param['className'];
      }
      if (param['id']==undefined){
         if (e.id!=undefined || e.id!=""){
            i.setAttribute('id',e.id);
         }
      }
      else{
         i.id=param['id'];
      }
   }
   else{
      alert("ERROR: unknown target type '"+param['type']+"'");
   }
   p=e.parentNode;
   p.replaceChild(i,e);
 //  alert("fifi"+e.parentNode.name);

}
