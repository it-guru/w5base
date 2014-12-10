//
// Einheitliche Applications Startup Handler für Marvin JavaScript Anwendungen
//
var App;
i18n.init({
//        lng: 'en',
   debug: true,
   fallbackLng: 'en',                 // default language ist en
   lngWhitelist: ['de','en'],
   lowerCaseLng: true,
   load:'current',
   cookieName: 'lang',
   resGetPath: "__ns__-__lng__.json",
   ns: {
       namespaces: ['i18n'],
       defaultNs: 'i18n'
   }
   },function (t){
      App=new Application();   // Appl Objekt erzeugen

      if (!App.W5Base){
         App.W5Base=function(){
            if (!this._W5Base){
               var tempW5Base;
               var J5BaseConnect={
                     useUTF8:false,
                     mode:'auth',
                     transfer:'JSON',
                     baseURL:J5Base_baseUrl
               };
               eval("tempW5Base=createConfig(J5BaseConnect,J5Base_baseUrl);");
               this._W5Base=tempW5Base;
            }
            return(this._W5Base);
         }
      }
      if (!App.run){
         App.run=function(){};
      }


      $("*").i18n();           // Übersetzungen durchführen
      $("*[i18n]").hide();                   // i18n Elemente ausblenden
      $("*[i18n|='"+i18n.lng()+"']").show(); // die passenden i18n Elemente anz.
      if (Marvin_Home!=""){
         $(".homebutton").show();
         $(".homebutton").attr("href",Marvin_Home);
      }
      else{
         $("#homebutton").hide();
      }
      console.log("Marvin_Home:"+Marvin_Home);
      console.log("caller:"+document.referrer);
      window.setTimeout(function(){App.run();},1000);
   }
);


$(document).on( "mobileinit", function() {
   // ----------------------------------------------------
   // configure Loading box
   $.mobile.loader.prototype.options.text = "loading ...";
   $.mobile.loader.prototype.options.textVisible = true;
   $.mobile.loader.prototype.options.theme = "b";
   $.mobile.loader.prototype.options.html = "";
   // ----------------------------------------------------
});


