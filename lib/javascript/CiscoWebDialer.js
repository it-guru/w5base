


// JavaScript Document
//Singleton SOAP Client
var csWebDial = function(param){
   this.Proxy="../../../../auth/base/interface/SOAP";
   jQuery.extend(true,this,param);
   if (!this.mode){
      this.mode="auth";
   }
   if (param.mode=="public"){
      this.Proxy="../../../../public/base/interface/SOAP";
   }
   this.ContextInfo=function(){   // returns informations about the login
       var i={mode:this.mode};
       var user=getModuleObject(this,"base::user"); 
       i=user.doPing(true);
       return(i);
   }
	this.SOAPServer="";
	this.ContentType="text/xml";
	this.CharSet="utf-8";
	this.ResponseXML=null;
	this.ResponseText="";
	this.Status=0;
	this.ContentLength=0;
	this.Namespace=function(name, uri) {
		return {"name":name, "uri":uri};
	}
	this.SendRequest=function(soapReq,getResponse, callback) {		
		if(this.Proxy != null) {
			this.ResponseText = "";
			this.ResponseXML = null;
			this.Status = 0;
         this.callback=callback;
			
			var content = soapReq.toString();
			this.ContentLength = content.length;
			
         var acall={
            type: "POST",
            url: this.Proxy,
            dataType: "xml",
            processData: false,
            w5base: this,
            soapReq: soapReq,
            callback: callback,
            data: content,
            complete: getResponse,
            beforeSend: function(req) {
               req.setRequestHeader("Method",
                                    "POST");
               req.setRequestHeader("Content-Length", 
                                    this.w5base.ContentLength);
               req.setRequestHeader("Content-Type", 
                                   this.w5base.ContentType+ 
                                   "; charset=\""+this.w5base.CharSet+"\"");
              req.setRequestHeader("SOAPServer", 
                                   this.w5base.SOAPServer);
              req.setRequestHeader("SOAPAction", 
                                   this.soapReq.Action);
            }
         }
         if (callback){
            $.ajax(acall);
		   }
         else{
            acall.async=false;
            this.jsOut=undefined;
            var res=$.ajax(acall);
            res=this.jsOut;
            return(res);
         }
      }
	}
}
var ToXML=function(soapObj) {
		var out = "";
		var isNSObj=false;
		try {
			if(soapObj!=null && typeof(soapObj)=="object" && 
            soapObj.typeOf=="SOAPObject") {								
				//Namespaces
				if(soapObj.ns!=null) {
					if(typeof(soapObj.ns)=="object") {
						isNSObj=true;
						out+="<"+soapObj.ns.name+":"+soapObj.name;
						out+=" xmlns:"+soapObj.ns.name+"=\""+soapObj.ns.uri+"\"";
					} else  {
						out+="<"+soapObj.name;
						out+=" xmlns=\""+soapObj.ns+"\"";
					}
				} else {
					out+="<"+soapObj.name;
				}
				//Node Attributes
				if(soapObj.attributes.length > 0) {
					 var cAttr;
					 var aLen=soapObj.attributes.length-1;
					 do {
						 cAttr=soapObj.attributes[aLen];
						 if(isNSObj) {
						 	out+=" "+soapObj.ns.name+":"+
                          cAttr.name+"=\""+cAttr.value+"\"";
						 } else {
							out+=" "+cAttr.name+"=\""+cAttr.value+"\"";
						 }
					 } while(aLen--);					 					 
				}
				out+=">";
				//Node children
				if(soapObj.hasChildren()) {					
					var cPos, cObj;
					for(cPos in soapObj.children){
						cObj = soapObj.children[cPos];
						if(typeof cObj == "object"){out+=ToXML(cObj);}
					}
				}
				//Node Value
				if(soapObj.value != null){out+=soapObj.XMLvalue();}
				//Close Tag
				if(isNSObj){out+="</"+soapObj.ns.name+":"+soapObj.name+">";}
				else {out+="</"+soapObj.name+">";}
				return out;
			}
		} catch(e){alert("Unable to process SOAPObject! Object must be an instance of SOAPObject");}
	}
//Soap request - this is what being sent using SOAPClient.SendRequest
var SOAPRequest=function(uri,method, soapObj) {
	this.Action=uri+"#"+method;	
	var nss=[];
	var headers=[];
	var bodies=(soapObj!=null)?[soapObj]:[];
	this.addNamespace=function(ns, uri){nss.push(new SOAPClient.Namespace(ns, uri));}	
	this.addHeader=function(soapObj){headers.push(soapObj);};
	this.addBody=function(soapObj){bodies.push(soapObj);}
	this.toString=function() {
		var soapEnv = new SOAPObject("soapenv:Envelope");
			soapEnv.attr("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
			soapEnv.attr("xmlns:appl","http://w5base.net/mod/itil/appl");
		//Add Namespace(s)
		if(nss.length>0){
			var tNs, tNo;
			for(tNs in nss){tNo=nss[tNs];if(typeof(tNo)=="object"){soapEnv.attr("xmlns:"+tNo.name, tNo.uri)}}
		}
		//Add Header(s)
		if(headers.length>0) {
			var soapHeader = soapEnv.appendChild(new SOAPObject("soapenv:Header"));
			var tHdr;
			for(tHdr in headers){soapHeader.appendChild(headers[tHdr]);}
		}
		//Add Body(s)
		if(bodies.length>0) {
			var soapBody = soapEnv.appendChild(new SOAPObject("soapenv:Body"));
			var tBdy;
			for(tBdy in bodies){soapBody.appendChild(bodies[tBdy]);}
		}
      //alert("fifi "+soapEnv.toString());
		return soapEnv.toString();		
	}
}

//Soap Object - Used to build body envelope and other structures
var SOAPObject = function(name,value) {
	this.typeOf="SOAPObject";
	this.ns=null;
	this.name=name;
	this.attributes=[];
	this.children=[]
	this.value=null;
   this.XMLvalue=function() {
     return this.value.replace(/&/g,'&amp;')
                .replace(/</g,'&lt;').replace(/>/g,'&gt;');
   }

   if (value){
	   this.value=value;
   }
	this.attr=function(name, value){this.attributes.push({"name":name, "value":value});return this;};
	this.appendChild=function(obj){this.children.push(obj);return obj;};
	this.hasChildren=function(){return (this.children.length > 0)?true:false;};
	this.val=function(v){if(v==null){return this.value}else{this.value=v;return this;}};	
	this.toString=function(){
      return ToXML(this);
   }		
}


