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


