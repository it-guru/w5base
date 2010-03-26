/**
* jQuery changecss plug-in v0.1
* @requires jQuery v1.2
*
* Copyright (c) 2009 Amr Shahin amrnablus at gmail dot com
*
*
* @param string className - the class name that you want to change ( with . ). For example .myclass
* @param string propertyName  - the property name you wany to change. For example font-weight
* @param string value - the new value for the property
*
* Examples:
*
* jQuery().changecss( '.amrstyle',  'color', 'blue' );
* jQuery().changecss(  '.amrstyle', 'font-size','100px' ) ;
*
* Note:
* the code is quoted from "http://www.shawnolson.net/a/503/altering-css-class-attributes-with-javascript.html" with some modifications.
***************************************************************************************************/


(function($){
    jQuery.fn.extend({
//plugin name - changecss
        changecss: function(className , propertyName , value) {

            return this.each(function(  ) {
               
                if(
                ( className == '' ) ||
                ( propertyName == '' ) ||
                ( value == '' ) ) {
                    return ;
                }

                var propertyIndexName = false;
                var falg = false;
                var numberOfStyles = document.styleSheets.length
               
                if (document.styleSheets[0]['rules']) {
                    propertyIndexName = 'rules';
                } else if (document.styleSheets[0]['cssRules']) {
                    propertyIndexName = 'cssRules';
                }
               
                for (var i = 0; i < numberOfStyles; i++) {
                    for (var j = 0; j < document.styleSheets[i][propertyIndexName].length; j++) {
                        if (document.styleSheets[i][propertyIndexName][j].selectorText == className) {
                            if(document.styleSheets[i][propertyIndexName][j].style[propertyName]){
                                document.styleSheets[i][propertyIndexName][j].style[propertyName] = value;
                                falg=true;
                                break;
                            }
                        }
                    }
                    if(!falg){
                        if(document.styleSheets[i].insertRule){
                            document.styleSheets[i].insertRule(className+' { '+propertyName+': '+value+'; }',document.styleSheets[i][propertyIndexName].length);
                        } else if (document.styleSheets[i].addRule) {
                            document.styleSheets[i].addRule(className,propertyName+': '+value+';');
                        }
                    }
                }
            }
    );
        }
    });
})(jQuery);
