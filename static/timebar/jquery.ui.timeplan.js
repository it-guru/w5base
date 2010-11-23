(function( $ ) {
   $.widget( "ui.timeplan", {
      options: {
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
      //* _refreshValue: redraw the dataCube
      //*
      _refreshValue: function() {
         var currentWidget=this;
         var d="";
         for(c=0;c<10;c++){
            d+="<div style='position:relative;background-color:blue;width:100%;border:0px;height:40px'><div style='position:absolute;top:0;left:0;border:0;width:100%'><div style='border-style:solid;border-width:1px'></div></div></div>";
         }
         this.valueDiv.html("<div class=labelarea>"+d+"</div>");
      }
   });
   $.extend( $.ui.timeplan, {
      version: "1.0"
   });
})( jQuery );
