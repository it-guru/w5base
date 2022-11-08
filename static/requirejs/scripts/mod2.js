console.log("load of mod2");

var mod2function=function(){

   require(['mod11'],function(m11){
      console.log("result in mod2 of m11 load",m11);
   });

   return {
       mod2: "object",
       size: "unisize"
   }
};



var ClassObj=function(){
   console.log("ClassObj at m2 constructor");
   this.name="ClassObj init";
   this.f1callcount=0;
   this.f1=function(){
       this.f1callcount++;
       console.log("ClassObj at m2 f1 function:",this.f1callcount);
   };
};

define(function () {
    //Do setup work here

    return(ClassObj);
});





define(mod2function);



