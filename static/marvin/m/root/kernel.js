//
//   console.log Hack
//
var alertFallback = false;
if (typeof console === "undefined" || typeof console.log === "undefined") {
  console = {};
  if (alertFallback) {
      console.log = function(msg) {
           alert(msg);
      };
  } else {
      console.log = function() {};
  }
}

function loadScript(url) {
    var script = document.createElement('script');
    console.log("loadScript:"+url);
    script.type = 'text/javascript';
    script.src = url;
    $("head").append(script);
}
loadScript(J5Base_baseUrl+"public/base/load/J5BaseMinimal.js");


//////////////////////////////////////////////////////////////////////////

