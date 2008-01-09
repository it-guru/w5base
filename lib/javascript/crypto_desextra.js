//the base 64 characters
var BASE64 = new Array ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');

//Convert a string into base64
function stringToBase64 (s) {
  var r = "", c1, c2, c3; //remember the original length of the string
  for (var i=0; i<s.length; i+=3) { //3 input characters at a time, converted to 4 base 64 characters
    c1 = s.charCodeAt(i); //1st input character
    c2 = i+1 >= s.length ? 0 : s.charCodeAt(i+1); //2nd input or 0
    c3 = i+2 >= s.length ? 0 : s.charCodeAt(i+2); //3rd input or 0
    r += BASE64[c1>>2]; //the 1st base64 characters comes from the 1st 6 bits of the 1st character
    r += BASE64[((c1&0x3)<<4) | (c2>>4)]; //the next one comes from 2 bits of the 1st and 4 of the 2nd
    r += c2 ? BASE64[((c2&0xf)<<2) | (c3>>6)] : "="; //then 4 of the 2nd and 2 of the 3rd or put = at the end of the string
    r += c3 ? BASE64[c3&0x3f] : "="; //then 6 of the 3rd character, or output an equals
  } //for every 3 input charachters
  return r; //return the result
}

//Convert a base64 string into a normal string
function base64ToString (s) {
  var decode = new Object();
  for (var i=0; i<BASE64.length; i++) {decode[BASE64[i]] = i;} //inverse of the array
  decode['='] = 0; //add the equals sign as well
  var r = "", c1, c2, c3, c4, len=s.length; //define variables
  s += "===="; //just to make sure it is padded correctly
  for (var i=0; i<len; i+=4) { //4 input characters at a time
    c1 = s.charAt(i); //the 1st base64 input characther
    c2 = s.charAt(i+1);
    c3 = s.charAt(i+2);
    c4 = s.charAt(i+3);
    r += String.fromCharCode (((decode[c1] << 2) & 0xff) | (decode[c2] >> 4)); //reform the string
    if (c3 != '=') r += String.fromCharCode (((decode[c2] << 4) & 0xff) | (decode[c3] >> 2));
    if (c4 != '=') r += String.fromCharCode (((decode[c3] << 6) & 0xff) | decode[c4]);
  }
  return r;
}

//String replace function that works on older Javascript versions where String.replace hasn't
//been implemented.
function stringReplace (s, from, to) {
  var pos = 0; var inf=0;
  while ((pos = s.indexOf (from, pos)) >= 0 && inf++<1000) {
    s = s.substr (0, pos) + to + s.substr (pos + from.length);
    pos += to.length;
  }
  return s;
}

//Add entities to a plain text string for any character over 128
function stringToEntities (s) {
  var r = "", c;
  for (var i=0; i<s.length; i++) {
    c = s.charCodeAt (i);
    r += (c<32 || c==38 || c>127) ? ("&#" + c + ";") : s.charAt (i); 
  }
  return r;
}

//Convert a string with entities back into a normal string
function entitiesToString (s) {
  var r = "", c;
  for (var i=0; i<s.length; i++) { //loop through all the characters
    if (s.charAt(i) == "&" && s.charAt(i+1) == "#") { //if I find a &#
      var d = 0; //keep a number count
      for (i=i+2; i<s.length; i++) { //start looping again
        c = s.charCodeAt(i); //get the next digit
        if (c >= 48 && c <= 57) {d = d * 10 + c - 48;} //if it's a number then add it
        else {break;} //or else break and go back to the main loop
      } //for each number
      if (d > 0) {r += String.fromCharCode (d);} //add the number to the string
    } //if there was an &#
    else r += s.charAt(i); //or else just add the character as it is
  }
  return r; //return the result
}



function stringToHex (s) {
  var r = "0x";
  var hexes = new Array ("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");
  for (var i=0; i<s.length; i++) {r += hexes [s.charCodeAt(i) >> 4] + hexes [s.charCodeAt(i) & 0xf];}
  return r;
}

