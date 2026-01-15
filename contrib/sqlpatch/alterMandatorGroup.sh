#!/bin/bash
OLDGRPID="17480408690014"
NEWGRPID="17649822400001"
(
echo "update mandator set grpid='${NEWGRPID}' where grpid='${OLDGRPID}';"
for t in $(mysql -NBf -e "select a.table_name from information_schema.columns a 
                          where a.column_name='mandator' and 
                          column_type='bigint(20)';"); do
#   if [ "$t" != "lnkqrulemandator" ]; then
      echo "update $t set mandator=${NEWGRPID} where mandator in (${OLDGRPID});"
#   fi
done
) | mysql -f
