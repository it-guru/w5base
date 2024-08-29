#!/bin/bash

if [ "$W5BASESITE" = "" ]; then
   W5BASESITE="https://w5base-testenv.telekom.de"
fi

AssetW5BaseID="16128769720001"

AddContacts="16191623190003 12344399120001"

for USERID in $AddContacts; do
   JSONREQ=$(
      jq -n \
         --arg OP "save" \
         --arg refid "${AssetW5BaseID}" \
         --arg targetid "${USERID}" \
         --arg target   "base::user" \
         --arg CV '(id)' \
         "{OP: \$OP,CurrentView: \$CV,refid: \$refid, \
           target: \$target,targetid: \$targetid}"
   )
   echo "JSON=$JSONREQ"
   RES=$( curl -X POST "${W5BASESITE}/darwin/auth/itil/lnkassetcontact/Modify" \
               -H 'Content-Type: application/json' \
               -H 'Accept: application/json' \
               -n -s \
               -d "${JSONREQ}"
   )
   echo "RES=$RES"

done


