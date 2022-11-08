console.log("load of mod3");

var ClassObj=function(){
   console.log("ClassObj constructor");
   this.name="ClassObj init";
   this.f1callcount=0;
   this.f1=function(){
       this.f1callcount++;
       console.log("ClassObj f1 function:",this.f1callcount);
   };
};

define(function () {
    //Do setup work here

    return(new ClassObj());
});




