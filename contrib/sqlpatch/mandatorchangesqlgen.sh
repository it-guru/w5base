#!/bin/bash
OLDGRPID="10000000000001,10000000000002,10000000000003,\
          10000000000004,10000000000006,14837587240001"
NEWGRPID="200"
(
for t in $(mysql -NBf -e "select a.table_name from information_schema.columns a 
                          where a.column_name='mandator' and 
                          column_type='bigint(20)';"); do
#   if [ "$t" != "lnkqrulemandator" ]; then
      echo "update $t set mandator=${NEWGRPID} where mandator in (${OLDGRPID});"
#   fi
done
) | mysql -f
