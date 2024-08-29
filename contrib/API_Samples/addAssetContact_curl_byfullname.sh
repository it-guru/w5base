#!/bin/bash

if [ "$W5BASESITE" = "" ]; then
   W5BASESITE="https://w5base-testenv.telekom.de"
fi

AssetW5BaseID="16128769720001"

AddContacts='service: apollo_x@telekom.com'

JSONREQ=$(
   jq -n \
      --arg refid "${AssetW5BaseID}" \
      --arg target "\"${AddContacts}\"" \
      --arg CV '(userid,cistatusid)' \
      "{CurrentView: \$CV, \
        search_fullname: \$target}"
)

RES=$( curl -X POST "${W5BASESITE}/darwin/auth/base/user/Result" \
            -H 'Content-Type: application/json' \
            -H 'Accept: application/json' \
            -n -s \
            -d "${JSONREQ}"
)
USERID=$(echo "$RES" | jq -r '.[0].userid' 2>/dev/null)

if [ ! -z "$USERID" ]; then
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
fi



