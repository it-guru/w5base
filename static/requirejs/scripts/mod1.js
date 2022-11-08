console.log("load of mod1");
require(['mod11'],function(m11){
   console.log("result in mod1 of m11 load",m11);
});

define(function () {
    //Do setup work here

    return {
        color: "black",
        size: "unisize"
    }
});
