<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="EmulateIE10;IE=edge"/>
<base href="%BASE%">
<link rel="stylesheet" href="../../../public/base/load/goldenlayout-base.css">
<link rel="stylesheet" href="../../../public/base/load/goldenlayout-light-theme.css">
<link rel="stylesheet" href="../../../public/base/load/OpenW5Desktop.css">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<title>OpenW5Desktop - preBETA!</title>
<script language="JavaScript" src="../../../public/base/load/promise.js?5">
</script>
<script language="JavaScript" src="../../../auth/base/load/J5Base.js">
</script>
<script language="JavaScript" src="../../../public/base/load/spin.js">
</script>
<script language="JavaScript" src="../../../public/base/load/datadumper.js">
</script>
<script language="JavaScript" src="../../../public/base/load/goldenlayout.js">
</script>
<style>
h2{
  font: 14px Arial, sans-serif;
  color:#fff;
  padding: 10px;
  text-align: center;
}

html, body{
  height: 100%;
}

*{
  margin: 0;
  padding: 0;
  list-style-type:none;
}

#wrapper{
  height: 100%;
  position: relative;
  width: 100%;
  overflow: hidden;
}

#menuContainer{
  width: 20%;
  height: 100%;
  position:absolute;
  top: 0;
  left: 0;
}

#menuContainer li{
  cursor: move;
  border-bottom: 1px solid #000;
  border-top: 1px solid #333;
  cursor: pointer;
  padding: 10px 5px;
  color: gray;
  background:#f4f4f4;
  font: 12px Arial, sans-serif;
}

#menuContainer li:hover{
  color: black;
  background:#f3f3f3;
}

#layoutContainer{
  width: 80%;
  height: 100%;
  position:absolute;
  top: 0;
  left: 20%;
  box-shadow: -3px 0px 9px 0px rgba( 0, 0, 0, 0.4 );
}
</style>


</head><body>
<div id="wrapper">
  <ul id="menuContainer"></ul>
  <div id="layoutContainer"></div>
</div>

<script>
$(document).ready(function(){
   var config = {
       dimensions: {
           minItemHeight: 480,
           minItemWidth: 640,
       },
       content: [{
           type: 'row',
           content: [{
               type:'component',
               componentName: 'w5base_dataobj',
               title:'Kontakteverwaltung',
               dataobj:'base::user',
               componentState: { 
                   text: "Loading... "
               }
           }
           ]
       }]
   };
   var myLayout,savedState=localStorage.getItem( 'savedState' );
   if (savedState!==null){
      config=JSON.parse(savedState);
   }
   // posible place for forcing config parameters
   delete(config.maxmisedItemId);


   // ///////////////////////////////////////////////////////////////////

   var myLayout = new window.GoldenLayout( config, $('#layoutContainer') );

   myLayout.registerComponent( 'w5base_dataobj', 
     function( container, state ){
       var dataobj=container._config.dataobj;
       console.log("w5 ",dataobj);
       var dataobjpath=dataobj.replace("::","/");
       var url="../../"+dataobjpath+"/NativMain";
       var html="<iframe style='width:100%;height:100%' "+
                "src='"+url+"'></iframe>";
       container.getElement().html(html);
     }
   );

   myLayout.on( 'stateChanged', function(){
       var state = JSON.stringify( myLayout.toConfig() );
       console.log("state=",state);
       localStorage.setItem( 'savedState', state );
   });

   myLayout.init();

   var addMenuItem = function( title, dataobj ) {
       var element = $( '<li>' + title + '</li>' );
       $( '#menuContainer' ).append( element );

      var newItemConfig = {
           title: title,
           type: 'component',
           dataobj:dataobj,
           componentName: 'w5base_dataobj',
           componentState: { text: 'Loading ...' }
       };
     
       myLayout.createDragSource( element, newItemConfig );
   };

   addMenuItem( 'Systemverwaltung->Gruppe', 'base::grp' );
   addMenuItem( 'Systemverwaltung->Kontakt', 'base::user' );
   addMenuItem( 'IT-Inventar->Anwendung', 'itil::appl' );
   addMenuItem( 'IT-Inventar->System', 'itil::system' );
});



</script>
</body>
</html>



