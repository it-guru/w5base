(function($) {
   $.widget("ui.barGrid", {
      options: {
         mainTableBorder: 1
      },
      _create: function() {
         this.element.css('background-color',"gray");
         this.element.css('margin',"0");
         this.element.css('padding',"0");
         this.element.css('border-width',"0");
         this._createTableGrid();
         var o=this;
         $(window).resize(function(){o.resize()});
      },

      _createBaseLayout: function(){
         this.mainTable=$("<table border='"+this.options.mainTableBorder+"' "+
                          "cellspacing=0 cellpadding=0 "+
                          "class='barGridMain' width=100% height=100%>"+
                          "</table>");
         this.mainTable.css('border-collapse','collapse');
         this.mainTable.appendTo(this.element);

         var row0=$("<tr height=1%></tr>");
         row0.appendTo(this.mainTable); 
         var row1=$("<tr height=1%></tr>");
         row1.appendTo(this.mainTable); 
         var row2=$("<tr></tr>");
         row2.appendTo(this.mainTable); 

         this.colHeadLabel=$("<td nowrap rowspan=2 width=1%></td>");
         this.colHeadLabel.appendTo(row0);
         var dummy=$("<td nowrap align=center>Tag</td>");
         dummy.appendTo(row0);


         this.colTable=$("<table cellspacing=0 cellpadding=0 border=0 class='barGridColumns'></table>");
         this.colTable.css('table-layout','fixed');
         this.colTable.css('border-collapse','collapse');
         this.colHeadRow=$("<tr></tr>");
         this.colHeadRow.appendTo(this.colTable);

         this.colHead=$("<div></div>");
         this.colHead.css('overflow','hidden');
         this.colHead.css('background-color','yellow');
         this.colHeadTd=$("<td></td>");
         this.colHead.appendTo(this.colHeadTd);
         this.colTable.appendTo(this.colHead);
         this.colHeadTd.appendTo(row1);

         this.rowTable=$("<table cellspacing=0 cellpadding=0 border=0 class='barGridRows'></table>");
         //this.rowTable.css('border-collapse','collapse');
         var row=$("<tr></tr>");
         row.appendTo(this.rowTable);

         this.rowHead=$("<div></div>");
         this.rowHead.css('overflow','hidden');
         this.rowHead.css('background-color','blue');
         this.rowTable.appendTo(this.rowHead);
         this.rowHeadTd=$("<td valign=top></td>");
         this.rowHead.appendTo(this.rowHeadTd);
         this.rowHeadTd.appendTo(row2);
         this.dataTable=$("<table cellspacing=0 cellpadding=0 border=0>"+
                         "</table>");
         this.dataArea=$("<div></div>");
         this.dataArea.css('background-color','silver');
         this.dataScrollArea=$("<div></div>");
         this.dataArea.appendTo(this.dataScrollArea);
         var o=this;
         this.dataScrollArea.scroll(function(){
            var tPos=o.dataScrollArea.scrollTop();
            var lPos=o.dataScrollArea.scrollLeft();
            o.colHead.scrollLeft(lPos);
            o.rowHead.scrollTop(tPos);
         });
         this.dataTable.appendTo(this.dataArea);
         this.dataScrollArea.css('overflow','auto');
         this.dataScrollArea.css('background-color','orange');
         this.dataAreaTd=$("<td valign=top></td>");
         this.dataScrollArea.appendTo(this.dataAreaTd);
         this.dataAreaTd.appendTo(row2);
         this.resize();
       //  this.colHead.width(50); 
       //  this.rowHead.height(50); 
      },
      _initHeaders: function(){
         for(var c=0;c<this.options.rowModel.length;c++){
            this.addRow(this.options.rowModel[c]);
         }
         for(var c=0;c<this.options.colModel.length;c++){
            this.addCol(this.options.colModel[c]);
         }
      },
      _resizeOptimizerLevel2: function(){
         console.log("this.colHeadLabel.width",this.colHeadLabel.width());
         this.rowHead.height(this.totalHeight-this.colHeadLabel.height()-
                             3*this.options.mainTableBorder);
         this.colHead.width(this.totalWidth-this.colHeadLabel.width()-
                             3*this.options.mainTableBorder);
         this.dataArea.width(this.dataTable.width()+40);
         this.dataArea.height(this.dataTable.height()+40);
         this.dataScrollArea.width(this.colHead.width());
         this.dataScrollArea.height(this.rowHead.height());
      },
      // interface:
      resize: function(){
         this.colHead.width(1);
         this.rowHead.height(1);
         this.dataScrollArea.width(1);
         this.dataScrollArea.height(1);
         this.totalWidth=this.element.width();
         this.totalHeight=this.element.height();

         console.log("totalWidth",this.totalWidth);
         console.log("totalHeight",this.totalHeight);
         var o=this;
         setTimeout(function(){o._resizeOptimizerLevel2();},1);
      },
      addCol: function(col){
            var label=col.name;
            if (col.label!=undefined){
               label=col.label;
            }
            col.d=$("<div>"+label+"</div>");
            if (col.width){
               col.d.css('width',col.width+'px');
            }
            col.d.css('text-align',"center");
            col.d.css('border-right-width',"1px");
            col.d.css('border-right-style',"solid");
            col.d.css('border-right-color',"black");
            col.e=$("<td nowrap id='"+col.name+"'></td>");
            if (col.width){
               col.e.css('width',col.width+'px');
            }
            col.d.appendTo(col.e);
            col.e.appendTo(this.colHeadRow);
            console.log("addCol ",col.name);
            $('tbody tr', this.dataTable).each(function (i){
               var div=$("<div>X</div>");
               var td=$("<td></td>");
               if (col.width){
                  div.width(col.width);
                  td.width(col.width);
               }
            div.css('text-align',"center");
            div.css('border-right-width',"1px");
            div.css('border-right-style',"solid");
            div.css('border-right-color',"black");
            div.css('border-bottom-width',"1px");
            div.css('border-bottom-style',"solid");
            div.css('border-bottom-color',"black");
               div.appendTo(td);
               td.appendTo(this);
            });
            
 

      },
      addRow: function(row){
            var label=row.name;
            if (row.label!=undefined){
               label=row.label;
            }
            var tr=$("<tr id='"+row.name+"'></tr>");
            row.d=$("<div>"+label+"</div>");
            row.d.css('border-bottom-width',"1px");
            row.d.css('border-bottom-style',"solid");
            row.d.css('border-bottom-color',"black");
            row.e=$("<td></td>");
            row.d.appendTo(row.e);
            row.e.appendTo(tr);
            tr.appendTo(this.rowTable);

            var dataRow=$("<tr></tr>");
            dataRow.appendTo(this.dataTable);
            console.log("addRow ",row.name);
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

