/*-----------------------------------\
| correct sort of date with notation |
| dd.mm.yyyy hh:mm:ss ...            |
\-----------------------------------*/

function mkdatesortable(str) {
   var ret=new String(str);
   var date_de=/^\d{2}\.\d{2}\.\d{4}/;

   if (date_de.test(ret)) {
      var dt =ret.split(" ");
      var dmy=dt[0].split(".");

      ret=dmy[2]+dmy[1]+dmy[0]+dt[1];
   }

   return ret;
}

SortableTable.prototype.addSortType("iDate",mkdatesortable);
