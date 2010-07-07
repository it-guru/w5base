(function($) {
   $.widget("ui.barGrid", {
      _init: function(){
         this.element.css('background-color',"gray");
         this._createTableGrid();
      },
      _createBaseLayout: function(){
         this.mainTable=$("<table border=0 class='barGridMain' width=100% height=100%>"+
                          "</table>");
         this.mainTable.css('border-collapse','collapse');
         this.mainTable.appendTo(this.element);

         var row1=$("<tr height=1%></tr>");
         row1.appendTo(this.mainTable); 
         var row2=$("<tr></tr>");
         row2.appendTo(this.mainTable); 

         this.colHeadLabel=$("<td width=1% nowrap>&nbsp;</td>");
         this.colHeadLabel.appendTo(row1);


         this.colTable=$("<table border=1 class='barGridColumns'></table>");
         this.colTable.css('table-layout','fixed');
         this.colTable.css('border-collapse','collapse');
         this.colHeadRow=$("<tr></tr>");
         this.colHeadRow.appendTo(this.colTable);

         this.colHead=$("<div></div>");
         this.colHead.css('overflow','auto');
         this.colHeadTd=$("<td></td>");
         this.colHead.appendTo(this.colHeadTd);
         this.colTable.appendTo(this.colHead);
         this.colHeadTd.appendTo(row1);

         this.rowTable=$("<table border=1 class='barGridRows'></table>");
         this.rowTable.css('table-layout','fixed');
         this.rowTable.css('border-collapse','collapse');
         var row=$("<tr></tr>");
         row.appendTo(this.rowTable);

         this.rowHead=$("<div></div>");
         this.rowHead.css('overflow','auto');
         this.rowTable.appendTo(this.rowHead);
         this.rowHeadTd=$("<td valign=top></td>");
         this.rowHead.appendTo(this.rowHeadTd);
         this.rowHeadTd.appendTo(row2);
         this.resize();
       //  this.colHead.width(50); 
       //  this.rowHead.height(50); 
      },
      _initHeaders: function(){
         for(var c=0;c<this.options.colModel.length;c++){
            this.addCol(this.options.colModel[c]);
         }
         for(var c=0;c<this.options.rowModel.length;c++){
            this.addRow(this.options.rowModel[c]);
         }
      },
      // interface:
      resize: function(){
         this.colHead.css('display','none');
         this.rowHead.css('display','none');

         this.rowHead.css('display','block');
         var rowHeadWidth=this.rowHeadTd.width();
         var rowHeadHeight=this.rowHead.height();
         this.rowHead.css('display','none');

         this.colHead.css('display','block');
         var colHeadHeight=this.colHeadTd.height();
         var colHeadWidth=this.colHead.width();
         this.colHead.css('display','none');

         var totalWidth=this.element.width();
         var totalHeight=this.element.height();

         this.colHead.css('width',(totalWidth-rowHeadWidth)+"px");
         this.rowHead.css('height',(totalHeight-18)+"px"); // 18 oben + 3* rahmen
         this.rowHead.css('width',(200)+"px");

 //        this.colHead.css('display','block');
         this.rowHead.css('display','block');
      },
      addCol: function(col){
            var label=col.name;
            if (col.label!=undefined){
               label=col.label;
            }
            col.e=$("<td id='"+col.name+"'>"+label+"</td>");
            if (col.width){
               col.e.css('width',col.width+'px');
            }
            col.e.appendTo(this.colHeadRow);
      },
      addRow: function(row){
            var label=row.name;
            if (row.label!=undefined){
               label=row.label;
            }
            var tr=$("<tr id='"+row.name+"'></tr>");
            row.e=$("<td>"+label+"</td>");
            row.e.appendTo(tr);
            tr.appendTo(this.rowTable);
      },
//      _createColHead: function(pe){
//         this.colTable=$("<table border=1 class='barGridColumns'></table>");
//         this.colHeadRow=$("<tr></tr>");
//         this.colHeadRow.appendTo(this.colTable);
//         for(var c=0;c<this.options.colModel.length;c++){
//            var col=this.options.colModel[c];
//         }
//        this.colTable.appendTo(this.colColHead);
//        td.appendTo(pe);
//      },
//      _createRowHead: function(pe){
//         this.rowTable=$("<table border=1 class='barGridRows'></table>");
//         for(var c=0;c<this.options.rowModel.length;c++){
//            var col=this.options.rowModel[c];
//            var label=col.name;
//            if (this.options.rowLabel[c]!=undefined){
//               label=this.options.rowLabel[c];
//            }
//            var row=$("<tr></tr>");
//            row.appendTo(this.rowTable);
//            col.e=$("<td>"+label+"</td>");
//            col.e.appendTo(row);
//         }
//         this.colRowHead=$("<div></div>");
//         var td=$("<td valign=top width=1% nowrap></td>");
//         this.colRowHead.appendTo(td);
//         this.rowTable.appendTo(this.colRowHead);
//         td.appendTo(pe);
//      },
      _createTableGrid: function(){
         this.element.html("");
         this._createBaseLayout();
         this._initHeaders();



//         // head table
//         var ht="";
//         ht+="<table class='barGridColumns'>"; 
//         ht+="<tr>"; 
//         for(var f=1;f<=31;f++){
//            ht+="<td nowrap>"+f+"<td>"; 
//         }
//         ht+="</tr>"; 
//         ht+="</table>"; 
//
//         // row table
//         var rt="";
//         rt+="<table class='barGridColumns'>"; 
//         for(var f=1;f<=50;f++){
//            rt+="<tr><td nowrap>Bla Bla Bla Zeile"+f+"<td></tr>"; 
//         }
//         rt+="</table>"; 
//
//         // main table
//         this.rowContainer=$("<div></div>");
//         var mt="";
//         mt+="<table class='barGridMain' width=100% height=100%>"; 
//         mt+="<tr height=1%>"; 
//         mt+="<td width=1% nowrap>Names</td>"; 
//         mt+="<td valign=top>"+ht+"</td>"; 
//         mt+="</tr>"; 
//         mt+="<tr>"; 
//         mt+="<td valign=top width=1% nowrap>"+rt+"</td>"; 
//         mt+="<td valign=top>Data</td>"; 
//         mt+="</tr>"; 
//         mt+="</table>"; 
         //$(mt).appendTo(this.element);
      }
   });
})(jQuery);

