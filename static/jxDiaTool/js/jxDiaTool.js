function _(str) { /* getText */
	if (!(str in window.LOCALE)) { return str; }
	return window.LOCALE[str];
}

var DATATYPES = false;
var LOCALE = {};
var jxDiaTool = {};

/* -------------------- base visual element -------------------- */

jxDiaTool.Visual = OZ.Class(); /* abstract parent */
jxDiaTool.Visual.prototype.init = function() {
	this._init();
	this._build();
}

jxDiaTool.Visual.prototype._init = function() {
	this.dom = {
		container:OZ.DOM.elm("div"),
		content:OZ.DOM.elm("div"),
		title:OZ.DOM.elm("div",{className:"title"})
	};
	this.data = {
		title:""
	}
}

jxDiaTool.Visual.prototype._build = function() {}

jxDiaTool.Visual.prototype.toXML = function() {}

jxDiaTool.Visual.prototype.fromXML = function(node) {}

jxDiaTool.Visual.prototype.destroy = function() { /* "destructor" */
	var p = this.dom.container.parentNode;
	if (p && p.nodeType == 1) {
		p.removeChild(this.dom.container);
	}
}

jxDiaTool.Visual.prototype.setTitle = function(text) {
	if (!text) { return; }
	this.data.title = text;
	this.dom.title.innerHTML = text;
}

jxDiaTool.Visual.prototype.getTitle = function() {
	return this.data.title;
}

jxDiaTool.Visual.prototype.redraw = function() {}

/* --------------------- table row ( = db column) ------------ */

jxDiaTool.Row = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.Row.prototype.init = function(parent, title, data) {
	this.parent = parent;
	this.relations = [];
	this.keys = [];
	this.selected = false;
	this.expanded = false;
	
	jxDiaTool.Visual.prototype.init.apply(this);
	
	this.data.type = 0;
	this.data.size = "";
	this.data.def = null;
	this.data.nll = true;
	this.data.ai = false;
	this.data.comment = "";
	
	if (data) { this.update(data); }
	this.setTitle(title);
}

jxDiaTool.Row.prototype._build = function() {
	this.dom.container.className = "row";
	this.dom.content.style.display = "none";
	
	this.enter = this.bind(this.enter);
	this.changeComment = this.bind(this.changeComment);
	
	this.dom.selected = OZ.DOM.elm("span",{className:"row_selected"});
	this.dom.selected.innerHTML = "&raquo;&nbsp;";
	
	OZ.DOM.append([this.dom.container,this.dom.selected,this.dom.title,this.dom.content]);

	OZ.Event.add(this.dom.container,"click",this.bind(this.click));
	OZ.Event.add(this.dom.container,"dblclick",this.bind(this.dblclick));
	OZ.Event.add(this.dom.container,"mousedown",this.bind(this.mousedown));
}

jxDiaTool.Row.prototype.select = function() {
	if (this.selected) { return; }
	this.selected = true;
	this.redraw();
}

jxDiaTool.Row.prototype.deselect = function() {
	if (!this.selected) { return; }
	this.selected = false;
	this.redraw();
	this.collapse();
}

jxDiaTool.Row.prototype.setTitle = function(t) {
	var old = this.getTitle();
	for (var i=0;i<this.relations.length;i++) {
		var r = this.relations[i];
		if (r.row1 != this) { continue; }
		var tt = r.row2.getTitle().replace(new RegExp(old,"g"),t);
		if (tt != r.row2.getTitle()) { r.row2.setTitle(tt); }
	}
	jxDiaTool.Visual.prototype.setTitle.apply(this, [t]);
}

jxDiaTool.Row.prototype.click = function(e) { /* clicked on row */
	OZ.Event.stop(e);
	this.dispatch("rowclick",this);
//	this.parent.parent.rowManager.select(this);
}

jxDiaTool.Row.prototype.dblclick = function(e) { /* dblclicked on row */
	OZ.Event.prevent(e);
	OZ.Event.stop(e);
	this.expand();
}

jxDiaTool.Row.prototype.mousedown = function(e) {
	OZ.Event.stop(e);
	this.parent.parent.entityManager.select(this.parent);
}

jxDiaTool.Row.prototype.update = function(data) { /* update subset of row data */
	var des = jxDiaTool.MainApp;
	if (data.nll && data.def && data.def.match(/^null$/i)) { data.def = null; }
	
	for (var p in data) { this.data[p] = data[p]; }
	if (!this.data.nll && this.data.def === null) { this.data.def = ""; }

	var elm = this.getDataType();
	for (var i=0;i<this.relations.length;i++) {
		var r = this.relations[i];
		if (r.row1 == this) { r.row2.update({type:des.getFKTypeFor(this.data.type),size:this.data.size}); }
	}
	this.redraw();
}

jxDiaTool.Row.prototype.up = function() { /* shift up */
	var r = this.parent.rows;
	var idx = r.indexOf(this);
	if (!idx) { return; }
	r[idx-1].dom.container.parentNode.insertBefore(this.dom.container,r[idx-1].dom.container);
	r.splice(idx,1);
	r.splice(idx-1,0,this);
	this.redraw();
}

jxDiaTool.Row.prototype.down = function() { /* shift down */
	var r = this.parent.rows;
	var idx = r.indexOf(this);
	if (idx+1 == this.parent.rows.length) { return; }
	r[idx].dom.container.parentNode.insertBefore(this.dom.container,r[idx+1].dom.container.nextSibling);
	r.splice(idx,1);
	r.splice(idx+1,0,this);
	this.redraw();
}

jxDiaTool.Row.prototype.buildContent = function() {
	var elms = [];
	this.dom.name = OZ.DOM.elm("input");
	this.dom.name.type = "text";
	elms.push(["name",this.dom.name]);
	OZ.Event.add(this.dom.name, "keypress", this.enter);

	this.dom.type = this.buildTypeSelect(this.data.type);
	elms.push(["type",this.dom.type]);

	this.dom.size = OZ.DOM.elm("input");
	this.dom.size.type = "text";
	elms.push(["size",this.dom.size]);

	this.dom.def = OZ.DOM.elm("input");
	this.dom.def.type = "text";
	elms.push(["def",this.dom.def]);

	this.dom.ai = OZ.DOM.elm("input");
	this.dom.ai.type = "checkbox";
	elms.push(["ai",this.dom.ai]);

	this.dom.nll = OZ.DOM.elm("input");
	this.dom.nll.type = "checkbox";
	elms.push(["null",this.dom.nll]);
	
	this.dom.commentbtn = OZ.DOM.elm("input");
	this.dom.commentbtn.type = "button";
	this.dom.commentbtn.value = _("comment");
	
	OZ.Event.add(this.dom.commentbtn, "click", this.changeComment);

	for (var i=0;i<elms.length;i++) {
		var row = elms[i];
		var l = OZ.DOM.text(_(row[0])+": ");
		this.dom.content.appendChild(l);
		this.dom.content.appendChild(row[1]);
		this.dom.content.appendChild(OZ.DOM.elm("br"));
	}
	
	this.dom.comment = OZ.DOM.elm("span",{className:"comment"});
	this.dom.comment.innerHTML = this.data.comment;
	
	this.dom.content.appendChild(this.dom.comment);
	this.dom.content.appendChild(this.dom.commentbtn);
}

jxDiaTool.Row.prototype.changeComment = function(e) {
	var c = prompt(_("commenttext"),this.data.comment);
	this.data.comment = c || "";
	this.dom.comment.innerHTML = this.data.comment;
}

jxDiaTool.Row.prototype.expand = function() {
	if (this.expanded) { return; }
	this.expanded = true;
	this.dom.title.style.display = "none";
	this.dom.content.style.display = "block";
	this.buildContent();
	this.load();
	this.redraw();
	this.dom.name.focus();
	this.dom.name.select();
}

jxDiaTool.Row.prototype.collapse = function() {
	if (!this.expanded) { return; }
	this.expanded = false;

	this.setTitle(this.dom.name.value);
	var data = {
		type: this.dom.type.selectedIndex,
		def: this.dom.def.value,
		size: this.dom.size.value,
		nll: this.dom.nll.checked,
		ai: this.dom.ai.checked
	}

	OZ.DOM.clear(this.dom.content);
	this.dom.content.style.display = "none";
	this.dom.title.style.display = "block";
	this.update(data);
	/* gecko hack */
	this.parent.moveBy(1,1);
	this.parent.moveBy(-1,-1); 
}

jxDiaTool.Row.prototype.load = function() { /* put data to expanded form */
	this.dom.name.value = this.getTitle();
	var def = this.data.def;
	if (def === null) { def = "NULL"; }
	
	this.dom.def.value = def;
	this.dom.size.value = this.data.size;
	this.dom.nll.checked = this.data.nll;
	this.dom.ai.checked = this.data.ai;
}

jxDiaTool.Row.prototype.redraw = function() {
	var color = this.getColor();
	this.dom.container.style.backgroundColor = color;
	OZ.DOM.removeClass(this.dom.container,"primary");
	OZ.DOM.removeClass(this.dom.container,"key");
	if (this.isPrimary()) { OZ.DOM.addClass(this.dom.container,"primary"); }
	if (this.isKey()) { OZ.DOM.addClass(this.dom.container,"key"); }
	this.dom.selected.style.display = (this.selected ? "" : "none");
	this.parent.redraw();
//	this.parent.parent.rowManager.redraw();
}

jxDiaTool.Row.prototype.addRelation = function(r) {
	this.relations.push(r);
}

jxDiaTool.Row.prototype.removeRelation = function(r) {
	var idx = this.relations.indexOf(r);
	if (idx == -1) { return; }
	this.relations.splice(idx,1);
}

jxDiaTool.Row.prototype.addKey = function(k) {
	this.keys.push(k);
	this.redraw();
}

jxDiaTool.Row.prototype.removeKey = function(k) {
	var idx = this.keys.indexOf(k);
	if (idx == -1) { return; }
	this.keys.splice(idx,1);
	this.redraw();
}

jxDiaTool.Row.prototype.getDataType = function() {
	var type = this.data.type;
	var elm = DATATYPES.getElementsByTagName("type")[type];
	return elm;
}

jxDiaTool.Row.prototype.getColor = function() {
	var elm = this.getDataType();
	var g = this.getDataType().parentNode;
	return elm.getAttribute("color") || g.getAttribute("color") || "#fff";
}

jxDiaTool.Row.prototype.buildTypeSelect = function(id) { /* build selectbox with avail datatypes */
	var s = OZ.DOM.elm("select");
	var gs = DATATYPES.getElementsByTagName("group");
	for (var i=0;i<gs.length;i++) {
		var g = gs[i];
		var og = OZ.DOM.elm("optgroup");
		og.style.backgroundColor = g.getAttribute("color") || "#fff";
		og.label = g.getAttribute("label");
		s.appendChild(og);
		var ts = g.getElementsByTagName("type");
		for (var j=0;j<ts.length;j++) {
			var t = ts[j];
			var o = OZ.DOM.elm("option");
			if (t.getAttribute("color")) { o.style.backgroundColor = t.getAttribute("color"); }
			if (t.getAttribute("note")) { o.title = t.getAttribute("note"); }
			o.innerHTML = t.getAttribute("label");
			og.appendChild(o);
		}
	}
	s.selectedIndex = id;
	return s;
}

jxDiaTool.Row.prototype.destroy = function() {
	jxDiaTool.Visual.prototype.destroy.apply(this);
	while (this.relations.length) {
		this.parent.parent.removeRelation(this.relations[0]);
	}
	for (var i=0;i<this.keys.length;i++){ 
		this.keys[i].removeRow(this);
	}
}

