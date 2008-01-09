	//created by Raine Lightner 2006
	
	var rot13array;
	
	//creates the array of alpha conversion
	function createROT13array()
	{
	  var rot13map = new Array();
	  var sAlphabet  = "abcdefghijklmnopqrstuvwxyz";
	  
	  for (i=0; i < sAlphabet.length; i++)
		rot13map[sAlphabet.charAt(i)] = sAlphabet.charAt((i + 13) % 26);
	  
	  for (i=0; i < sAlphabet.length; i++)
		rot13map[sAlphabet.charAt(i).toUpperCase()] = sAlphabet.charAt((i+ 13) % 26).toUpperCase();
	  
	  return rot13map;
	}
	
	//converts a string par
	function convertROT13String(a) {
		//
		if (!rot13array)
			rot13array=createROT13array();
		var sOutput = "";
		
		for (i=0; i<a.length; i++)
		{
			sOutput += convertROT13Char( a.charAt(i) );
		}
		
		return sOutput;
	}
	
	function convertROT13Char(a) {
		return (a>='A' && a<='Z' || a>='a' && a<='z' ? rot13array[a] : a);
	}
	
	function convertROTStringWithBrackets(s) {
		if (!rot13array)
			rot13array=createROT13array();
	
		var sChar = "";
		var sOutput = "";
		var bDecrypt = true;
		
		for( i = 0; i < s.length ; i++) {
			sChar = s.charAt(i);
			// check for line-break html tags
			if ( i < (s.length - 4) ) {
				if ( s.toLowerCase().substr( i, 4 ) == "<br>" ) {
					sOutput += "<br>";
					i += 3;
					continue;
				}
			}
			
			// ignore any text enclosed in [ ] brackets
			if (sChar == "[")
				bDecrypt = false;
			else if (sChar == "]")
				bDecrypt = true;
			else if ( (sChar == " ") || (sChar == "&dhbg;") ) {
				// do nothing
			}
			else {
				if (bDecrypt)
					sChar = convertROT13Char(sChar);
			}
				
			sOutput += sChar;
		}
	
		return sOutput;
	}