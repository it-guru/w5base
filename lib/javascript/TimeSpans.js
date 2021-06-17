var TimeSpans=function(init,initParam){
   this.setParam=function(initParam){
      if (typeof(initParam)==="object" && initParam!==null){
         for (var i in initParam) {
            this[i]=initParam[i];
         }
      }
   };
   if (typeof(initParam)==="object" && initParam!==null){
      this.setParam(initParam);
   }
   this._spans=new Array();
   if (!this.hasOwnProperty("maxDays")){
      this.maxDays=7;
   }
   if (!('validType' in this)){
      this.validType=[];
   }
   if (!('dayLabel' in this)){
      this.dayLabel={};
   }
   if (!('typeColor' in this)){
      this.typeColor={
         '':'blue'
      };
   }
   if (!('typeLabel' in this)){
      this.typeLabel={
      };
   }
   if (!('defaultType' in this)){
      this.defaultType="";
   }
   this._sortSpans=function(dayno){
      if (this._spans[dayno]){
         this._spans[dayno] = this._spans[dayno].filter(function(x) {
            return x !== undefined;
         });
         this._spans[dayno].sort(function (a, b) {
           return a.startMin - b.startMin;
         });
      }
   };
   this.table=function(){
      var tab="<table class=timetable>";
      tab+="<tr><td width=80>&nbsp;</td><td>";
      tab+="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0><tr>";
      tab+="<td align=left width=\"10%\">0h</td>";
      tab+="<td align=center width=\"25%\">6h</td>";
      tab+="<td align=center width=\"25%\">12h</td>";
      tab+="<td align=center width=\"25%\">18h</td>";
      tab+="<td align=right>24h</td>";
      tab+="</tr></table></td></tr>\n";
      for(var dayno=0;dayno<this._spans.length;dayno++){
         var dayLabel=dayno;
         if (dayno in this.dayLabel){
            dayLabel=this.dayLabel[dayno];
         }
         tab+="<tr><td>"+dayLabel+"</td><td>";
         var blks=new Array();
         for(var blkno=0;blkno<this._spans[dayno].length;blkno++){
             var e=this._spans[dayno][blkno];
             var sp=Math.round(e.startMin*100/1439);
             var ep=Math.round(e.endMin*100/1439);
             if (sp<=ep){
                blks.push({
                   startMin:e.startMin,
                   endMin:e.endMin,
                   startPercent:sp,
                   endPercent:ep,
                   type:e.type
                });
             }
         }
         blks.sort(function (a, b) {
           return a.startPercent - b.startPercent;
         });
         var blkslength=blks.length;
         for(var blk=1;blk<blks.length;blk++){  // create space blocks bettween
            if (blks[blk-1].endPercent!=blks[blk].startPercent){
             //  if (blks[blk-1].endPercent>=blks[blk].startPercent){
                  blks.push({
                     startPercent:blks[blk-1].endPercent,
                     endPercent:blks[blk].startPercent,
                     emptyBlk:1
                  });
                  blks.sort(function (a, b) {
                    return a.startPercent - b.startPercent;
                  });
             //  }
            }
         }
         blks.sort(function (a, b) {
           return a.startPercent - b.startPercent;
         });
         if (blkslength>0){
            if (blks[0].startPercent!=0){
               var zeroblk={
                  endPercent:blks[0].startPercent,
                  startPercent:0
               };
               blks.push(zeroblk);
            }
         }
         blks.sort(function (a, b) {
           return a.startPercent - b.startPercent;
         });


         for(var blk=0;blk<blks.length;blk++){
            var w=blks[blk].endPercent-blks[blk].startPercent;
            var color="blue";
            if ('type' in blks[blk]){
               color=this.typeColor[blks[blk].type];
            }
            else{
               color="transparent";
            }
            var titletag="";
            var tlabel="";
            if ('type' in blks[blk]){
               tlabel=blks[blk].type;
               if (tlabel in this.typeLabel){
                  tlabel=this.typeLabel[tlabel];
               }
            }
            var trange="";
            if ('startMin' in blks[blk] && 'endMin' in blks[blk]){
               var h1=parseInt(blks[blk].startMin/60);
               var m1=blks[blk].startMin-(60*h1);
               var h2=parseInt(blks[blk].endMin/60);
               var m2=blks[blk].endMin-(60*h2);
               if (h1<10) h1="0"+h1;
               if (h2<10) h2="0"+h2;
               if (m1<10) m1="0"+m1;
               if (m2<10) m2="0"+m2;
               trange=""+h1+":"+m1+"-"+h2+":"+m2;
            }
            if (trange!=""){
               if (tlabel!=""){
                  tlabel+=": ";
               }
               tlabel+=trange;
            }


            if (tlabel!=""){
               titletag="title=\""+tlabel+"\" class=\"timespan\" ";
            }
            tab+="<div id=\"name.dayno.seg\" "+titletag+
                 "style=\"background:"+color+";"+
                 "width:"+w+"%;height:18px;float:left;border-width:0;"+
                 "border-style:none;padding:0px;margin:0px\">";
            tab+="&nbsp;";
            tab+="</div>";
         }
           
         tab+="</td></tr>\n";
      }
      tab+="</table>";
      return(tab);
   };
   this.overlay=function(add){
      var o=new TimeSpans(this);
      for(var dayno=0;dayno<add._spans.length;dayno++){
         for(var blkno=0;blkno<add._spans[dayno].length;blkno++){
            var insblk=add._spans[dayno][blkno];
            if (!o._spans[dayno]){
               o._spans[dayno]=new Array();
            }
            var target=o._spans[dayno];
            var addBuffer=new Array();
            if (insblk.startMin<insblk.endMin && target.length<1000){
               INSLOOP: for(var i=0;i<target.length;i++){
                  if (insblk.startMin>target[i].startMin && // v0
                      insblk.endMin<target[i].endMin){
                     var n={
                        startMin:insblk.endMin,
                        endMin:target[i].endMin,
                        type:target[i].type
                     };
                     if (n.startMin>1439) n.startMin=1439;
                     target[i].endMin=insblk.startMin; 
                     if (target[i].endMin<0) target[i].endMin=0;
                     if (target[i].endMin==target[i].startMin){
                        target[i]=undefined;
                     }
                     if (n.startMin<=n.endMin){
                        target.push(n);
                     }
                     break INSLOOP;
                  }
                  else if (insblk.startMin<=target[i].startMin && // v4
                      insblk.endMin>=target[i].endMin){
                     target[i]=undefined;
                  //   break INSLOOP;
                  }
                  else if (insblk.startMin<=target[i].startMin &&  // v3
                      insblk.endMin<target[i].endMin &&
                      insblk.endMin>insblk.startMin){
                     target[i].startMin=insblk.endMin;
                     if (target[i].endMin>1439) target[i].endMin=1439;
                     break INSLOOP;
                  }
                  else if (target[i].endMin>insblk.startMin &&
                           target[i].startMin<insblk.startMin &&
                           target[i].endMin<=insblk.endMin){
                     target[i].endMin=insblk.startMin;
                     if (target[i].startMin<0) target[i].startMin=0;
                     break INSLOOP;
                  }
               }
               if (insblk){
                  target.push(insblk);
               }
               this._sortSpans(dayno);
            }
         }
      }
      return(o);
   }
   this._min2hm=function(min){
      var h=parseInt(min/60);
      var m=min-(h*60);
      if (h<10) h="0"+h;
      if (m<10) m="0"+m;
      return(h+":"+m);
   };
   this._dumpblk=function(dayno,blkno){
      var e=this._spans[dayno][blkno];
      e.end=this._min2hm(e.endMin);
      e.start=this._min2hm(e.startMin);
      return(e);
   };
   this.dump=function(){
      for(var dayno=0;dayno<this._spans.length;dayno++){
         for(var blkno=0;blkno<this._spans[dayno].length;blkno++){
            var b=this._dumpblk(dayno,blkno);
         }
      }
   }
   this.RangeScan=function(startMin,endMin,dayno){
      var r=new Array();
      var inRange=0;
      if (this._spans[dayno]){
         for(var blkno=0;blkno<this._spans[dayno].length;blkno++){
            if ((this._spans[dayno][blkno].startMin<=startMin) &&
                (this._spans[dayno][blkno].endMin>=endMin)){
               r.push({
                 mode:'fullScan',
                 startMin:startMin,
                 endMin:endMin,
                 from:this._spans[dayno][blkno],
                 type:this._spans[dayno][blkno].type,
                 fromsearch:{startMin:startMin,endMin:endMin}
               });
            }
            else if (this._spans[dayno][blkno].startMin>=startMin &&
                this._spans[dayno][blkno].endMin<=endMin){
               r.push({
                 mode:'fullSpan',
                 endMin:this._spans[dayno][blkno].endMin,
                 startMin:this._spans[dayno][blkno].startMin,
                 type:this._spans[dayno][blkno].type,
               });
            }
            else if (this._spans[dayno][blkno].startMin>startMin &&
                     this._spans[dayno][blkno].startMin<endMin){
               r.push({
                 mode:'startCut',
                 endMin:endMin,
                 startMin:this._spans[dayno][blkno].startMin,
                 type:this._spans[dayno][blkno].type,
               });
            }
            else if (this._spans[dayno][blkno].endMin>startMin &&
                     this._spans[dayno][blkno].endMin<endMin){
               r.push({
                 mode:'endCut',
                 endMin:this._spans[dayno][blkno].endMin,
                 startMin:startMin,
                 type:this._spans[dayno][blkno].type,
               });
            }
         }
      }
      return(r);
   }
   this.parseString=function(s){
      var blocks=s.split(/\+/);
      var fval=new Array();
      for(var c=0;c<blocks.length;c++){
         var blk=blocks[c].split(/^(\d+)\((.*)\)$/); 
         if (blk){
            fval[blk[1]]=blk[2];
         }
      }
      dayloop: for(var dayno=0;dayno<=this.maxDays;dayno++){
         if (!fval[dayno]) continue;
         var sp=fval[dayno].split(/\s*,\s*/);
         if (!sp) continue;
         sploop: for(var c=0;c<sp.length;c++){
            var e=sp[c].split(/\s*([a-z]{0,1})(\d+):(\d+)-(\d+):(\d+)\s*$/i);
            //var sperc=((parseInt(e[2])*60)+parseInt(e[3]))*100/1440;
            //var eperc=((parseInt(e[4])*60)+parseInt(e[5]))*100/1440;
            if (!this._spans[dayno]){
               this._spans[dayno]=new Array();
            }
            var type=this.defaultType;
            if (this.validType.includes(e[1])){
               type=e[1];
            }
            this._spans[dayno].push({
               startMin:(parseInt(e[2])*60)+parseInt(e[3]),
               endMin:(parseInt(e[4])*60)+parseInt(e[5]),
               type:type
            });
         }
         this._sortSpans();
      }
      //console.log("_sortSpans:",this._spans);
   }
   if (typeof(init)==="object" && init!==null){
      for (var i in init) {
         this[i]=init[i];
      }
   }
   else{
      //console.log("TimeSpans debug: init=",init);
      if (init){
         this.parseString(init);
      }
   }
};

if (typeof(define)!=="undefined"){
   define([],function(){return(TimeSpans);});
}



//var base=new TimeSpans("0(00:00-22:59)+1(00:00-23:59)+2(00:00-23:59)",{
//   maxDays:3
//});
//
//var add1=new TimeSpans(
//   "0(21:00-21:30,21:33-21:44)+1(00:00-23:59)+2(00:00-23:59)",{
//   defaultType:'k',
//   validType:[],
//   maxDays:3
//});
//
//var add2=new TimeSpans(
//   "0(21:33-21:44)+1(01:00-2:59)+2(03:00-3:59)",{
//   defaultType:'r',
//});
//
//
//var sum=base.overlay(add1);
//sum=sum.overlay(add2);
//
//console.log("base=",base);
//console.log("add1=",add1);
//console.log("add2=",add2);
//console.log("sum=",sum);
//sum.setParam({
//  dayLabel:{
//     0:"Mo-Fr.",
//     1:"Sa",
//     2:"So"
//  },
//  typeColor:{
//     'k':'red',
//     '':'silver',
//     'r':'green'
//  }
//});
//sum.dump();
//document.write(sum.table());
//



