var W5Base;


function Application(){
   this.run=function(){
      var J5BaseConnect={ 
            useUTF8:false,
            mode:'auth',
            transfer:'JSON',
            baseURL:J5Base_baseUrl
      };
      eval("W5Base=createConfig(J5BaseConnect,J5Base_baseUrl);");
   }
   $("input").keypress(function(event) {
     //  if (event.which == 13) {
     //     console.log("key 13 event");
     //     $(this).closest('form').submit();
     //     return(false);
     //  }
     //  return(false);
   });
   return(this);
};


function displayApplication(rec)
{
   $.mobile.navigate("#appdetail");
   $("#appdetail-content").html("OK found "+rec[0].name);

}

function searchApplication()
{
   var listview="name,id";
   var detailview="name,description,id";
   var curview=listview;
   var o=W5Base.getModuleObject("itil::appl");

   if (0){ // directer call
      curview=detailview;
      // url auswerten, welche ID geladen werden soll
   }
   else{
      var search_name=$('#search_application_name').val();
      o.SetFilter({name:search_name, cistatusid:"!6"});
   }
   o.findRecord(curview,function(l){
      if (l.length==0){
         alert("not found");
      }
      else if (l.length==1){
         if (curview!=detailview){
            o.SetFilter({id:l[0].id});  // detail Felder hinzuladen
            o.findRecord(detailview,displayApplication);
         }
         else{  // direct anzeigen
            displayApplication(l);
         }
      }
      else{
         $.mobile.navigate("#applist");
         var label="Anwendungsliste";
         $("#applist-content").html("");
         var ul=$('<ul id="listview" data-role="listview" '+
                  'data-inset="true" style="height:100%"/>');
         ul.append("<li data-role='list-divider'>"+label+"</li>");
         for(c=0;c<l.length;c++){
            var li=$('<li />').attr({
               id:l[c].id,
               name:l[c].name
            });
            li.html(searchApplicationListEntry(l[c]));
            ul.append(li);
         }
         $("#applist-content").append(ul);
         $('#applist').trigger("create");
      }
   });
   return(false);
}

function searchApplicationListEntry(rec)
{
   var d="<a class='list-href' rel='external' id='"+rec.id+"' "+
         "href='?searchApplication("+rec.id+")#applist"+
         "'>"+rec.name+"</a>";
   return(d);
}



