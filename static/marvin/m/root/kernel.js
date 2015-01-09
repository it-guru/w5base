//
//   console.log Hack
//
var alertFallback = false;
if (typeof console === "undefined" || typeof console.log === "undefined") {
  console = {};
  if (alertFallback) {
      console.log = function(msg) {
           alert(msg);
      };
  } else {
      console.log = function() {};
  }
}

function loadScript(url) {
    var script = document.createElement('script');
    console.log("loadScript:"+url);
    script.type = 'text/javascript';
    script.src = url;
    $("head").append(script);
}

function call(f,t){
   if (!t){
      t=10;
   }
   window.setTimeout(f,10);
}
loadScript(J5Base_baseUrl+"public/base/load/J5BaseMinimal.js");




//////////////////////////////////////////////////////////////////////////

// Form parsing

jQuery.fn.extend({
   parseForm:function(){
      var paramObj = {};
      $.each($(this).serializeArray(), function(_, kv) {
         paramObj[kv.name] = kv.value;
      });
      return(paramObj);
   }
});

//////////////////////////////////////////////////////////////////////////

// query coding 

function queryenc(str) {
    return("["+Base64.encode(str)+"]");
}

function querydec(str) {
    str=str.replace(/^\[/,'');
    str=str.replace(/\]$/,'');
    return(Base64.decode(str));
}


//////////////////////////////////////////////////////////////////////////

// Add an URL parser to JQuery that returns an object
// This function is meant to be used with an URL like the window.location
// Use: $.parseParams('http://mysite.com/?var=string') or $.parseParams() to parse the window.location
// Simple variable:  ?var=abc                        returns {var: "abc"}
// Simple object:    ?var.length=2&var.scope=123     returns {var: {length: "2", scope: "123"}}
// Simple array:     ?var[]=0&var[]=9                returns {var: ["0", "9"]}
// Array with index: ?var[0]=0&var[1]=9              returns {var: ["0", "9"]}
// Nested objects:   ?my.var.is.here=5               returns {my: {var: {is: {here: "5"}}}}
// All together:     ?var=a&my.var[]=b&my.cookie=no  returns {var: "a", my: {var: ["b"], cookie: "no"}}
// You just cant have an object in an array, ?var[1].test=abc DOES NOT WORK
(function ($) {
    var re = /([^&=]+)=?([^&]*)/g;
    var decode = function (str) {
        return decodeURIComponent(str.replace(/\+/g, ' '));
    };
    $.parseParams = function (query) {
        // recursive function to construct the result object
        function createElement(params, key, value) {
            key = key + '';
            // if the key is a property
            if (key.indexOf('.') !== -1) {
                // extract the first part with the name of the object
                var list = key.split('.');
                // the rest of the key
                var new_key = key.split(/\.(.+)?/)[1];
                // create the object if it doesnt exist
                if (!params[list[0]]) params[list[0]] = {};
                // if the key is not empty, create it in the object
                if (new_key !== '') {
                    createElement(params[list[0]], new_key, value);
                } else console.warn('parseParams :: empty property in key "' + key + '"');
            } else
            // if the key is an array    
            if (key.indexOf('[') !== -1) {
                // extract the array name
                var list = key.split('[');
                key = list[0];
                // extract the index of the array
                var list = list[1].split(']');
                var index = list[0]
                // if index is empty, just push the value at the end of the array
                if (index == '') {
                    if (!params) params = {};
                    if (!params[key] || !$.isArray(params[key])) params[key] = [];
                    params[key].push(value);
                } else
                // add the value at the index (must be an integer)
                {
                    if (!params) params = {};
                    if (!params[key] || !$.isArray(params[key])) params[key] = [];
                    params[key][parseInt(index)] = value;
                }
            } else
            // just normal key
            {
                if (!params) params = {};
                params[key] = value;
            }
        }
        // be sure the query is a string
        query = query + '';
        if (query === '') query = window.location + '';
        var params = {}, e;
        if (query) {
            // remove # from end of query
            if (query.indexOf('#') !== -1) {
                query = query.substr(0, query.indexOf('#'));
            }

            // remove ? at the begining of the query
            if (query.indexOf('?') !== -1) {
                query = query.substr(query.indexOf('?') + 1, query.length);
            } else return {};
            // empty parameters
            if (query == '') return {};
            // execute a createElement on every key and value
            while (e = re.exec(query)) {
                var key = decode(e[1]);
                var value = decode(e[2]);
                createElement(params, key, value);
            }
        }
        return params;
    };
})(jQuery);


