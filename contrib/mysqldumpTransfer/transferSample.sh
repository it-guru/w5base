#!/bin/bash
SRCHOST="w5testapp"
SRCDB="w5basetest1"

DSTHOST="w5basedb01"
DSTDB="w5base2"

IDLIST="(14109489800001,14109490390001,14109490540001,14109490670001,14370535950001,14370539450001,14370542040001,14370544240001,14370549100001,14370551430002,14373792500003,14373795280001,14373798280001,14373800560001,14373807430003,14373809470001,14373811070001,14373814810001,14373817830001,14373821480001,14373823080005,14373824780005,14373826370001,14373828850001,14373837070004,14373838980001,14373848900001,14373851130001,14373856050001,14373860280001,14373862720001,14373865700001,14373868660001,14373871910001,14373874000001,14373875950001,14424818890001,14424819060001)"

MYSQLDUMP="/usr/bin/mysqldump"
DUMPPARAM="--defaults-file=~/.my.cnf --complete-insert \
           --no-create-db --no-create-info --extended-insert=FALSE"

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   system --where=\"id in $IDLIST\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   lnkapplsystem --where=\"system in $IDLIST\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   ipaddress --where=\"system in $IDLIST\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   lnksoftwaresystem --where=\"system in $IDLIST\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   grpindivsystem --where=\"dataobjid in $IDLIST\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   lnkcontact --where=\"refid in $IDLIST and parentobj=\\\"itil::system\\\"\" \
      | ssh $DSTHOST mysql --force $DSTDB

ssh $SRCHOST $MYSQLDUMP $DUMPPARAM  $SRCDB \
   phonenumber --where=\"refid in $IDLIST and parentobj=\\\"itil::system\\\"\" \
      | ssh $DSTHOST mysql --force $DSTDB


