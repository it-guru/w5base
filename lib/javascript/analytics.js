function AnalyticsQCount(param)
{
   var base=param.base;
   var key=param.key;
   var d="<table class=analysedata>";
   for (i in iparent){
      iparent[i].done=iparent[i].interviewst.total-
                      iparent[i].interviewst.todo;
      iparent[i].p=iparent[i].done*100/iparent[i].interviewst.total;
   }
   for (i in iparent){
      d+="<tr>";
      d+="<th width=1% nowrap>"+iparent[i][key]+"</td>";
      var done=iparent[i].done;
      var p=iparent[i].p;
      if (p<3) p=3;
      if (p>97) p=97;
      p=parseInt(p);
      var p2=100-p;
      d+="<td nowrap>"+
         "<div style=\"width:"+p+"%;background-color:green;float:left\">"+
         done+"</div>";
      d+="<div style=\"width:"+p2+"%;"+
         "text-align:right;background-color:red;float:left\">"+
         iparent[i].interviewst.todo+"</div></td>";
      d+="</tr>";
   }
   d+="</table>";
   $(document).ready(function () {
      $("#out").html(d);
   });
}
function AnalyticsGoal(param)
{
   var base=param.base;
   var key=param.key;
   var d="<table class=analysedata>";
   var i;
   for (i in iparent){
      var done=iparent[i].interviewst.total-
               iparent[i].interviewst.todo;
      iparent[i].v=done*100/iparent[i].interviewst.total;
   }
   function s(a,b){
      return ((iparent[a].v > iparent[b].v) ? -1 : 
              ((iparent[a].v < iparent[b].v) ? 1 : 0));
   }
   var keys=[];
   for (var property in iparent) keys.push(property);
   keys=keys.sort(s);
   if (param.desc!=undefined){
      d+="<tr><th></th><th class=desc>"+param.desc+"</th><tr>";
   }
   while(i=keys.shift()){
      d+="<tr>";
      d+="<th width=1% nowrap>"+iparent[i][key]+"</td>";
      d+="<td><div style=\"display:none\">"+
         sprintf("%.2f",iparent[i].v)+"%</div></td>";
      d+="</tr>";
   }
   d+="</table>";
   $(document).ready(function () {
      $("#out").html(d);
      $("#out div").each(function (i) {
          var cap=parseInt(Math.round($(this).text().replace(/\..*%/,""))); 
          var color="#c00000";
          if (cap>50){color="yellow"}
          if (cap>90){color="green"}
          $(this).width(cap+"%").css("background-color",color);
      }).show(800);
   });
}

