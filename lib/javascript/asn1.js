var ID   = new Array();
var NAME = new Array();

ID['BOOLEAN']          = 0x01;
ID['INTEGER']          = 0x02;
ID['BITSTRING']        = 0x03;
ID['OCTETSTRING']      = 0x04;
ID['NULL']             = 0x05;
ID['OBJECTIDENTIFIER'] = 0x06;
ID['ObjectDescripter'] = 0x07;
ID['UTF8String']       = 0x0c;
ID['SEQUENCE']         = 0x10;
ID['SET']              = 0x11;
ID['NumericString']    = 0x12;
ID['PrintableString']  = 0x13;
ID['TeletexString']    = 0x14;
ID['IA5String']        = 0x16;
ID['UTCTime']          = 0x17;
ID['GeneralizedTime']  = 0x18;

var i;
for ( i in ID ){
	NAME[ID[i]] = i;
}

var OID = new Array();

var TAB = "                              ";
var TAB_num = -1;

var Bitstring_hex_limit = 4;

var isEncode = new RegExp("[^0-9a-zA-Z\/=+]", "i");
var isB64    = new RegExp("[^0-9a-fA-F]", "i");

function convert(src, ans, mode){
	var srcValue = src.value.replace(/[\s\r\n]/g, '');
	
	if ( mode == 'auto' ){
		if ( srcValue.match(isEncode) ){
			mode = 'encode';
		}
		else if ( srcValue.match(isB64) ){
			mode = 'decode_B64';
		}
		else {
			mode = 'decode_HEX';
		}
	}

	if ( mode == 'encode'){
		ans.value = encode(srcValue);
		return;
	}
	else if ( mode == 'decode_B64'){
		if ( srcValue.match(isEncode) ){
			if ( confirm("Illegal character for Decoding process.\nDo you wish to continue as Encoding process?") ){
				ans.value = encode(srcValue);
				return;
			}
			else{
				return;
			}
		}
		//ans.value = bin2hex(base64decode(srcValue));
		ans.value = decode(bin2hex(base64decode(srcValue)));
	}
	else if ( mode == 'decode_HEX'){
		if ( srcValue.match(isB64) ){
			if ( confirm("Illegal character for Decoding process.\nDo you wish to continue as Encoding process?") ){
				ans.value = encode(srcValue);
				return;
			}
			else{
				return;
			}
		}
		ans.value = decode(srcValue);
	}
}

function encode(src){
	var ans;
	return ans;
}
function decode(src){
	if ( src.length % 2 != 0 ){
		alert('Illegal length. Hex string\'s length must be even.');
	}
	return readASN1(src);
}

function readASN1(data){
	var point = 0;
	var ret = "";
	TAB_num++;

	while ( point < data.length ){

		// Detecting TAG field (Max 1 octet)

		var tag10 = parseInt("0x" + data.substr(point, 2));
		var isSeq = tag10 & 32;
		var isContext = tag10 & 128;
		var tag = tag10 & 31;
		var tagName = isContext ? "[" + tag + "]" : NAME[tag];
		if ( tagName == undefined ){
			tagName = "Unsupported_TAG";
		}

		point += 2;
		
		// Detecting LENGTH field (Max 2 octets)

		var len = 0;
		if ( tag != 0x5){	// Ignore NULL
			if ( parseInt("0x" + data.substr(point, 2)) & 128 ){
				var lenLength = parseInt("0x" + data.substr(point, 2)) & 127;
				if ( lenLength > 2 ){
					var error_message = "LENGTH field is too long.(at " + point
					 + ")\nThis program accepts up to 2 octets of Length field.";
					alert( error_message );
					return error_message;
				}
				len = parseInt("0x" + data.substr( point+2, lenLength*2));
				point += lenLength*2 + 2;  // Special thanks to Mr.(or Ms.) T (Mon, 25 Nov 2002 23:49:29)
			}
			else if ( lenLength != 0 ){  // Special thanks to Mr.(or Ms.) T (Mon, 25 Nov 2002 23:49:29)
				len = parseInt("0x" + data.substr(point,2));
				point += 2;
			}
			
			if ( len > data.length - point ){
				var error_message = "LENGTH is longer than the rest.\n";
					+ "(LENGTH: " + len + ", rest: " + data.length + ")";

				alert( error_message );
				return error_message;
			}
		}
		else{
			point += 2;
		}

		// Detecting VALUE
		
		var val = "";
		var tab = TAB.substr(0, TAB_num*3);
		if ( len ){
			val = data.substr( point, len*2);
			point += len*2;
		}

		ret += tab + tagName + " ";
		ret += ( isSeq ) ? "{\n" + readASN1(val) + tab + "}" : getValue( isContext ? 4 : tag , val);
		ret += "\n";
	};
	
	TAB_num--;
	return ret;
}