jxDiaTool.Row.prototype.toXML = function() {
	var xml = "";
	
	var t = this.getTitle().replace(/"/g,"&quot;"); // "
	var nn = (this.data.nll ? "1" : "0");
	var ai = (this.data.ai ? "1" : "0");
	xml += '<row name="'+t+'" null="'+nn+'" autoincrement="'+ai+'">\n';

	var elm = this.getDataType();
	var t = elm.getAttribute("sql");
	if (elm.getAttribute("length") == "1" && this.data.size) { t += "("+this.data.size+")"; }
	xml += "<datatype>"+t+"</datatype>\n";
	
	if (this.data.def || this.data.def === null) {
		var q = elm.getAttribute("quote");
		var d = this.data.def;
		if (d === null) { 
			d = "NULL"; 
		} else if (d != "CURRENT_TIMESTAMP") { 
			d = q+d+q; 
		}
		xml += "<default>"+d+"</default>";
	}

	for (var i=0;i<this.relations.length;i++) {
		var r = this.relations[i];
		if (r.row2 != this) { continue; }
		xml += '<relation table="'+r.row1.parent.getTitle()+'" row="'+r.row1.getTitle()+'" />\n';
	}
	
	if (this.data.comment) { 
		var escaped = this.data.comment.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;");
		xml += "<comment>"+escaped+"</comment>\n"; 
	}
	
	xml += "</row>\n";
	return xml;
}

jxDiaTool.Row.prototype.fromXML = function(node) {
	var name = node.getAttribute("name");
	this.setTitle(name);
	
	var obj = { type:0, size:"" };
	obj.nll = (node.getAttribute("null") == "1");
	obj.ai = (node.getAttribute("autoincrement") == "1");
	
	var cs = node.getElementsByTagName("comment");
	if (cs.length && cs[0].firstChild) { obj.comment = cs[0].firstChild.nodeValue; }
	
	var d = node.getElementsByTagName("datatype");
	if (d.length && d[0].firstChild) { 
		var s = d[0].firstChild.nodeValue;
		var r = s.match(/^([^\(]+)(\((.*)\))?.*$/);
		var type = r[1];
		if (r[3]) { obj.size = r[3]; }
		var types = window.DATATYPES.getElementsByTagName("type");
		for (var i=0;i<types.length;i++) {
			var sql = types[i].getAttribute("sql");
			var re = types[i].getAttribute("re");
			if (sql == type || (re && new RegExp(re).exec(type)) ) { obj.type = i; }
		}
	}
	
	var elm = DATATYPES.getElementsByTagName("type")[obj.type];
	var d = node.getElementsByTagName("default");
	if (d.length && d[0].firstChild) { 
		var def = d[0].firstChild.nodeValue;
		obj.def = def;
		var q = elm.getAttribute("quote");
		if (q) {
			var re = new RegExp("^"+q+"(.*)"+q+"$");
			var r = def.match(re);
			if (r) { obj.def = r[1]; }
		}
	}

	this.update(obj);
}

jxDiaTool.Row.prototype.isPrimary = function() {
	for (var i=0;i<this.keys.length;i++) {
		var k = this.keys[i];
		if (k.getType() == "PRIMARY") { return true; }
	}
	return false;
}

jxDiaTool.Row.prototype.isUnique = function() {
	for (var i=0;i<this.keys.length;i++) {
		var k = this.keys[i];
		var t = k.getType();
		if (t == "PRIMARY" || t == "UNIQUE") { return true; }
	}
	return false;
}

jxDiaTool.Row.prototype.isKey = function() {
	return this.keys.length > 0;
}

jxDiaTool.Row.prototype.enter = function(e) {
	if (e.keyCode == 13) { 
		this.collapse();
	}
}

/* --------------------------- relation (connector) ----------- */

jxDiaTool.Relation = OZ.Class().extend(jxDiaTool.Visual);
jxDiaTool.Relation._counter = 0;
jxDiaTool.Relation.prototype.init = function(parent, row1, row2) {
	this.constructor._counter++;
	this.parent = parent;
	this.row1 = row1;
	this.row2 = row2;
	this.hidden = false;
	jxDiaTool.Visual.prototype.init.apply(this);
	
	this.row1.addRelation(this);
	this.row2.addRelation(this);
	
	this.dom = [];
	if (CONFIG.RELATION_COLORS) {
		var colorIndex = this.constructor._counter - 1;
		var color = CONFIG.RELATION_COLORS[colorIndex % CONFIG.RELATION_COLORS.length];
	} else {
		var color = "#000";
	}
	
	if (this.parent.vector == "svg") {
		var path = document.createElementNS(this.parent.svgNS, "path");
		path.setAttribute("stroke", color);
		path.setAttribute("stroke-width", CONFIG.RELATION_THICKNESS);
		path.setAttribute("fill", "none");
		this.parent.dom.svg.appendChild(path);
		this.dom.push(path);
	} else if (this.parent.vector == "vml") {
		var curve = OZ.DOM.elm("v:curve");
		curve.strokeweight = CONFIG.RELATION_THICKNESS+"px";
		curve.from = "0 0";
		curve.to = "0 0";
		curve.control1 = "10 10";
		curve.control2 = "100 300";
		curve.strokecolor = color;
		curve.filled = false;
		this.parent.dom.content.appendChild(curve);
		this.dom.push(curve);
	} else {
		for (var i=0;i<3;i++) {
			var div = OZ.DOM.elm("div",{position:"absolute",className:"relation"});
			this.dom.push(div);
			if (i & 1) { /* middle */
				OZ.Style.set(div,{width:CONFIG.RELATION_THICKNESS+"px"});
			} else { /* first & last */
				OZ.Style.set(div,{height:CONFIG.RELATION_THICKNESS+"px"});
			}
			this.parent.dom.content.appendChild(div);
		}
	}
	
	this.redraw();
}

jxDiaTool.Relation.prototype.show = function() {
	this.hidden = false;
	for (var i=0;i<this.dom.length;i++) {
		this.dom[i].style.visibility = "";
	}
}

jxDiaTool.Relation.prototype.hide = function() {
	this.hidden = true;
	for (var i=0;i<this.dom.length;i++) {
		this.dom[i].style.visibility = "hidden";
	}
}

jxDiaTool.Relation.prototype.redrawNormal = function(p1, p2, half) {
	if (this.parent.vector == "svg") {
		var str = "M "+p1[0]+" "+p1[1]+" C "+(p1[0] + half)+" "+p1[1]+" ";
		str += (p2[0]-half)+" "+p2[1]+" "+p2[0]+" "+p2[1];
		this.dom[0].setAttribute("d",str);
	} else if (this.parent.vector == "vml") {
		this.dom[0].from = p1[0]+" "+p1[1];
		this.dom[0].to = p2[0]+" "+p2[1];
		this.dom[0].control1 = (p1[0]+half)+" "+p1[1];
		this.dom[0].control2 = (p2[0]-half)+" "+p2[1];
	} else {
		this.dom[0].style.left = p1[0]+"px";
		this.dom[0].style.top = p1[1]+"px";
		this.dom[0].style.width = half+"px";

		this.dom[1].style.left = (p1[0] + half) + "px";
		this.dom[1].style.top = Math.min(p1[1],p2[1]) + "px";
		this.dom[1].style.height = (Math.abs(p1[1] - p2[1])+CONFIG.RELATION_THICKNESS)+"px";

		this.dom[2].style.left = (p1[0]+half+1)+"px";
		this.dom[2].style.top = p2[1]+"px";
		this.dom[2].style.width = half+"px";
	}
}

jxDiaTool.Relation.prototype.redrawSide = function(p1, p2, x) {
	if (this.parent.vector == "svg") {
		var str = "M "+p1[0]+" "+p1[1]+" C "+x+" "+p1[1]+" ";
		str += x+" "+p2[1]+" "+p2[0]+" "+p2[1];
		this.dom[0].setAttribute("d",str);
	} else if (this.parent.vector == "vml") {
		this.dom[0].from = p1[0]+" "+p1[1];
		this.dom[0].to = p2[0]+" "+p2[1];
		this.dom[0].control1 = x+" "+p1[1];
		this.dom[0].control2 = x+" "+p2[1];
	} else {
		this.dom[0].style.left = Math.min(x,p1[0])+"px";
		this.dom[0].style.top = p1[1]+"px";
		this.dom[0].style.width = Math.abs(p1[0]-x)+"px";
		
		this.dom[1].style.left = x+"px";
		this.dom[1].style.top = Math.min(p1[1],p2[1]) + "px";
		this.dom[1].style.height = (Math.abs(p1[1] - p2[1])+CONFIG.RELATION_THICKNESS)+"px";
		
		this.dom[2].style.left = Math.min(x,p2[0])+"px";
		this.dom[2].style.top = p2[1]+"px";
		this.dom[2].style.width = Math.abs(p2[0]-x)+"px";
	}
}

jxDiaTool.Relation.prototype.redraw = function() { /* draw connector */
	if (this.hidden) { return; }
	var t1 = this.row1.parent.dom.container;
	var t2 = this.row2.parent.dom.container;

	var l1 = t1.offsetLeft;
	var l2 = t2.offsetLeft;
	var r1 = l1 + t1.offsetWidth;
	var r2 = l2 + t2.offsetWidth;
	var t1 = t1.offsetTop + this.row1.dom.container.offsetTop + Math.round(this.row1.dom.container.offsetHeight/2);
	var t2 = t2.offsetTop + this.row2.dom.container.offsetTop + Math.round(this.row2.dom.container.offsetHeight/2);
	
	if (this.row1.parent.selected) { t1++; l1++; r1--; }
	if (this.row2.parent.selected) { t2++; l2++; r2--; }
	
	var p1 = [0,0];
	var p2 = [0,0];
	
	if (r1 < l2 || r2 < l1) { /* between tables */
		if (Math.abs(r1 - l2) < Math.abs(r2 - l1)) {
			p1 = [r1,t1];
			p2 = [l2,t2];
		} else {
			p1 = [r2,t2];
			p2 = [l1,t1];
		}
		var half = Math.floor((p2[0] - p1[0])/2);
		this.redrawNormal(p1, p2, half);
	} else { /* next to tables */
		var x = 0;
		var l = 0;
		if (Math.abs(l1 - l2) < Math.abs(r1 - r2)) { /* left of tables */
			p1 = [l1,t1];
			p2 = [l2,t2];
			x = Math.min(l1,l2) - CONFIG.RELATION_SPACING;
		} else { /* right of tables */
			p1 = [r1,t1];
			p2 = [r2,t2];
			x = Math.max(r1,r2) + CONFIG.RELATION_SPACING;
		}
		this.redrawSide(p1, p2, x);
	} /* line next to tables */
}

jxDiaTool.Relation.prototype.destroy = function() {
	this.row1.removeRelation(this);
	this.row2.removeRelation(this);
	for (var i=0;i<this.dom.length;i++) {
		this.dom[i].parentNode.removeChild(this.dom[i]);
	}
}

/* --------------------- db table ------------ */

jxDiaTool.DBEntity = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.DBEntity.prototype.init = function(parent,type,name,x,y,z) {
	this.parent = parent;
	this.type = type;
	this.rows = [];
	this.keys = [];
	this.zIndex = 0;

	this.flag = false;
	this.selected = false;
	jxDiaTool.Visual.prototype.init.apply(this);
	this.data.comment = "";
	
	this.dom.container.className = "dbentity";
	this.setTitle(name);
	this.x = x || 0;
	this.y = y || 0;
	this.setZ(z);
	this.snap();
}

jxDiaTool.DBEntity.prototype._build = function() {
	this.dom.mini = OZ.DOM.elm("div",{className:"mini"});
	
	this.dom.title.className = "dbentity_title";

	OZ.DOM.append([this.dom.container,this.dom.title,this.dom.content]);
	this.parent.map.dom.content.appendChild(this.dom.mini);

	OZ.Event.add(this.dom.container,"click",this.bind(this.click));
	OZ.Event.add(this.dom.container,"dblclick",this.bind(this.dblclick));
	OZ.Event.add(this.dom.container,"mousedown",this.bind(this.down));
}

jxDiaTool.DBEntity.prototype.setTitle = function(t) {
	var old = this.getTitle();
	for (var i=0;i<this.rows.length;i++) {
		var row = this.rows[i];
		for (var j=0;j<row.relations.length;j++) {
			var r = row.relations[j];
			if (r.row1 != row) { continue; }
			var tt = row.getTitle().replace(new RegExp(old,"g"),t);
			if (tt != row.getTitle()) { row.setTitle(tt); }
		}
	}
	jxDiaTool.Visual.prototype.setTitle.apply(this, [t]);
}

jxDiaTool.DBEntity.prototype.getRelations = function() {
	var arr = [];
	for (var i=0;i<this.rows.length;i++) {
		var row = this.rows[i];
		for (var j=0;j<row.relations.length;j++) {
			var r = row.relations[j];
			if (arr.indexOf(r) == -1) { arr.push(r); }
		}
	}
	return arr;
}

jxDiaTool.DBEntity.prototype.showRelations = function() {
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].show(); }
}

jxDiaTool.DBEntity.prototype.hideRelations = function() {
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].hide(); }
}

jxDiaTool.DBEntity.prototype.click = function(e) {
	OZ.Event.stop(e);
	this.dispatch("tableclick",this);
//	this.parent.rowManager.select(false);
}

jxDiaTool.DBEntity.prototype.dblclick = function() {
	this.parent.entityManager.edit();
}

jxDiaTool.DBEntity.prototype.select = function() { 
	if (this.selected) { return; }
	this.selected = true;
	OZ.DOM.addClass(this.dom.container,"dbentity_selected");
	OZ.DOM.addClass(this.dom.mini,"mini_selected");
	this.redraw();
}

