
var Graph = function()
{
	this.nodeSet = {};
	this.nodes = [];
	this.edges = [];
	this.adjacency = {};

	this.nextNodeId = 0;
	this.nextEdgeId = 0;
	this.eventListeners = [];
   return(this);
};

Node = function(id, data)
{
	this.id     = id;
	this.data   = data;
	this.active = 0;
   return(this);
};


Edge = function(id, source, target, data)
{
	this.id = id;
	this.source = source;
	this.target = target;
	this.data = typeof(data) !== 'undefined' ? data : {};
	this.active = 0;
   return(this);
};

Graph.prototype.addNode = function(node)
{
	this.nodes.push(node);
	this.nodeSet[node.id] = node;

	this.notify();
	return(node);
};

Graph.prototype.eachNode = function(callback)
{
   var t=this;
   var n=0;

   for(var k in this.nodeSet){
      callback.call(t,this.nodeSet[k],k,n);
      n++;
   }
};

Graph.prototype.NodeExists = function(k)
{
   if (this.nodeSet[k]){
      return(this.nodeSet[k]);
   }
   return(undefined);
};


Graph.prototype.delNode = function(k)
{
   console.log("delNode "+k);
   for(c=0;c<this.edges.length;c++){
      //console.log("e=",this.edges[c]);
      //console.log("source=",this.edges[c].source);
      //console.log("target=",this.edges[c].target);
      if (this.edges[c].target.id==k ||
          this.edges[c].source.id==k){
         this.edges.splice(c,1);
         c--;
      }
   }
   delete this.nodeSet[k];

   this.notify();
   return;
};


Graph.prototype.addEdge = function(edge)
{
	this.edges.push(edge);
   
   

	if (typeof(this.adjacency[edge.source.id]) === 'undefined')
	{
		this.adjacency[edge.source.id] = new Object();
	}
	if (typeof(this.adjacency[edge.source.id][edge.target.id]) === 'undefined')
	{
		this.adjacency[edge.source.id][edge.target.id] = new Object();
	}

	this.adjacency[edge.source.id][edge.target.id][edge.id]=edge;

	this.notify();
	return edge;
};

Graph.prototype.EdgeExists = function(k)
{
   for(c=0;c<this.edges.length;c++){
      if (this.edges[c].id==k){
         return(this.edges[c]);
      }
   }
   return(undefined);
};


Graph.prototype.newNode = function(k,data)
{
	var node = new Node(k, data);
	this.addNode(node);
   //console.log("newNode",k,data,node,this);
	return(node);
};

Graph.prototype.newEdge = function(k,source, target, data)
{
	//var edge = new Edge(this.nextEdgeId++, source, target, data);

	var edge = new Edge(k, source, target, data);
	this.addEdge(edge);
	return edge;
};

// find the edges from node1 to node2
Graph.prototype.getEdges = function(node1, node2)
{
	if (typeof(this.adjacency[node1.id]) !== 'undefined'
		&& typeof(this.adjacency[node1.id][node2.id]) !== 'undefined')
	{
      var l=new Array();
      for(var k in this.adjacency[node1.id][node2.id]){
         l.push(this.adjacency[node1.id][node2.id][k]);
      }
		return(l);
	}

	return([]);
};


Graph.prototype.addGraphListener = function(obj)
{
	this.eventListeners.push(obj);
};

Graph.prototype.notify = function()
{
//	this.eventListeners.forEach(function(obj){
//		obj.graphChanged();
//	});
};

// -----------
var Layout = {};
Layout.ForceDirected = function(graph, stiffness, repulsion, damping)
{
	this.graph = graph;
	this.stiffness = stiffness; // spring stiffness constant
	this.repulsion = repulsion; // repulsion constant
	this.damping = damping; // velocity damping factor

	this.nodePoints = {}; // keep track of points associated with nodes
	this.edgeSprings = {}; // keep track of points associated with nodes

	this.intervalId = null;
};

Layout.ForceDirected.prototype.point = function(node)
{
	if (typeof(this.nodePoints[node.id]) === 'undefined')
	{
		var mass = typeof(node.data.mass) !== 'undefined' ? node.data.mass : 1.0;
      // Problem!
      var newpoint=new Layout.ForceDirected.Point(Vector.random(), mass);
      //for(var k in this.nodePoints){
      //   if (newpoint.p.x==this.nodePoints[k].p.x &&
      //       newpoint.p.y==this.nodePoints[k].p.y){
      //   console.log("check k=",k,this.nodePoints[k]);
      //      newpoint=new Layout.ForceDirected.Point(Vector.random(), mass);
      //   }
      //}
		this.nodePoints[node.id] = newpoint;
	}

	return this.nodePoints[node.id];
};

