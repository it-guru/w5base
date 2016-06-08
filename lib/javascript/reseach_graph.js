
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