jxDiaTool.DBEntity.prototype.deselect = function() { 
	if (!this.selected) { return; }
	this.selected = false;
	OZ.DOM.removeClass(this.dom.container,"dbentity_selected");
	OZ.DOM.removeClass(this.dom.mini,"mini_selected");
	this.redraw();
}

jxDiaTool.DBEntity.prototype.addRow = function(title, data) {
	var r = new jxDiaTool.Row(this, title, data);
	this.rows.push(r);
	this.dom.content.appendChild(r.dom.container);
	this.redraw();
	return r;
}

jxDiaTool.DBEntity.prototype.removeRow = function(r) {
	var idx = this.rows.indexOf(r);
	if (idx == -1) { return; } 
	r.destroy();
	this.rows.splice(idx,1);
	this.redraw();
}

jxDiaTool.DBEntity.prototype.addKey = function(name) {
	var k = new jxDiaTool.Key(this, name);
	this.keys.push(k);
	return k;
}

jxDiaTool.DBEntity.prototype.removeKey = function(i) {
	var idx = this.keys.indexOf(k);
	if (idx == -1) { return; }
	k.destroy();
	this.keys.splice(idx,1);
}

jxDiaTool.DBEntity.prototype.redraw = function() {
	var x = this.x;
	var y = this.y;
	if (this.selected) { x--; y--; }
	this.dom.container.style.left = x+"px";
	this.dom.container.style.top = y+"px";
	
	var ratioX = this.parent.map.width / this.parent.width;
	var ratioY = this.parent.map.height / this.parent.height;
	
	var w = this.dom.container.offsetWidth * ratioX;
	var h = this.dom.container.offsetHeight * ratioY;
	var x = this.x * ratioX;
	var y = this.y * ratioY;
	
	this.dom.mini.style.width = Math.round(w)+"px";
	this.dom.mini.style.height = Math.round(h)+"px";
	this.dom.mini.style.left = Math.round(x)+"px";
	this.dom.mini.style.top = Math.round(y)+"px";

	this.width = this.dom.container.offsetWidth;
	this.height = this.dom.container.offsetHeight;
	
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].redraw(); }
   this.dom.content.innerHTML="<img border=1 src='entity/"+this.type+".gif'>";
}

jxDiaTool.DBEntity.prototype.moveBy = function(dx, dy) {
	this.x += dx;
	this.y += dy;
	
	this.snap();
	this.redraw();
}

jxDiaTool.DBEntity.prototype.moveTo = function(x, y) {
	this.x = x;
	this.y = y;

	this.snap();
	this.redraw();
}

jxDiaTool.DBEntity.prototype.snap = function() {
	var snap = parseInt(jxDiaTool.MainApp.getOption("snap"));
   snap=10;
	if (snap) {
		this.x = Math.round(this.x / snap) * snap;
		this.y = Math.round(this.y / snap) * snap;
	}
}

jxDiaTool.DBEntity.prototype.down = function(e) { /* mousedown - start drag */
	OZ.Event.stop(e);
	OZ.Event.prevent(e);
	/* a non-shift click within a selection preserves the selection */
	if (e.shiftKey || ! this.selected) {
		this.parent.entityManager.select(this, e.shiftKey);
	}

	var t = jxDiaTool.DBEntity;
	t.active = this.parent.entityManager.selection;
	var n = t.active.length;
	t.x = new Array(n);
	t.y = new Array(n);
	for (var i=0;i<n;i++) {
		/* position relative to mouse cursor */ 
		t.x[i] = t.active[i].x - e.clientX;
		t.y[i] = t.active[i].y - e.clientY;
	}
	
	if (this.parent.getOption("hide")) { this.hideRelations(); }
	
	this.documentMove = OZ.Event.add(document, "mousemove", this.bind(this.move));
	this.documentUp = OZ.Event.add(document, "mouseup", this.bind(this.up));
}

jxDiaTool.DBEntity.prototype.toXML = function() {
	var t = this.getTitle().replace(/"/g,"&quot;"); //"
	var xml = "";
	xml += '<table x="'+this.x+'" y="'+this.y+'" name="'+t+'">\n';
	for (var i=0;i<this.rows.length;i++) {
		xml += this.rows[i].toXML();
	}
	for (var i=0;i<this.keys.length;i++) {
		xml += this.keys[i].toXML();
	}
	var c = this.getComment();
	if (c) { 
		c = c.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;");
		xml += "<comment>"+c+"</comment>\n"; 
	}
	xml += "</table>\n";
	return xml;
}

jxDiaTool.DBEntity.prototype.fromXML = function(node) {
	var name = node.getAttribute("name");
	this.setTitle(name);
	var x = parseInt(node.getAttribute("x")) || 0;
	var y = parseInt(node.getAttribute("y")) || 0;
	this.moveTo(x, y);
	var rows = node.getElementsByTagName("row");
	for (var i=0;i<rows.length;i++) {
		var row = rows[i];
		var r = this.addRow("");
		r.fromXML(row);
	}
	var keys = node.getElementsByTagName("key");
	for (var i=0;i<keys.length;i++) {
		var key = keys[i];
		var k = this.addKey();
		k.fromXML(key);
	}
	for (var i=0;i<node.childNodes.length;i++) {
		var ch = node.childNodes[i];
		if (ch.tagName && ch.tagName.toLowerCase() == "comment" && ch.firstChild) {
			this.setComment(ch.firstChild.nodeValue);
		}
	}
}

jxDiaTool.DBEntity.prototype.getZ = function() {
	return this.zIndex;
}

jxDiaTool.DBEntity.prototype.setZ = function(z) {
	this.zIndex = z;
	this.dom.container.style.zIndex = z;
}

jxDiaTool.DBEntity.prototype.findNamedRow = function(n) { /* return row with a given name */
	for (var i=0;i<this.rows.length;i++) {
		if (this.rows[i].getTitle() == n) { return this.rows[i]; }
	}
	return false;
}

jxDiaTool.DBEntity.prototype.addKey = function(type, name) {
	var i = new jxDiaTool.Key(this, type, name);
	this.keys.push(i);
	return i;
}

jxDiaTool.DBEntity.prototype.removeKey = function(i) {
	var idx = this.keys.indexOf(i);
	if (idx == -1) { return; }
	i.destroy();
	this.keys.splice(idx,1);
}

jxDiaTool.DBEntity.prototype.setComment = function(c) {
	this.data.comment = c;
}

jxDiaTool.DBEntity.prototype.getComment = function() {
	return this.data.comment;
}

jxDiaTool.DBEntity.prototype.move = function(e) { /* mousemove */
	var t = jxDiaTool.DBEntity;
	jxDiaTool.MainApp.removeSelection();
	for (var i=0;i<t.active.length;i++) {
		var x = t.x[i] + e.clientX;
		var y = t.y[i] + e.clientY;
		t.active[i].moveTo(x,y);
	}
}

jxDiaTool.DBEntity.prototype.up = function(e) {
	var t = jxDiaTool.DBEntity;
	var d = jxDiaTool.MainApp;
	if (d.getOption("hide")) { t.active.showRelations(); }
	t.active = false;
	OZ.Event.remove(this.documentMove);
	OZ.Event.remove(this.documentUp);
	this.parent.sync();
}

jxDiaTool.DBEntity.prototype.destroy = function() {
	jxDiaTool.Visual.prototype.destroy.apply(this);
	this.dom.mini.parentNode.removeChild(this.dom.mini);
	while (this.rows.length) {
		this.removeRow(this.rows[0]);
	}
}

/* --------------------- db table ------------ */

jxDiaTool.Table = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.Table.prototype.init = function(parent, name, x, y, z) {
	this.parent = parent;
	this.rows = [];
	this.keys = [];
	this.zIndex = 0;

	this.flag = false;
	this.selected = false;
	jxDiaTool.Visual.prototype.init.apply(this);
	this.data.comment = "";
	
	this.dom.container.className = "table";
	this.setTitle(name);
	this.x = x || 0;
	this.y = y || 0;
	this.setZ(z);
	this.snap();
}

jxDiaTool.Table.prototype._build = function() {
	this.dom.mini = OZ.DOM.elm("div",{className:"mini"});
	
	this.dom.title.className = "table_title";

	OZ.DOM.append([this.dom.container,this.dom.title,this.dom.content]);
	this.parent.map.dom.content.appendChild(this.dom.mini);

	OZ.Event.add(this.dom.container,"click",this.bind(this.click));
	OZ.Event.add(this.dom.container,"dblclick",this.bind(this.dblclick));
	OZ.Event.add(this.dom.container,"mousedown",this.bind(this.down));
}

jxDiaTool.Table.prototype.setTitle = function(t) {
	var old = this.getTitle();
	for (var i=0;i<this.rows.length;i++) {
		var row = this.rows[i];
		for (var j=0;j<row.relations.length;j++) {
			var r = row.relations[j];
			if (r.row1 != row) { continue; }
			var tt = row.getTitle().replace(new RegExp(old,"g"),t);
			if (tt != row.getTitle()) { row.setTitle(tt); }
		}
	}
	jxDiaTool.Visual.prototype.setTitle.apply(this, [t]);
}

jxDiaTool.Table.prototype.getRelations = function() {
	var arr = [];
	for (var i=0;i<this.rows.length;i++) {
		var row = this.rows[i];
		for (var j=0;j<row.relations.length;j++) {
			var r = row.relations[j];
			if (arr.indexOf(r) == -1) { arr.push(r); }
		}
	}
	return arr;
}

jxDiaTool.Table.prototype.showRelations = function() {
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].show(); }
}

jxDiaTool.Table.prototype.hideRelations = function() {
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].hide(); }
}

jxDiaTool.Table.prototype.click = function(e) {
	OZ.Event.stop(e);
	this.dispatch("tableclick",this);
//	this.parent.rowManager.select(false);
}

jxDiaTool.Table.prototype.dblclick = function() {
	this.parent.entityManager.edit();
}

jxDiaTool.Table.prototype.select = function() { 
	if (this.selected) { return; }
	this.selected = true;
	OZ.DOM.addClass(this.dom.container,"table_selected");
	OZ.DOM.addClass(this.dom.mini,"mini_selected");
	this.redraw();
}

jxDiaTool.Table.prototype.deselect = function() { 
	if (!this.selected) { return; }
	this.selected = false;
	OZ.DOM.removeClass(this.dom.container,"table_selected");
	OZ.DOM.removeClass(this.dom.mini,"mini_selected");
	this.redraw();
}

jxDiaTool.Table.prototype.addRow = function(title, data) {
	var r = new jxDiaTool.Row(this, title, data);
	this.rows.push(r);
	this.dom.content.appendChild(r.dom.container);
	this.redraw();
	return r;
}

jxDiaTool.Table.prototype.removeRow = function(r) {
	var idx = this.rows.indexOf(r);
	if (idx == -1) { return; } 
	r.destroy();
	this.rows.splice(idx,1);
	this.redraw();
}

jxDiaTool.Table.prototype.addKey = function(name) {
	var k = new jxDiaTool.Key(this, name);
	this.keys.push(k);
	return k;
}

jxDiaTool.Table.prototype.removeKey = function(i) {
	var idx = this.keys.indexOf(k);
	if (idx == -1) { return; }
	k.destroy();
	this.keys.splice(idx,1);
}

jxDiaTool.Table.prototype.redraw = function() {
	var x = this.x;
	var y = this.y;
	if (this.selected) { x--; y--; }
	this.dom.container.style.left = x+"px";
	this.dom.container.style.top = y+"px";
	
	var ratioX = this.parent.map.width / this.parent.width;
	var ratioY = this.parent.map.height / this.parent.height;
	
	var w = this.dom.container.offsetWidth * ratioX;
	var h = this.dom.container.offsetHeight * ratioY;
	var x = this.x * ratioX;
	var y = this.y * ratioY;
	
	this.dom.mini.style.width = Math.round(w)+"px";
	this.dom.mini.style.height = Math.round(h)+"px";
	this.dom.mini.style.left = Math.round(x)+"px";
	this.dom.mini.style.top = Math.round(y)+"px";

	this.width = this.dom.container.offsetWidth;
	this.height = this.dom.container.offsetHeight;
	
	var rs = this.getRelations();
	for (var i=0;i<rs.length;i++) { rs[i].redraw(); }
}

jxDiaTool.Table.prototype.moveBy = function(dx, dy) {
	this.x += dx;
	this.y += dy;
	
	this.snap();
	this.redraw();
}

jxDiaTool.Table.prototype.moveTo = function(x, y) {
	this.x = x;
	this.y = y;

	this.snap();
	this.redraw();
}