//////////////////////////////////////////////////////////////////////////

// Class Handling

var Class = function() {  
   var parentClass, classPrototype;              
   var newClassObject=function() { 
      this.Constructor.apply(this, arguments); 
   };
   var extendObject = function(dstObj, srcObj){   
      for (var property in srcObj) {
        dstObj[property] = srcObj[property];
      }
      // IE 8 Bug handling:
      if (!Object.getOwnPropertyNames){
         var objMethods=[
            'toString',     
            'valueOf' , 
            'isPrototypeOf',
            'propertyIsEnumerable',
            'hasOwnProperty',
            'toLocaleString'
         ];
       
         for(var i=0; i<objMethods.length; i++) {
            if (typeof(srcObj[objMethods[i]])==='function' &&  
                srcObj[objMethods[i]].toString().indexOf('[native code]')==-1){
               dstObj[objMethods[i]]=srcObj[objMethods[i]];
            }
         }
      }

      dstObj.SUPER=function(callParentMethod){
         var parentClass=this.$parentClass;
         var methodArguments=Array.prototype.slice.call(arguments, 1);
         return(parentClass[callParentMethod].apply(this,methodArguments));
      }
      return(dstObj);  
   };

   if (typeof(arguments[0])==='function') {       // Derivation of a existing
      parentClass=arguments[0];                   // Class
      classPrototype=arguments[1];     
      extendObject(newClassObject.prototype,parentClass.prototype);       
      newClassObject.prototype.$parentClass=parentClass.prototype;
   } else {                                        // newClassObject is Top
      classPrototype=arguments[0];     
   }     

   extendObject(newClassObject.prototype,classPrototype);  
   newClassObject.prototype.constructor=newClassObject;      

   if (!newClassObject.prototype.Constructor){
      newClassObject.prototype.Constructor=function(){};         
   }
   return(newClassObject);   
};


//////////////////////////////////////////////////////////////////////////

// W5Base JavaScrit List(Edit) Class