Layout.ForceDirected.prototype.spring = function(edge)
{
	if (typeof(this.edgeSprings[edge.id]) === 'undefined')
	{
		var length = typeof(edge.data.length) !== 'undefined' ? edge.data.length : 1.0;

		var existingSpring = false;

		var from = this.graph.getEdges(edge.source, edge.target);
		from.forEach(function(e){
			if (existingSpring === false && typeof(this.edgeSprings[e.id]) !== 'undefined') {
				existingSpring = this.edgeSprings[e.id];
			}
		}, this);

		if (existingSpring !== false) {
			return new Layout.ForceDirected.Spring(existingSpring.point1, existingSpring.point2, 0.0, 0.0);
		}

		var to = this.graph.getEdges(edge.target, edge.source);
		from.forEach(function(e){
			if (existingSpring === false && typeof(this.edgeSprings[e.id]) !== 'undefined') {
				existingSpring = this.edgeSprings[e.id];
			}
		}, this);

		if (existingSpring !== false) {
			return new Layout.ForceDirected.Spring(existingSpring.point2, existingSpring.point1, 0.0, 0.0);
		}

		this.edgeSprings[edge.id] = new Layout.ForceDirected.Spring(
			this.point(edge.source), this.point(edge.target), length, this.stiffness
		);
	}

	return this.edgeSprings[edge.id];
};

// callback should accept two arguments: Node, Point
Layout.ForceDirected.prototype.eachNode = function(callback)
{
	var t = this;

   var n=0; 
   for(var k in this.graph.nodeSet){
      if (this.graph.nodeSet[k].active){
         //callback.call(t, n, t.point(this.graph.nodeSet[k]));
         callback.call(t,this.graph.nodeSet[k],t.point(this.graph.nodeSet[k]));
         n++;
      }
   }

//	this.graph.nodes.forEach(function(n){
//		callback.call(t, n, t.point(n));
//	});
};

// callback should accept two arguments: Edge, Spring
Layout.ForceDirected.prototype.eachEdge = function(callback)
{
	var t = this;

	this.graph.edges.forEach(function(e){
      if (e.active){
         callback.call(t, e, t.spring(e));
      }
	});
};

// callback should accept one argument: Spring
Layout.ForceDirected.prototype.eachSpring = function(callback)
{
	var t = this;
	this.graph.edges.forEach(function(e){
		callback.call(t, t.spring(e));
	});
};


// Physics stuff
Layout.ForceDirected.prototype.applyCoulombsLaw = function()
{
	this.eachNode(function(n1, point1) {
		this.eachNode(function(n2, point2) {
			if (point1 !== point2)
			{
				var d = point1.p.subtract(point2.p);
				var distance = d.magnitude() + 1.0;
				var direction = d.normalise();

				// apply force to each end point
				point1.applyForce(direction.multiply(this.repulsion).divide(distance * distance * 0.5));
				point2.applyForce(direction.multiply(this.repulsion).divide(distance * distance * -0.5));
			}
		});
	});
};

Layout.ForceDirected.prototype.applyHookesLaw = function()
{
	this.eachSpring(function(spring){
		var d = spring.point2.p.subtract(spring.point1.p); // the direction of the spring
		var displacement = spring.length - d.magnitude();
		var direction = d.normalise();

		// apply force to each end point
		spring.point1.applyForce(direction.multiply(spring.k * displacement * -0.5));
		spring.point2.applyForce(direction.multiply(spring.k * displacement * 0.5));
	});
};

Layout.ForceDirected.prototype.attractToCentre = function()
{
	this.eachNode(function(node, point) {
		var direction = point.p.multiply(-1.0);
		point.applyForce(direction.multiply(this.repulsion / 5.0));
	});
};


Layout.ForceDirected.prototype.updateVelocity = function(timestep)
{
	this.eachNode(function(node, point) {
		point.v = point.v.add(point.f.multiply(timestep)).multiply(this.damping);
		point.f = new Vector(0,0);
	});
};

Layout.ForceDirected.prototype.updatePosition = function(timestep)
{
	this.eachNode(function(node, point) {
		point.p = point.p.add(point.v.multiply(timestep));
	});
};

Layout.ForceDirected.prototype.totalEnergy = function(timestep)
{
	var energy = 0.0;
	this.eachNode(function(node, point) {
		var speed = point.v.magnitude();
		energy += speed * speed;
	});

	return energy;
};