function hexToString (h) {
  var r = "";
  for (var i= (h.substr(0, 2)=="0x")?2:0; i<h.length; i+=2) {r += String.fromCharCode (parseInt (h.substr (i, 2), 16));}
  return r;
}

function integerToHex (n) {
  var r = "0x", z=0, h=0;
  //if (n < 0) {return n;} //if leftmost bit is set, return a negative number
  if (n < 0) {n = -n; r = "-0x";}
  else if (n >= 0x80000000) {n = -n - 0x100000000; r = "-0x";}
  var hexes = new Array ("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");
  for (var i=28; i>=0; i-=4) {h = (n>>i)&0xf; z+=h; if (z) {r += hexes[h];}}
  if (r == "0x") {r = "0";}
  return r;
}

function integerArrayToHex (a) {
  for (var i=0; i<a.length; i++) {a[i] = integerToHex (a[i], 0);}
  return "new Array (" + a.join (",") + ");";
}

function integerToBinary (input) {
  var display = new Array(); //the variable for displaying
  var ander = 0x1;
  var numbits = 32;
  for (var bit=0; bit<numbits; bit++) {
    //extract the bit-th bit from the input
    display[numbits-1-bit] = Math.abs ((input & ander) >> bit) + (bit % 8 ? '' : ' ');
    ander = ander << 1; //ander doubles each time
  }
  return display.join('');
}
 

//moveBits
//produces an array for moving bits around, bits should be between 1 and 32
//for example, moveBits (16, 7, 2, 23) will produce an array with 16 elements
//such that when you pass in 4 bits, they will be moved to the requested places
function moveBits () {
  var results = new Array (Math.pow(2,arguments.length));
  var hexes = new Array(arguments.length);
  //loop through each argument and put the new bits in place
  for (var i=hexes.length; i>0; i--) {hexes[hexes.length-i] = arguments[i-1] ? (0x1 << (32 - arguments[i-1])) : 0;}
  //now loop through each number and create the array
 
  //loop through each number from 0 to 2 ^ number of bits
  for (var i=0; i<results.length; i++) {
    results[i] = 0x0;
    //for each number, loop through each bit
    for (var j=0; j<hexes.length; j++) {
      //if this bit is turned on, then add the relevent result
      if ((i >>> j) & 0x1) {results[i] |= hexes[j];}
    } //for each bit
  } //for 2 ^ number of bits
 
  //return the array
  return results;
}

//convertStable
//this converts the four rows of an S table into the right order
function convertStable (s) {
  var results = new Array ();
  var stable = s.split(' ');
  //the length of each row in the S table
  var eachrow = stable.length/4;
  //rearrange the table
  for (var i=0; i<eachrow; i++) {
    results[i*2] = parseInt (stable[i]); //the top row
    results[i*2+1] = parseInt (stable[i + eachrow]); //the second row
    results[(i+eachrow)*2] = parseInt (stable[i + eachrow*2]);
    results[(i+eachrow)*2+1] = parseInt (stable[i + eachrow*3]);
  }
  return results;
}

//createSfunction
//This takes where the bits should be moved to, and an array containing the selection,
//and returns the movements applied to the selections. It can be used to create
//the S function arrays. Such as: 
//document.writeln (integerArrayToHex (createSfunction (moveBits ( 8, 16, 22, 30), convertStable ("14 4 13 1 2 15 11 8 3 10 6 12 5 9 0 7 0 15 7 4 14 2 13 1 10 6 12 11 9 5 3 8 4 1 14 8 13 6 2 11 15 12 9 7 3 10 5 0 15 12 8 2 4 9 1 7 5 11 3 14 10 0 6 13"))));
function createSfunction (movedbits, sselection) {
  var results = new Array ();
  for (var i=0; i<sselection.length; ++i) {results[i] = movedbits[sselection[i]];}
  return results;
}
 
