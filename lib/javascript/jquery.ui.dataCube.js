/*
 * jQuery UI dataCube 1.0
 *
 * Copyright (c) 2010 AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://docs.jquery.com/UI/dataCube
 *
 * Depends:
 *   jquery.ui.core.js
 *   jquery.ui.widget.js
 */
(function( $ ) {

$.widget( "ui.dataCube", {
   options: {
      value: 0,
      width: undefined,
      currentKey: "",
      drillDown:1
   },
   //**********************************************************************
   //* Create Handler
   //*
   _create: function() {
      if (this.options.width!=undefined){
         this.element.width(this.options.width);
      }
      this.table = $( "<table border=1><tr><td>x</td></tr></table>" );
      this.label=new Array();
      this.row=new Array();
      this.label[0] = $( "<td>label0</td>" );
      this.row[0] = $( "<tr><td>x</td></tr>" );
      this.row[0].appendTo(this.table);
      
      this.valueDiv = $( "<div></div>" )
         .appendTo( this.element );

      this.table.appendTo(this.valueDiv);
      

      this._refreshValue();
   },

   //**********************************************************************
   //* Destory Handler
   //*
   destroy: function() {
      this.valueDiv.remove();

      $.Widget.prototype.destroy.apply( this, arguments );
   },

   //**********************************************************************
   //* value accessesor
   //*
   value: function( newValue ) {
      if ( newValue === undefined ) {
         return this._value();
      }

      this._setOption( "value", newValue );
      return this;
   },

   //**********************************************************************
   //* setOption Handler
   //*
   _setOption: function( key, value ) {
      switch ( key ) {
         case "value":
            this.options.value = value;
            this._refreshValue();
            this._trigger( "change" );
            break;
      }

      $.Widget.prototype._setOption.apply( this, arguments );
   },

   //**********************************************************************
   //* _value Handler
   //*
   _value: function() {
      var val = this.options.value;
      if ( typeof val !== "object" ) {
         val = new Array();
      }
      return(val);
   },

   //**********************************************************************
   //* setCurrentKey: setting a new key and redraw the dataCube
   //*
   setCurrentKey: function(newKey){
      this.options.currentKey=newKey;
      this._refreshValue();
   },

   //**********************************************************************
   //* _refreshValue: redraw the dataCube
   //*
   _refreshValue: function() {
      this.visualObj=new Object();
      var val=this._value();

      var c=this.options.currentKey.split(".");

      for(var i=0;i<val.length;i++){
         var k=val[i].label;
         var v=parseInt(val[i].value);
         if (v==undefined) v=0;
         var tr=$("<tr></tr>");
         // level check
         var level=c.length;
         if (this.options.currentKey==""){
            level=0;
         }
         var kLayerStr=k.split(".").splice(0,level).join(".");
         var usedKey=k.split(".").splice(0,level+1).join(".");
         var usedLabel=k.split(".").splice(level,1).join(".");
         if (kLayerStr==undefined) kLayerStr="";
         if (kLayerStr==this.options.currentKey && usedLabel!=""){
            var label=$("<td width=1% nowrap>"+usedLabel+"</td>");
            label.attr({key:usedKey,widget:this});
            
            var value=$("<td></td>");
            var div=$("<div class='ui-dataCube-value ui-widget-header "+
                      "ui-corner-left'></div>")
            div.appendTo(value);
            label.appendTo(tr);
            value.appendTo(tr);
            if (this.visualObj[usedKey]==undefined){
               this.visualObj[usedKey]={tr:tr,
                                        elements:1,
                                        subcategories:0,
                                        div:div,
                                        label:label,
                                        value:v};
            }
            else{
               this.visualObj[usedKey].value=
                     parseInt((this.visualObj[usedKey].value+v)/2);
               this.visualObj[usedKey].elements++;
               if (k!=usedKey){
                  this.visualObj[usedKey].subcategories++;
               }
            }
         }
      }
      var table=$("<table border=1></table");
      var toblabelval=this.options.currentKey;
      if (this.options.label!=undefined && this.options.label!=""){
         toblabelval=this.options.label+": "+toblabelval;
      }
      var toplabel=$("<th colspan=2 align=left>"+toblabelval+"&nbsp;</th>");
      var currentKey=this.options.currentKey.split(".");
      var topkey=currentKey.splice(0,currentKey.length-1).join(".");
      if (this.options.currentKey!=""){
         toplabel.attr({key:topkey});
         var currentWidget=this;
         toplabel.css({cursor:"pointer"});
         toplabel.click(function(){
            currentWidget.setCurrentKey($(this).attr('key')); 
         });
      }
      
      var toprow=$("<tr></tr>");
      toplabel.appendTo(toprow);
      toprow.appendTo(table);
           
      for (r in this.visualObj){
         this.visualObj[r].tr.appendTo(table);  
         this.visualObj[r].div.width(this.visualObj[r].value+"%");
         this.visualObj[r].div.html(this.visualObj[r].value);
         if (this.visualObj[r].subcategories>1){
            var currentWidget=this;
            this.visualObj[r].label.css({cursor:"pointer"});
            this.visualObj[r].label.click(function(){
               currentWidget.setCurrentKey($(this).attr('key')); 
            });
            $("<span>...</span>").appendTo(this.visualObj[r].label);
         }
      }
       
      
      this.valueDiv.html("");
      table.appendTo(this.valueDiv);
   }
});

$.extend( $.ui.dataCube, {
   version: "1.0"
});

})( jQuery );
