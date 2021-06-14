function DoFieldonClick(th)
{
  var val=th.getAttribute('xvalue');
  var view=document.getElementById('NewCurrentView');
  if ( th.className == 'denote' ){
    for(c=view.length-1;c>=0;c--){
      if (view.options[c].value == val){
         view.remove(c);
         inittree('tree_route',1);
      }
    }
    th.className='note';
  }else{
    var o=document.createElement('option');
    for(c=0;c<view.length;c++){
      view.options[c].selected=false;
    }
    view.appendChild(o);
    console.log("child=o",th.childNodes);
    o.text=th.childNodes[1].nodeValue;
    if (th.childNodes[1].nodeType!=3){
       o.text=th.childNodes[2].nodeValue;
    }
    o.value=val;
  //  o.selected=true;
  //  th.className='denote';
    inittree('tree_route',1);
    th.firstChild.className='lispan';
  }
}   

function inittree(tree,m)
{
  var view=document.getElementById('NewCurrentView');
  var ss=document.getElementById('shortsearch');
  for(var c=0;c<document.getElementById(tree).childNodes.length;c++){
    var srcview=document.getElementById(tree).childNodes[c];
    if ( srcview.nodeName == 'LI' || srcview.nodeName == 'UL' ){ 
      if (srcview.getAttribute('xhead') == 1 ){
         xc=0;
      }
      if ( srcview.getAttribute('downpoint') == 1 ){ 
        srcview.className='note';
        for(var i=0;i<view.length;i++){
          var chkvalue=view.options[i].value;
          chkvalue=chkvalue.replace(/^[+-]/,"");
          if (chkvalue == srcview.getAttribute("xvalue")){
            srcview.className='denote';
          }
          if (ss.value != ""){
             srcview.style.display='none'; 
          }else{
             srcview.style.display='block'; 
          }
        }
        var pattern=eval("/" + ss.value + "/gi");
        var xsv;
        //console.warn(srcview.textContent);
        // innerText for ie and textContent for firefox
        if (typeof srcview.textContent == "undefined"){
           xsv=srcview.innerText;
        }else{
           xsv=srcview.textContent;
        }

        if (xsv.match(pattern) && ss.value != ""){
           srcview.style.display='block';
           srcview.parentNode.parentNode.className='liOpen';
           srcview.parentNode.parentNode.style.display='block';
           xc=1;
        }else if ( xc == 0 && m != 1 ){
           if (ss.value == ""){
              srcview.parentNode.parentNode.className='liClosed';
              srcview.parentNode.parentNode.style.display='block';
           }else{
              srcview.parentNode.parentNode.style.display='none';
           }
        }
      }
      inittree(srcview.id,m);
    }
  }
}

function ShSearch()
{
  var des=window.document.getElementById('FullFieldTreeSelect');
  inittree('tree_route');
}

function RefreshViewDropDown(tree)
{
   var des=window.document.getElementById('FullFieldTreeSelect');
   var src=window.document.getElementById('NewCurrentView');
   if (des && src){
      des.style.height=src.offsetHeight;
      src.style.height=des.offsetHeight;
   }
   inittree(tree,1);
   return;
}

var DataChanged=0;


function addEvent(o,e,f) 
{
  if (o.addEventListener) { 
     o.addEventListener(e,f,true); return true; 
  }else if (o.attachEvent) { 
     return o.attachEvent("on"+e,f); 
  }else { 
     return false; 
  }
}

function setDefault(name,val) 
{
  if (typeof(window[name])=="undefined" || window[name]==null) {
     window[name]=val;
  }
}

function expandTree(treeId) 
{
  var ul = document.getElementById(treeId);
  if (ul == null) { 
    return false; 
  }
  expandCollapseList(ul,nodeOpenClass);
}

function collapseTree(treeId) 
{
  var ul = document.getElementById(treeId);
  if (ul == null) { 
    return false; 
  }
  expandCollapseList(ul,nodeClosedClass);
}

function expandToItem(treeId,itemId) 
{
  var ul = document.getElementById(treeId);
  if (ul == null) { 
    return false; 
  }
  var ret = expandCollapseList(ul,nodeOpenClass,itemId);
  if (ret) {
    var o = document.getElementById(itemId);
    if (o.scrollIntoView) {
      o.scrollIntoView(false);
    }
  }
}

function expandCollapseList(ul,cName,itemId) 
{
  if (!ul.childNodes || ul.childNodes.length==0) { 
    return false; 
  }
  for (var itemi=0;itemi<ul.childNodes.length;itemi++) {
    var item = ul.childNodes[itemi];
    if (itemId!=null && item.id==itemId) { 
      return true; 
    }
    if (item.nodeName == "LI") {
      var subLists = false;
      for (var sitemi=0;sitemi<item.childNodes.length;sitemi++) {
        var sitem = item.childNodes[sitemi];
        if (sitem.nodeName=="UL") {
          subLists = true;
          var ret = expandCollapseList(sitem,cName,itemId);
          if (itemId!=null && ret) {
            item.className=cName;
            return true;
          }
        }
      }
      if (subLists && itemId==null) {
        item.className = cName;
      }
    }
  }
}

function convertTrees() 
{
  setDefault("treeClass","mktree");
  setDefault("nodeClosedClass","liClosed");
  setDefault("nodeOpenClass","liOpen");
  setDefault("nodeBulletClass","liBullet");
  setDefault("nodeLinkClass","bullet");
  setDefault("preProcessTrees",true);
  if (preProcessTrees) {
    if (!document.createElement) { 
      return; 
    }
    uls = document.getElementsByTagName("ul");
    for (var uli=0;uli<uls.length;uli++) {
      var ul=uls[uli];
      if (ul.nodeName=="UL" && ul.className==treeClass) {
        processList(ul);
      }
    }
  }
}

function processList(ul,oall) 
{
  if (!ul.childNodes || ul.childNodes.length==0) { 
    return; 
  }
  for (var itemi=0;itemi<ul.childNodes.length;itemi++) {
    var item = ul.childNodes[itemi];
    if (item.nodeName == "LI") {
      var subLists = false;
      for (var sitemi=0;sitemi<item.childNodes.length;sitemi++) {
        var sitem = item.childNodes[sitemi];
        if (sitem.nodeName=="UL") {
          subLists = true;
          processList(sitem);
        }
      }
      var s= document.createElement("SPAN");
      var t= '\u00A0'; 
      s.className = nodeLinkClass;
      if (subLists) {
        if (item.className==null || item.className=="") {
          item.className = nodeClosedClass;
        }
        if (item.firstChild.nodeName=="#text") {
          t = t+item.firstChild.nodeValue;
          item.removeChild(item.firstChild);
        }
        s.onclick = function () {
          this.parentNode.className = (this.parentNode.className==nodeOpenClass) ? nodeClosedClass : nodeOpenClass;
          return false;
        }
      }else if ( item.className != "denote"  ){
        item.className = nodeBulletClass;
        s.onclick = function () { 
          return false; 
        }
      }
      s.appendChild(document.createTextNode(t));
      item.insertBefore(s,item.firstChild);
      if ( item.className == "denote"  ){
        item.firstChild.className="lispan";
        s.onclick = function () { 
          return false; 
        }
      }else if (item.className == "liBullet"){
        item.firstChild.className="lispan";

      }
    }
  }
}



