
function Application(){

   this.searchApplication=function(id){
      var listview="name,id";
      var detailview="name,description,id";
      var curview=listview;
      var o=this.W5Base().getModuleObject("itil::appl");

     
      if (id){ // directer call
         console.log("show direct id "+id);
         curview=detailview;
         o.SetFilter({id:id});
      }
      else{
         var search_name=$('#search_application_name').val();
         if (search_name.length==0){
            $.mobile.navigate("#appsearch");
         }
         o.SetFilter({name:search_name, cistatusid:"!6"});
      }
      o.findRecord(curview,function(l){
         if (l.length==0){
            alert("not found");
         }
         else if (l.length==1){
            if (curview!=detailview){
               o.SetFilter({id:l[0].id});  // detail Felder hinzuladen
               o.findRecord(detailview,function(l){
                  App.currentApplication=l[0];
                  App.displayApplication(l);
               });
            }
            else{  // direct anzeigen
               App.callStack(function(){App.displayApplication(l);});
            }
         }
         else{
            $.mobile.navigate("#applist");
            $('#appdetail-back-btn').attr('href',"#applist"); // allow back list
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
            $(".list-href").click(function(){
               $.mobile.loading('show');
               var id=$(this).attr("id");
               App.A(id); 
            });

         }
      });
      return(false);
   }
   this.A=this.searchApplication;

   this.displayApplicationURL=function(rec){
      return("#appdetail?A("+rec.id+")");
   }

   this.displayApplication=function(rec){
      $.mobile.navigate(App.displayApplicationURL(rec[0]));
      $("#appdetail-content").html("OK found "+rec[0].name);
   }


   this.searchApplicationListEntry=function(rec){
      var d="<a class='list-href' rel='external' id='"+rec.id+"' "+
            "href='"+App.displayApplicationURL(rec)+"'>"+rec.name+"</a>";
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
            "href='#toplist?T:"+rec.id+
            "'>"+rec.name+"</a>";
      return(d);
   }

   $('#toplists').live('pagebeforeshow',function(event, ui){
      console.log("pagebeforeshow");
      $("#toplists-content").html("");
   });

   $('#applist').live('pageshow',function(event, ui){  // falls applist gebooked
      var search_name=$('#search_application_name').val();
      if (search_name.length==0){
         $.mobile.navigate("#appsearch");
      }
   });

   $('#toplists').live('pageshow',function(event, ui){
       console.log("pageshow");
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