var W5ModuleObject=new Class({
   Constructor:function(pApp,frontname,dataobj){
      console.log("constructor W5ModuleObject");
      this.frontname=frontname;
      this.name=dataobj;
      this.pApp=pApp;
      this.queryStack=new Object();

      this.idField="id";
      if (!this.listView){
         this.listView=['fullname','name'];
      }
      if (!this.detailView){
         this.detailView=['fullname','name','cdate','mdate'];
      }
      this.currentView=undefined;
      var This=this;
      $('#'+this.frontname+"-search").live('pageshow',function(e,ui){
         var hash = document.location.hash.replace(/^#/,'');
         var stackIsHandled=This.queryStackLoader("search",ui);
         if (!stackIsHandled){
            This.setBackButtonTarget("search",This.queryStack,ui);
         }
      });
      $('#'+this.frontname+"-search-result").live('pageshow',function(e,ui){
         var stackIsHandled=This.queryStackLoader("search-result",ui);
         if (!stackIsHandled){
            This.setBackButtonTarget("search-result",This.queryStack,ui);
         }
      });
      $('#'+this.frontname+"-detail").live('pageshow',function(e,ui){
         var stackIsHandled=This.queryStackLoader("detail",ui);
         var id=This.queryStack.ID;
         if (ui.prevPage[0]==undefined){
            if (!$.isEmptyObject(This.queryStack)){
               stackIsHandled=
                  This.queryStackHandler("detail",This.queryStack,ui);
            }
            if (!stackIsHandled){
               var idname=This.getIdFieldName();
               var flt={};
               flt[idname]=id;
               This.doSearch(flt); 
            }
         }
         if (!stackIsHandled){
            This.setBackButtonTarget("detail",This.queryStack,ui);
         }
      });
   },

   queryStackLoader:function(hash,ui){
      var qstring=document.location.hash.replace(/^#/,'');
      var queryStack=$.extend({},this.queryStack);
      if (qstring.match(/\?/)){
         qstring=qstring.replace(/^.*\?/,'');
         if (qstring!=""){
             queryStack=$.parseParams("?"+querydec(qstring));
         }
         this.queryStack=queryStack;
      }
      return(this.queryStackHandler(hash,queryStack,ui));
   },

   setBackButtonTarget:function(hash,queryStack,ui){
       var This=this;
       var backButtonId='#'+this.frontname+"-"+hash+"-back-btn";
       $(backButtonId).unbind('click');
       if (hash=="detail"){
          if (ui.prevPage[0]==undefined){
               $(backButtonId).click(function(){
                  var queryStack=$.extend({},This.queryStack);
                  delete queryStack.ID;
                  var target="#"+This.frontname+"-search"+"?"+
                    queryenc($.param(queryStack));
                  $.mobile.navigate(target);
               });
          }
          else{
             $(backButtonId).click(function(){
                var target="#"+ui.prevPage[0].id+"?"+
                  queryenc($.param($.extend(This.queryStack,
                                            {ID:queryStack.ID})));
                $.mobile.navigate(target);
             });
          }
       }
       if (hash=="search-result"){
          if ($("#"+This.frontname+"-search").length){
             var previousPage =$.mobile.activePage;
             var backButtonId='#'+This.frontname+"-search-result-back-btn";
             if (ui.prevPage[0]==undefined){
                $.mobile.navigate("#"+This.frontname+"-search");
             }
             $(backButtonId).unbind('click');
             $(backButtonId).click(function(){
                console.log("click on back button");
                $.mobile.navigate("#"+This.frontname+"-search");
                return(false);
             });
          }
          else{
             if (ui.prevPage[0]==undefined){
                This.doSearch({});
             }
             else{
                var queryStack=$.extend({},This.queryStack);
                delete queryStack.ID;
                var r=$("#"+This.frontname+"-search-result-content").html();
                if (r.match(/^\s*$/)){   /// result content ist noch leer
                   This.doSearch(queryStack);
                }
             }
          }
       }
   },

   queryStackHandler:function(hash,queryStack,ui){
      return(false);
   },

   getIdFieldName:function(){
      return(this.idField);
   },

   getListView:function(){
      return(this.listView);
   },

   getDetailView:function(){
      return(this.detailView);
   },

   openSearch:function(){
      var target='#'+this.frontname+"-search";
      $.mobile.navigate(target);
   },

   handleSearchSubmit:function(elem){
      var form = $(elem).parents('form:first');
      var paramObj=$(form).parseForm();
      this.doSearch(paramObj);
      return(false);
   },

   openListResult:function(l){
      var label="List:";
      var label="";
      var ul=$('<ul id="listview" data-role="listview" '+
               'data-inset="true" style="height:100%"/>');
      ul.append("<li data-role='list-divider'>"+label+"</li>");
      for(c=0;c<l.length;c++){
         var li=$('<li />').attr({
            id:l[c].id,
            name:l[c].name
         });
         li.html(this.formatListResultEntry(l[c]));
         ul.append(li);
      }
      $('#'+this.frontname+"-search-result-content").html(ul);
      $('#'+this.frontname+"-search-result-content").trigger('create');
      var This=this;
      $("."+this.frontname+"-detail-link").each(function(i){
         var id=$(this).attr("id");
         var queryStack=$.extend({},this.queryStack,{ID:id});
         var link='#'+This.frontname+"-detail?"+queryenc($.param(queryStack));
         $(this).attr("href",link);
      });
      $("."+this.frontname+"-detail-link").unbind('click');
      $("."+this.frontname+"-detail-link").click(function(){
         $.mobile.loading('show');
         var id=$(this).attr("id");
         var idname=This.getIdFieldName();
         var flt={};
         flt[idname]=id;
         This.doSearch(flt);
         return(false);
      });
      console.log("search-result displayed",this.queryStack);
      var target='#'+this.frontname+"-search-result";
      if (!$.isEmptyObject(this.queryStack)){
         target+="?"+queryenc($.param(this.queryStack));
      }
      console.log("search-result displayed navigate to "+target);
      $.mobile.navigate(target);
      $.mobile.loading('hide');
   },

   formatListResultEntry:function(rec){
      var n=this.frontname;
      var d="<a class='"+n+"-detail-link' rel='external' id='"+rec.id+"' "+
            "href=''>"+rec.name+"</a>";
      return(d);
   },

   openDetailResult:function(rec){
      var idname=this.getIdFieldName();
      console.log("call this.formatDetail",rec);
      $.mobile.loading('hide');
      var contentid='#'+this.frontname+"-detail-content";
      var d=this.formatDetail(rec,$(contentid));
      //if (d!=""){
      //   $(contentid).html(d);
      //}
      $(contentid).trigger('create');
      window.setTimeout(function(){
         $(contentid+" :input:visible:first").focus();
      },1000);
      
      var target='#'+this.frontname+"-detail"+"?"+
              queryenc($.param($.extend({},this.queryStack,{ID:rec[idname]})));
      $.mobile.navigate(target);
   },

   formatDetail:function(rec,jqo){
      var d='';
      var view=this.getDetailView();
      for(c=0;c<view.length;c++){
         name=view[c];
         d+="<fieldset data-role='fieldcontain'>";
         var ename=this.frontname+"-detail-content-"+name;
         d+="<label for='"+ename+"'>"+name+":</label>";
         var val=new String(rec[name]);
         //if (val==undefined){
         //   val="";
         //}
         if (val.length>45 || val.match(/\n/)){
            d+="<textarea readonly name='"+ename+"'>"+val+"</textarea>";
         }
         else{
            d+="<input readonly name='"+ename+"' value='"+val+"' />";
         }
         d+="</fieldset>";
      }
      d+='</table>';
      jqo.html(d);
      return;
   },

   doSearch:function(filter){
      $.mobile.loading('show');
      this.setFilter(filter);
      var o=this.DataObj();
      this.currentView=this.getListView();
      console.log("doSearch with View ",this.currentView);
      var useView=this.currentView.slice(0);
      if (useView.indexOf(this.getIdFieldName())==-1){
         useView.push(this.getIdFieldName());
      }
      var This=this; // store this, because it is needed in callback
      o.findRecord(useView,function(l){
          This.handleSearchResult(l);
      });
      
      return(false);
   },
   
   handleSearchResult: function(originalRecordList){
      var l=new Array();
      for(c=0;c<originalRecordList.length;c++){
         var newRec=this.softFilterRecord(originalRecordList[c]);
         if (newRec){
            l.push(newRec);
         }
      }
      
      if (l.length==0){
         alert("not found");
      }
      else if (l.length==1){
         console.log("found 1 record with view "+this.currentView.join(","));
         if (this.currentView.join(",")!=this.getDetailView().join(",")){
            var idname=this.getIdFieldName();
            var flt={};
            flt[idname]=l[0][idname];
            this.setFilter(flt);
            var o=this.DataObj();
            //this.currentView=this.getDetailView();
            var new_currentView=this.getDetailView();
            var useView=new_currentView.slice(0);
            if (useView.indexOf(this.getIdFieldName())==-1){
               useView.push(this.getIdFieldName());
            }
            var This=this; // store this, because it is needed in callback
            console.log("new search with view "+useView.join(","));
            o.findRecord(useView,function(l){
                This.currentView=new_currentView;
                This.handleSearchResult(l);
            });
         }
         else{
            console.log("call of openDetailResult with ",l[0]);
            this.openDetailResult(l[0]);
         }
      }
      else{
         this.openListResult(l);
      }
   },

   setFilter:function(f){
      var o=this.DataObj();
      return(o.SetFilter(f));
   },

   softFilterRecord:function(rec){
      return(rec);
   },

   DataObj:function(){   // get W5Base Connection Object from parent Application
      if (!this.$W5Base){
         this.$W5Base=this.pApp.W5Base();
      }
      if (!this.$DataObj){
         this.$DataObj=this.$W5Base.getModuleObject(this.name);
      }
      return(this.$DataObj);
   }
});

