//
// Einheitliche Applications Startup Handler für Marvin JavaScript Anwendungen
//
var App;
$(document).bind("pagebeforecreate", function(){
   console.log("pagebeforecreate");
   if (App){
      return
   }
   i18n.init({
   //        lng: 'en',
      debug: true,
      lng:"de",
      lngWhitelist: ['de','en'],
      fallbackLng: false,
      defaultValueFromContent:false,
      lowerCaseLng: true,
      load:'current',
      cookieName: 'lang',
      resGetPath: "__ns__-__lng__.json",
      ns: {
          namespaces: ['i18n'],
          defaultNs: 'i18n'
      }
      },function (t){
         console.log("derive App");
         App=new Application();   // Appl Objekt erzeugen

         if (!App.W5Base){
            App.W5Base=function(){
               if (!this.$W5Base){
                  var tempW5Base;
                  var J5BaseConnect={
                        useUTF8:false,
                        mode:'auth',
                        transfer:'JSON',
                        baseURL:J5Base_baseUrl
                  };
                  eval("tempW5Base=createConfig(J5BaseConnect,J5Base_baseUrl);");
                  this.$W5Base=tempW5Base;
               }
               return(this.$W5Base);
            }
         }
         if (!App.run){
            App.run=function(){
                console.log("App default run()");
            };
         }

         console.log("i18next translation");
         $("*").i18n();           // Übersetzungen durchführen
         $("*[i18n]").hide();                   // i18n Elemente ausblenden
         $("*[i18n|='"+i18n.lng()+"']").show(); // die passenden i18n Elemente 
         $('[type="button"]').button().button('refresh'); 
            //restyle after translation
            // anzeigen

         if (Marvin_Home!=""){
            $(".homebutton").show();
            $(".homebutton").attr("href",Marvin_Home);
         }
         else{
            $("#homebutton").hide();
         }
         console.log("Marvin_Home:"+Marvin_Home);
         console.log("caller:"+document.referrer);


         $('form').bind("keypress", function(e) {   // fix to handle IE8 
           if (e.keyCode == 13) {                   // behavier on submit by
                                                    // enter key
             $(this).find("input[type=submit]").trigger("click");
             e.preventDefault();
             return false;
           }
         });



         var hash = document.location.hash.replace(/^#/,'');
         if (hash.match(/\?/)){
            hash=hash.replace(/^.*\?/,'');
            var callpath=hash.split(";");
            App.CurrentPath=callpath;
            App.CallPath=callpath;
         }
         else{
            App.CurrentPath=[];
            App.CallPath=[];
         }
         
        // App.callStack=function(finalcall){
        //    var nextcall=App.CallPath.shift();
        //    if (nextcall==undefined){
        //       if (finalcall){
        //          finalcall();
        //       }
        //    }
        //    else{
        //       var regex=/^(.*)\((.*)\)$/;
        //       r=nextcall.match(regex);
        //       eval("App."+r[1]+"("+r[2]+");");
        //    }
        //    console.log("callstack:"+nextcall);
        //  //  alert("callstack:"+nextcall);
        // };

         window.setTimeout(function(){
           // App.callStack(function(){
               App.run();
           // });
         },100);
      }
   );

});
$(document).bind("mobileinit", function(){
   console.log("mobileinit");

});
$(document).on("pageinit", function(){
   console.log("pageinit");
});



$(document).ready(function () {
//   if ($.browser.msie || $.browser.webkit) {  // IE only works correct with
//       $("a").attr("data-ajax", "false");     // external references
//       $("a").attr("rel", "external");
//       var a = $("form");
//       if (a != null) {
//           $("form").first().attr("data-ajax", "false");
//           $("form").first().attr("rel", "external");
//       }
//   }
   $.mobile.loader.prototype.options.text = "loading ...";
   $.mobile.loader.prototype.options.textVisible = true;
   $.mobile.loader.prototype.options.theme = "b";
   $.mobile.loader.prototype.options.html = "";
   console.log("ready done");

});


