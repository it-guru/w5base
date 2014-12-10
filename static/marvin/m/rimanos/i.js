
function Application(){

   this.searchApplication=function(){
      var listview="name,id";
      var detailview="name,description,id";
      var curview=listview;
      var o=this.W5Base().getModuleObject("itil::appl");
     
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
               li.html(App.searchApplicationListEntry(l[c]));
               ul.append(li);
            }
            $("#applist-content").append(ul);
            $('#applist').trigger("create");
         }
      });
      return(false);
   }

   this.displayApplication=function(rec){
      $.mobile.navigate("#appdetail");
      $("#appdetail-content").html("OK found "+rec[0].name);
   }


   this.searchApplicationListEntry=function(rec){
      var d="<a class='list-href' rel='external' id='"+rec.id+"' "+
            "href='?A:"+rec.id+"#applist"+
            "'>"+rec.name+"</a>";
      return(d);
   }



   this.searchTopLists=function(){
      var listview="name,applications,id";
      var detailview="name,description,id";
      var curview=listview;
      $.mobile.loading('show');
      var o=this.W5Base().getModuleObject("itil::mgmtitemgroup");
     
      if (0){ // directer call
         curview=detailview;
         // url auswerten, welche ID geladen werden soll
      }
      else{
         o.SetFilter({name:"top*", cistatusid:"4"});
      }
      o.findRecord(curview,function(l){
         $.mobile.loading('hide');
         if (l.length==0){
            alert("not found");
         }
         else if (l.length==1){
            if (curview!=detailview){
               o.SetFilter({id:l[0].id});  // detail Felder hinzuladen
               o.findRecord(detailview,App.displayTopList);
            }
            else{  // direct anzeigen
               displayTopList(l);
            }
         }
         else{
            var label="Top-Listen:";
            var ul=$('<ul id="listview" data-role="listview" '+
                     'data-inset="true" style="height:100%"/>');
            ul.append("<li data-role='list-divider'>"+label+"</li>");
            for(c=0;c<l.length;c++){
               if (l[c].applications.length){ 
                  var li=$('<li />').attr({
                     id:l[c].id,
                     name:l[c].name
                  });
                  li.html(App.searchTopListsEntry(l[c]));
                  ul.append(li);
               }
            }
            $("#toplists-content").append(ul);
            $('#toplists').trigger("create");
         }
      });
      return(false);
   }

   this.displayTopList=function(rec){
      $.mobile.navigate("#toplist");
      $("#toplist-content").html("OK found "+rec[0].name);
   }


   this.searchTopListsEntry=function(rec){
      var d="<a class='list-href' rel='external' id='"+rec.id+"' "+
            "href='?T:"+rec.id+"#toplist"+
            "'>"+rec.name+"</a>";
      return(d);
   }





   $('#toplists').live('pagebeforeshow',function(event, ui){
      $("#toplists-content").html("");
   });

   $('#toplists').live('pageshow',function(event, ui){
       App.searchTopLists();
   });


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