//wherethingsgo
//this function analyses what happens to each bit in an operation
//it is passed code which manipulates the "left" and "right" variables
function wherethingsgo (description, code) {
  var leftbit=0x0, rightbit=0x1, found = new Array();
  var bit, look, temp;
  //initialse the found array
  for (bit=0; bit<=63; bit++) {found[bit] = 0;}
  //perform the operation on each bit, starting with the last bit of right
  for (bit=64; bit>=1; bit--) {
    //run the code, which shoud operate on the variables left and right
    left=leftbit; right=rightbit;
    eval (code);
    //alert ("Bit: " + bit + "\nLeft:" + integerToBinary(left) + "\nRight:" + integerToBinary(right));
    //now try and find the bit, by looping through left or right
    if (temp= left) {look=0; while (temp!=1) {temp >>>= 1; look++;} found[31-look] = bit;}
    if (temp=right) {look=0; while (temp!=1) {temp >>>= 1; look++;} found[63-look] = bit;}
    if (bit > 33) {rightbit <<= 1;}
    if (bit == 33) {leftbit = 0x1; rightbit = 0x0;}
    if (bit < 33) {leftbit <<= 1;}
  } //for each bit
  //display the results
  temp = description ? ("<B>" + description + "</B>:" ): "";
  temp += "<TABLE BORDER=0><TR><TD ALIGN=RIGHT WIDTH=25>";
  for (bit=0; bit<=63; bit++) {temp += "</TD>" + (bit%8 ? "" : "</TR>\n<TR>") + "<TD ALIGN=RIGHT WIDTH=25>" + found[bit];}
  temp += "</TD></TR></TABLE><P>";
  document.writeln (temp);
}

function timeTrial () {
    var type = "DES ECB with local vars", upto=6, howmany=2; //8 and 3 for real tests
    var key, inputvector, ciphertext, total;
    var starttime, endtime;
    var resultarray = new Array(), messagearray = new Array();

    var inputvector = integersToString (new Array (0x12345678,0x90abcdef));
    var key = integersToString (new Array (0x01234567,0x89abcdef));
    var r = "<table border=0 cellspacing=10><tr><td>Type</td><td>Bytes</td>";

    message = "0123456789012345678901234567890123456789012345678901234567890123"; //64 bytes
    message += message; 128
    for (var i=0; i<upto; i++) { //build the message array
      message += message; //does 256, 512, 1024, 2048, 4096, etc
      messagearray[i] = message;
    }
  
    for (var j=0; j<howmany; j++) { //do three sets of trials
      r += "<td>Trial " + (j+1) + "</td>";
      for (var i=0; i<upto; i++) { //do with successive sizes
        starttime = (new Date()).getTime();
        ciphertext = des (key, messagearray[i], 1, 0, inputvector);
        endtime = (new Date()).getTime();
        resultarray[j*upto + i] = (endtime-starttime); //store all the resulting times
      }
    }

    r += "<td>Average</td><td>sec/kb</td></tr>\n";
    for (var i=0; i<upto; i++) { //do with successive sizes
      total = 0;
      r += "<tr><td>" + type + "</td><td align=right>" + messagearray[i].length + "</td>";
      for (var j=0; j<howmany; j++) {
        total += resultarray[j*upto + i];
        r += "<td align=right>" + (resultarray[j*upto + i] / 1000) + "</td>";
      }
      r += "<td align=right>" + (Math.ceil (total/howmany) / 1000) + "</td>";
      r += "<td align=right>" + (Math.ceil (1024 * ((total/howmany) / messagearray[i].length)) / 1000) + "</td>";
      r += "</tr>\n";
    }

    r += "</table>";
    document.writeln (r + "<p>");
    //r = r.replace (/</g, "<");
    //r = r.replace (/>/g, ">");
    //r = r.replace (/\n/g, "<br>");
    //document.writeln (r);
}
