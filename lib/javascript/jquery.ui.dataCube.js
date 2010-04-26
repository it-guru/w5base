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
      maxLabelLength:35, 
      aggregation:'avg',  // avg||min||max||sum
      precision:-1,       // -n = dynamic - n=fix  count of digets after .
      width: undefined
   },
   //**********************************************************************
   //* Create Handler
   //*
   _create: function() {
      if (this.options.width!=undefined){
         this.element.width(this.options.width);
      }
      this.valueDiv = $( "<div class='ui-dataCube'></div>" )
         .appendTo( this.element );
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
   setCurrentKey: function(filterIndex,newKey){
      this.options.currentFilter=filterIndex;
      this.options.filter[filterIndex].currentKey=newKey;
      this._refreshValue();
   },

   //**********************************************************************
   //* setCurrentKey: setting a new key and redraw the dataCube
   //*
   setCurrentFilter: function(filterIndex){
      this.options.currentFilter=filterIndex;
      this._refreshValue();
   },

   //**********************************************************************
   //* _refreshValue: redraw the dataCube
   //*
   _refreshValue: function() {
      var currentWidget=this;
      this.valueDiv.html("");
      this.visualObj=new Object();
      var val=this._value();
      for(var i=0;i<val.length;i++){
         var v=parseFloat(val[i].value);
         var w=parseInt(val[i].weight);
         var useData=true;
         var usedLabel="?";
         var usedKey="?";
         var dString="?";
         for(var f=0;f<this.options.filter.length;f++){
            var key=this.options.filter[f].key;
            if (f==this.options.currentFilter){
               var currentKey=this.options.filter[f].currentKey;
               var ls=this.options.filter[f].levelSeperator;
               var dString=val[i][key];
               if (ls!=undefined){
                  if (currentKey==undefined) currentKey="";
                  var currentKeyLevels=currentKey.split(ls);
                  var currentLevel=currentKeyLevels.length;
                  if (currentKey=="") currentLevel=0;
                  usedKey=dString.split(ls).splice(0,currentLevel+1).join(ls); 
                  usedLabel=dString.split(ls).splice(currentLevel,1).join(ls);
                  if (dString.substring(0,currentKey.length)!=currentKey ||
                      usedLabel==""){
                     useData=false;
                     break;
                  }
               }
               else{
                  usedLabel=dString;
                  usedKey=dString;
               }
            }
            else{
               var secCurKey=this.options.filter[f].currentKey;
               var secCurVal=val[i][key];
               if (secCurVal!=undefined &&
                   secCurVal.substring(0,secCurKey.length)!=secCurKey){
                  useData=false;
                  break;
               }
            }
         }
         if (useData){
            var row=$("<tr></tr>");
            if (usedLabel.length>this.options.maxLabelLength){
               usedLabel=usedLabel.substring(0,this.options.maxLabelLength-3)+
                         "<font color=red>....</font>";
            }
            var label=$("<td width=1% nowrap>"+usedLabel+"</td>");
            label.attr({key:usedKey,widget:this});
            label.addClass("ui-dataCube-dataline");
            
            var value=$("<td nowrap></td>");
            var div=$("<div class='ui-dataCube-value'></div>")
            div.appendTo(value);
            label.appendTo(row);
            value.appendTo(row);
            value.addClass("ui-dataCube-dataline");
            if (this.visualObj[usedKey]==undefined){
               this.visualObj[usedKey]={tr:row,
                                        div:div,
                                        elements:1,
                                        subcategories:0,
                                        label:label,
                                        value:new Array()};
            }
            for(var cc=0;cc<w;cc++){
               this.visualObj[usedKey].value.push(v);
            }
            this.visualObj[usedKey].elements++;
            if (dString!=usedKey){
               this.visualObj[usedKey].subcategories++;
            }
         }
      }
      var table=$("<table></table");
      table.css({'border-collapse':'collapse'});
      var filtertable=$("<table></table");
      filtertable.css({'border-collapse':'collapse'});
      for(var f=0;f<this.options.filter.length;f++){
         var row=$("<tr></tr>");
         var label;
         if (f==this.options.currentFilter){
            label=$("<td nowrap><b>"+
                    this.options.filter[f].label+" :</b></td>");  
         }
         else{
            label=$("<td nowrap>"+this.options.filter[f].label+" :</td>");  
         }
         var newIndex=f;
         label.attr({newIndex:f});
         label.click(function(){
            currentWidget.setCurrentFilter($(this).attr("newIndex"));
         });
         label.css({cursor:'pointer','width':'1%'});
         label.addClass("ui-dataCube-filterline");
         var k=this.options.filter[f].currentKey;
         if (k=="") k="*";
         var filter=$("<td>"+k+"</td>");  
         filter.attr({newIndex:f});
         if (k!="*"){
            var newKey="";
            var ls=this.options.filter[f].levelSeperator;
            if (ls!=undefined){
               var ll=this.options.filter[f].currentKey.split(ls);
               newKey=ll.splice(0,ll.length-1).
                      join(this.options.filter[f].levelSeperator);
            }
            filter.attr({'newKey':newKey});
            
         }
         filter.css({cursor:"pointer"});
         filter.addClass("ui-dataCube-filterline");
         filter.click(function(){
            var newKey=$(this).attr("newKey");
            if (newKey!=undefined){
               currentWidget.setCurrentKey($(this).attr("newIndex"),newKey);
            }
            else{
               currentWidget.setCurrentFilter($(this).attr("newIndex"));
            }
         });
         label.appendTo(row);
         filter.appendTo(row);
         



         row.appendTo(filtertable);
      }

      var toblabelval=this.options.currentKey;
      if (this.options.label!=undefined && this.options.label!=""){
         toblabelval=this.options.label+": "+toblabelval;
      }
      var toplabel=$("<th colspan=2 align=left></th>");
      filtertable.appendTo($("<div class='ui-dataCube-filter'></div>")
                 .appendTo(toplabel));
      
      var toprow=$("<tr></tr>");
      toplabel.appendTo(toprow);
      toprow.appendTo(table);

      var keyOrder=new Array();

      for (var r in this.visualObj){
          keyOrder.push(r);
          if (this.options.aggregation=='avg'){
             var s=0;
             $.each(this.visualObj[r].value,function(index, value) { 
                s+=value;
             });
             this.visualObj[r].value=s/this.visualObj[r].value.length;
          }
          else if (this.options.aggregation=='sum'){
             var s=0;
             $.each(this.visualObj[r].value,function(index, value) { 
                s+=value;
             });
             this.visualObj[r].value=s;
          }
          else{
             this.visualObj[r].value=1;
          }
      }
      var visualObj=this.visualObj;

      keyOrder=keyOrder.sort(function(a,b){
         var x=visualObj[a].value;
         var y=visualObj[b].value;
         return ((x < y) ? -1 : ((x > y) ? 1 : 0));
      });

           
      var f=currentWidget.options.currentFilter;
      for (var ikeyr=0;ikeyr<keyOrder.length;ikeyr++){
         var r=keyOrder[ikeyr];
         this.visualObj[r].tr.appendTo(table);  
         var dispVal=parseInt(this.visualObj[r].value);

         // -----------------------------------------
         //
         // precision handling is a ToDo!
         //
         var f=parseFloat(this.visualObj[r].value);
         if (parseFloat(f.toFixed(0))!=parseFloat(f.toFixed(1))){
            dispVal=f.toFixed(1);
         }
         if (this.options.unit!=undefined){
            dispVal+=" "+this.options.unit;
         }
         // -----------------------------------------

         this.visualObj[r].div.html(dispVal);
         this.visualObj[r].div.width(this.visualObj[r].value+"%");

         // caclulate styles by value
         var dyncss=this.options.filter[this.options.currentFilter].dyncss;
         var v=this.visualObj[r].value;
         for(var dyni=0;dyni<dyncss.length;dyni++){
            if (v>=dyncss[dyni].range[0] &&
                v<=dyncss[dyni].range[1]){
               this.visualObj[r].div.addClass(dyncss[dyni].cssclass);
               break;
            }
         }

         if (this.visualObj[r].subcategories>1){
            var currentWidget=this;
            this.visualObj[r].label.css({cursor:"pointer"});
            this.visualObj[r].label.click(function(){
               currentWidget.setCurrentKey(currentWidget.options.currentFilter,
                                           $(this).attr('key')); 
            });
            $("<span> ... </span>").appendTo(this.visualObj[r].label);
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
