
var ERROR="ERROR";
var WARN="WARN";
var INFO="WARN";
var LOG="LOG";
var MSG="MSG";
var DEBUG="DEBUG";

// JavaScript Document
//Singleton SOAP Client
var SOAPClient = function(param,baseUrl){
   this.baseUrl=baseUrl;
   this.Proxy="../../../../auth/base/interface/SOAP";
   this.getModuleObject=function(module){
      return(new W5baseObject(this,module));
   }
   jQuery.extend(true,this,param);
   if (!this.mode){
      this.mode="auth";
   }
   if (!this.baseUrl){
       this.baseUrl="../../../";
   }
   if (param.mode=="public"){
      this.Proxy=this.baseUrl+"public/base/interface/SOAP";
   }
   else{
      this.Proxy=this.baseUrl+"auth/base/interface/SOAP";
   }

   this.ContextInfo=function(){   // returns informations about the login
       var i={mode:this.mode};
       var user=getModuleObject(this,"base::user"); 
       i=user.doPing(true);
       return(i);
   }
   
   if (!this.transfer) this.transfer="SOAP";
   if (!this.dataType) this.dataType="xml";
	this.SOAPServer="";
	this.ContentType="text/xml";
	this.CharSet="utf-8";
	this.ResponseXML=null;
	this.ResponseText="";
	this.Status=0;
	this.ContentLength=0;
	this.Namespace=function(name, uri) {
		return {"name":name, "uri":uri};
	};
	this.Clone=function() {		
      return(new SOAPClient(this,this.baseUrl));
   };
   this.msg=function(t,msg){
      if (t==LOG){
         $('#W5BaseState').html("<font color=darkgreen>"+msg+"</font>");
      }
      else if (t==ERROR){
         $('#W5BaseState').html("<font color=darkred>ERROR: "+msg+"</font>");
      }
      else if (t==WARN){
         $('#W5BaseState').html("<font color=darkred>WARN: "+msg+"</font>");
      }
      else if (t==DEBUG){
         if (window.console){
            console.log(msg);
         }
      }
      else{
         $('#W5BaseState').html("<font>"+msg+"</font>");
      }
   };

	this.SendRequest=function(soapReq,getResponse, callback) {		
		if(this.Proxy != null) {
			this.ResponseText = "";
			this.ResponseXML = null;
			this.Status = 0;
         this.callback=callback;
			
			var content = soapReq.toString();
			this.ContentLength = content.length;
         {
            var acall={
               type: "POST",
               url: this.Proxy,
               dataType: this.dataType,
               processData: false,
               w5base: this,
               soapReq: soapReq,
               callback: callback,
               data: content,
               jsonp:'jsonp_callback',
               complete: getResponse,
              // error: function (xhr, ajaxOptions, thrownError) {
              //      alert(xhr.status);
              //      alert(thrownError);
              // },
               beforeSend: function(req) {
                  req.setRequestHeader("Method",
                                       "POST");
         //         req.setRequestHeader("Content-Length", 
         //                              this.w5base.ContentLength);
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
	this.attr=function(name, value){
      this.attributes.push({"name":name, "value":value});
      return this;
   };
	this.appendChild=function(obj){this.children.push(obj);return obj;};
	this.hasChildren=function(){return (this.children.length > 0)?true:false;};
	this.val=function(v){
      if(v==null){
         return this.value
      }
      else{
         this.value=v;
         return this;
      }
   };	
	this.toString=function(){
      return ToXML(this);
   }		
}


function getModuleObject(module,mode){
   return(new W5baseObject(module,mode));
}

function createConfig(mode,baseurl)
{
   var so=new SOAPClient(mode,baseurl);
   return(so);
}

var W5baseObject = function(config,module){
   this.typeOf="W5BaseObject::"+module;
   this.module=module;
   this.name=function (){return(this.module)}

   this.ResetFilter=function(flt){
      var soapFilter=new SOAPObject("filter");
      soapFilter.ns=this.ns;
      this._CurrentFilter=soapFilter;
   }

   this.SetFilter=function(flt){
      this._RawFilter=flt;
      this.ResetFilter();
      var soapFilter=this._CurrentFilter;
      for (var i in flt) {
         soapFilter.appendChild(new SOAPObject(i,flt[i]));
      } 
      this._CurrentFilter=soapFilter;
   }


   this.doPing=function(getContextInfo){

      var loadContext=new SOAPObject("loadContext");
      if (getContextInfo) loadContext.value="2";
      loadContext.ns=this.ns;

      var soapInp=new SOAPObject("input");
      soapInp.ns=this.ns;
      soapInp.appendChild(loadContext);

      var soapBody=new SOAPObject("doPing");
      soapBody.ns=this.ns;

      soapBody.appendChild(soapInp);

      function getfindRecordResponse(xData) {
         this.Status = xData.status;
         this.ResponseText = xData.responseText;
         if (xData.responseXML===undefined){
            alert("ERROR: can not get responseXML from SOAP Request");
            return(undefined);
         }
         this.ResponseXML = xData.responseXML;

         var jsOut = $.j5xml2json(this.w5base.useUTF8,xData.responseXML);
         if (jsOut.Body){
            jsOut=jsOut.Body;
         }
         if (jsOut.doPingResponse){
            jsOut=jsOut.doPingResponse;
         }
         if (jsOut.output){
            jsOut=jsOut.output;
         }
         delete(jsOut.result);
         this.w5base.jsOut=jsOut;   // store result in w5base object;
         return(jsOut);
      }

      var sr=new SOAPRequest(this.ns.uri,'doPing',soapBody);
      return(this.SOAPClient.SendRequest(sr,getfindRecordResponse,undefined)); 
   }


   this.getRelatedWorkflows=function(id,filter,view,
                                     processCallback,errorHandler){
      var useUTF8=config.useUTF8;
      if (this.SOAPClient.transfer=="JSON"){
         var url=this.SOAPClient.baseUrl;
         if (!url.match(/\/$/)) url+="/";
         url+="auth/";

         var module=this.module;
         var UseLimit=this._Limit;
         var UseLimitStart=this._LimitStart;
         if (UseLimit==undefined){
            UseLimit=0;
         }
         if (UseLimitStart==undefined){
            UseLimitStart=0;
         }
         var q="FormatAs=JSONP&UseLimit="+UseLimit+"&"+
               "UseLimitStart="+UseLimitStart+"&"+
               "CurrentView=("+encodeURIComponent(view)+")";

         module=module.replace("::","/")
         url+=module+"/WorkflowLinkResult";

         this.processCallback=processCallback;
         filter.CurrentId=id;
         
			for(v in filter){
            var qname=v;
            if (qname=="CurrentId" || qname=="class" || qname=="fulltext"){
               //passt
            }
            else if (qname=="timerange"){
               qname="Search_ListTime";
            }
            else{
               alert("invalid parameter in getRelatedWorkflows");
               return;
            }
            if (useUTF8){  // encodeURIComponent only works with UTF8 data
               q+="&"+qname+"="+encodeURIComponent(filter[v]);
            }
            else{
               var filt=filter[v];
               // at this point there is need to do a litle quoting!
               q+="&"+qname+"="+filt;
            }
         }

         var requesturl=url;
         if (urlBaseValidation(requesturl)){
            var W5Base={
                requesturl:requesturl,
                processCallback:processCallback
            };
            $.ajax({
                dataType:'jsonp',
                data:q,
                type:'POST',
                async:true,
                error:function (XMLHttpRequest, textStatus, errorThrown){
                   if (errorHandler){
                      errorHandler({
                         url:this.url,
                         errormsg:textStatus,
                         errorcode:1
                      });
                   }
                   else{
                      if (window.console){
                         console.log("call error:"+textStatus+
                                     " call: "+this.url);
                      }
                      alert("call error:"+textStatus+" call: "+this.url);
                   }
                },
                success: function (data) {
                   if (typeof(data)!="object"){
                      if (errorHandler){
                         errorHandler({
                             unexpected:data,
                             exitcode:2
                         });
                      }
                   }
                   else if (typeof(data)=="object" && 
                            Object.keys(data).length==1 && 
                            "LastMsg" in data){ 
                      if (errorHandler){
                         errorHandler({
                             LastMsg:data.LastMsg,
                             exitcode:3
                         });
                      }
                   }
                   else{
                      W5Base.processCallback(data);
                   }
                },
                url:requesturl
            });
         }
      }
      else{
         alert("Call of getRelatedWorkflows only supports JSONP transfer");
      }
   };


   this.getHashList=this.findRecord=function(vw,processCallback,errorHandler){
      //console.log("findRecord transfer",this.SOAPClient.transfer);
      var view=vw;
      if (Array.isArray(vw)){
         view=vw.join(",");
      }
      var useUTF8=config.useUTF8;
      if (this.SOAPClient.transfer=="JSON"){
         var url=this.SOAPClient.baseUrl;
         if (!url.match(/\/$/)) url+="/";
         if (this.SOAPClient.mode!='public'){
            url+="auth/";
         }
         else{
            url+="public/";
         }
         var module=this.module;
         var UseLimit=this._Limit;
         var UseLimitStart=this._LimitStart;
         if (UseLimit==undefined){
            UseLimit=0;
         }
         if (UseLimitStart==undefined){
            UseLimitStart=0;
         }
         var q="FormatAs=JSONP&UseLimit="+UseLimit+"&"+
               "UseLimitStart="+UseLimitStart+"&"+
               "CurrentView=("+encodeURIComponent(view)+")";
         if (module.match(/::MyW5Base::/)){
            url+="base/MyW5Base/Result";
            q+="&MyW5BaseSUBMOD="+encodeURIComponent(module);
         }
         else{
            module=module.replace("::","/")
            url+=module+"/Result";
         }
         this.processCallback=processCallback;
			for(v in this._RawFilter){
            if (useUTF8){  // encodeURIComponent only works with UTF8 data
               q+="&search_"+v+"="+encodeURIComponent(this._RawFilter[v]);
            }
            else{
               var filt=this._RawFilter[v];
               // at this point there is need to do a litle quoting!
               q+="&search_"+v+"="+filt;
            }
         }
         var requesturl=url;
         if (urlBaseValidation(requesturl)){
            var W5Base={
                requesturl:requesturl,
                processCallback:processCallback
            };
            $.ajax({
                dataType:'jsonp',
                data:q,
                type:'POST',
                async:true,
                error:function (XMLHttpRequest, textStatus, errorThrown){
                   if (errorHandler){
                      errorHandler({
                         url:this.url,
                         errormsg:textStatus,
                         errorcode:1
                      });
                   }
                   else{
                      if (window.console){
                         console.log("call error:"+textStatus+
                                     " call: "+this.url);
                      }
                      alert("call error:"+textStatus+" call: "+this.url);
                   }
                },
                success: function (data) {
                   if (typeof(data)!="object"){
                      if (errorHandler){
                         errorHandler({
                             unexpected:data,
                             exitcode:2
                         });
                      }
                   }
                   else if (typeof(data)=="object" && 
                            Object.keys(data).length==1 && 
                            "LastMsg" in data){ 
                      if (errorHandler){
                         errorHandler({
                             LastMsg:data.LastMsg,
                             exitcode:3
                         });
                      }
                   }
                   else{
                      W5Base.processCallback(data);
                   }
                },
                url:requesturl
            });
         }
      }
      else{
         var View=new SOAPObject("view",view);
         View.ns=this.ns;
        
         var soapInp=new SOAPObject("input");
         soapInp.ns=this.ns;
         soapInp.appendChild(View);
         soapInp.appendChild(this._CurrentFilter);
        
         var soapBody=new SOAPObject("findRecord");
         soapBody.ns=this.ns;
        
         soapBody.appendChild(soapInp);
        
         //console.log("find Record");
         //console.log(ToXML(soapBody));
        
        
         function getfindRecordResponse(xData) {
            this.Status = xData.status;
            this.ResponseText = xData.responseText;
            this.ResponseXML = xData.responseXML;
        
            var jsOut = $.j5xml2json(this.w5base.useUTF8,xData.responseXML);
            if (jsOut.Body){
               jsOut=jsOut.Body;
            }
            if (jsOut.findRecordResponse){
               jsOut=jsOut.findRecordResponse;
            }
            if (jsOut.output){
               jsOut=jsOut.output;
            }
            if (jsOut.records){
               jsOut=jsOut.records;
            }
            if (jsOut.record){
               jsOut=jsOut.record;
               if (!isArray(jsOut)){
                  jsOut=new Array(jsOut);
               }
            }
            if(this.callback != null) {
               this.callback(jsOut);
            }
            this.w5base.jsOut=jsOut;   // store result in w5base object;
            return(jsOut);
         }
        
         var sr=new SOAPRequest(this.ns.uri,'findRecord',soapBody);
         if (window.console){
            console.log("SOAP call:");
            console.log(soapBody);
         }
         return(this.SOAPClient.SendRequest(sr,getfindRecordResponse, 
                                            processCallback));
      }
   }


   this.getOnlyFirst=function(view){
      this.Limit(1);
      console.log("find getOnlyFirst");
   }
   this.Limit=function(limit,limitstart){
      this._Limit=limit;
      this._LimitStart=limitstart;
   }


   this.SOAPClient=config;
   this.ns=new SOAPObject("appl");
   this.ns.uri="http://w5base.net/mod/"+module.replace("::","/");
   this.toString=function(){return(this.typeOf);}
   this._CurrentFilter=undefined;
   this._Limit=undefined;
   this._LimitStart=undefined;
   this.ResetFilter();
   return(this);
}


function urlBaseValidation(url){
   if (url.length>2000){
      alert("ERROR: the resulted request URL is longer then 2000 "+
            "characters! This will not work in Browsers f.e. like IE6.\n"+
            "Please contact the developer of this page, to fix these "+
            "behavior!");
      return(false);
   }
   return(true);
}




/*
 ### jQuery XML to JSON Plugin v1.0 - 2008-07-01 ###
 * http://www.fyneworks.com/ - diego@fyneworks.com
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 ###
 Website: http://www.fyneworks.com/jquery/xml-to-json/
*//*
 # INSPIRED BY: http://www.terracoder.com/
           AND: http://www.thomasfrank.se/xml_to_json.html
											AND: http://www.kawa.net/works/js/xml/objtree-e.html
*//*
 This simple script converts XML (document of code) into a JSON object. It is the combination of 2
 'xml to json' great parsers (see below) which allows for both 'simple' and 'extended' parsing modes.
*/
// Avoid collisions
 // Add function to jQuery namespace
$.extend({
   // converts xml documents and xml text to json object
   j5xml2json: function(useUTF8, xml, extended) {
      if (!xml) return {}; // quick fail
      // Core function
      function parseXML(node, simple){
         if (!node) return null;
         var txt = '', obj = null, att = null;
    
         var nv = node.text || node.nodeValue || '';
         if (node.childNodes){
            if (node.childNodes.length>0){
               $.each(node.childNodes, function(n,cn){
                  var cnt=cn.nodeType,cnn = jsVar(cn.localName || cn.nodeName);
                  var cnv=cn.text || cn.nodeValue || '';
                  if (useUTF8){
                     cnv=Utf8.decode(cnv);
                  }
                  cnn=cnn.replace("soap:","");  //fix for IE6
                  if (cnt==8){
                     return; // ignore comment node
                  }
                  else if (cnt==3 || cnt==4 || !cnn){
                     // ignore white-space in between tags
                     if (cnv.match(/^\s+$/)){
                        return;
                     };
                     txt+=cnv.replace(/^\s+/,'').replace(/\s+$/,'');
                     // make sure we ditch trailing spaces from markup
                  }
                  else{
                     obj = obj || {};
                     if (obj[cnn]){
                        if (!isArray(obj[cnn])){
                           obj[cnn] = new Array(obj[cnn]);
                        }
                        obj[cnn][obj[cnn].length]=parseXML(cn,true/* simple */);
                        obj[cnn].length=obj[cnn].length;
                     }
                     else{
                        obj[cnn] = parseXML(cn);
                        if (cnn=="item"){ // item entries in soap always are
                           obj[cnn]=new Array(obj[cnn]);
                        }
                     };
                  };
               });  // end of each loop for all child nodes
            };//node.childNodes.length>0
         };//node.childNodes
         if (node.attributes){
            if (node.attributes.length>0){
               att = {}; obj = obj || {};
               $.each(node.attributes, function(a,at){
                  var atn = jsVar(at.name), atv = at.value;
                  att[atn] = atv;
                  if (obj[atn]){
                     if (isArray(obj[atn])) obj[atn]=new Array(obj[atn]);
                     obj[atn][ obj[atn].length ] = atv;
                     obj[atn].length = obj[atn].length;
                  }
                  else{
                     obj[atn] = atv;
                  };
               });
               //obj['attributes'] = att;
            };//node.attributes.length>0
         };//node.attributes
         if (obj){
            obj=$.extend((txt!='' ? new String(txt) : {}), obj || {});
            txt=(obj.text) ? (typeof(obj.text)=='object' ? obj.text : [obj.text || '']).concat([txt]) : txt;
            if (txt) obj.text=txt;
            txt = '';
         };
         var out = obj || txt;
         //console.log([extended, simple, out]);
         if (extended){
            if (txt) out = {};//new String(out);
            txt = out.text || txt || '';
            if (txt) out.text = txt;
            if (!simple) out = new Array(out);
         };
         return out;
      };// parseXML
      // Core Function End
      // Utility functions
      var jsVar = function(s){ 
        return String(s || '').replace(/-/g,"_"); 
      };
      var isNum = function(s){ 
          return (typeof s == "number") || 
                  String((s && typeof s == "string") ? s : '').test(/^((-)?([0-9]*)((\.{0,1})([0-9]+))?$)/); 
      };
      //### PARSER LIBRARY END
   
      // Convert plain text to xml
      if (typeof xml=='string') xml = $.text2xml(xml);
      
      // Quick fail if not xml (or if this is a node)
      if (!xml.nodeType) return;
      if (xml.nodeType == 3 || xml.nodeType == 4) return xml.nodeValue;
      
      // Find xml root node
      var root = (xml.nodeType == 9) ? xml.documentElement : xml;
      
      // Convert xml to json
      var out = parseXML(root, true /* simple */);
      
      // Clean-up memory
      xml = null; root = null;
      
      // Send output
      return out;
   },
   
   // Convert text to XML DOM
   text2xml: function(str) {
      // NOTE: I'd like to use jQuery for this, but 
      // jQuery makes all tags uppercase
      // return $(xml)[0];
      var out;
      try{
         var xml=($.browser.msie) ?
                 new ActiveXObject("Microsoft.XMLDOM") : new DOMParser();
         xml.async = false;
      }catch(e){ 
         throw new Error("XML Parser could not be instantiated") 
      };
      try{
         if ($.browser.msie) out = (xml.loadXML(str))?xml:false;
         else out = xml.parseFromString(str, "text/xml");
      }catch(e){ 
         throw new Error("Error parsing XML string") 
      };
      return out;
   }
		
}); // extend $



