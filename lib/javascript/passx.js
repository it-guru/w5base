function verifypassword(key)
{
  var f=document.forms[0];

  var cdata=f.elements['verify'].value;
  var plain=des(key, hexToString(cdata), 0, 0,false);
  plain=plain.substring(0,plain.length-1); // remove binary 0 at the end
  if (plain=="KeyIsOK"){
     return(1);
  }
  return(0);
}
function unecryptkeys(key)
{
  if (!verifypassword(key)){
     alert("invalid personal password or undefined key");
     return;
  }
  var f=document.forms[0];
  var l=new Array('p','q','d','dmp1','dmq1','coeff');
  for(c=0;c<l.length;c++){
     var cdata=f.elements[l[c]].value;
     var plain=des(key, hexToString(cdata), 0, 0,false);
     plain=plain.replace(/\u0000/g, '');  // do not know, why 0 bytes in
     f.elements['plain_'+l[c]].value=plain;
  }
  var l=new Array('n','e');
  for(c=0;c<l.length;c++){
     var plain=f.elements[l[c]].value;
     f.elements['plain_'+l[c]].value=plain;
  }
}

