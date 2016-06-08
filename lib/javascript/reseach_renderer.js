// PlanRenderer handles the layout rendering loop
function PlanRenderer(interval,layout,clear,drawEdge,drawNode,finalize,resize)
{
	this.interval = interval;
	this.layout = layout;
	this.clear = clear;
	this.finalize = resize;
	this.resize = resize;
	this.drawEdge = drawEdge;
	this.drawNode = drawNode;

	this.layout.graph.addGraphListener(this);
}

PlanRenderer.prototype.graphChanged = function(e)
{
	this.start();
};

PlanRenderer.prototype.start = function()
{
	var t = this;
	this.layout.start(this.interval, function render() {
		t.clear();

		t.layout.eachEdge(function(edge, spring) {
			t.drawEdge(edge, spring.point1.p, spring.point2.p);
		});

		t.layout.eachNode(function(node, point) {
			t.drawNode(node, point.p);
		});
      if (t.finalize){
         t.finalize();
      }
	});
};

PlanRenderer.prototype.Resize = function()
{
	var t = this;
   if (t.resize){
      t.resize();
   }
};








// TabRenderer handles the layout rendering loop
function TabRenderer(interval,layout,clear,drawEdge,drawNode,finalize,resize)
{
	this.interval = interval;
	this.layout = layout;
	this.clear = clear;
	this.finalize = finalize;
	this.resize = resize;
	this.drawEdge = drawEdge;
	this.drawNode = drawNode;
   this.isFresh  =0;

	this.layout.graph.addGraphListener(this);
}

TabRenderer.prototype.graphChanged = function(e)
{
	this.start();
};

TabRenderer.prototype.start = function()
{
	var t = this;
//   if (!this.isFresh){
//	this.layout.start(20, function render() {console.log("render background")});
      t.clear();

      t.layout.eachEdge(function(edge, spring) {
         t.drawEdge(edge, spring.point1.p, spring.point2.p);
      });

      t.layout.graph.eachNode(function(node) {
         t.drawNode(node);
      });
      if (t.finalize){
         t.finalize();
      }
      this.isFresh=1;
 //  }

//	this.layout.start(50, function render() {
//		t.clear();
//
//		t.layout.eachEdge(function(edge, spring) {
//			t.drawEdge(edge, spring.point1.p, spring.point2.p);
//		});
//
//		t.layout.eachNode(function(node, point) {
//			t.drawNode(node, point.p);
//		});
 //     if (t.finalize){
  //       t.finalize();
   //   }
//	});
};

TabRenderer.prototype.Resize = function()
{
	var t = this;
   if (t.resize){
      t.resize();
   }
};