jxDiaTool.Table.prototype.snap = function() {
	var snap = parseInt(jxDiaTool.MainApp.getOption("snap"));
	if (snap) {
		this.x = Math.round(this.x / snap) * snap;
		this.y = Math.round(this.y / snap) * snap;
	}
}

jxDiaTool.Table.prototype.down = function(e) { /* mousedown - start drag */
	OZ.Event.stop(e);
	OZ.Event.prevent(e);
	/* a non-shift click within a selection preserves the selection */
	if (e.shiftKey || ! this.selected) {
		this.parent.entityManager.select(this, e.shiftKey);
	}

	var t = jxDiaTool.Table;
	t.active = this.parent.entityManager.selection;
	var n = t.active.length;
	t.x = new Array(n);
	t.y = new Array(n);
	for (var i=0;i<n;i++) {
		/* position relative to mouse cursor */ 
		t.x[i] = t.active[i].x - e.clientX;
		t.y[i] = t.active[i].y - e.clientY;
	}
	
	if (this.parent.getOption("hide")) { this.hideRelations(); }
	
	this.documentMove = OZ.Event.add(document, "mousemove", this.bind(this.move));
	this.documentUp = OZ.Event.add(document, "mouseup", this.bind(this.up));
}

jxDiaTool.Table.prototype.toXML = function() {
	var t = this.getTitle().replace(/"/g,"&quot;"); //"
	var xml = "";
	xml += '<table x="'+this.x+'" y="'+this.y+'" name="'+t+'">\n';
	for (var i=0;i<this.rows.length;i++) {
		xml += this.rows[i].toXML();
	}
	for (var i=0;i<this.keys.length;i++) {
		xml += this.keys[i].toXML();
	}
	var c = this.getComment();
	if (c) { 
		c = c.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;");
		xml += "<comment>"+c+"</comment>\n"; 
	}
	xml += "</table>\n";
	return xml;
}

jxDiaTool.Table.prototype.fromXML = function(node) {
	var name = node.getAttribute("name");
	this.setTitle(name);
	var x = parseInt(node.getAttribute("x")) || 0;
	var y = parseInt(node.getAttribute("y")) || 0;
	this.moveTo(x, y);
	var rows = node.getElementsByTagName("row");
	for (var i=0;i<rows.length;i++) {
		var row = rows[i];
		var r = this.addRow("");
		r.fromXML(row);
	}
	var keys = node.getElementsByTagName("key");
	for (var i=0;i<keys.length;i++) {
		var key = keys[i];
		var k = this.addKey();
		k.fromXML(key);
	}
	for (var i=0;i<node.childNodes.length;i++) {
		var ch = node.childNodes[i];
		if (ch.tagName && ch.tagName.toLowerCase() == "comment" && ch.firstChild) {
			this.setComment(ch.firstChild.nodeValue);
		}
	}
}

jxDiaTool.Table.prototype.getZ = function() {
	return this.zIndex;
}

jxDiaTool.Table.prototype.setZ = function(z) {
	this.zIndex = z;
	this.dom.container.style.zIndex = z;
}

jxDiaTool.Table.prototype.findNamedRow = function(n) { /* return row with a given name */
	for (var i=0;i<this.rows.length;i++) {
		if (this.rows[i].getTitle() == n) { return this.rows[i]; }
	}
	return false;
}

jxDiaTool.Table.prototype.addKey = function(type, name) {
	var i = new jxDiaTool.Key(this, type, name);
	this.keys.push(i);
	return i;
}

jxDiaTool.Table.prototype.removeKey = function(i) {
	var idx = this.keys.indexOf(i);
	if (idx == -1) { return; }
	i.destroy();
	this.keys.splice(idx,1);
}

jxDiaTool.Table.prototype.setComment = function(c) {
	this.data.comment = c;
}

jxDiaTool.Table.prototype.getComment = function() {
	return this.data.comment;
}

jxDiaTool.Table.prototype.move = function(e) { /* mousemove */
	var t = jxDiaTool.Table;
	jxDiaTool.MainApp.removeSelection();
	for (var i=0;i<t.active.length;i++) {
		var x = t.x[i] + e.clientX;
		var y = t.y[i] + e.clientY;
		t.active[i].moveTo(x,y);
	}
}

jxDiaTool.Table.prototype.up = function(e) {
	var t = jxDiaTool.Table;
	var d = jxDiaTool.MainApp;
	if (d.getOption("hide")) { t.active.showRelations(); }
	t.active = false;
	OZ.Event.remove(this.documentMove);
	OZ.Event.remove(this.documentUp);
	this.parent.sync();
}

jxDiaTool.Table.prototype.destroy = function() {
	jxDiaTool.Visual.prototype.destroy.apply(this);
	this.dom.mini.parentNode.removeChild(this.dom.mini);
	while (this.rows.length) {
		this.removeRow(this.rows[0]);
	}
}

/* --------------------- db index ------------ */

jxDiaTool.Key = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.Key.prototype.init = function(parent, type, name) {
	this.parent = parent;
	this.rows = [];
	this.type = type || "INDEX";
	this.name = name || "";
	jxDiaTool.Visual.prototype.init.apply(this);
}

jxDiaTool.Key.prototype.setName = function(n) {
	this.name = n;
}

jxDiaTool.Key.prototype.getName = function() {
	return this.name;
}

jxDiaTool.Key.prototype.setType = function(t) {
	if (!t) { return; }
	this.type = t;
	for (var i=0;i<this.rows.length;i++) { this.rows[i].redraw(); }
}

jxDiaTool.Key.prototype.getType = function() {
	return this.type;
}

jxDiaTool.Key.prototype.addRow = function(r) {
	if (r.parent != this.parent) { return; }
	this.rows.push(r);
	r.addKey(this);
}

jxDiaTool.Key.prototype.removeRow = function(r) {
	var idx = this.rows.indexOf(r);
	if (idx == -1) { return; }
	r.removeKey(this);
	this.rows.splice(idx,1);
}

jxDiaTool.Key.prototype.destroy = function() {
	for (var i=0;i<this.rows.length;i++) {
		this.rows[i].removeKey(this);
	}
}

jxDiaTool.Key.prototype.getLabel = function() {
	return this.name || this.type;
}

jxDiaTool.Key.prototype.toXML = function() {
	var xml = "";
	xml += '<key type="'+this.getType()+'" name="'+this.getName()+'">\n';
	for (var i=0;i<this.rows.length;i++) {
		var r = this.rows[i];
		xml += '<part>'+r.getTitle()+'</part>\n';
	}
	xml += '</key>\n';
	return xml;
}

jxDiaTool.Key.prototype.fromXML = function(node) {
	this.setType(node.getAttribute("type"));
	this.setName(node.getAttribute("name"));
	var parts = node.getElementsByTagName("part");
	for (var i=0;i<parts.length;i++) {
		var name = parts[i].firstChild.nodeValue;
		var row = this.parent.findNamedRow(name);
		this.addRow(row);
	}
}

/* --------------------- rubberband -------------------- */

jxDiaTool.Rubberband = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.Rubberband.prototype.init = function(parent) {
	this.parent = parent;
	jxDiaTool.Visual.prototype.init.apply(this);
	this.dom.container = this.dom.content = OZ.$("rubberband");
	OZ.Event.add("area", "mousedown", this.bind(this.down));
}

jxDiaTool.Rubberband.prototype.down = function(e) {
	OZ.Event.prevent(e);
	var scroll = OZ.DOM.scroll();
	this.x = this.x0 = e.clientX + scroll[0];
	this.y = this.y0 = e.clientY + scroll[1];
	this.width = 0;
	this.height = 0;
	this.redraw();
	this.documentMove = OZ.Event.add(document, "mousemove", this.bind(this.move));
	this.documentUp = OZ.Event.add(document, "mouseup", this.bind(this.up));
}

jxDiaTool.Rubberband.prototype.move = function(e) {
	var scroll = OZ.DOM.scroll();
	var x = e.clientX + scroll[0];
	var y = e.clientY + scroll[1];
	this.width = Math.abs(x-this.x0);
	this.height = Math.abs(y-this.y0);
	if (x<this.x0) { this.x = x; } else { this.x = this.x0; }
	if (y<this.y0) { this.y = y; } else { this.y = this.y0; }
	this.redraw();
	this.dom.container.style.visibility = "visible";	
}

jxDiaTool.Rubberband.prototype.up = function(e) {
	OZ.Event.prevent(e);
	this.dom.container.style.visibility = "hidden";
	OZ.Event.remove(this.documentMove);
	OZ.Event.remove(this.documentUp);
	this.parent.entityManager.selectRect(this.x, this.y, this.width, this.height);
}

jxDiaTool.Rubberband.prototype.redraw = function() {
	this.dom.container.style.left = this.x+"px";
	this.dom.container.style.top = this.y+"px";
	this.dom.container.style.width = this.width+"px";
	this.dom.container.style.height = this.height+"px";
}

/* --------------------- minimap ------------ */

jxDiaTool.Map = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.Map.prototype.init = function(parent) {
	this.parent = parent;
	jxDiaTool.Visual.prototype.init.apply(this);
	this.dom.container = this.dom.content = OZ.$("minimap");
	this.width = this.dom.container.offsetWidth - 2;
	this.height = this.dom.container.offsetHeight - 2;
	
	this.dom.port = OZ.DOM.elm("div",{className:"port", zIndex:1});
	this.dom.container.appendChild(this.dom.port);
	this.sync = this.bind(this.sync);
	
	this.flag = false;
	this.sync();
	
	OZ.Event.add(window, "resize", this.sync);
	OZ.Event.add(window, "scroll", this.sync);
	OZ.Event.add(this.dom.container, "mousedown", this.bind(this.down));
}

jxDiaTool.Map.prototype.down = function(e) { /* mousedown - move view and start drag */
	this.flag = true;
	this.dom.container.style.cursor = "move";
	var pos = OZ.DOM.pos(this.dom.container);

	this.x = Math.round(pos[0] + this.l + this.w/2);
	this.y = Math.round(pos[1] + this.t + this.h/2);
	this.move(e);

	this.documentMove = OZ.Event.add(document, "mousemove", this.bind(this.move));
	this.documentUp = OZ.Event.add(document, "mouseup", this.bind(this.up));
}

jxDiaTool.Map.prototype.move = function(e) { /* mousemove */
	if (!this.flag) { return; }
	OZ.Event.prevent(e);
	
	var dx = e.clientX - this.x;
	var dy = e.clientY - this.y;
	if (this.l + dx < 0) { dx = -this.l; }
	if (this.t + dy < 0) { dy = -this.t; }
	if (this.l + this.w + 4 + dx > this.width) { dx = this.width - 4 - this.l - this.w; }
	if (this.t + this.h + 4 + dy > this.height) { dy = this.height - 4 - this.t - this.h; }
	
	
	this.x += dx;
	this.y += dy;
	
	this.l += dx;
	this.t += dy;
	
	var coefX = this.width / this.parent.width;
	var coefY = this.height / this.parent.height;
	var left = this.l / coefX;
	var top = this.t / coefY;
	
	if (OZ.webkit) {
		document.body.scrollLeft = Math.round(left);
		document.body.scrollTop = Math.round(top);
	} else {
		document.documentElement.scrollLeft = Math.round(left);
		document.documentElement.scrollTop = Math.round(top);
	}
	
	this.redraw();
}

jxDiaTool.Map.prototype.up = function(e) { /* mouseup */
	this.flag = false;
	this.dom.container.style.cursor = "";
	OZ.Event.remove(this.documentMove);
	OZ.Event.remove(this.documentUp);
}

jxDiaTool.Map.prototype.sync = function() { /* when window changes, adjust map */
	var dims = OZ.DOM.win();
	var scroll = OZ.DOM.scroll();
	var scaleX = this.width / this.parent.width;
	var scaleY = this.height / this.parent.height;

	var w = dims[0] * scaleX - 4 - 0;
	var h = dims[1] * scaleY - 4 - 0;
	var x = scroll[0] * scaleX;
	var y = scroll[1] * scaleY;
	
	this.w = Math.round(w);
	this.h = Math.round(h);
	this.l = Math.round(x);
	this.t = Math.round(y);
	
	this.redraw();
}

jxDiaTool.Map.prototype.redraw = function() {
	this.dom.port.style.width = this.w+"px";
	this.dom.port.style.height = this.h+"px";
	this.dom.port.style.left = this.l+"px";
	this.dom.port.style.top = this.t+"px";
}

/* --------------------- io ------------ */

jxDiaTool.IO = OZ.Class();

jxDiaTool.IO.prototype.init = function(parent) {
	this.parent = parent;
	this._name = ""; /* last used keyword */
	this.dom = {
		container:OZ.$("io")
	};

	var ids = ["saveload","clientsave","clientload","clientsql","serversave","serverload","serverlist","serverimport"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		this.dom[id] = elm;
		elm.value = _(id);
	}

	var ids = ["client","server","output","backendlabel"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		elm.innerHTML = _(id);
	}
	
	this.dom.ta = OZ.$("textarea");
	this.dom.backend = OZ.$("backend");
	
	this.dom.container.parentNode.removeChild(this.dom.container);
	this.dom.container.style.visibility = "";
	
	this.saveresponse = this.bind(this.saveresponse);
	this.loadresponse = this.bind(this.loadresponse);
	this.listresponse = this.bind(this.listresponse);
	this.importresponse = this.bind(this.importresponse);
	
	OZ.Event.add(this.dom.saveload, "click", this.bind(this.click));
	OZ.Event.add(this.dom.clientsave, "click", this.bind(this.clientsave));
	OZ.Event.add(this.dom.clientload, "click", this.bind(this.clientload));
	OZ.Event.add(this.dom.clientsql, "click", this.bind(this.clientsql));
	OZ.Event.add(this.dom.serversave, "click", this.bind(this.serversave));
	OZ.Event.add(this.dom.serverload, "click", this.bind(this.serverload));
	OZ.Event.add(this.dom.serverlist, "click", this.bind(this.serverlist));
	OZ.Event.add(this.dom.serverimport, "click", this.bind(this.serverimport));
	this.build();
}

jxDiaTool.IO.prototype.build = function() {
	OZ.DOM.clear(this.dom.backend);

	var bs = CONFIG.AVAILABLE_BACKENDS;
	var def = CONFIG.DEFAULT_BACKEND;
	for (var i=0;i<bs.length;i++) {
		var o = OZ.DOM.elm("option");
		o.value = bs[i];
		o.innerHTML = bs[i];
		this.dom.backend.appendChild(o);
		if (bs[i] == def) { this.dom.backend.selectedIndex = i; }
	}
}

jxDiaTool.IO.prototype.click = function() { /* open io dialog */
	this.build();
	this.dom.ta.value = "";
	this.dom.clientsql.value = _("clientsql") + " (" + window.DATATYPES.getAttribute("db") + ")";
	this.parent.window.open(_("saveload"),this.dom.container);
}

jxDiaTool.IO.prototype.fromXML = function(xmlDoc) {
	if (!xmlDoc || !xmlDoc.documentElement) {
		alert(_("xmlerror")+': Null document');
		return false; 
	}
	this.parent.fromXML(xmlDoc.documentElement);
	this.parent.window.close();
	return true;
}

jxDiaTool.IO.prototype.clientsave = function() {
	var xml = this.parent.toXML();
	this.dom.ta.value = xml;
}

jxDiaTool.IO.prototype.clientload = function() {
	var xml = this.dom.ta.value;
	if (!xml) {
		alert(_("empty"));
		return;
	}
	try {
		if (window.DOMParser) {
			var parser = new DOMParser();
			var xmlDoc = parser.parseFromString(xml, "text/xml");
		} else if (window.ActiveXObject) {
			var xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
			xmlDoc.loadXML(xml);
		} else {
			throw new Error("No XML parser available.");
		}
	} catch(e) { 
		alert(_("xmlerror")+': '+e.message);
		return;
	}
	this.fromXML(xmlDoc);
}

jxDiaTool.IO.prototype.clientsql = function() {
	var bp = this.parent.getOption("staticpath");
	var path = bp + "db/"+window.DATATYPES.getAttribute("db")+"/output.xsl";
	this.parent.window.showThrobber();
	OZ.Request(path, this.bind(this.finish), {xml:true});
}

jxDiaTool.IO.prototype.finish = function(xslDoc) {
	this.parent.window.hideThrobber();
	var xml = this.parent.toXML();
	var sql = "";
	try {
		if (window.XSLTProcessor && window.DOMParser) {
			var parser = new DOMParser();
			var xmlDoc = parser.parseFromString(xml, "text/xml");
			var xsl = new XSLTProcessor();
			xsl.importStylesheet(xslDoc);
			var result = xsl.transformToDocument(xmlDoc);
			sql = result.documentElement.textContent;
		} else if (window.ActiveXObject) {
			var xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
			xmlDoc.loadXML(xml);
			sql = xmlDoc.transformNode(xslDoc);
		} else {
			throw new Error("No XSLT processor available");
		}
	} catch(e) {
		alert(_("xmlerror")+': '+e.message);
		return;
	}
	this.dom.ta.value = sql;
}

jxDiaTool.IO.prototype.serversave = function(e) {
	var name = prompt(_("serversaveprompt"), this._name);
	if (!name) { return; }
	this._name = name;
	var xml = this.parent.toXML();
	var bp = this.parent.getOption("xhrpath");
	var url = bp + "backend/"+this.dom.backend.value+"/?action=save&keyword="+encodeURIComponent(name);
	var h = {"Content-type":"application/xml"};
	this.parent.window.showThrobber();
	this.parent.setTitle(name);
	OZ.Request(url, this.saveresponse, {xml:true, method:"post", data:xml, headers:h});
}

jxDiaTool.IO.prototype.serverload = function(e, keyword) {
	var name = keyword || prompt(_("serverloadprompt"), this._name);
	if (!name) { return; }
	this._name = name;
	var bp = this.parent.getOption("xhrpath");
	var url = bp + "backend/"+this.dom.backend.value+"/?action=load&keyword="+encodeURIComponent(name);
	this.parent.window.showThrobber();
	this.name = name;
	OZ.Request(url, this.loadresponse, {xml:true});
}

jxDiaTool.IO.prototype.serverlist = function(e) {
	var bp = this.parent.getOption("xhrpath");
	var url = bp + "backend/"+this.dom.backend.value+"/?action=list";
	this.parent.window.showThrobber();
	OZ.Request(url, this.listresponse);
}

jxDiaTool.IO.prototype.serverimport = function(e) {
	var name = prompt(_("serverimportprompt"), "");
	if (!name) { return; }
	var bp = this.parent.getOption("xhrpath");
	var url = bp + "backend/"+this.dom.backend.value+"/?action=import&database="+name;
	this.parent.window.showThrobber();
	OZ.Request(url, this.importresponse, {xml:true});
}

jxDiaTool.IO.prototype.check = function(code) {
	switch (code) {
		case 201:
		case 404:
		case 500:
		case 501:
		case 503:
			var lang = "http"+code;
			this.dom.ta.value = _("httpresponse")+": "+_(lang);
			return false;
		break;
		default: return true;
	}
}

jxDiaTool.IO.prototype.saveresponse = function(data, code) {
	this.parent.window.hideThrobber();
	this.check(code);
}

jxDiaTool.IO.prototype.loadresponse = function(data, code) {
	this.parent.window.hideThrobber();
	if (!this.check(code)) { return; }
	this.fromXML(data);
	this.parent.setTitle(this.name);
}

jxDiaTool.IO.prototype.listresponse = function(data, code) {
	this.parent.window.hideThrobber();
	if (!this.check(code)) { return; }
	this.dom.ta.value = data;
}

jxDiaTool.IO.prototype.importresponse = function(data, code) {
	this.parent.window.hideThrobber();
	if (!this.check(code)) { return; }
	if (this.fromXML(data)) {
		this.parent.alignTables();
	}
}

/* --------------------- table manager ------------ */

jxDiaTool.EntityManager = OZ.Class();

jxDiaTool.EntityManager.prototype.init = function(parent) {
	this.parent = parent;
	this.dom = {
		container:OZ.$("editdbentity"),
		name:OZ.$("tablename"),
		comment:OZ.$("tablecomment")
	};
	this.selection = [];
	this.adding = false;
	
	var ids = ["addtable","adddbentity","removetable","aligntables","cleartables","addrow","edittable","tablekeys"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		this.dom[id] = elm;
		elm.value = _(id);
	}

	var ids = ["tablenamelabel","tablecommentlabel"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		elm.innerHTML = _(id);
	}
	
	
	this.select(false);
	
	this.save = this.bind(this.save);
	
	OZ.Event.add("area", "click", this.bind(this.click));
	OZ.Event.add(this.dom.addtable, "click", this.bind(this.preAdd));
	OZ.Event.add(this.dom.adddbentity, "click", this.bind(this.preAddEntity));
	OZ.Event.add(this.dom.removetable, "click", this.bind(this.remove));
	OZ.Event.add(this.dom.cleartables, "click", this.bind(this.clear));
	OZ.Event.add(this.dom.addrow, "click", this.bind(this.addRow));
	OZ.Event.add(this.dom.aligntables, "click", this.parent.bind(this.parent.alignTables));
	OZ.Event.add(this.dom.edittable, "click", this.bind(this.edit));
	OZ.Event.add(this.dom.tablekeys, "click", this.bind(this.keys));
	OZ.Event.add(document, "keydown", this.bind(this.press));

	this.dom.container.parentNode.removeChild(this.dom.container);
}

jxDiaTool.EntityManager.prototype.addRow = function(e) {
	var newrow = this.selection[0].addRow(_("newrow"));
//	this.parent.rowManager.select(newrow);
	newrow.expand();
}

jxDiaTool.EntityManager.prototype.select = function(table, multi) { /* activate table */
	if (table) {
		if (multi) {
			var i = this.selection.indexOf(table);
			if (i < 0) {
				this.selection.push(table);
			} else {
				this.selection.splice(i, 1);
			}
		} else {
			if (this.selection[0] === table) { return; }
			this.selection = [table];
		}
	} else {
		this.selection = [];
	}
	this.processSelection();
}

jxDiaTool.EntityManager.prototype.processSelection = function() {
	var dbentities = this.parent.dbentities;
	for (var i=0;i<dbentities.length;i++) {
		dbentities[i].deselect();
	}
	if (this.selection.length == 1) {
		this.dom.addrow.disabled = false;
		this.dom.edittable.disabled = false;
		this.dom.tablekeys.disabled = false;
		this.dom.removetable.value = _("removetable");
	} else {
		this.dom.addrow.disabled = true;
		this.dom.edittable.disabled = true;
		this.dom.tablekeys.disabled = true;
	}
	if (this.selection.length) {
		this.dom.removetable.disabled = false;
		if (this.selection.length > 1) { this.dom.removetable.value = _("removetables"); }
	} else {
		this.dom.removetable.disabled = true;
		this.dom.removetable.value = _("removetable");
	}
	for (var i=0;i<this.selection.length;i++) {
		var t = this.selection[i];
		t.parent.raise(t);
		t.select();
	}
}

jxDiaTool.EntityManager.prototype.selectRect = function(x,y,width,height) { /* select all tables intersecting a rectangle */
	this.selection = [];
	var tables = this.parent.tables;
	var x1 = x+width;
	var y1 = y+height;
	for (var i=0;i<tables.length;i++) {
		var t = tables[i];
		var tx = t.x;
		var tx1 = t.x+t.width;
		var ty = t.y;
		var ty1 = t.y+t.height;
		if (((tx>=x && tx<x1) || (tx1>=x && tx1<x1) || (tx<x && tx1>x1)) &&
		    ((ty>=y && ty<y1) || (ty1>=y && ty1<y1) || (ty<y && ty1>y1)))
			{ this.selection.push(t); }
	}
	this.processSelection();
}

jxDiaTool.EntityManager.prototype.click = function(e) { /* finish adding new table */
	var newtable = false;
	if (this.addingEntity!=undefined) {
      var adding=this.addingEntity;
		this.addingEntity = undefined;
		OZ.DOM.removeClass("area","adding");
      if (adding=="dbentity"){
			this.dom.addtable.value = this.oldvalue;
			var scroll = OZ.DOM.scroll();
			var x = e.clientX + scroll[0];
			var y = e.clientY + scroll[1];
	//		newtable = this.parent.addDBEntity("nativeserver","Horst",x,y);


         this.parent.finddbentity.click();
      }
	   this.select(newtable);
	}
	if (this.adding) {
		this.adding = false;
		OZ.DOM.removeClass("area","adding");
		this.dom.addtable.value = this.oldvalue;
		var scroll = OZ.DOM.scroll();
		var x = e.clientX + scroll[0];
		var y = e.clientY + scroll[1];
		newtable = this.parent.addTable(_("newtable"),x,y);
		var r = newtable.addRow("id",{ai:true});
		var k = newtable.addKey("PRIMARY","");
		k.addRow(r);
	   this.select(newtable);
	   if (this.selection.length == 1) { this.edit(e); }
	}
   //this.parent.rowManager.select(false);
}

jxDiaTool.EntityManager.prototype.preAdd = function(e) { /* click add new table */
	if (this.adding) {
		this.adding = false;
		OZ.DOM.removeClass("area","adding");
		this.dom.addtable.value = this.oldvalue;
	} else {
		this.adding = true;
		OZ.DOM.addClass("area","adding");
		this.oldvalue = this.dom.addtable.value;
		this.dom.addtable.value = "["+_("addpending")+"]";
	}
}

jxDiaTool.EntityManager.prototype.preAddEntity = function(e) { /* click add new table */
	if (this.addingEntity) {
		this.addingEntity = undefined;
		OZ.DOM.removeClass("area","adding");
		this.dom.adddbentity.value = this.oldvalue;
	} else {
		this.addingEntity = "dbentity";
		OZ.DOM.addClass("area","adding");
		this.oldvalue = this.dom.adddbentity.value;
		this.dom.adddbentity.value = "["+_("adddbentitypending")+"]";
	}
}

jxDiaTool.EntityManager.prototype.clear = function(e) { /* remove all tables */
	if (!this.parent.tables.length) { return; }
	var result = confirm(_("confirmall")+" ?");
	if (!result) { return; }
	this.parent.clearTables();
}

jxDiaTool.EntityManager.prototype.remove = function(e) {
	var titles = this.selection.slice(0);
	for (var i=0;i<titles.length;i++) { titles[i] = "'"+titles[i].getTitle()+"'"; }
	var result = confirm(_("confirmtable")+" "+titles.join(", ")+"?");
	if (!result) { return; }
	var sel = this.selection.slice(0);
	for (var i=0;i<sel.length;i++) { this.parent.removeTable(sel[i]); }
}

jxDiaTool.EntityManager.prototype.edit = function(e) {
	this.parent.window.open(_("edittable"), this.dom.container, this.save);
	
	var title = this.selection[0].getTitle();
	this.dom.name.value = title;
	try { /* throws in ie6 */
		this.dom.comment.value = this.selection[0].getComment();
	} catch(e) {}

	/* pre-select table name */
//	this.dom.name.focus();
	if (OZ.ie) {
		try { /* throws in ie6 */
			this.dom.name.select();
		} catch(e) {}
	} else {
		this.dom.name.setSelectionRange(0, title.length);
	} 
}

jxDiaTool.EntityManager.prototype.keys = function(e) { /* open keys dialog */
	this.parent.keyManager.open(this.selection[0]);
}

jxDiaTool.EntityManager.prototype.save = function() {
	this.selection[0].setTitle(this.dom.name.value);
	this.selection[0].setComment(this.dom.comment.value);
}

jxDiaTool.EntityManager.prototype.press = function(e) {
	if (! this.selection.length) { return; }
	/* do not process keypresses if a row is selected */
//	if (this.parent.rowManager.selected) { return; }
	switch (e.keyCode) {
		case 46:
			this.remove();
			OZ.Event.prevent(e);
		break;
	}
}

/* --------------------- row manager ------------ */

jxDiaTool.RowManager = OZ.Class();

jxDiaTool.RowManager.prototype.init = function(parent) {
	this.parent = parent;
	this.dom = {};
	this.selected = null;
	this.creating = false;
	this.connecting = false;
	
	var ids = ["editrow","removerow","uprow","downrow","foreigncreate","foreignconnect","foreigndisconnect"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		this.dom[id] = elm;
		elm.value = _(id);
	}

	this.select(false);
	
	OZ.Event.add(this.dom.editrow, "click", this.bind(this.edit));
	OZ.Event.add(this.dom.uprow, "click", this.bind(this.up));
	OZ.Event.add(this.dom.downrow, "click", this.bind(this.down));
	OZ.Event.add(this.dom.removerow, "click", this.bind(this.remove));
	OZ.Event.add(this.dom.foreigncreate, "click", this.bind(this.foreigncreate));
	OZ.Event.add(this.dom.foreignconnect, "click", this.bind(this.foreignconnect));
	OZ.Event.add(this.dom.foreigndisconnect, "click", this.bind(this.foreigndisconnect));
	OZ.Event.add(false, "tableclick", this.bind(this.tableClick));
	OZ.Event.add(false, "rowclick", this.bind(this.rowClick));
	OZ.Event.add(document, "keydown", this.bind(this.press));
}

jxDiaTool.RowManager.prototype.select = function(row) { /* activate a row */
	if (this.selected === row) { return; }
	if (this.selected) { this.selected.deselect(); }

	this.selected = row;
	if (this.selected) { this.selected.select(); }
	this.redraw();
}

jxDiaTool.RowManager.prototype.tableClick = function(e) { /* create relation after clicking target table */
	if (!this.creating) { return; }
	
	var r1 = this.selected;
	var t2 = e.target;
	
	var p = this.parent.getOption("pattern");
	p = p.replace(/%T/g,r1.parent.getTitle());
	p = p.replace(/%t/g,t2.getTitle());
	p = p.replace(/%R/g,r1.getTitle());
	
	var r2 = t2.addRow(p, r1.data);
	r2.update({"type":jxDiaTool.MainApp.getFKTypeFor(r1.data.type)});
	r2.update({"ai":false});
	this.parent.addRelation(r1, r2);
}

jxDiaTool.RowManager.prototype.rowClick = function(e) { /* draw relation after clicking target row */
	if (!this.connecting) { return; }
	
	var r1 = this.selected;
	var r2 = e.target;
	
	if (r1 == r2) { return; }
	
	this.parent.addRelation(r1, r2);
}

jxDiaTool.RowManager.prototype.foreigncreate = function(e) { /* start creating fk */
	this.endConnect();
	if (this.creating) {
		this.endCreate();
	} else {
		this.creating = true;
		this.dom.foreigncreate.value = "["+_("foreignpending")+"]";
	}
}

jxDiaTool.RowManager.prototype.foreignconnect = function(e) { /* start drawing fk */
	this.endCreate();
	if (this.connecting) {
		this.endConnect();
	} else {
		this.connecting = true;
		this.dom.foreignconnect.value = "["+_("foreignconnectpending")+"]";
	}
}

jxDiaTool.RowManager.prototype.foreigndisconnect = function(e) { /* remove connector */
	var rels = this.selected.relations;
	for (var i=rels.length-1;i>=0;i--) {
		var r = rels[i];
		if (r.row2 == this.selected) { this.parent.removeRelation(r); }
	}
	this.redraw();
}

jxDiaTool.RowManager.prototype.endCreate = function() {
	this.creating = false;
	this.dom.foreigncreate.value = _("foreigncreate");
}

jxDiaTool.RowManager.prototype.endConnect = function() {
	this.connecting = false;
	this.dom.foreignconnect.value = _("foreignconnect");
}

jxDiaTool.RowManager.prototype.up = function(e) {
	this.selected.up();
	this.redraw();
}

jxDiaTool.RowManager.prototype.down = function(e) {
	this.selected.down();
	this.redraw();
}

jxDiaTool.RowManager.prototype.remove = function(e) {
	var result = confirm(_("confirmrow")+" '"+this.selected.getTitle()+"' ?");
	if (!result) { return; }
	var t = this.selected.parent;
	this.selected.parent.removeRow(this.selected);
	
	var next = false;
	if (t.rows) { next = t.rows[t.rows.length-1]; }
	this.select(next);
}

jxDiaTool.RowManager.prototype.redraw = function() {
	this.endCreate();
	this.endConnect();
	if (this.selected) {
		var table = this.selected.parent;
		var rows = table.rows;
		this.dom.uprow.disabled = (rows[0] == this.selected);
		this.dom.downrow.disabled = (rows[rows.length-1] == this.selected);
		this.dom.removerow.disabled = false;
		this.dom.editrow.disabled = false;
		this.dom.foreigncreate.disabled = !(this.selected.isUnique());
		this.dom.foreignconnect.disabled = !(this.selected.isUnique());
		
		this.dom.foreigndisconnect.disabled = true;
		var rels = this.selected.relations;
		for (var i=0;i<rels.length;i++) {
			var r = rels[i];
			if (r.row2 == this.selected) { this.dom.foreigndisconnect.disabled = false; }
		}
		
	} else {
		this.dom.uprow.disabled = true;
		this.dom.downrow.disabled = true;
		this.dom.removerow.disabled = true;
		this.dom.editrow.disabled = true;
		this.dom.foreigncreate.disabled = true;
		this.dom.foreignconnect.disabled = true;
		this.dom.foreigndisconnect.disabled = true;
	}
}

jxDiaTool.RowManager.prototype.press = function(e) {
	if (!this.selected) { return; }
	switch (e.keyCode) {
		case 38:
			this.up();
			OZ.Event.prevent(e);
		break;
		case 40:
			this.down();
			OZ.Event.prevent(e);
		break;
		case 46:
			this.remove();
			OZ.Event.prevent(e);
		break;
		case 13:
		case 27:
			this.selected.collapse();
		break;
	}
}

jxDiaTool.RowManager.prototype.edit = function(e) {
	this.selected.expand();
}

/* --------------------- FindDBEntity ------------ */

jxDiaTool.FindDBEntity = OZ.Class();

jxDiaTool.FindDBEntity.prototype.init = function(parent) {
	this.parent = parent;
	this._name = ""; /* last used keyword */
	this.dom = {
		container:OZ.$("finddbentity")
	};

//	var ids = ["saveload","clientsave","clientload","clientsql","serversave","serverload","serverlist","serverimport"];
//	for (var i=0;i<ids.length;i++) {
//		var id = ids[i];
//		var elm = OZ.$(id);
//		this.dom[id] = elm;
//		elm.value = _(id);
//	}

//	var ids = ["client","server","output","backendlabel"];
//	for (var i=0;i<ids.length;i++) {
//		var id = ids[i];
//		var elm = OZ.$(id);
//		elm.innerHTML = _(id);
//	}
//	
//	this.dom.ta = OZ.$("textarea");
//	this.dom.backend = OZ.$("backend");
//	
	this.dom.container.parentNode.removeChild(this.dom.container);
	this.dom.container.style.visibility = "";
//	
//	this.saveresponse = this.bind(this.saveresponse);
//	this.loadresponse = this.bind(this.loadresponse);
//	this.listresponse = this.bind(this.listresponse);
//	this.importresponse = this.bind(this.importresponse);
//	
//	OZ.Event.add(this.dom.saveload, "click", this.bind(this.click));
//	OZ.Event.add(this.dom.clientsave, "click", this.bind(this.clientsave));
//	OZ.Event.add(this.dom.clientload, "click", this.bind(this.clientload));
//	OZ.Event.add(this.dom.clientsql, "click", this.bind(this.clientsql));
//	OZ.Event.add(this.dom.serversave, "click", this.bind(this.serversave));
//	OZ.Event.add(this.dom.serverload, "click", this.bind(this.serverload));
//	OZ.Event.add(this.dom.serverlist, "click", this.bind(this.serverlist));
//	OZ.Event.add(this.dom.serverimport, "click", this.bind(this.serverimport));
	this.build();
}

jxDiaTool.FindDBEntity.prototype.build = function() {
//	OZ.DOM.clear(this.dom.backend);
//
//	var bs = CONFIG.AVAILABLE_BACKENDS;
//	var def = CONFIG.DEFAULT_BACKEND;
//	for (var i=0;i<bs.length;i++) {
//		var o = OZ.DOM.elm("option");
//		o.value = bs[i];
//		o.innerHTML = bs[i];
//		this.dom.backend.appendChild(o);
//		if (bs[i] == def) { this.dom.backend.selectedIndex = i; }
//	}
}

jxDiaTool.FindDBEntity.prototype.click = function() { /* open io dialog */
	this.build();
	this.parent.window.open(_("saveload"),this.dom.container);
}

jxDiaTool.FindDBEntity.prototype.check = function(code) {
//	switch (code) {
//		case 201:
//		case 404:
//		case 500:
//		case 501:
//		case 503:
//			var lang = "http"+code;
//			this.dom.ta.value = _("httpresponse")+": "+_(lang);
//			return false;
//		break;
//		default: return true;
//	}
}


/* ----------------- key manager ---------- */

jxDiaTool.KeyManager = OZ.Class();

jxDiaTool.KeyManager.prototype.init = function(parent) {
	this.parent = parent;
	this.dom = {
		container:OZ.$("keys")
	}
	this.build();
}

jxDiaTool.KeyManager.prototype.build = function() {
	this.dom.list = OZ.$("keyslist");
	this.dom.type = OZ.$("keytype");
	this.dom.name = OZ.$("keyname");
	this.dom.left = OZ.$("keyleft");
	this.dom.right = OZ.$("keyright");
	this.dom.fields = OZ.$("keyfields");
	this.dom.avail = OZ.$("keyavail");
	this.dom.listlabel = OZ.$("keyslistlabel");

	var ids = ["keyadd","keyremove"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		this.dom[id] = elm;
		elm.value = _(id);
	}

	var ids = ["keyedit","keytypelabel","keynamelabel","keyfieldslabel","keyavaillabel"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		elm.innerHTML = _(id);
	}
	
	var types = ["PRIMARY","INDEX","UNIQUE","FULLTEXT"];
	for (var i=0;i<types.length;i++) {
		var o = OZ.DOM.elm("option");
		o.innerHTML = types[i];
		o.value = types[i];
		this.dom.type.appendChild(o);
	}

	this.purge = this.bind(this.purge);

	OZ.Event.add(this.dom.list, "change", this.bind(this.listchange));
	OZ.Event.add(this.dom.type, "change", this.bind(this.typechange));
	OZ.Event.add(this.dom.name, "keyup", this.bind(this.namechange));
	OZ.Event.add(this.dom.keyadd, "click", this.bind(this.add));
	OZ.Event.add(this.dom.keyremove, "click", this.bind(this.remove));
	OZ.Event.add(this.dom.left, "click", this.bind(this.left));
	OZ.Event.add(this.dom.right, "click", this.bind(this.right));
	
	this.dom.container.parentNode.removeChild(this.dom.container);
}

jxDiaTool.KeyManager.prototype.listchange = function(e) {
	this.switchTo(this.dom.list.selectedIndex);
}

jxDiaTool.KeyManager.prototype.typechange = function(e) {
	this.key.setType(this.dom.type.value);
	this.redrawListItem();
}

jxDiaTool.KeyManager.prototype.namechange = function(e) {
	this.key.setName(this.dom.name.value);
	this.redrawListItem();
}

jxDiaTool.KeyManager.prototype.add = function(e) {
	var type = (this.table.keys.length ? "INDEX" : "PRIMARY");
	this.table.addKey(type);
	this.sync(this.table);
	this.switchTo(this.table.keys.length-1);
}

jxDiaTool.KeyManager.prototype.remove = function(e) {
	var index = this.dom.list.selectedIndex;
	if (index == -1) { return; }
	var r = this.table.keys[index];
	this.table.removeKey(r);
	this.sync(this.table);
}

jxDiaTool.KeyManager.prototype.purge = function() { /* remove empty keys */
	for (var i=this.table.keys.length-1;i>=0;i--) {
		var k = this.table.keys[i];
		if (!k.rows.length) { this.table.removeKey(k); }
	}
}

jxDiaTool.KeyManager.prototype.sync = function(table) { /* sync content with given table */
	this.table = table;
	this.dom.listlabel.innerHTML = _("keyslistlabel").replace(/%s/,table.getTitle());
	
	OZ.DOM.clear(this.dom.list);
	for (var i=0;i<table.keys.length;i++) {
		var k = table.keys[i];
		var o = OZ.DOM.elm("option");
		this.dom.list.appendChild(o);
		var str = (i+1)+": "+k.getLabel();
		o.innerHTML = str;
	}
	if (table.keys.length) { 
		this.switchTo(0); 
	} else {
		this.disable();
	}
}

jxDiaTool.KeyManager.prototype.redrawListItem = function() {
	var index = this.table.keys.indexOf(this.key);
	this.option.innerHTML = (index+1)+": "+this.key.getLabel();
}

jxDiaTool.KeyManager.prototype.switchTo = function(index) { /* show Nth key */
	this.enable();
	var k = this.table.keys[index];
	this.key = k;
	this.option = this.dom.list.getElementsByTagName("option")[index];
	
	this.dom.list.selectedIndex = index;
	this.dom.name.value = k.getName();
	
	var opts = this.dom.type.getElementsByTagName("option");
	for (var i=0;i<opts.length;i++) {
		if (opts[i].value == k.getType()) { this.dom.type.selectedIndex = i; }
	}

	OZ.DOM.clear(this.dom.fields);
	for (var i=0;i<k.rows.length;i++) {
		var o = OZ.DOM.elm("option");
		o.innerHTML = k.rows[i].getTitle();
		o.value = o.innerHTML;
		this.dom.fields.appendChild(o);
	}
	
	OZ.DOM.clear(this.dom.avail);
	for (var i=0;i<this.table.rows.length;i++) {
		var r = this.table.rows[i];
		if (k.rows.indexOf(r) != -1) { continue; }
		var o = OZ.DOM.elm("option");
		o.innerHTML = r.getTitle();
		o.value = o.innerHTML;
		this.dom.avail.appendChild(o);
	}
}

jxDiaTool.KeyManager.prototype.disable = function() {
	OZ.DOM.clear(this.dom.fields);
	OZ.DOM.clear(this.dom.avail);
	this.dom.keyremove.disabled = true;
	this.dom.left.disabled = true;
	this.dom.right.disabled = true;
	this.dom.list.disabled = true;
	this.dom.name.disabled = true;
	this.dom.type.disabled = true;
	this.dom.fields.disabled = true;
	this.dom.avail.disabled = true;
}

jxDiaTool.KeyManager.prototype.enable = function() {
	this.dom.keyremove.disabled = false;
	this.dom.left.disabled = false;
	this.dom.right.disabled = false;
	this.dom.list.disabled = false;
	this.dom.name.disabled = false;
	this.dom.type.disabled = false;
	this.dom.fields.disabled = false;
	this.dom.avail.disabled = false;
}

jxDiaTool.KeyManager.prototype.left = function(e) { /* add field to index */
	var opts = this.dom.avail.getElementsByTagName("option");
	for (var i=0;i<opts.length;i++) {
		var o = opts[i];
		if (o.selected) {
			var row = this.table.findNamedRow(o.value);
			this.key.addRow(row);
		}
	}
	this.switchTo(this.dom.list.selectedIndex);
}

jxDiaTool.KeyManager.prototype.right = function(e) { /* remove field from index */
	var opts = this.dom.fields.getElementsByTagName("option");
	for (var i=0;i<opts.length;i++) {
		var o = opts[i];
		if (o.selected) {
			var row = this.table.findNamedRow(o.value);
			this.key.removeRow(row);
		}
	}
	this.switchTo(this.dom.list.selectedIndex);
}

jxDiaTool.KeyManager.prototype.open = function(table) {
	this.sync(table);
	this.parent.window.open(_("tablekeys"),this.dom.container,this.purge);
}

/* --------------------- window ------------ */

jxDiaTool.Window = OZ.Class();

jxDiaTool.Window.prototype.init = function(parent) {
	this.parent = parent;
	this.dom = {
		container:OZ.$("window"),
		background:OZ.$("background"),
		ok:OZ.$("windowok"),
		cancel:OZ.$("windowcancel"),
		title:OZ.$("windowtitle"),
		content:OZ.$("windowcontent"),
		throbber:OZ.$("throbber")
	}
	this.dom.ok.value = _("windowok");
	this.dom.cancel.value = _("windowcancel");
	this.dom.throbber.alt = this.dom.throbber.title = _("throbber");
	OZ.Event.add(this.dom.ok, "click", this.bind(this.ok));
	OZ.Event.add(this.dom.cancel, "click", this.bind(this.close));
	OZ.Event.add(document, "keydown", this.bind(this.key));
	
	this.sync = this.bind(this.sync);
	
	OZ.Event.add(window, "scroll", this.sync);
	OZ.Event.add(window, "resize", this.sync);
	this.state = 0;
	this.hideThrobber();
	
	this.sync();
}

jxDiaTool.Window.prototype.showThrobber = function() {
	this.dom.throbber.style.visibility = "";
}

jxDiaTool.Window.prototype.hideThrobber = function() {
	this.dom.throbber.style.visibility = "hidden";
}

jxDiaTool.Window.prototype.open = function(title, content, callback) {
	this.state = 1;
	this.callback = callback;
	while (this.dom.title.childNodes.length > 1) { this.dom.title.removeChild(this.dom.title.childNodes[1]); }

	var txt = OZ.DOM.text(title);
	this.dom.title.appendChild(txt);
	this.dom.background.style.visibility = "visible";
	OZ.DOM.clear(this.dom.content);
	this.dom.content.appendChild(content);
	
	var win = OZ.DOM.win();
	var scroll = OZ.DOM.scroll();
	this.dom.container.style.left = Math.round(scroll[0] + (win[0] - this.dom.container.offsetWidth)/2)+"px";
	this.dom.container.style.top = Math.round(scroll[1] + (win[1] - this.dom.container.offsetHeight)/2)+"px";
	
	this.dom.cancel.style.visibility = (this.callback ? "" : "hidden");
	this.dom.container.style.visibility = "visible";

	var formElements = ["input","select","textarea"];
	var all = this.dom.container.getElementsByTagName("*");
	for (var i=0;i<all.length;i++) {
		if (formElements.indexOf(all[i].tagName.toLowerCase()) != -1) {
			all[i].focus();
			break;
		}
	}
}

jxDiaTool.Window.prototype.key = function(e) {
	if (!this.state) { return; }
	if (e.keyCode == 13) { this.ok(e); }
	if (e.keyCode == 27) { this.close(); }
}

jxDiaTool.Window.prototype.ok = function(e) {
	if (this.callback) { this.callback(); }
	this.close();
}

jxDiaTool.Window.prototype.close = function() {
	if (!this.state) { return; }
	this.state = 0;
	this.dom.background.style.visibility = "hidden";
	this.dom.container.style.visibility = "hidden";
}

jxDiaTool.Window.prototype.sync = function() { /* adjust background position */
	var dims = OZ.DOM.win();
	var scroll = OZ.DOM.scroll();
	this.dom.background.style.width = dims[0]+"px";
	this.dom.background.style.height = dims[1]+"px";
	this.dom.background.style.left = scroll[0]+"px";
	this.dom.background.style.top = scroll[1]+"px";
}

/* --------------------- options ------------ */

jxDiaTool.Options = OZ.Class();

jxDiaTool.Options.prototype.init = function(parent) {
	this.parent = parent;
	this.dom = {
		container:OZ.$("opts"),
		btn:OZ.$("options")
	}
	this.dom.btn.value = _("options");
	this.save = this.bind(this.save);
	this.build();
}

jxDiaTool.Options.prototype.build = function() {
	this.dom.optionlocale = OZ.$("optionlocale");
	this.dom.optiondb = OZ.$("optiondb");
	this.dom.optionsnap = OZ.$("optionsnap");
	this.dom.optionpattern = OZ.$("optionpattern");
	this.dom.optionhide = OZ.$("optionhide");
	this.dom.optionvector = OZ.$("optionvector");

	var ids = ["language","db","snap","pattern","hide","vector","optionsnapnotice","optionpatternnotice","optionsnotice"];
	for (var i=0;i<ids.length;i++) {
		var id = ids[i];
		var elm = OZ.$(id);
		elm.innerHTML = _(id);
	}
	
	var ls = CONFIG.AVAILABLE_LOCALES;
	for (var i=0;i<ls.length;i++) {
		var o = OZ.DOM.elm("option");
		o.value = ls[i];
		o.innerHTML = ls[i];
		this.dom.optionlocale.appendChild(o);
		if (this.parent.getOption("locale") == ls[i]) { this.dom.optionlocale.selectedIndex = i; }
	}

	var dbs = CONFIG.AVAILABLE_DBS;
	for (var i=0;i<dbs.length;i++) {
		var o = OZ.DOM.elm("option");
		o.value = dbs[i];
		o.innerHTML = dbs[i];
		this.dom.optiondb.appendChild(o);
		if (this.parent.getOption("db") == dbs[i]) { this.dom.optiondb.selectedIndex = i; }
	}

	
	OZ.Event.add(this.dom.btn, "click", this.bind(this.click));
	
	this.dom.container.parentNode.removeChild(this.dom.container);
}

jxDiaTool.Options.prototype.save = function() {
	this.parent.setOption("locale",this.dom.optionlocale.value);
	this.parent.setOption("db",this.dom.optiondb.value);
	this.parent.setOption("snap",this.dom.optionsnap.value);
	this.parent.setOption("pattern",this.dom.optionpattern.value);
	this.parent.setOption("hide",this.dom.optionhide.checked ? "1" : "");
	this.parent.setOption("vector",this.dom.optionvector.checked ? "1" : "");
}

jxDiaTool.Options.prototype.click = function() {
	this.parent.window.open(_("options"),this.dom.container,this.save);
	this.dom.optionsnap.value = this.parent.getOption("snap");
	this.dom.optionpattern.value = this.parent.getOption("pattern");
	this.dom.optionhide.checked = this.parent.getOption("hide");
	this.dom.optionvector.checked = this.parent.getOption("vector");
}

/* ------------------ minimize/restore bar ----------- */

jxDiaTool.Toggle = OZ.Class();

jxDiaTool.Toggle.prototype.init = function(elm) {
	this._state = null;
	this._elm = elm;
	OZ.Event.add(elm, "click", this._click.bind(this));
	
	var defaultState = true;
	if (document.location.href.match(/toolbar=hidden/)) { defaultState = false; }
	this._switch(defaultState);
}

jxDiaTool.Toggle.prototype._click = function(e) {
	this._switch(!this._state);
}

jxDiaTool.Toggle.prototype._switch = function(state) {
	this._state = state;
	if (this._state) {
		OZ.$("bar").style.height = "";
	} else {
		OZ.$("bar").style.overflow = "hidden";
		OZ.$("bar").style.height = this._elm.offsetHeight + "px";
	}
	this._elm.className = (this._state ? "on" : "off");
}

/* --------------------- www sql designer ------------ */

jxDiaTool.MainApp = OZ.Class().extend(jxDiaTool.Visual);

jxDiaTool.MainApp.prototype.init = function() {
	jxDiaTool.MainApp = this;
	
	this.dbentities = [];
	this.tables = [];
	this.relations = [];
	this.title = document.title;
	
	jxDiaTool.Visual.prototype.init.apply(this);
	new jxDiaTool.Toggle(OZ.$("toggle"));
	
	this.dom.container = this.dom.content = OZ.$("area");
	this.minSize = [
		this.dom.container.offsetWidth,
		this.dom.container.offsetHeight
	];
	this.width = this.minSize[0];
	this.height = this.minSize[1];
	
	this.typeIndex = false;
	this.fkTypeFor = false;

	this.vector = this.getOption("vector") && (OZ.gecko || OZ.opera || OZ.webkit || OZ.ie);
	if (this.vector) {
		this.vector = "svg";
		if (OZ.ie) { this.vector = "vml"; }
	}
	if (this.vector == "svg") {
		this.svgNS = "http://www.w3.org/2000/svg";
		this.dom.svg = document.createElementNS(this.svgNS, "svg");
		this.dom.content.appendChild(this.dom.svg);
	}

	this.flag = 2;
	this.requestLanguage();
	this.requestDB();
}

/* update area size */
jxDiaTool.MainApp.prototype.sync = function() {
	var w = this.minSize[0];
	var h = this.minSize[0];
	for (var i=0;i<this.tables.length;i++) {
		var t = this.tables[i];
		w = Math.max(w, t.x + t.width);
		h = Math.max(h, t.y + t.height);
	}
	
	this.width = w;
	this.height = h;
	this.map.sync();

	if (this.vector == "svg") {	
		this.dom.svg.setAttribute("width", this.width);
		this.dom.svg.setAttribute("height", this.height);
	}
}

jxDiaTool.MainApp.prototype.requestLanguage = function() { /* get locale file */
	var lang = this.getOption("locale")
	var bp = this.getOption("staticpath");
	var url = bp + "locale/"+lang+".xml";
	OZ.Request(url, this.bind(this.languageResponse), {method:"get", xml:true});
}

jxDiaTool.MainApp.prototype.languageResponse = function(xmlDoc) {
	if (xmlDoc) {
		var strings = xmlDoc.getElementsByTagName("string");
		for (var i=0;i<strings.length;i++) {
			var n = strings[i].getAttribute("name");
			var v = strings[i].firstChild.nodeValue;
			window.LOCALE[n] = v;
		}
	}
	this.flag--;
	if (!this.flag) { this.init2(); }
}

jxDiaTool.MainApp.prototype.requestDB = function() { /* get datatypes file */
	var db = this.getOption("db");
	var bp = this.getOption("staticpath");
	var url = bp + "db/"+db+"/datatypes.xml";
	OZ.Request(url, this.bind(this.dbResponse), {method:"get", xml:true});
}

jxDiaTool.MainApp.prototype.dbResponse = function(xmlDoc) {
	if (xmlDoc) {
		window.DATATYPES = xmlDoc.documentElement;
	}
	this.flag--;
	if (!this.flag) { this.init2(); }
}

jxDiaTool.MainApp.prototype.init2 = function() { /* secondary init, after locale & datatypes were retrieved */
	this.map = new jxDiaTool.Map(this);
	this.rubberband = new jxDiaTool.Rubberband(this);
	this.entityManager = new jxDiaTool.EntityManager(this);
//	this.rowManager = new jxDiaTool.RowManager(this);
	this.keyManager = new jxDiaTool.KeyManager(this);
	this.io = new jxDiaTool.IO(this);
	this.finddbentity = new jxDiaTool.FindDBEntity(this);
	this.options = new jxDiaTool.Options(this);
	this.window = new jxDiaTool.Window(this);

	this.sync();
	
	OZ.$("docs").value = _("docs");

	var url = window.location.href;
	var r = url.match(/keyword=([^&]+)/);
	if (r) {
		var keyword = r[1];
		this.io.serverload(false, keyword);
	}
	document.body.style.visibility = "visible";
   this.addDBEntity("nativeserver","e8npnu08",50,50);
}

jxDiaTool.MainApp.prototype.getMaxZ = function() { /* find max zIndex */
	var max = 0;
	for (var i=0;i<this.tables.length;i++) {
		var z = this.tables[i].getZ();
		if (z > max) { max = z; }
	}
	
	OZ.$("controls").style.zIndex = max+5;
	return max;
}

jxDiaTool.MainApp.prototype.addDBEntity = function(type,name, x, y) {
	var max = this.getMaxZ();
	var e = new jxDiaTool.DBEntity(this,type , name, x, y, max+1);
	this.dbentities.push(e);
	this.dom.content.appendChild(e.dom.container);
	e.redraw();
	return e;
}

jxDiaTool.MainApp.prototype.addTable = function(name, x, y) {
	var max = this.getMaxZ();
	var t = new jxDiaTool.Table(this, name, x, y, max+1);
	this.tables.push(t);
	this.dom.content.appendChild(t.dom.container);
	t.redraw();
	return t;
}

jxDiaTool.MainApp.prototype.removeTable = function(t) {
	this.entityManager.select(false);
//	this.rowManager.select(false);
	var idx = this.tables.indexOf(t);
	if (idx == -1) { return; }
	t.destroy();
	this.tables.splice(idx,1);
}

jxDiaTool.MainApp.prototype.addRelation = function(row1, row2) {
	var r = new jxDiaTool.Relation(this, row1, row2);
	this.relations.push(r);
	return r;
}

jxDiaTool.MainApp.prototype.removeRelation = function(r) {
	var idx = this.relations.indexOf(r);
	if (idx == -1) { return; }
	r.destroy();
	this.relations.splice(idx,1);
}

jxDiaTool.MainApp.prototype.getCookie = function() {
	var c = document.cookie;
	var obj = {};
	var parts = c.split(";");
	for (var i=0;i<parts.length;i++) {
		var part = parts[i];
		var r = part.match(/wwwsqldesigner=({.*?})/);
		if (r) { obj = eval("("+r[1]+")"); }
	}
	return obj;
}

jxDiaTool.MainApp.prototype.setCookie = function(obj) {
	var arr = [];
	for (var p in obj) {
		arr.push(p+":'"+obj[p]+"'");
	}
	var str = "{"+arr.join(",")+"}";
	document.cookie = "wwwsqldesigner="+str+"; path=/";
}

jxDiaTool.MainApp.prototype.getOption = function(name) {
	var c = this.getCookie();
	if (name in c) { return c[name]; }
	/* defaults */
	switch (name) {
		case "locale": return CONFIG.DEFAULT_LOCALE;
		case "db": return CONFIG.DEFAULT_DB;
		case "staticpath": return CONFIG.STATIC_PATH || "";
		case "xhrpath": return CONFIG.XHR_PATH || "";
		case "snap": return 0;
		case "pattern": return "%R_%T";
		case "hide": return false;
		case "vector": return true;
		default: return null;
	}
}

jxDiaTool.MainApp.prototype.setOption = function(name, value) {
	var obj = this.getCookie();
	obj[name] = value;
	this.setCookie(obj);
}

jxDiaTool.MainApp.prototype.raise = function(table) { /* raise a table */
	var old = table.getZ();
	var max = this.getMaxZ();
	table.setZ(max);
	for (var i=0;i<this.tables.length;i++) {
		var t = this.tables[i];
		if (t == table) { continue; }
		if (t.getZ() > old) { t.setZ(t.getZ()-1); }
	}
	var m = table.dom.mini;
	m.parentNode.appendChild(m);
}

jxDiaTool.MainApp.prototype.clearTables = function() {
	while (this.tables.length) { this.removeTable(this.tables[0]); }
	this.setTitle(false);
}

jxDiaTool.MainApp.prototype.alignTables = function() {
	var win = OZ.DOM.win();
	var avail = win[0] - OZ.$("bar").offsetWidth;
	var x = 10;
	var y = 10;
	var max = 0;
	
	this.tables.sort(function(a,b){
		return b.getRelations().length - a.getRelations().length;
	});

	for (var i=0;i<this.tables.length;i++) {
		var t = this.tables[i];
		var w = t.dom.container.offsetWidth;
		var h = t.dom.container.offsetHeight;
		if (x + w > avail) {
			x = 10;
			y += 10 + max;
			max = 0;
		}
		t.moveTo(x,y);
		x += 10 + w;
		if (h > max) { max = h; }
	}

	this.sync();
}

jxDiaTool.MainApp.prototype.findNamedTable = function(name) { /* find row specified as table(row) */
	for (var i=0;i<this.tables.length;i++) {
		if (this.tables[i].getTitle() == name) { return this.tables[i]; }
	}
}

jxDiaTool.MainApp.prototype.toXML = function() {
	var xml = '<?xml version="1.0" encoding="utf-8" ?>\n';
	xml += '<sql>\n';
	
	/* serialize datatypes */
	if (window.XMLSerializer) {
		var s = new XMLSerializer();
		xml += s.serializeToString(window.DATATYPES);
	} else if (window.DATATYPES.xml) {
		xml += window.DATATYPES.xml;
	} else {
		alert(_("errorxml")+': '+e.message);
	}
	
	for (var i=0;i<this.tables.length;i++) {
		xml += this.tables[i].toXML();
	}
	xml += "</sql>\n";
	return xml;
}

jxDiaTool.MainApp.prototype.fromXML = function(node) {
	this.clearTables();
	var types = node.getElementsByTagName("datatypes");
	if (types.length) { window.DATATYPES = types[0]; }
	var tables = node.getElementsByTagName("table");
	for (var i=0;i<tables.length;i++) {
		var t = this.addTable("", 0, 0);
		t.fromXML(tables[i]);
	}

	/* relations */
	var rs = node.getElementsByTagName("relation");
	for (var i=0;i<rs.length;i++) {
		var rel = rs[i];
		var tname = rel.getAttribute("table");
		var rname = rel.getAttribute("row");
		
		var t1 = this.findNamedTable(tname);
		if (!t1) { continue; }
		var r1 = t1.findNamedRow(rname);
		if (!r1) { continue; }

		tname = rel.parentNode.parentNode.getAttribute("name");
		rname = rel.parentNode.getAttribute("name");
		var t2 = this.findNamedTable(tname);
		if (!t2) { continue; }
		var r2 = t2.findNamedRow(rname);
		if (!r2) { continue; }

		this.addRelation(r1, r2);
	}
}

jxDiaTool.MainApp.prototype.setTitle = function(t) {
	document.title = this.title + (t ? " - "+t : "");
}

jxDiaTool.MainApp.prototype.removeSelection = function() {
	var sel = (window.getSelection ? window.getSelection() : document.selection);
	if (!sel) { return; }
	if (sel.empty) { sel.empty(); }
	if (sel.removeAllRanges) { sel.removeAllRanges(); }
}

jxDiaTool.MainApp.prototype.getTypeIndex = function(label) {
	if (!this.typeIndex) {
		this.typeIndex = {};
		var types = window.DATATYPES.getElementsByTagName("type");
		for (var i=0;i<types.length;i++) {
			var l = types[i].getAttribute("label");
			if (l) { this.typeIndex[l] = i; }
		}
	}
	return this.typeIndex[label];
}

jxDiaTool.MainApp.prototype.getFKTypeFor = function(typeIndex) {
	if (!this.fkTypeFor) {
		this.fkTypeFor = {};
		var types = window.DATATYPES.getElementsByTagName("type");
		for (var i=0;i<types.length;i++) {
			this.fkTypeFor[i] = i;
			var fk = types[i].getAttribute("fk");
			if (fk) { this.fkTypeFor[i] = this.getTypeIndex(fk); }
		}
	}
	return this.fkTypeFor[typeIndex];
}

//OZ.Event.add(window, "beforeunload", OZ.Event.prevent);