// start simulation
Layout.ForceDirected.prototype.start = function(interval, render, done)
{
	var t = this;

	if (this.intervalId !== null) {
		return; // already running
	}

	this.intervalId = setInterval(function() {
      var intervalNewNodes=0;
      var intervalNewEdges=0;
      var maxNewNodes=6;
      var maxNewEdges=4;
      var nNodes=0; 
      var nEdges=0; 
      for(var k in t.graph.nodeSet){
         if (t.graph.nodeSet[k].active){
            nNodes++;
         }
      }
      if (nNodes>50){
          maxNewNodes=2;
          maxNewEdges=4;
      }
      if (nNodes>100){
          maxNewNodes=1;
          maxNewEdges=2;
      }
      var e=t.totalEnergy();
      if (e>10){
         maxNewEdges=1;
         maxNewNodes=1;
      }
      if (e>50){
         maxNewEdges=0;
      }
      if (e>150){
         maxNewNodes=0;
         maxNewEdges=0;
      }
      nNodes=0;
      for(var k in t.graph.nodeSet){
         if (!t.graph.nodeSet[k].active){
            if (intervalNewNodes<maxNewNodes){
               t.graph.nodeSet[k].active=1;
               intervalNewNodes++;
            }
         }
         else{
            nNodes++;
         }
      }
      if (intervalNewNodes>0){
         if (maxNewEdges>0){
            maxNewEdges=1;
         }
      }
	   for(var c=0;c<t.graph.edges.length;c++){
         var edge=t.graph.edges[c];
         if (!edge.active){
            if (intervalNewEdges<maxNewEdges){
               edge.active=1;
               intervalNewEdges++;
            }
         }
         else{
            nEdges++;
         }
      }
      //console.log("e=",e," activeNodes=",nNodes," activeEdges=",nEdges,"start new Interval ....");
      if (isNaN(e) && nNodes>0){  // error in system!
         console.log("ERROR in energy system");
		   clearInterval(t.intervalId);
      }

		t.applyCoulombsLaw();
		t.applyHookesLaw();
		t.attractToCentre();
		t.updateVelocity(0.04);
		t.updatePosition(0.04);

		if (typeof(render) !== 'undefined') { render(); }

		// stop simulation when energy of the system goes below a threshold
      var e=t.totalEnergy();
      var pct=Math.sqrt(e);
      if (pct>100){
         pct=100;
      }
      if (pct<1){
         pct=0;
      }
      pct=Math.round(pct);
      if (pct>0){
         var d="<div style='width:100%;height:"+pct+"%;"+
               "background-color:darkblue;display: inline-block;'></div>";
         $('#loadPct').html(d);
      }
      else{
         $('#loadPct').html("");
      }
      //$('#totalEnergy').html("e="+e);
		if (e < 0.3 ) {
			clearInterval(t.intervalId);
			t.intervalId = null;
			if (typeof(done) !== 'undefined') { done(); }
		}
	}, interval);
};

// Find the nearest point to a particular position
Layout.ForceDirected.prototype.nearest = function(pos)
{
	var min = {node: null, point: null, distance: null};
	var t = this;
	this.graph.nodes.forEach(function(n){
		var point = t.point(n);
		var distance = point.p.subtract(pos).magnitude();

		if (min.distance === null || distance < min.distance)
		{
			min = {node: n, point: point, distance: distance};
		}
	});

	return min;
};

// returns [bottomleft, topright]
Layout.ForceDirected.prototype.getBoundingBox = function()
{
	var bottomleft = new Vector(-0.1,-0.1);
	var topright = new Vector(0.1,0.1);

	this.eachNode(function(n, point) {
		if (point.p.x < bottomleft.x) {
			bottomleft.x = point.p.x;
		}
		if (point.p.y < bottomleft.y) {
			bottomleft.y = point.p.y;
		}
		if (point.p.x > topright.x) {
			topright.x = point.p.x;
		}
		if (point.p.y > topright.y) {
			topright.y = point.p.y;
		}
	});

	var padding = topright.subtract(bottomleft).multiply(0.05); // 5% padding

	return {bottomleft: bottomleft.subtract(padding), topright: topright.add(padding)};
};


// Vector
Vector = function(x, y)
{
	this.x = x;
	this.y = y;
};

Vector.random = function()
{
	return new Vector(2.0 * (Math.random() - 0.5), 2.0 * (Math.random() - 0.5));
};

Vector.prototype.add = function(v2)
{
	return new Vector(this.x + v2.x, this.y + v2.y);
};

Vector.prototype.subtract = function(v2)
{
	return new Vector(this.x - v2.x, this.y - v2.y);
};

Vector.prototype.multiply = function(n)
{
	return new Vector(this.x * n, this.y * n);
};

Vector.prototype.divide = function(n)
{
	return new Vector(this.x / n, this.y / n);
};

Vector.prototype.magnitude = function()
{
	return Math.sqrt(this.x*this.x + this.y*this.y);
};

Vector.prototype.normal = function()
{
	return new Vector(-this.y, this.x);
};

Vector.prototype.normalise = function()
{
	return this.divide(this.magnitude());
};

// Point
Layout.ForceDirected.Point = function(position, mass)
{
	this.p = position; // position
	this.m = mass; // mass
	this.v = new Vector(0, 0); // velocity
	this.f = new Vector(0, 0); // force
};

Layout.ForceDirected.Point.prototype.applyForce = function(force)
{
	this.f = this.f.add(force.divide(this.m));
};

// Spring
Layout.ForceDirected.Spring = function(point1, point2, length, k)
{
	this.point1 = point1;
	this.point2 = point2;
	this.length = length; // spring length at rest
	this.k = k; // spring constant (See Hooke's law) .. how stiff the spring is
};

// Layout.ForceDirected.Spring.prototype.distanceToPoint = function(point)
// {
// 	// hardcore vector arithmetic.. ohh yeah!
// 	// .. see http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment/865080#865080
// 	var n = this.point2.p.subtract(this.point1.p).normalise().normal();
// 	var ac = point.p.subtract(this.point1.p);
// 	return Math.abs(ac.x * n.x + ac.y * n.y);
// };

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

      t.layout.eachNode(function(node, point) {
         t.drawNode(node, point.p);
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


