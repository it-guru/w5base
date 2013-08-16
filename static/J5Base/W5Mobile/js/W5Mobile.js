var ENV=getConfigNameFromURL(document.URL);
loadScript(ENV.rootpath+"public/base/load/J5Base.js"); //ensure J5Base is loaded

console.log(ENV);



function getConfigNameFromURL(url){
   var options={
      'url':url,
      'unescape':true,
      'convert_num':true
   };

   var a = document.createElement('a');
   a.href = options['url'];
   url_query = a.search.substring(1);

   var params = {};
   var vars = url_query.split('&');

   if(vars[0].length > 1)
   {
      for(var i = 0; i < vars.length; i++)
      {
        var pair = vars[i].split("=");
        var key = (options['unescape'])?unescape(pair[0]):pair[0];
        var val = (options['unescape'])?unescape(pair[1]):pair[1];
 
        if(options['convert_num'])
        {   
           if(val.match(/^\d+$/))
             val = parseInt(val);
 
           else if(val.match(/^\d+\.\d+$/))
             val = parseFloat(val);
        }

        if(typeof params[key] === "undefined")
           params[key] = val;
        else if(typeof params[key] === "string")
           params[key] = [params[key],val];
        else
           params[key].push(val);
      }  
   }
   var path=a.pathname.split('/');
   path.shift();
   path.pop();
   var rpath=path.reverse();
   var config=rpath[3];

   var urlObj = {
      protocol:a.protocol,
      hostname:a.hostname,
      host:a.host,
      port:a.port,
      hash:a.hash,
      pathname:a.pathname,
      configname:config,
      rootpath:"../../../"+config+"/",
      path:path,
      search:a.search,
      parameters:params
   };
 
   return urlObj;
}

function loadScript(scriptname) {  
  var snode = document.createElement('script');  
  snode.setAttribute('type','text/javascript');  
  snode.setAttribute('src',scriptname);  
  document.getElementsByTagName('head')[0].appendChild(snode);  
}  
