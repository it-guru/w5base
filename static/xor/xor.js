function encrypt(str, pwd){
   var prand = "";
   for (var i=0;i<pwd.length;i++){
      prand+=pwd.charCodeAt(i).toString();
   }
   console.log("prand",prand);
   var sPos=Math.floor(prand.length / 5);

   var mult=parseInt(prand.charAt(sPos)+prand.charAt(sPos*2)+
            prand.charAt(sPos*3)+prand.charAt(sPos*4)+
            prand.charAt(sPos*5));
   if (mult<2){
      alert("Algorithm cannot find a suitable hash. "+
            "Please choose a different password. \n"+
            "Possible considerations are to choose "+
            "a more complex or longer password.");
      return null;
   }
   console.log("mult",mult);

   var incr=Math.ceil(pwd.length / 2);
   var modu=Math.pow(2, 31) - 1;
   var salt=Math.round(Math.random()*1000000000)%100000000;
   console.log("salt",salt);
   prand+=salt;
   console.log("prand",prand);
   while(prand.length>10){
      prand=(parseBigInt(prand.substring(0, 10),16)+
             parseBigInt(prand.substring(10,prand.length),16)).toString();
      console.log("1prand",prand);
   }
   console.log("2prand",prand);
   prand=(mult*prand+incr)%modu;
   var enc_chr="";
   var enc_str="";
   for (var i=0;i<str.length;i++){
   console.log("i",i);
      enc_chr=parseInt(str.charCodeAt(i)^Math.floor((prand / modu) * 255));
      if (enc_chr<16){
         enc_str+="0"+enc_chr.toString(16);
      } 
      else{
         enc_str += enc_chr.toString(16);
      }
      prand = (mult * prand + incr) % modu;
   }
   salt = salt.toString(16);
   while(salt.length<8){
      salt = "0" + salt;
   }
   enc_str += salt;
   return(enc_str);
}

function decrypt(str, pwd) {
   if (str==null || str.length<8){
      alert("A salt value could not be extracted from the encrypted "+
            "message because it's length is too short. "+
            "The message cannot be decrypted.");
      return;
   }
   if (pwd==null || pwd.length<=0){
      alert("Please enter a password with which to decrypt the message.");
      return;
   }
   var prand = "";
   for(var i=0;i<pwd.length;i++){
      prand += pwd.charCodeAt(i).toString();
   }
   var sPos=Math.floor(prand.length / 5);
   var mult=parseInt(prand.charAt(sPos)+
            prand.charAt(sPos*2)+prand.charAt(sPos*3)+
            prand.charAt(sPos*4) + prand.charAt(sPos*5));
   console.log("mult",mult);
   var incr=Math.round(pwd.length / 2);
   console.log("incr",incr);
   var modu=Math.pow(2, 31) - 1;
   console.log("modu",modu);
   var salt=parseInt(str.substring(str.length - 8, str.length), 16);
   console.log("salt",salt);
   str=str.substring(0, str.length - 8);
   prand+=salt;
   console.log("prand pre while",prand);
   while(prand.length>10){
      console.log("prand:"+prand);
      console.log("s1:"+prand.substring(0, 10));
      console.log("s2:"+prand.substring(10, prand.length));
      prand=(parseBigInt(prand.substring(0, 10),16)+ 
             parseBigInt(prand.substring(10, prand.length)),16).toString();
   }
   prand=(mult*prand+incr)%modu;
   console.log("prand",prand);
   var enc_chr="";
   var enc_str="";
   for(var i=0;i<str.length;i+=2){
      enc_chr=parseInt(parseInt(str.substring(i,i+2),16)^
              Math.floor((prand/modu)* 255));
      enc_str+=String.fromCharCode(enc_chr);
      prand = (mult * prand + incr) % modu;
   }
   return(enc_str);
}

function parseBigInt(str,r) {
  return new BigInteger(str,r);
}