function getValue(tag, data){
	var ret = "";
	
	if (tag == 1){
		ret = data ? 'TRUE' : 'FALSE';
	}
	else if (tag == 2){
		ret = (data.length < 3 ) ? parseInt("0x" + data) : data + ' : Too long Integer. Printing in HEX.';
	}
	else if (tag == 3){
		var unUse = parseInt("0x" + data.substr(0, 2));
		var bits  = data.substr(2);
		
		if ( bits.length > Bitstring_hex_limit ){
			ret = "0x" + bits;
		}
		else{
			ret = parseInt("0x" + bits).toString(2);
		}
		ret += " : " + unUse + " unused bit(s)";
	}
	else if (tag == 5){
		ret = "";
	}
	else if (tag == 6){
		var res = new Array();
		var d0 = parseInt("0x" + data.substr(0, 2));
		res[0] = Math.floor(d0 / 40);
		res[1] = d0 - res[0]*40;
		
		var stack = new Array();
		var powNum = 0;
		var i;
		for(i=1; i < data.length -2; i=i+2){
			var token = parseInt("0x" + data.substr(i+1,2));
			stack.push(token & 127);
			
			if ( token & 128 ){
				powNum++;
			}
			else{
				var j;
				var sum = 0;
				for (j in stack){
					sum += stack[j] * Math.pow(128, powNum--);
				}
				res.push( sum );
				powNum = 0;
				stack = new Array();
			}
		}
		ret = res.join(".");
		if ( OID[ret] ) {
			ret += " (" + OID[ret] + ")";
		}
	}
	else if (NAME[tag].match(/(Time|String)$/) ) {
		var k = 0;
		ret += "'";
		while ( k < data.length ){
			ret += String.fromCharCode("0x"+data.substr(k, 2));
			k += 2;
		}
		ret += "'";
	}
	else{
		ret = data;
	}
	return ret;
}

function init_oid( src_text ){
	var lines = new Array();
	lines = src_text.split(/\r?\n/);
	
	var i;
	for ( i in lines ){
		var item = new Array();
		item = lines[i].split(/,/);
		
		var j;
		for ( j in item ){
			item[j] = item[j].replace(/^\s+/);
			item[j] = item[j].replace(/\s+$/);
		}
		
		
		if ( item.length < 2 || item[0].match(/^#/) ){
			continue;
		}
		
		if ( item[0].match(/[^0-9\.\-\s]/) ){
			OID[ item[1] ] = item[0];
		}
		else{
			OID[ item[0] ] = item[1];
		}
	}
}

function bin2hex(bin){
	var hex = "";
	var i = 0;
	var len = bin.length;
	
	while ( i < len ){
		var h1 = bin.charCodeAt(i++).toString(16);
		if ( h1.length < 2 ){
			hex += "0";
		}
		hex += h1;
	}

	return hex;
}

/* I have copied the routine for decoding BASE64 from 
   http://www.onicos.com/staff/iz/amuse/javascript/expert/base64.txt */

var base64chr = new Array(
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1);
function base64decode(str) {
	var c1, c2, c3, c4;
	var i, len, out;
	len = str.length;
	i = 0;
	out = "";
	while(i < len) {
		/* c1 */
		do {
		    c1 = base64chr[str.charCodeAt(i++) & 0xff];
		} while(i < len && c1 == -1);
		if(c1 == -1){ break; }

		/* c2 */
		do {
		    c2 = base64chr[str.charCodeAt(i++) & 0xff];
		} while(i < len && c2 == -1);
		if(c2 == -1){ break; }
		out += String.fromCharCode((c1 << 2) | ((c2 & 0x30) >> 4));

		/* c3 */
		do {
		    c3 = str.charCodeAt(i++) & 0xff;
		    if(c3 == 61) { return out; }
		    c3 = base64chr[c3];
		} while(i < len && c3 == -1);
		if(c3 == -1) { break; }
		out += String.fromCharCode(((c2 & 0XF) << 4) | ((c3 & 0x3C) >> 2));

		/* c4 */
		do {
		    c4 = str.charCodeAt(i++) & 0xff;
		    if(c4 == 61) { return out; }
		    c4 = base64chr[c4];
		} while(i < len && c4 == -1);
		if(c4 == -1) { break; }
		out += String.fromCharCode(((c3 & 0x03) << 6) | c4);
	}
	return out;
}
