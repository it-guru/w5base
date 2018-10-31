define(["visjs"],function(vis){
  W5ExploreClass.prototype.ShowNetworkMap=function(MapParamTempl){
      var app=this;
      this.LayoutNetworkMap();
   };

   W5ExploreClass.prototype.LayoutSimpleStatMap=function(){
      if (!this.main ||  $(this.main).attr("data-layout")!="NetworkMap"){
         this.LayoutBase();
         this.netmap = document.createElement('div');
         this.netmap.id = 'netmap';
         this.workspace.appendChild(this.netmap);
         this.netmap.innerHTML = 'netmap';
        
         this.ctrl = document.createElement('div');
         this.ctrl.id = 'ctrl';
         this.workspace.appendChild(this.ctrl);

         this.ctrlbar = document.createElement('div');
         this.ctrlbar.id = 'ctrlbar';
         this.ctrl.appendChild(this.ctrlbar);

         this.dbrec = document.createElement('div');
         this.dbrec.id = 'dbrec';
         this.ctrl.appendChild(this.dbrec);

         this.showDefaultDBRec();
        
         this.console.div = document.createElement('div');
         this.console.div.id = 'cons';
         this.console.div.innerHTML = '';
         this.main.appendChild(this.console.div);
         $(this.ctrlbar).html(""); 
         $(this.ctrlbar).append($(this.globalFunctions())); 
         this.ResizeLayout();
         $.fn.disableSelection = function() {
             return this
                      .attr('unselectable', 'on')
                      .css('user-select', 'none')
                      .on('selectstart', false);
         };
         $(this.main).attr("data-layout","NetworkMap");
      }
   };

});

